# Dashboard metriques agents

> Ce document definit l'ensemble des indicateurs cles de performance (KPIs)
> suivis pour chaque agent du systeme multi-agent, ainsi que les KPIs
> systeme, memoire et cout. Ces metriques alimentent les dashboards SiYuan.

---

## KPIs systeme (niveau Paperclip)

### Metriques operationnelles

| Metrique                          | Source                    | Frequence   | Cible              |
|-----------------------------------|---------------------------|-------------|---------------------|
| Taches creees par jour            | Paperclip API /tasks      | Quotidien   | Tracking            |
| Taches completees par jour        | Paperclip API /tasks      | Quotidien   | Tracking            |
| Taches creees par semaine         | Paperclip API /tasks      | Hebdomadaire| Tracking            |
| Taches completees par semaine     | Paperclip API /tasks      | Hebdomadaire| Tracking            |
| Temps moyen de resolution         | Paperclip API /tasks      | Quotidien   | < 30 min            |
| Taux de re-ouverture              | Paperclip API /tasks      | Hebdomadaire| < 5%                |
| Nombre d'escalades par semaine    | Paperclip API /tasks      | Hebdomadaire| < 3                 |

### Requete Paperclip pour taches completees

```bash
# Taches completees aujourd'hui
curl -s "http://localhost:3001/api/tasks?status=completed&since=$(date -I)" | \
  jq 'length'
```

### Requete SiYuan SQL pour dashboard

```sql
SELECT
  b.content AS agent,
  COUNT(*) AS taches_completees
FROM blocks b
WHERE b.hpath LIKE '%task%'
  AND b.ial LIKE '%status=completed%'
GROUP BY b.content
ORDER BY taches_completees DESC
```

---

## KPIs par agent

| Agent          | KPI                        | Cible            | Mesure                                        |
|----------------|----------------------------|------------------|-----------------------------------------------|
| CEO            | Decisions par semaine       | >= 3             | Mem0 query `type=decision user_id=ceo`        |
| CTO            | Knowledge reviews           | >= 1/mois        | Mem0 query `type=architecture`                |
| CTO            | ADRs crees                  | Tracking         | SiYuan query `hpath LIKE '%adr%'`             |
| CPO            | PRDs actifs                 | Tracking         | Mem0 query `type=prd state=active`            |
| CFO            | Rapports cout               | >= 1/semaine     | Mem0 query `type=report user_id=cfo`          |
| Lead Backend   | Latence P95                 | < 200ms          | Monitoring systeme                            |
| Lead Backend   | Coverage                    | > 85%            | Rapports CI                                   |
| Lead Frontend  | Lighthouse perf             | > 90             | Rapports CI                                   |
| Lead Frontend  | Core Web Vitals             | LCP<2.5s, CLS<0.1 | Monitoring systeme                          |
| DevOps         | Deploys reussis             | > 95%            | Logs n8n                                      |
| DevOps         | Temps de deploy             | < 10min          | Logs n8n                                      |
| Security       | Vulnerabilites ouvertes     | 0 critiques      | Mem0 query `type=vulnerability`               |
| QA             | Coverage globale            | > 80%            | Rapports CI                                   |
| QA             | Bugs non resolus            | < 5              | Mem0 query `type=bug state=active`            |
| Designer       | Composants documentes       | 100%             | SiYuan query                                  |
| Researcher     | Digests publies             | >= 1/semaine     | Mem0 query `type=research`                    |

### Exemples de requetes Mem0 par agent

```bash
# Decisions du CEO cette semaine
curl -s "http://localhost:8050/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "decision",
    "user_id": "ceo",
    "filters": {"type": "decision"},
    "limit": 50
  }' | jq '[.[] | select(.created_at > "2026-03-04")] | length'

# Vulnerabilites critiques ouvertes
curl -s "http://localhost:8050/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "vulnerability",
    "user_id": "security",
    "filters": {"type": "vulnerability", "state": "active"}
  }' | jq '[.[] | select(.metadata.severity == "critical")] | length'

# PRDs actifs du CPO
curl -s "http://localhost:8050/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "prd",
    "user_id": "cpo",
    "filters": {"type": "prd", "state": "active"}
  }' | jq 'length'
```

---

## KPIs memoire (sante Mem0)

### Ratios de sante

| Indicateur                                  | Cible           | Alerte si        |
|---------------------------------------------|-----------------|------------------|
| Ratio memoires actives                      | > 70%           | < 50%            |
| Ratio memoires deprecated                   | < 15%           | > 25%            |
| Ratio memoires archived                     | < 30%           | N/A              |
| Hypothesis non promues > 14 jours           | 0               | > 5              |
| Memoires sans source_task (orphelines)      | < 5%            | > 10%            |
| Taux de duplication (cosine > 0.92)         | < 2%            | > 5%             |

