# Regles d'Alerting et Monitoring

*SLI/SLO, seuils d'alerte, escalation, bonnes pratiques*

## Principes

1. **Alerter sur les symptomes, pas les causes** — "le temps de reponse est > 500ms" plutot que "le CPU est a 90%"
2. **Chaque alerte doit etre actionnable** — si on ne peut rien faire, ce n'est pas une alerte
3. **Eviter l'alert fatigue** — moins d'alertes mais plus pertinentes
4. **SLO-based alerting** — les alertes protegent les SLOs

## SLI / SLO Definitions

### SLI (Service Level Indicators)

| SLI | Mesure | Outil |
|-----|--------|-------|
| Disponibilite | % de requetes reussies (status < 500) | Uptime Kuma |
| Latence | p50, p95, p99 du temps de reponse | Logs / Monitoring |
| Error rate | % de reponses 5xx | Logs |
| Throughput | Requetes par seconde | Logs |
| Saturation | Utilisation CPU, memoire, disque, connexions DB | Docker stats |

### SLO (Service Level Objectives)

| Service | Disponibilite | Latence p95 | Error rate | Budget d'erreur/mois |
|---------|:-------------:|:-----------:|:----------:|:--------------------:|
| API Backend | 99.9% | < 200ms | < 0.1% | 43 min downtime |
| Frontend | 99.5% | < 2s LCP | < 1% | 3.6h downtime |
| PostgreSQL | 99.99% | < 50ms | < 0.01% | 4.3 min downtime |
| Mem0 API | 99.5% | < 500ms | < 0.5% | 3.6h downtime |
| SiYuan | 99.0% | < 1s | < 1% | 7.3h downtime |
| Ollama | 95.0% | < 5s | < 5% | 36.5h downtime |

### Budget d'erreur

```
Budget mensuel = (1 - SLO) × 30 jours × 24h × 60min

Exemple pour SLO 99.9% :
  (1 - 0.999) × 30 × 24 × 60 = 43.2 minutes/mois

Si on a consomme 80% du budget → mode prudent (pas de deploy risque)
Si on a consomme 100% → freeze des deploys jusqu'au mois suivant
```

## Seuils d'alerte

### Services Mac (local)

| Service | Port | Metrique | Warning | Critical | Check interval |
|---------|:----:|----------|:-------:|:--------:|:--------------:|
| Ollama | 11434 | Response time | > 3s | > 10s | 60s |
| Ollama | 11434 | Uptime | < 99% | < 95% | 60s |
| Chroma | 8000 | Response time | > 500ms | > 2s | 30s |
| Chroma | 8000 | Uptime | < 99.5% | < 99% | 30s |
| Mem0 API | 8050 | Response time | > 300ms | > 1s | 30s |
| Mem0 API | 8050 | Uptime | < 99.5% | < 99% | 30s |
| SiYuan | 6806 | Response time | > 500ms | > 2s | 60s |
| SiYuan | 6806 | Uptime | < 99.5% | < 99% | 60s |
| Paperclip | 8060 | Response time | > 500ms | > 2s | 30s |
| LiteLLM | 4000 | Response time | > 1s | > 5s | 60s |

### Services Serveur

| Service | Metrique | Warning | Critical |
|---------|----------|:-------:|:--------:|
| PostgreSQL | Connexions actives | > 80% max | > 95% max |
| PostgreSQL | Replication lag | > 1s | > 10s |
| Redis | Memory usage | > 80% | > 95% |
| Caddy | Certificate expiry | < 14 jours | < 3 jours |
| Disque | Usage | > 80% | > 90% |
| Docker | Container restarts | > 3/heure | > 10/heure |

### Seuils systeme

| Ressource | Warning | Critical | Action |
|-----------|:-------:|:--------:|--------|
| CPU | > 80% pendant 5 min | > 95% pendant 2 min | Investiguer le process |
| Memoire | > 85% | > 95% | Identifier les leaks |
| Disque | > 80% | > 90% | Nettoyer docker, logs |
| Swap | > 50% | > 80% | Ajouter de la RAM ou optimiser |

## Escalation matrix

### P0 — Service principal down

```
T+0    : Alerte automatique (ntfy priority: urgent)
T+0    : Issue Paperclip auto-creee (assignee: devops)
T+5min : Notification SiYuan push (timeout: 0)
T+15min: Si pas de reponse → escalade CTO
T+30min: Si pas de resolution → mode incident (all hands)
```

### P1 — Degradation majeure

```
T+0    : Alerte ntfy (priority: high)
T+15min: Issue Paperclip creee
T+30min: Investigation attendue
T+1h   : Si pas de resolution → escalade
```

### P2 — Probleme mineur

```
T+0    : Log dans Mem0 (user_id: monitoring)
T+next heartbeat: Review par DevOps
T+24h  : Resolution attendue
```

### P3 — Information

```
T+0    : Log dans Mem0
T+next sprint: Evaluation et planification si necessaire
```

## On-call practices

### Responsabilites

| Responsabilite | Detail |
|----------------|--------|
| Temps de reponse | < 15 min pour P0/P1 |
| Triage | Evaluer la severite, commencer l'investigation |
| Communication | Notifier l'equipe si impact |
| Escalade | Si pas de resolution dans le SLA |
| Post-mortem | Rediger si P0/P1 |

### Rotation

```
Semaine 1 : devops (primary), cto (backup)
Semaine 2 : cto (primary), devops (backup)
```

## Prevention de l'alert fatigue

### Regles anti-fatigue

| Regle | Implementation |
|-------|---------------|
| Pas de "warning-only" alerts | Warning = log, Critical = notification |
| Chaque alerte a un runbook | L'alerte reference la doc de resolution |
| Review mensuelle | Supprimer les alertes non actionnable |
| Grouper les alertes | Pas 50 alertes pour le meme incident |
| Seuils adaptatifs | Ajuster les seuils si trop de faux positifs |

### Classification des alertes

| Type | Notification | Exemple |
|------|-------------|---------|
| **Page** (wake up) | ntfy urgent + SiYuan push | Service down P0 |
| **Ticket** (next business hour) | ntfy high + Paperclip issue | Degradation P1 |
| **Log** (review periodique) | Mem0 entry | Warning, tendance |

## Dashboards essentiels

### Dashboard Services (Uptime Kuma)

```
Pour chaque service :
- Uptime 24h / 7j / 30j
- Response time (p50, p95)
- Derniere erreur
- Certificat SSL expiry
```

### Dashboard Systeme

```
- CPU usage (graph 24h)
- Memory usage (graph 24h)
- Disk usage (% avec prediction)
- Network I/O
- Docker containers (running, stopped, restarting)
```

### Dashboard Application

```
- Requetes/seconde (graph)
- Error rate (graph)
- Latence p95 (graph)
- Top 10 endpoints les plus lents
- Derniers deployments
```

## Health check endpoints

Chaque service DOIT exposer :

```bash
# Health basique (process alive)
GET /health → 200 {"status": "ok"}

# Health approfondi (dependances)
GET /health/deep → 200 {
  "status": "ok",
  "checks": {
    "database": {"status": "ok", "latency_ms": 3},
    "redis": {"status": "ok", "latency_ms": 1},
    "ollama": {"status": "ok", "latency_ms": 150}
  }
}
```

## Configuration Uptime Kuma

```bash
# Ajouter un monitor via l'interface
# Type: HTTP(s)
# URL: http://SERVICE:PORT/health
# Interval: 30s
# Retries: 3
# Timeout: 10s
# Accepted status codes: 200
# Notification: ntfy
```
