# OWASP Top 10 — 2021

*Checklist par categorie avec exemples de code et tests*

## A01: Broken Access Control

### Description
L'utilisateur accede a des ressources ou actions non autorisees. Inclut IDOR, privilege escalation, CORS misconfiguration.

### Prevention

```typescript
// BIEN — Verifier les permissions a chaque requete
async function getOrder(orderId: string, currentUser: User): Promise<Order> {
  const order = await orderRepo.findById(orderId);
  if (!order) throw new NotFoundError('Order not found');

  // Verifier que l'utilisateur a le droit d'acceder a cette commande
  if (order.userId !== currentUser.id && currentUser.role !== 'admin') {
    throw new ForbiddenError('Access denied');
  }
  return order;
}
```

```python
# BIEN — Middleware de verification des permissions
@router.get("/orders/{order_id}")
async def get_order(order_id: str, current_user: User = Depends(get_current_user)):
    order = await order_repo.find_by_id(order_id)
    if not order:
        raise HTTPException(404, "Order not found")
    if order.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(403, "Access denied")
    return order
```

### Checklist
- [ ] Verifier les permissions a chaque endpoint (pas seulement cote client)
- [ ] Pas d'IDOR : verifier l'ownership des ressources
- [ ] CORS configure strictement (pas `*` en production)
- [ ] Tokens avec expiration courte (15 min access, 7j refresh)
- [ ] Default deny : tout est interdit sauf explicitement autorise

## A02: Cryptographic Failures

### Description
Donnees sensibles exposees par manque de chiffrement ou chiffrement faible.

### Prevention

```typescript
// Hashing de mots de passe avec argon2
import argon2 from 'argon2';

async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 65536,  // 64 MB
    timeCost: 3,
    parallelism: 4,
  });
}

async function verifyPassword(hash: string, password: string): Promise<boolean> {
  return argon2.verify(hash, password);
}
```

```python
# Hashing avec passlib + argon2
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

### Checklist
- [ ] HTTPS partout (Caddy gere le TLS)
- [ ] Mots de passe hashes avec argon2id ou bcrypt (cost >= 12)
- [ ] Secrets dans les variables d'env, jamais dans le code
- [ ] Donnees sensibles chiffrees au repos (AES-256-GCM)
- [ ] Pas de MD5 ou SHA1 pour le hashing de secrets

## A03: Injection

### Description
Donnees non fiables envoyees a un interprete (SQL, NoSQL, OS, LDAP).

### Prevention

```typescript
// MAL — Injection SQL
const query = `SELECT * FROM users WHERE email = '${email}'`;

// BIEN — Query parametree
const user = await db.query('SELECT * FROM users WHERE email = $1', [email]);

// BIEN — ORM (Prisma)
const user = await prisma.user.findUnique({ where: { email } });
```

```python
# MAL — Injection SQL
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# BIEN — Query parametree
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

# BIEN — ORM (SQLAlchemy)
user = session.query(User).filter(User.email == email).first()
```

```typescript
// XSS — Sanitization
import DOMPurify from 'isomorphic-dompurify';

const safeHtml = DOMPurify.sanitize(userInput);
```

### Checklist
- [ ] Queries parametrees partout (pas de concatenation)
- [ ] ORM ou query builder pour les requetes
- [ ] Sanitization HTML en sortie (DOMPurify)
- [ ] Validation des inputs avec schemas (zod / pydantic)
- [ ] CSP header pour prevenir XSS inline

## A04: Insecure Design

### Description
Failles dans la conception meme, avant meme l'implementation.

### Prevention
- Threat modeling avant implementation des features critiques
- Rate limiting sur les endpoints sensibles
- Limites metier (ex: max 3 tentatives de login, max 10 transfers/jour)

### Checklist
- [ ] Threat modeling pour les features auth/paiement/admin
- [ ] Rate limiting sur login, signup, reset password
- [ ] Limites metier documentees et implementees
- [ ] Separation des privileges (least privilege)

## A05: Security Misconfiguration

### Description
Configuration par defaut, headers manquants, permissions trop larges.

### Prevention

```
# Headers de securite (Caddy / Express / FastAPI)
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; script-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

### Checklist
- [ ] Headers de securite configures (voir ci-dessus)
- [ ] Pas de page d'erreur verbose en production (pas de stack traces)
- [ ] Ports non necessaires fermes
- [ ] Credentials par defaut changees
- [ ] Mode debug desactive en production
- [ ] Docker : pas de containers en root

## A06: Vulnerable and Outdated Components

### Description
Utilisation de librairies avec des vulnerabilites connues.