### Requetes Mem0 pour indicateurs de sante

```bash
# Ratio actives / total
TOTAL=$(curl -s "http://localhost:8050/memories" | jq 'length')
ACTIVE=$(curl -s "http://localhost:8050/memories?filter=state:active" | jq 'length')
echo "Ratio actives: $(echo "scale=2; $ACTIVE / $TOTAL * 100" | bc)%"

# Hypothesis non promues depuis > 14 jours
curl -s "http://localhost:8050/memories?filter=confidence:hypothesis" | \
  jq '[.[] | select(
    (now - (.updated_at | fromdateiso8601)) / 86400 > 14
  )] | length'

# Memoires orphelines (sans source_task)
curl -s "http://localhost:8050/memories?filter=state:active" | \
  jq '[.[] | select(.metadata.source_task == null)] | length'
```

### Detection de duplication

```bash
# Verifier les doublons potentiels pour un agent
curl -s "http://localhost:8050/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "TEXTE_MEMOIRE",
    "user_id": "AGENT_ID",
    "threshold": 0.92
  }' | jq '[.[] | select(.score > 0.92)]'
```

---

## KPIs cout (CFO)

### Metriques de cout

| Metrique                           | Source                      | Frequence    |
|------------------------------------|-----------------------------|--------------|
| Cout total par agent par semaine   | Paperclip /cost-events      | Hebdomadaire |
| Cout par tache completee           | Paperclip /cost-events      | Par tache    |
| Budget utilise vs alloue           | Paperclip /agents           | Quotidien    |
| Tendance mensuelle                 | Paperclip /cost-events      | Mensuel      |
| Tokens in/out par agent            | Paperclip /cost-events      | Temps reel   |

### Requetes cout

```bash
# Cout total par agent cette semaine
curl -s "http://localhost:3001/api/cost-events?since=$(date -d '-7 days' -I)" | \
  jq 'group_by(.agent_id) | map({
    agent: .[0].agent_id,
    total_tokens_in: (map(.tokens_in) | add),
    total_tokens_out: (map(.tokens_out) | add)
  })'

# Budget restant par agent
curl -s "http://localhost:3001/api/agents" | \
  jq '.[] | {
    agent: .id,
    budget_mensuel: .budgetMonthlyCents,
    utilise: .currentMonthSpendCents,
    restant: (.budgetMonthlyCents - .currentMonthSpendCents)
  }'
```

### Seuils budgetaires

| Niveau d'utilisation | Couleur | Action                                          |
|----------------------|---------|-------------------------------------------------|
| < 70%                | Vert    | Aucune action                                   |
| 70% - 90%            | Orange  | Notification CFO                                |
| > 90%                | Rouge   | Alerte CEO + recommandation d'optimisation      |
| > 100%               | Critique| Suspension possible des taches non prioritaires  |

---

## Implementation

### Workflows n8n

| Workflow | Nom                      | Frequence    | Description                              |
|----------|--------------------------|--------------|------------------------------------------|
| WF14     | Agent Metrics Collector   | Toutes les heures | Collecte les metriques par agent    |
| WF15     | Memory Health Check       | Quotidien    | Verifie la sante de Mem0                 |
| WF16     | Cost Report Generator     | Hebdomadaire | Genere le rapport de cout CFO            |

### SiYuan SQL query embeds pour dashboards live

```sql
-- Dashboard : taches par agent (embed SiYuan)
SELECT
  ial_value(b.ial, 'agent') AS agent,
  COUNT(CASE WHEN ial_value(b.ial, 'status') = 'completed' THEN 1 END) AS completees,
  COUNT(CASE WHEN ial_value(b.ial, 'status') = 'in_progress' THEN 1 END) AS en_cours,
  COUNT(CASE WHEN ial_value(b.ial, 'status') = 'blocked' THEN 1 END) AS bloquees
FROM blocks b
WHERE b.type = 'p'
  AND b.hpath LIKE '%tasks%'
GROUP BY agent
ORDER BY completees DESC
```

```sql
-- Dashboard : memoires par type (embed SiYuan)
SELECT
  ial_value(b.ial, 'type') AS type_memoire,
  COUNT(*) AS nombre,
  ial_value(b.ial, 'state') AS etat
FROM blocks b
WHERE b.hpath LIKE '%memory%'
GROUP BY type_memoire, etat
ORDER BY nombre DESC
```

---

## References

- [dashboards--all-projects](./dashboards--all-projects.md) : vue d'ensemble de tous les projets
- [monitoring--alerting-rules](../operations/monitoring--alerting-rules.md) : regles d'alerte et de monitoring
- [templates--sprint-report](./templates--sprint-report.md) : modele de rapport de sprint
