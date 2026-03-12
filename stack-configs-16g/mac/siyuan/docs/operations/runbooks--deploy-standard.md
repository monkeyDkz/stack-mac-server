# Runbook : Deploiement Standard

*Procedure de deploiement avec verification, rollback et communication*

## Pre-requis (STOP si un item echoue)

### Code

- [ ] PR mergee sur `main` (squash merge)
- [ ] Tous les tests CI passes (unit + integration)
- [ ] Code review approuvee (min 1 reviewer)
- [ ] Pas de CVE critique dans les dependances (`npm audit`, `pip-audit`)

### Environnement

- [ ] Pas d'incident en cours (verifier Uptime Kuma / alerting)
- [ ] Pas de deploy en cours sur un autre service
- [ ] Fenetre de deploy respectee (eviter vendredi 17h)
- [ ] Backup recente de la base (< 24h)

### Verification pre-deploy

```bash
# Verifier l'etat de tous les services
curl -sf http://host.docker.internal:8050/health/deep | python3 -m json.tool

# Verifier Uptime Kuma (pas d'alerte active)
# Dashboard : https://status.home

# Verifier les dernieres erreurs
docker compose logs --tail=50 SERVICE_NAME 2>&1 | grep -i error

# Verifier l'espace disque
df -h /var/lib/docker
```

## Procedure de deploiement

### Etape 1 : Preparation

```bash
# Se positionner dans le repo
cd /path/to/project

# Verifier qu'on est sur main et a jour
git checkout main
git pull origin main

# Verifier le tag/commit a deployer
git log --oneline -5
```

### Etape 2 : Deploiement canary (si applicable)

```bash
# Build de la nouvelle image
docker compose build --no-cache SERVICE_NAME

# Deployer un seul replica d'abord
docker compose up -d --scale SERVICE_NAME=2 SERVICE_NAME

# Verifier les logs du nouveau container
docker compose logs --tail=20 -f SERVICE_NAME
# Attendre 2-5 min, verifier pas d'erreur

# Si OK, couper l'ancien
docker compose up -d SERVICE_NAME
```

### Etape 3 : Deploiement rolling (standard)

```bash
# Build et deploy en une commande
docker compose pull SERVICE_NAME 2>/dev/null || true
docker compose build SERVICE_NAME
docker compose up -d SERVICE_NAME

# Verifier que le container demarre
docker compose ps SERVICE_NAME
```

### Etape 4 : Deploiement via n8n (automatise)

```bash
# Declencher via webhook n8n
curl -X POST "$N8N_WEBHOOK_URL/agent-event" \
  -H "Content-Type: application/json" \
  -H "X-N8N-Agent-Key: $N8N_AGENT_KEY" \
  -d '{
    "event": "deploy",
    "agent": "devops",
    "task_id": "PAPER-XX",
    "payload": {
      "repo": "SERVICE_NAME",
      "branch": "main",
      "run_tests": true,
      "notify": true
    }
  }'
```

## Verification post-deploy (obligatoire)

### Health checks

```bash
# Health check du service (doit retourner 200)
curl -sf http://localhost:PORT/health
curl -sf http://localhost:PORT/api/health

# Health check approfondi
curl -sf http://localhost:PORT/health/deep | python3 -m json.tool
```

### Smoke tests

```bash
# Tester les endpoints critiques
# GET sur une ressource connue
curl -sf http://localhost:PORT/api/v1/RESOURCE | head -c 200

# POST de test (si applicable)
curl -sf -X POST http://localhost:PORT/api/v1/RESOURCE \
  -H "Content-Type: application/json" \
  -d '{"test": true}' | head -c 200
```

### Verification des logs

```bash
# Pas d'erreur dans les 2 premieres minutes
docker compose logs --tail=100 SERVICE_NAME 2>&1 | grep -i -E "error|fatal|panic|exception"

# Verifier les metriques de base
# - Temps de reponse (pas de regression)
# - Taux d'erreur (doit etre 0)
# - Memory usage (pas de leak evident)
docker stats --no-stream SERVICE_NAME
```

### Verification fonctionnelle

- [ ] Les pages principales se chargent
- [ ] L'authentification fonctionne
- [ ] Les operations CRUD de base fonctionnent
- [ ] Les integrations externes repondent (Mem0, SiYuan, etc.)

## Rollback (si probleme)

### Criteres de rollback

| Signal | Action |
|--------|--------|
| Health check echoue | Rollback immediat |
| Taux d'erreur > 1% | Rollback immediat |
| Temps de reponse p95 > 2x normal | Rollback si persiste > 5 min |
| Feature ne fonctionne pas | Evaluer : fix forward ou rollback |

### Procedure de rollback

```bash
# Option 1 : Revenir a l'image precedente
docker compose down SERVICE_NAME
git checkout HEAD~1 -- docker-compose.yml  # ou tag specifique
docker compose up -d SERVICE_NAME

# Option 2 : Utiliser un tag specifique
docker compose pull SERVICE_NAME:PREVIOUS_TAG
docker compose up -d SERVICE_NAME

# Option 3 : Rollback complet via git
git revert HEAD
git push origin main
# Puis re-deployer

# Option 4 : Rollback via n8n
curl -X POST "$N8N_WEBHOOK_URL/agent-event" \
  -H "X-N8N-Agent-Key: $N8N_AGENT_KEY" \
  -d '{
    "event": "deploy",
    "agent": "devops",
    "payload": {
      "repo": "SERVICE_NAME",
      "branch": "main",
      "tag": "PREVIOUS_TAG"
    }
  }'
```

### Apres un rollback

1. Verifier que le service est stable
2. Creer un post-mortem si impact utilisateur
3. Sauvegarder dans Mem0 :

```bash
curl -X POST http://host.docker.internal:8050/memories \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Rollback SERVICE: [raison]. Commit: [hash]. Impact: [description].",
    "user_id": "devops",
    "metadata": {
      "type": "incident",
      "project": "PROJECT_SLUG",
      "confidence": "validated"
    }
  }'
```

## Communication

### Template de notification pre-deploy

```
[DEPLOY] SERVICE_NAME v1.2.3
- Changements: [resume en 1-2 lignes]
- PR: #123
- Responsable: [agent]
- Fenetre estimee: 5 min
```

### Template de notification post-deploy

```
[DEPLOY OK] SERVICE_NAME v1.2.3
- Deploye a: HH:MM
- Health: OK
- Smoke tests: OK
```

### Template de notification rollback

```
[ROLLBACK] SERVICE_NAME v1.2.3 → v1.2.2
- Raison: [description courte]
- Impact: [description]
- Status: Service restaure
- Post-mortem: [lien ou a venir]
```

## Checklist resume

```
PRE-DEPLOY
[ ] PR mergee, tests OK
[ ] Pas d'incident en cours
[ ] Backup recente
[ ] Health check pre-deploy OK

DEPLOY
[ ] Build
[ ] Start nouveau container
[ ] Verifier logs (pas d'erreur)

POST-DEPLOY
[ ] Health check OK
[ ] Smoke tests OK
[ ] Logs propres (2 min)
[ ] Notification envoyee

SI PROBLEME
[ ] Rollback
[ ] Notification rollback
[ ] Mem0 incident
[ ] Post-mortem si impact
```
