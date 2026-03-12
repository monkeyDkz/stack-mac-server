# API Cheatsheet

*Reference rapide : tous les endpoints avec des exemples curl fonctionnels*

## Mem0 (port 8050)

Base URL : `http://host.docker.internal:8050`
Auth : Aucune (reseau Docker interne)

### Sauvegarder une memoire

```bash
curl -X POST http://host.docker.internal:8050/memories \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Description de la memoire a sauvegarder",
    "user_id": "cto",
    "metadata": {
      "type": "decision",
      "project": "global",
      "confidence": "tested"
    }
  }'

# Reponse
# {"id": "mem_abc123", "created_at": "2026-03-11T10:00:00Z"}
```

### Rechercher (avec filtres)

```bash
curl -X POST http://host.docker.internal:8050/search/filtered \
  -H "Content-Type: application/json" \
  -d '{
    "query": "architecture decision database",
    "user_id": "cto",
    "filters": {
      "$and": [
        {"type": {"$eq": "decision"}},
        {"state": {"$eq": "active"}}
      ]
    },
    "limit": 5
  }'

# Reponse : liste de memoires avec score de relevance
```

### Rechercher (multi-agent)

```bash
curl -X POST http://host.docker.internal:8050/search/multi \
  -H "Content-Type: application/json" \
  -d '{
    "query": "authentication oauth jwt",
    "user_ids": ["cto", "lead-backend", "security"],
    "limit_per_user": 3
  }'
```

### Changer l'etat d'une memoire

```bash
# Deprecier une memoire
curl -X PATCH http://host.docker.internal:8050/memories/mem_abc123/state \
  -H "Content-Type: application/json" \
  -d '{"state": "deprecated"}'

# Archiver
curl -X PATCH http://host.docker.internal:8050/memories/mem_abc123/state \
  -H "Content-Type: application/json" \
  -d '{"state": "archived"}'
```

### Timeline

```bash
# Dernieres memoires d'un agent
curl "http://host.docker.internal:8050/timeline/cto?since=2026-03-01&limit=10"
```

### Stats

```bash
# Stats globales
curl http://host.docker.internal:8050/stats

# Stats par agent
curl http://host.docker.internal:8050/stats/cto

# Reponse exemple:
# {"total": 142, "by_type": {"decision": 45, "learning": 30, ...}, "by_confidence": {...}}
```

### Health

```bash
# Health check rapide
curl http://host.docker.internal:8050/health

# Health check approfondi (inclut Chroma, PostgreSQL)
curl http://host.docker.internal:8050/health/deep
```

## SiYuan (port 6806)

Base URL : `http://host.docker.internal:6806`
Auth : `Authorization: Token paperclip-siyuan-token`

### Recherche SQL

```bash
# Trouver des documents par path
curl -X POST http://host.docker.internal:6806/api/query/sql \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"stmt": "SELECT b.id, b.content, b.hpath FROM blocks b WHERE b.type = '\''d'\'' AND b.hpath LIKE '\''%conventions%'\'' ORDER BY b.updated DESC LIMIT 10"}'

# Trouver des docs par attribut custom
curl -X POST http://host.docker.internal:6806/api/query/sql \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"stmt": "SELECT b.content, b.hpath, a.value FROM blocks b JOIN attributes a ON b.id = a.block_id WHERE a.name = '\''custom-type'\'' AND a.value = '\''guideline'\'' AND b.type = '\''d'\'' ORDER BY b.updated DESC"}'

# Recherche full-text
curl -X POST http://host.docker.internal:6806/api/query/sql \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"stmt": "SELECT b.id, b.content, b.hpath FROM blocks b WHERE b.content LIKE '\''%TypeScript%'\'' AND b.type = '\''p'\'' LIMIT 20"}'
```

### Creer un document

```bash
curl -X POST http://host.docker.internal:6806/api/filetree/createDocWithMd \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{
    "notebook": "NOTEBOOK_ID",
    "path": "/chemin/du/document",
    "markdown": "# Titre\n\nContenu du document..."
  }'
```

### Lire un document

```bash
# Par ID de block
curl -X POST http://host.docker.internal:6806/api/filetree/getDoc \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"id": "BLOCK_ID"}'
```

### Poser des attributs custom

```bash
curl -X POST http://host.docker.internal:6806/api/attr/setBlockAttrs \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{
    "id": "BLOCK_ID",
    "attrs": {
      "custom-project": "auth-service",
      "custom-type": "adr",
      "custom-status": "active",
      "custom-agent": "cto"
    }
  }'
```

### Notification push

