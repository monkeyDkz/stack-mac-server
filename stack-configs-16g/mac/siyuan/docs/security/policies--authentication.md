# Standards d'Authentification

*Password hashing, JWT, sessions, OAuth2, MFA*

## Mots de passe

### Hashing

```
Algorithme : argon2id (prefere) ou bcrypt (acceptable)
Parametres argon2id :
  - memory: 64 MB (65536 KB)
  - iterations: 3
  - parallelism: 4
Parametres bcrypt :
  - cost factor: >= 12 (viser 100-250ms par hash)
```

```typescript
// argon2 (recommande)
import argon2 from 'argon2';

const hash = await argon2.hash(password, {
  type: argon2.argon2id,
  memoryCost: 65536,
  timeCost: 3,
  parallelism: 4,
});

const isValid = await argon2.verify(hash, password);
```

```python
# argon2 via passlib
from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=["argon2"],
    argon2__memory_cost=65536,
    argon2__time_cost=3,
    argon2__parallelism=4,
)

hashed = pwd_context.hash(password)
is_valid = pwd_context.verify(password, hashed)
```

### Politique de mots de passe

| Regle | Valeur | Justification |
|-------|--------|---------------|
| Longueur minimum | 12 caracteres | NIST SP 800-63B |
| Longueur maximum | 128 caracteres | Prevenir DoS via hashing |
| Complexite forcee | Non | NIST deconseille les regles arbitraires |
| Blocklist | Oui | Verifier contre HaveIBeenPwned top 100k |
| Expiration forcee | Non | NIST deconseille la rotation forcee |
| Indicateur de force | Oui | Afficher un meter (zxcvbn) |

```typescript
// Verification contre les mots de passe compromis (k-anonymity)
import crypto from 'node:crypto';

async function isPasswordBreached(password: string): Promise<boolean> {
  const sha1 = crypto.createHash('sha1').update(password).digest('hex').toUpperCase();
  const prefix = sha1.slice(0, 5);
  const suffix = sha1.slice(5);

  const res = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`);
  const text = await res.text();
  return text.includes(suffix);
}
```

## JWT (JSON Web Tokens)

### Configuration

```
Access Token:
  - Algorithme: RS256 ou ES256 (asymetrique)
  - Expiration: 15 minutes
  - Stockage client: httpOnly cookie (pas localStorage)
  - Claims: sub, iat, exp, role

Refresh Token:
  - Expiration: 7 jours
  - Rotation: nouveau refresh token a chaque utilisation
  - Stockage: httpOnly cookie + hash en BDD
  - Revocation: supprimer de la BDD au logout
```

### Structure des claims

```json
{
  "sub": "usr_abc123",
  "iat": 1710200000,
  "exp": 1710200900,
  "role": "admin",
  "permissions": ["read:users", "write:users"]
}
```

### Implementation

```typescript
import jwt from 'jsonwebtoken';
import { readFileSync } from 'node:fs';

const PRIVATE_KEY = readFileSync('./keys/private.pem');
const PUBLIC_KEY = readFileSync('./keys/public.pem');

function createAccessToken(user: User): string {
  return jwt.sign(
    { sub: user.id, role: user.role },
    PRIVATE_KEY,
    { algorithm: 'RS256', expiresIn: '15m' }
  );
}

function createRefreshToken(user: User): string {
  return jwt.sign(
    { sub: user.id, type: 'refresh' },
    PRIVATE_KEY,
    { algorithm: 'RS256', expiresIn: '7d' }
  );
}

function verifyToken(token: string): JwtPayload {
  return jwt.verify(token, PUBLIC_KEY, {
    algorithms: ['RS256'],
  }) as JwtPayload;
}
```

### Token rotation

```typescript
async function refreshTokens(refreshToken: string): Promise<TokenPair> {
  // 1. Verifier le refresh token
  const payload = verifyToken(refreshToken);
  if (payload.type !== 'refresh') throw new Error('Invalid token type');

  // 2. Verifier que le token est en BDD (pas revoque)
  const stored = await tokenRepo.findByHash(hashToken(refreshToken));
  if (!stored) {
    // Token reutilise apres rotation → compromis
    // Revoquer TOUS les tokens de l'utilisateur
    await tokenRepo.revokeAllForUser(payload.sub);
    throw new SecurityError('Refresh token reuse detected');
  }

  // 3. Revoquer l'ancien refresh token
  await tokenRepo.revoke(stored.id);

  // 4. Emettre de nouveaux tokens
  const user = await userRepo.findById(payload.sub);
  const newAccess = createAccessToken(user);
  const newRefresh = createRefreshToken(user);

  // 5. Stocker le hash du nouveau refresh token
  await tokenRepo.store({
    userId: user.id,
    hash: hashToken(newRefresh),
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  });

  return { accessToken: newAccess, refreshToken: newRefresh };
}
```

### Cookies securises

```typescript
// Configuration des cookies
const COOKIE_OPTIONS = {
  httpOnly: true,     // Pas accessible via JavaScript
  secure: true,       // HTTPS uniquement
  sameSite: 'lax' as const,  // Protection CSRF
  path: '/',
  maxAge: 15 * 60,    // 15 min pour access
};

