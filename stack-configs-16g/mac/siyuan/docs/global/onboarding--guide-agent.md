# Guide d'Onboarding Agent

*Procedure complete pour le premier eveil d'un agent IA*

## Premiere chose a faire au premier reveil

A chaque demarrage, un agent DOIT executer ces 4 etapes dans l'ordre.

### 1. Charger les conventions

Recuperer les conventions actives depuis la memoire partagee du CTO :

```bash
curl -X POST "http://host.docker.internal:8050/search/filtered" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "conventions standards regles guidelines",
    "user_id": "cto",
    "filters": {
      "$and": [
        {"type": {"$eq": "convention"}},
        {"state": {"$eq": "active"}}
      ]
    },
    "limit": 10
  }'
```

Les conventions couvrent :
- Git workflow (branching, commits, PR)
- Code review checklist
- API design (REST, error format, pagination)
- Nommage (TypeScript, Python, SQL)
- Testing (pyramide, AAA, coverage)

### 2. Charger l'architecture

Recuperer les decisions architecturales et la stack technique :

```bash
curl -X POST "http://host.docker.internal:8050/search/filtered" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "architecture stack decisions technology",
    "user_id": "cto",
    "filters": {
      "$and": [
        {"type": {"$in": ["architecture", "decision"]}},
        {"state": {"$eq": "active"}}
      ]
    },
    "limit": 10
  }'
```

### 3. Lire les docs SiYuan

Charger les documents de reference depuis la knowledge base :

```bash
# Lire les conventions (notebook architecture)
curl -X POST "http://host.docker.internal:6806/api/query/sql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"stmt": "SELECT b.content, b.hpath FROM blocks b WHERE b.type = '\''d'\'' AND b.hpath LIKE '\''%conventions%'\'' ORDER BY b.updated DESC LIMIT 10"}'

# Lire les guidelines de ton domaine
curl -X POST "http://host.docker.internal:6806/api/query/sql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"stmt": "SELECT b.content, b.hpath FROM blocks b WHERE b.type = '\''d'\'' AND b.hpath LIKE '\''%guidelines%'\'' ORDER BY b.updated DESC LIMIT 10"}'
```

### 4. Signaler ton arrivee

Enregistrer ton activation dans la memoire partagee :

```bash
curl -X POST "http://host.docker.internal:8050/memories" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Agent [NOM] operationnel. Role: [ROLE]. Contexte charge: conventions, architecture, guidelines [DOMAINE].",
    "user_id": "[NOM]",
    "metadata": {
      "type": "context",
      "project": "global",
      "confidence": "validated"
    }
  }'
```

## Services disponibles

### Mac (local — acces Docker)

| Service | URL interne (Docker) | URL externe | Port | Auth | Usage |
|---------|---------------------|-------------|:----:|------|-------|
| Mem0 | `http://host.docker.internal:8050` | `http://localhost:8050` | 8050 | Aucune | Memoire persistante |
| SiYuan | `http://host.docker.internal:6806` | `http://localhost:6806` | 6806 | Token header | Knowledge base |
| Paperclip | `http://localhost:3100` | `http://localhost:8060` | 3100/8060 | Bearer token | Orchestration |
| Ollama | `http://host.docker.internal:11434` | `http://localhost:11434` | 11434 | Aucune | LLM inference |
| LiteLLM | `http://host.docker.internal:4000` | `http://localhost:4000` | 4000 | API key | Proxy LLM |
| Chroma | `http://host.docker.internal:8000` | `http://localhost:8000` | 8000 | Aucune | Base vectorielle |
| LobeChat | - | `http://localhost:3210` | 3210 | - | Interface chat humain |

### Serveur (via NetBird VPN)

| Service | URL | Auth |
|---------|-----|------|
| n8n | `https://n8n.home/webhook` | `X-N8N-Agent-Key` header |
| Gitea | `https://git.home` | Token |
| PostgreSQL | `postgresql://user:pass@server:5432/db` | Connection string |
| Uptime Kuma | `https://status.home` | Dashboard (lecture seule) |

## Protocole memoire obligatoire

Chaque memoire sauvegardee dans Mem0 DOIT inclure ces metadata :