### Prevention

```bash
# Audit regulier
pnpm audit                 # Node.js
pip-audit                  # Python
docker scout cves IMAGE    # Docker

# Mise a jour automatisee
# Renovate ou Dependabot configure sur le repo
```

### Checklist
- [ ] Audit des dependances hebdomadaire
- [ ] Lock files utilises et commites
- [ ] Zero CVE critique en production
- [ ] CVE haute corrigee dans les 72h
- [ ] Renovate/Dependabot configure

## A07: Identification and Authentication Failures

### Description
Failles dans l'authentification : brute force, session fixation, credentials faibles.

### Prevention

```typescript
// Rate limiting sur le login
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,                    // 5 tentatives max
  message: { error: 'Too many login attempts, try again later' },
  standardHeaders: true,
});

app.post('/auth/login', loginLimiter, loginHandler);
```

```python
# Account lockout
MAX_ATTEMPTS = 5
LOCKOUT_DURATION = timedelta(minutes=15)

async def login(email: str, password: str) -> TokenPair:
    user = await user_repo.find_by_email(email)
    if user and user.locked_until and user.locked_until > datetime.utcnow():
        raise HTTPException(429, "Account locked, try again later")

    if not user or not verify_password(password, user.password_hash):
        if user:
            user.failed_attempts += 1
            if user.failed_attempts >= MAX_ATTEMPTS:
                user.locked_until = datetime.utcnow() + LOCKOUT_DURATION
            await user_repo.save(user)
        raise HTTPException(401, "Invalid credentials")

    user.failed_attempts = 0
    user.locked_until = None
    await user_repo.save(user)
    return create_token_pair(user)
```

### Checklist
- [ ] Rate limiting sur login (5 tentatives / 15 min)
- [ ] Account lockout apres N echecs
- [ ] Mots de passe >= 12 caracteres
- [ ] Tokens JWT avec expiration courte
- [ ] Refresh token rotation
- [ ] Logout invalide le token (blacklist ou DB)

## A08: Software and Data Integrity Failures

### Description
Code ou donnees modifiees sans verification d'integrite.

### Checklist
- [ ] Verification d'integrite des dependances (checksums, lockfiles)
- [ ] CI/CD securise (pas de secrets en clair dans les logs)
- [ ] Code review obligatoire pour les merges sur main
- [ ] Images Docker signees ou hash verifie
- [ ] Pas de telechargement de scripts non verifies (`curl | bash`)

## A09: Security Logging and Monitoring Failures

### Description
Manque de logs ou de monitoring pour detecter les attaques.

### Checklist
- [ ] Login / logout logues (avec IP et user agent)
- [ ] Echecs d'authentification logues
- [ ] Actions admin loguees (qui, quoi, quand)
- [ ] Tentatives d'acces non autorise loguees
- [ ] Logs ne contiennent PAS de donnees sensibles (mots de passe, tokens)
- [ ] Logs centralises et immutables
- [ ] Alertes sur les patterns suspects (voir alerting-rules)

## A10: Server-Side Request Forgery (SSRF)

### Description
L'application effectue des requetes HTTP vers une URL controllee par l'attaquant.

### Prevention

```typescript
// Validation des URLs
function isAllowedUrl(url: string): boolean {
  const parsed = new URL(url);
  const allowedHosts = ['api.example.com', 'cdn.example.com'];

  // Bloquer les IP privees
  const blockedPatterns = [
    /^10\./,
    /^172\.(1[6-9]|2[0-9]|3[01])\./,
    /^192\.168\./,
    /^127\./,
    /^0\./,
    /^169\.254\./,
    /localhost/i,
  ];

  if (blockedPatterns.some(p => p.test(parsed.hostname))) {
    return false;
  }

  return allowedHosts.includes(parsed.hostname);
}
```

### Checklist
- [ ] Validation et whitelist des URLs en entree
- [ ] Blocage des IP privees / localhost / metadata endpoints
- [ ] Pas de redirection ouverte
- [ ] Timeout court sur les requetes sortantes (5s)
- [ ] Logging des requetes sortantes

## Checklist globale de securite (revue periodique)

```
[ ] OWASP Top 10 couvert (cette checklist)
[ ] Dependances auditees (0 CVE critique)
[ ] Secrets en env vars (pas dans le code)
[ ] HTTPS partout
[ ] Headers de securite configures
[ ] Rate limiting sur les endpoints sensibles
[ ] Logs de securite actifs
[ ] Monitoring et alerting fonctionnels
[ ] Backup recentes et testees
[ ] Plan de reponse aux incidents documente
```