const REFRESH_COOKIE_OPTIONS = {
  ...COOKIE_OPTIONS,
  path: '/api/auth/refresh',  // Envoye uniquement au refresh endpoint
  maxAge: 7 * 24 * 60 * 60,  // 7 jours
};
```

## Sessions

```
ID de session: crypto.randomUUID() (128 bits d'entropie)
Stockage: Redis (serveur), jamais dans le cookie
Expiration: 24h d'inactivite, 7j absolue
```

```typescript
// Gestion de session avec Redis
import { randomUUID } from 'node:crypto';

async function createSession(userId: string): Promise<string> {
  const sessionId = randomUUID();
  await redis.set(`session:${sessionId}`, JSON.stringify({
    userId,
    createdAt: Date.now(),
    lastActivity: Date.now(),
  }), 'EX', 24 * 60 * 60); // 24h TTL

  return sessionId;
}

async function validateSession(sessionId: string): Promise<Session | null> {
  const data = await redis.get(`session:${sessionId}`);
  if (!data) return null;

  const session = JSON.parse(data);

  // Verifier l'expiration absolue (7 jours)
  if (Date.now() - session.createdAt > 7 * 24 * 60 * 60 * 1000) {
    await redis.del(`session:${sessionId}`);
    return null;
  }

  // Renouveler le TTL (sliding window)
  session.lastActivity = Date.now();
  await redis.set(`session:${sessionId}`, JSON.stringify(session), 'EX', 24 * 60 * 60);

  return session;
}

async function destroySession(sessionId: string): Promise<void> {
  await redis.del(`session:${sessionId}`);
}
```

### Regles de session

- Regenerer l'ID apres login (prevenir session fixation)
- Invalider toutes les sessions au changement de mot de passe
- Limiter les sessions actives par utilisateur (max 5)

## OAuth2 / OpenID Connect

### Flux recommande : Authorization Code + PKCE

```
1. Client genere code_verifier + code_challenge
2. Client redirige vers /authorize?response_type=code&code_challenge=...
3. Utilisateur se connecte chez le provider
4. Provider redirige vers callback avec ?code=...
5. Client echange code + code_verifier contre tokens
```

### Providers supportes

| Provider | Client ID env var | Usage |
|----------|-------------------|-------|
| Authelia (interne) | `AUTHELIA_CLIENT_ID` | SSO interne |

## MFA (Multi-Factor Authentication)

### TOTP (Time-based One-Time Password)

```typescript
import { authenticator } from 'otplib';

// Setup : generer le secret
const secret = authenticator.generateSecret();
const otpAuthUrl = authenticator.keyuri(user.email, 'Paperclip', secret);
// Afficher le QR code de otpAuthUrl

// Verification
function verifyTotp(token: string, secret: string): boolean {
  return authenticator.verify({ token, secret });
}
```

### Regles MFA

- Obligatoire pour les comptes admin
- Optionnel mais recommande pour tous
- Codes de recovery : 10 codes a usage unique, stockes hashes
- TOTP prefere aux SMS (SIM swapping)

## Rate limiting sur l'authentification

| Endpoint | Limite | Fenetre | Action si depasse |
|----------|:------:|:-------:|-------------------|
| POST /auth/login | 5 req | 15 min | 429 + lockout 15 min |
| POST /auth/register | 3 req | 1 heure | 429 |
| POST /auth/reset-password | 3 req | 1 heure | 429 |
| POST /auth/verify-mfa | 5 req | 5 min | 429 + lockout |

## Services internes

| Service | Methode d'auth | Token / Config |
|---------|---------------|----------------|
| Mem0 | Aucune (reseau Docker interne) | N/A |
| SiYuan | Token header | `Authorization: Token paperclip-siyuan-token` |
| Paperclip | Bearer token | `Authorization: Bearer <agent-api-key>` |
| n8n | Header custom | `X-N8N-Agent-Key: <key>` |
| Ollama | Aucune (localhost) | N/A |
| PostgreSQL | User/password | Connection string dans env |
| Redis | Password (optionnel) | `REDIS_URL` dans env |

## Checklist

- [ ] Mots de passe hashes avec argon2id (ou bcrypt cost >= 12)
- [ ] JWT avec algorithme asymetrique (RS256 / ES256)
- [ ] Access token expiration <= 15 min
- [ ] Refresh token rotation + detection de reutilisation
- [ ] Cookies httpOnly + secure + sameSite
- [ ] Rate limiting sur tous les endpoints auth
- [ ] Account lockout apres 5 echecs
- [ ] Session regeneration apres login
- [ ] MFA disponible pour les admins
- [ ] Logout invalide les tokens
