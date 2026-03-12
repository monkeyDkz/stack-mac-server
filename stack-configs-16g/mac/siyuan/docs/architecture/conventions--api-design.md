# Conventions API Design (REST)

*Base : Microsoft REST API Guidelines, Zalando RESTful API Guidelines, RFC 7807*

## Principes

1. **API-first** — designer l'API avant de coder
2. **Coherence** — memes conventions partout, memes patterns
3. **Evolutivite** — concevoir pour le changement sans casser les clients

## Nommage des URLs

```
# Ressources au pluriel, kebab-case
GET    /api/v1/user-profiles
GET    /api/v1/user-profiles/{id}
POST   /api/v1/user-profiles
PUT    /api/v1/user-profiles/{id}
PATCH  /api/v1/user-profiles/{id}
DELETE /api/v1/user-profiles/{id}

# Sous-ressources pour les relations
GET    /api/v1/users/{id}/memories
POST   /api/v1/users/{id}/memories

# Actions non-CRUD (verbe en POST)
POST   /api/v1/users/{id}/activate
POST   /api/v1/users/{id}/reset-password
POST   /api/v1/reports/generate
```

### Regles de nommage

| Regle | Exemple | Interdit |
|-------|---------|----------|
| Pluriel | `/users` | `/user` |
| kebab-case | `/user-profiles` | `/userProfiles`, `/user_profiles` |
| Pas de verbe dans l'URL | `POST /users` | `POST /createUser` |
| IDs dans le path | `/users/{id}` | `/users?id=123` (pour un seul) |
| Max 3 niveaux | `/users/{id}/tasks` | `/users/{id}/tasks/{tid}/comments/{cid}/reactions` |

## Methodes HTTP

| Methode | Usage | Idempotent | Code succes | Body requis |
|---------|-------|:----------:|:-----------:|:-----------:|
| GET | Lire une ressource / collection | Oui | 200 | Non |
| POST | Creer une ressource | Non | 201 | Oui |
| PUT | Remplacer entierement | Oui | 200 | Oui |
| PATCH | Modifier partiellement | Non | 200 | Oui |
| DELETE | Supprimer | Oui | 204 | Non |
| HEAD | Verifier l'existence | Oui | 200/404 | Non |
| OPTIONS | Decouvrir les capabilities | Oui | 200 | Non |

## Format des reponses

### Succes (objet unique)

```json
{
  "data": {
    "id": "usr_abc123",
    "name": "Alice",
    "email": "alice@example.com",
    "createdAt": "2026-03-11T10:00:00Z"
  }
}
```

### Succes (collection)

```json
{
  "data": [
    { "id": "usr_abc123", "name": "Alice" },
    { "id": "usr_def456", "name": "Bob" }
  ],
  "pagination": {
    "cursor": "eyJpZCI6InVzcl9kZWY0NTYifQ==",
    "hasMore": true,
    "totalCount": 142
  }
}
```

### Erreur (RFC 7807 — Problem Details)

```json
{
  "type": "https://api.example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "Le champ email est invalide.",
  "instance": "/api/v1/users",
  "errors": [
    {
      "field": "email",
      "code": "INVALID_FORMAT",
      "message": "L'adresse email n'est pas au bon format"
    },
    {
      "field": "name",
      "code": "TOO_SHORT",
      "message": "Le nom doit faire au moins 2 caracteres"
    }
  ]
}
```

### Codes HTTP courants

| Code | Signification | Quand l'utiliser |
|:----:|---------------|------------------|
| 200 | OK | GET, PUT, PATCH reussi |
| 201 | Created | POST reussi (+ header `Location`) |
| 204 | No Content | DELETE reussi |
| 400 | Bad Request | Input malformed (JSON invalide) |
| 401 | Unauthorized | Pas de token ou token invalide |
| 403 | Forbidden | Token valide mais pas les droits |
| 404 | Not Found | Ressource inexistante |
| 409 | Conflict | Duplication (email existe deja) |
| 422 | Unprocessable | Validation echouee (champs invalides) |
| 429 | Too Many Requests | Rate limit atteint |
| 500 | Internal Error | Erreur serveur inattendue |

## Versioning

```
# Via le path (recommande pour notre stack)
/api/v1/users
/api/v2/users

# Regles de versioning
# - v1 reste stable tant que des clients l'utilisent
# - Nouvelles features → ajouter a v1 (backward compatible)
# - Breaking changes → creer v2
# - Deprecation : header Sunset + min 6 mois de transition
```

Headers de deprecation :
```
Sunset: Sat, 01 Jan 2027 00:00:00 GMT
Deprecation: true
Link: <https://api.example.com/v2/users>; rel="successor-version"
```

## Pagination (cursor-based)

```bash
# Premiere page
GET /api/v1/users?limit=20

# Pages suivantes (cursor opaque)
GET /api/v1/users?limit=20&cursor=eyJpZCI6InVzcl9kZWY0NTYifQ==
```

### Pourquoi cursor-based plutot qu'offset

| Critere | Offset (`?page=3&per_page=20`) | Cursor |
|---------|-------------------------------|--------|
| Performance | O(n) — degrade avec le volume | O(1) — constant |
| Coherence | Elements manques/dupliques si insertion | Stable |
| Simplicite client | Plus simple | Un peu plus complexe |
| Recommandation | Petits datasets (< 10k) | Toujours |

## Filtrage et tri

```bash
# Filtrage par champ
GET /api/v1/users?status=active&role=admin

# Filtrage par date
GET /api/v1/users?created_after=2026-01-01&created_before=2026-12-31

# Tri
GET /api/v1/users?sort=created_at&order=desc

# Tri multiple
GET /api/v1/users?sort=role,-created_at

# Recherche full-text
GET /api/v1/users?q=alice
```

## Rate Limiting

Headers a inclure sur chaque reponse :

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1710200000
Retry-After: 30
```

Seuils recommandes :

| Endpoint | Limite | Fenetre |
|----------|:------:|---------|
| GET (lecture) | 100 req | par minute |
| POST (ecriture) | 30 req | par minute |
| Auth (login) | 5 req | par minute |
| Upload | 10 req | par heure |

## Authentification

```bash
# Bearer token (JWT)
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...

# API key (services internes)
X-API-Key: sk_live_abc123def456

# Token SiYuan
Authorization: Token paperclip-siyuan-token
```

## HATEOAS (liens de navigation)

```json
{
  "data": { "id": "usr_abc123", "name": "Alice" },
  "_links": {
    "self": { "href": "/api/v1/users/usr_abc123" },
    "memories": { "href": "/api/v1/users/usr_abc123/memories" },
    "tasks": { "href": "/api/v1/users/usr_abc123/tasks" }
  }
}
```

## Conventions pour notre stack

| Regle | Detail |
|-------|--------|
| Prefixe | Toujours `/api/v1/` |
| IDs | UUID v4, prefixe par type (`usr_`, `mem_`, `tsk_`) |
| Dates | ISO 8601 UTC : `2026-03-11T10:00:00Z` |
| Enums | snake_case en minuscules : `in_progress`, `not_started` |
| Booleans | Jamais de `is_` prefix dans le JSON (reserve au code) |
| Null | Omettre le champ plutot que `"field": null` |
| Validation | Zod (TS) ou Pydantic (Python) sur chaque input |