| Champ | Type | Valeurs possibles | Obligatoire |
|-------|------|-------------------|:-----------:|
| `type` | string | `decision`, `learning`, `bug`, `architecture`, `convention`, `prd`, `research`, `incident`, `pattern`, `report`, `context` | Oui |
| `project` | string | Slug du projet ou `"global"` | Oui |
| `confidence` | string | `hypothesis`, `tested`, `validated` | Oui |
| `state` | string | `active`, `deprecated`, `archived` | Auto (defaut: active) |
| `created` | string | `YYYY-MM-DD` | Auto |

### Niveaux de confiance

| Niveau | Definition | Quand l'utiliser |
|--------|-----------|-----------------|
| `hypothesis` | Hypothese non testee | Premiere idee, recherche preliminaire |
| `tested` | Teste mais pas valide en production | POC concluant, tests locaux OK |
| `validated` | Valide en production / par le CTO | Deploye et fonctionne, ou approuve |

### Exemples

```bash
# Decision technique
curl -X POST "http://host.docker.internal:8050/memories" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Choix de Redis pour le cache de sessions. Raison: deja dans la stack, TTL natif, performances <1ms. Alternative evaluee: memcached (rejete car pas de persistence).",
    "user_id": "cto",
    "metadata": {"type": "decision", "project": "auth-service", "confidence": "tested"}
  }'

# Bug decouvert
curl -X POST "http://host.docker.internal:8050/memories" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Bug: le endpoint /search retourne 500 quand query est vide. Cause: validation manquante. Fix: ajouter z.string().min(1) sur le schema.",
    "user_id": "lead-backend",
    "metadata": {"type": "bug", "project": "mem0-api", "confidence": "validated"}
  }'

# Apprentissage
curl -X POST "http://host.docker.internal:8050/memories" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Ollama: charger 2 modeles simultanement (32b + 14b) fonctionne avec OLLAMA_MAX_LOADED_MODELS=2 si RAM >= 40GB disponible. Switch time: 0s au lieu de 15s.",
    "user_id": "devops",
    "metadata": {"type": "learning", "project": "global", "confidence": "validated"}
  }'
```

## Regles de lecture cross-agent

### Ce que chaque agent peut lire

| Agent | Ses propres memoires | Memoires CTO | Memoires autres agents |
|-------|:-------------------:|:------------:|:---------------------:|
| CTO | Oui | - | Oui (toutes) |
| Lead Backend | Oui | Oui | Oui (meme projet) |
| Lead Frontend | Oui | Oui | Oui (meme projet) |
| DevOps | Oui | Oui | Oui (meme projet) |
| CPO | Oui | Oui | Oui (produit seulement) |
| Security | Oui | Oui | Oui (toutes) |
| QA | Oui | Oui | Oui (meme projet) |
| Researcher | Oui | Oui | Oui (research seulement) |

### Recherche multi-agent

```bash
# Lire les memoires de plusieurs agents
curl -X POST "http://host.docker.internal:8050/search/multi" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "authentication decision",
    "user_ids": ["cto", "lead-backend", "security"],
    "limit_per_user": 3
  }'
```

## Communication entre agents

### Via n8n webhook

```bash
curl -X POST "$N8N_WEBHOOK_URL/agent-event" \
  -H "Content-Type: application/json" \
  -H "X-N8N-Agent-Key: $N8N_AGENT_KEY" \
  -d '{
    "event": "notify",
    "agent": "[MON_NOM]",
    "task_id": "PAPER-XX",
    "payload": {
      "target": "[AGENT_CIBLE]",
      "message": "[Message]",
      "priority": "normal"
    }
  }'
```

### Events disponibles

| Event | Description | Payload |
|-------|-------------|---------|
| `deploy` | Declencher un deploiement | `{repo, branch, tag, run_tests}` |
| `notify` | Notifier un agent | `{target, message, priority}` |
| `scrape` | Scraper une page web | `{url, format, callback}` |
| `git` | Action Git (PR, merge) | `{action, repo, branch}` |
| `crm-sync` | Synchroniser avec Twenty CRM | `{entity, data}` |

## Checklist d'onboarding

- [ ] Conventions chargees depuis Mem0
- [ ] Architecture chargee depuis Mem0
- [ ] Docs SiYuan lues (conventions + guidelines de ton domaine)
- [ ] Arrivee signalee dans Mem0
- [ ] Profil Paperclip verifie (`GET /api/agents/me`)
- [ ] Premier health check des services dependants
