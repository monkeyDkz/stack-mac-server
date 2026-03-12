# Mem0 API — Reference

## Vue d'ensemble

Mem0 est la **memoire persistante des agents**. Chaque agent lit/ecrit sous son `user_id`. Le serveur custom (port 8050) ajoute : filtres avances, lifecycle, stats, timeline, deduplication.

Base URL : `http://localhost:8050` (depuis le Mac)
Depuis Docker : `http://host.docker.internal:8050`

## Endpoints principaux

### Sauvegarder une memoire

```bash
POST /memories
Content-Type: application/json

{
  "text": "Decision : utiliser PostgreSQL pour la persistence. Raison : requetes complexes, JSONB, fiabilite.",
  "user_id": "cto",
  "metadata": {
    "type": "decision",
    "project": "saas-app",
    "confidence": "validated",
    "tags": "database,architecture"
  }
}
```

**Metadata obligatoires** (protocole memoire v2) :

| Champ | Valeurs | Obligatoire |
|-------|---------|-------------|
| `type` | `decision`, `learning`, `bug`, `architecture`, `convention`, `context`, `task`, `research` | Oui |
| `project` | `global`, `saas-app`, etc. | Oui |
| `confidence` | `hypothesis`, `tested`, `validated` | Oui |

Le serveur ajoute automatiquement : `state: active`, `created: <date>`.

### Rechercher des memoires

```bash
# Recherche simple
POST /search
{
  "query": "quelle base de donnees",
  "user_id": "cto",
  "limit": 10
}

# Recherche avec filtres
POST /search/filtered
{
  "query": "decisions architecture",
  "user_id": "cto",
  "filters": {
    "type": {"$eq": "decision"},
    "project": {"$eq": "saas-app"},
    "state": {"$eq": "active"}
  },
  "limit": 10
}

# Recherche multi-agent
POST /search/multi
{
  "query": "conventions API",
  "user_ids": ["cto", "lead-backend", "lead-frontend"],
  "limit_per_user": 5
}
```

### Lifecycle des memoires

```bash
# Deprecier une memoire
PATCH /memories/{id}/state
{
  "state": "deprecated"
}

# Archiver
PATCH /memories/{id}/state
{
  "state": "archived"
}
```

Lifecycle : `active` → `deprecated` → `archived`

### Timeline

```bash
# Memoires recentes d'un agent
GET /timeline/cto?since=2026-03-01&limit=20
```

### Stats

```bash
# Stats d'un agent
GET /stats/cto
# → {total, by_type, by_project, by_state, by_confidence}

# Stats globales
GET /stats
```

### Health

```bash
GET /health
# → {"status": "ok"}

GET /health/deep
# → {status, ollama, chroma, memory_count, uptime}
```

## Deduplication

Le serveur detecte automatiquement les doublons (cosine similarity > 0.92) quand `deduplicate: true` :

```bash
POST /memories
{
  "text": "Utiliser PostgreSQL pour la persistence",
  "user_id": "cto",
  "metadata": {"type": "decision", "project": "global", "confidence": "validated"},
  "deduplicate": true
}
```

Si un doublon est detecte, la memoire existante est mise a jour au lieu d'en creer une nouvelle.

## Flux de memoire entre agents

```
CEO decisions ──→ Mem0 "ceo" ──→ CTO, CPO lisent
CTO architecture ──→ Mem0 "cto" ──→ Tous les devs lisent
CPO specs ──→ Mem0 "cpo" ──→ CTO, Designer lisent
Designer tokens ──→ Mem0 "designer" ──→ Lead Frontend lit
Lead Backend bugs ──→ Mem0 "lead-backend" ──→ QA, Frontend lisent
Researcher findings ──→ Mem0 "researcher" ──→ TOUS lisent
```

### User IDs systeme (alimentes par n8n)

| user_id | Contenu |
|---------|---------|
| `monitoring` | Metriques services, alertes |
| `analytics` | Stats usage, performance |
| `deployments` | Historique deploys |
| `git-events` | Commits, PRs, reviews |
| `security-events` | CVE detectees, scans |

## Decision Records

Format structure pour les decisions importantes :

```bash
POST /memories
{
  "text": "DECISION: Utiliser JWT avec refresh token rotation\nCONTEXT: Besoin d'auth stateless pour API multi-clients\nCHOICE: JWT access (15min) + refresh (7j) avec rotation\nALTERNATIVES: Sessions serveur (trop de state), API keys (pas de refresh)\nCONSEQUENCES: + Stateless, + Scalable, - Complexite token refresh\nSTATUS: accepted\nLINKED_TASK: ISSUE-234",
  "user_id": "cto",
  "metadata": {
    "type": "decision",
    "project": "saas-app",
    "confidence": "validated",
    "tags": "auth,jwt,security"
  }
}
```

## Operateurs de filtre

| Operateur | Exemple |
|-----------|---------|
| `$eq` | `{"type": {"$eq": "decision"}}` |
| `$ne` | `{"state": {"$ne": "archived"}}` |
| `$gt`, `$gte` | `{"confidence_score": {"$gte": 0.8}}` |
| `$lt`, `$lte` | `{"created": {"$lt": "2026-03-01"}}` |
| `$in` | `{"type": {"$in": ["decision", "convention"]}}` |
| `$nin` | `{"state": {"$nin": ["archived", "deprecated"]}}` |

## Bonnes pratiques agents

1. **Toujours mettre les 3 metadata obligatoires** : type, project, confidence
2. **Lire avant d'ecrire** : chercher si une memoire similaire existe deja
3. **Utiliser `deduplicate: true`** pour eviter les doublons
4. **Promouvoir la confidence** : `hypothesis` → `tested` → `validated` (QA/Security)
5. **Deprecier plutot que supprimer** : lifecycle `active` → `deprecated`
6. **Cross-agent reading** : utiliser `/search/multi` pour lire plusieurs agents
7. **Decision Records** pour toute decision architecture/technique importante