```bash
curl -X POST http://host.docker.internal:6806/api/notification/pushMsg \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{
    "msg": "Deploy termine avec succes pour auth-service v1.2.3",
    "timeout": 7000
  }'
```

### Lister les notebooks

```bash
curl -X POST http://host.docker.internal:6806/api/notebook/lsNotebooks \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{}'
```

### Ajouter du contenu a un document

```bash
curl -X POST http://host.docker.internal:6806/api/block/appendBlock \
  -H "Content-Type: application/json" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{
    "data": "## Nouvelle section\n\nContenu ajoute.",
    "dataType": "markdown",
    "parentID": "DOC_BLOCK_ID"
  }'
```

## Paperclip (port 3100)

Base URL : `http://localhost:3100`
Auth : `Authorization: Bearer $PAPERCLIP_API_KEY`

### Mon profil

```bash
curl http://localhost:3100/api/agents/me \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

### Checkout une tache

```bash
curl -X POST http://localhost:3100/api/issues/ISSUE_ID/checkout \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY"
```

### Mettre a jour une tache

```bash
curl -X PATCH http://localhost:3100/api/issues/ISSUE_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -d '{"status": "done"}'
```

### Creer une tache

```bash
curl -X POST http://localhost:3100/api/companies/COMPANY_ID/issues \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -d '{
    "title": "[US] Add password reset flow",
    "body": "En tant que utilisateur, je veux reinitialiser mon mot de passe...",
    "assigneeAgentId": "AGENT_ID",
    "labels": ["feature", "auth"]
  }'
```

### Reporter les couts

```bash
curl -X POST http://localhost:3100/api/companies/COMPANY_ID/cost-events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -d '{
    "agentId": "AGENT_ID",
    "issueId": "ISSUE_ID",
    "provider": "ollama",
    "model": "qwen2.5:32b",
    "inputTokens": 1500,
    "outputTokens": 800,
    "costCents": 0
  }'
```

## n8n (webhook)

Base URL : `$N8N_WEBHOOK_URL`
Auth : `X-N8N-Agent-Key: $N8N_AGENT_KEY`

### Declencher un event

```bash
# Format generique
curl -X POST "$N8N_WEBHOOK_URL/agent-event" \
  -H "Content-Type: application/json" \
  -H "X-N8N-Agent-Key: $N8N_AGENT_KEY" \
  -d '{
    "event": "EVENT_TYPE",
    "agent": "AGENT_NAME",
    "task_id": "PAPER-XX",
    "payload": { ... }
  }'
```

### Deploy

```bash
curl -X POST "$N8N_WEBHOOK_URL/agent-event" \
  -H "Content-Type: application/json" \
  -H "X-N8N-Agent-Key: $N8N_AGENT_KEY" \
  -d '{
    "event": "deploy",
    "agent": "devops",
    "task_id": "PAPER-42",
    "payload": {
      "repo": "auth-service",
      "branch": "main",
      "run_tests": true,
      "notify": true
    }
  }'
```

### Notification

```bash
curl -X POST "$N8N_WEBHOOK_URL/agent-event" \
  -H "Content-Type: application/json" \
  -H "X-N8N-Agent-Key: $N8N_AGENT_KEY" \
  -d '{
    "event": "notify",
    "agent": "cto",
    "payload": {
      "target": "lead-backend",
      "message": "Code review requise sur PR #123",
      "priority": "high"
    }
  }'
```

### Scraping

```bash
curl -X POST "$N8N_WEBHOOK_URL/agent-event" \
  -H "Content-Type: application/json" \
  -H "X-N8N-Agent-Key: $N8N_AGENT_KEY" \
  -d '{
    "event": "scrape",
    "agent": "researcher",
    "payload": {
      "url": "https://example.com/article",
      "format": "markdown"
    }
  }'
```

## Ollama (port 11434)

Base URL : `http://host.docker.internal:11434`
Auth : Aucune

```bash
# Lister les modeles
curl http://host.docker.internal:11434/api/tags

# Generation de texte
curl -X POST http://host.docker.internal:11434/api/generate \
  -d '{"model": "qwen2.5:14b", "prompt": "Hello", "stream": false}'

# Chat
curl -X POST http://host.docker.internal:11434/api/chat \
  -d '{
    "model": "qwen2.5:32b",
    "messages": [{"role": "user", "content": "Explique le pattern Repository"}],
    "stream": false
  }'

# Embeddings
curl -X POST http://host.docker.internal:11434/api/embeddings \
  -d '{"model": "nomic-embed-text", "prompt": "texte a vectoriser"}'

# Modeles charges en memoire
curl http://host.docker.internal:11434/api/ps
```
