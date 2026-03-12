# Guide d'analyse de couts

> Ce document definit le modele de cout, les metriques a suivre, les budgets
> par agent et les strategies d'optimisation pour le systeme multi-agent.
> L'inference etant locale (Ollama), le cout principal est le compute.

---

## Modele de cout

### Couts directs

| Composant              | Cout                    | Notes                                    |
|------------------------|-------------------------|------------------------------------------|
| Inference Ollama       | 0 EUR (local)           | Pas d'API externe, tout tourne en local  |
| Compute (RAM + GPU)    | ~0.15 EUR/h             | Estimation pour M5 Pro en charge IA      |
| Electricite            | Inclus dans le compute  | Estimation moyenne usage domestique      |
| Stockage Mem0 + Chroma | Negligeable             | Disque local SSD, pas de cloud           |

### Couts indirects

| Composant                  | Mesure                      | Source                        |
|----------------------------|-----------------------------|-------------------------------|
| Tokens in/out par agent    | Nombre de tokens consommes  | Paperclip cost-events         |
| Temps d'execution          | Duree par tache             | Paperclip /tasks              |
| Nombre de requetes Mem0    | Appels API memoire          | Logs Mem0                     |
| Nombre de requetes Chroma  | Appels vectoriels           | Logs Chroma                   |

### Estimation cout mensuel

En supposant un usage moyen de 8h/jour, 5j/semaine :

```
Cout compute mensuel = 0.15 EUR/h x 8h/j x 22j/mois = ~26.40 EUR/mois
```

Ce cout est fixe independamment du nombre d'agents ou de taches (la machine tourne).
L'objectif est donc d'**optimiser le debit** (taches completees par heure) plutot que
de reduire un cout variable.

---

## Metriques a tracker

| Metrique                    | Source                       | Frequence    |
|-----------------------------|------------------------------|--------------|
| Tokens in/out par agent     | Paperclip API /cost-events   | Temps reel   |
| Nombre de heartbeats        | Paperclip API                | Quotidien    |
| Duree d'execution par tache | Paperclip API /tasks         | Par tache    |
| Appels API externes         | Logs d'execution n8n         | Quotidien    |
| Memoires creees par jour    | Mem0 /stats                  | Quotidien    |
| Requetes Chroma par jour    | Logs Chroma                  | Quotidien    |

### Requetes de collecte

```bash
# Tokens par agent aujourd'hui
curl -s "http://localhost:3001/api/cost-events?since=$(date -I)" | \
  jq 'group_by(.agent_id) | map({
    agent: .[0].agent_id,
    tokens_in: (map(.tokens_in) | add),
    tokens_out: (map(.tokens_out) | add)
  })'

# Heartbeats par agent
curl -s "http://localhost:3001/api/agents" | \
  jq '.[] | {id: .id, heartbeats_today: .heartbeatsToday}'

# Duree moyenne par tache completee
curl -s "http://localhost:3001/api/tasks?status=completed&since=$(date -I)" | \
  jq '[.[].duration_seconds] | add / length | . / 60 | floor | tostring + " minutes"'
```

---

## Budget par agent

| Agent          | Niveau de budget | Justification                                      |
|----------------|------------------|----------------------------------------------------|
| CEO            | Pas de limite    | Decisions strategiques, ne doit pas etre bloque     |
| CTO            | Eleve            | Orchestration, reviews, decisions architecture      |
| Lead Backend   | Moyen            | Developpement actif, reviews                       |
| Lead Frontend  | Moyen            | Developpement actif, reviews                       |
| CPO            | Moyen            | PRDs, priorisation, coordination                   |
| DevOps         | Modere           | Deploiements, monitoring                           |
| Security       | Modere           | Audits periodiques, veille                         |
| QA             | Modere           | Tests, rapports qualite                            |
| Designer       | Modere           | Composants, reviews design                         |
| Researcher     | Modere           | Veille, recherche, benchmarks                      |
| CFO            | Faible           | Reporting periodique, analyses                     |

### Configuration dans Paperclip

Le budget mensuel est configurable par agent via le champ `budgetMonthlyCents` :

```json
{
  "agentId": "lead-backend",
  "budgetMonthlyCents": 5000,
  "alertThresholdPercent": 80
}
```

Quand un agent atteint le seuil d'alerte, une notification est envoyee au CFO.
Quand le budget est depasse, les taches non prioritaires sont mises en pause.

---

## Procedure de review cout (CFO)

### Cycle hebdomadaire

1. **Lundi matin** : le CFO tire le rapport hebdomadaire via le workflow n8n WF16.
2. **Analyse** : comparaison du cout reel avec le budget alloue pour chaque agent.
3. **Variance** : si la variance depasse 10%, le CFO declenche une alerte CEO.
4. **Depassement** : si un agent depasse son budget, le CFO recommande une optimisation :
   - Downgrade du modele (14b au lieu de 32b pour les taches simples).
   - Batching des taches similaires.
   - Augmentation de l'intervalle de heartbeat.
5. **Rapport mensuel** : synthese des tendances, calcul du ROI, recommandations.

### Rapport hebdomadaire type

```
=== Rapport hebdomadaire des couts - Semaine XX ===

Total tokens consommes : XXX,XXX
Repartition par agent :
  - CTO     : XX,XXX tokens (XX% du total)
  - Backend : XX,XXX tokens (XX% du total)
  - ...

Agents en depassement : aucun / [liste]
Tendance vs semaine precedente : +X% / -X%

Recommandations :
  - [si applicable]
```

### Rapport mensuel type

Le rapport mensuel inclut :
- Cout total du mois et comparaison avec le mois precedent.
- Repartition par agent avec graphique de tendance.
- ROI : nombre de taches completees / cout total.
- Top 5 des taches les plus couteuses.
- Recommandations d'optimisation pour le mois suivant.

---

## Strategies d'optimisation

### Selection du modele par complexite

| Complexite de la tache     | Modele recommande   | Tokens estimes |
|----------------------------|---------------------|----------------|
| Simple (formatage, tri)    | qwen2.5:14b         | < 1000         |
| Moyenne (analyse, review)  | qwen2.5:32b         | 1000 - 5000    |
| Complexe (architecture)    | qwen2.5:32b         | > 5000         |

La selection du modele peut etre configuree dans LiteLLM via les regles de routage.

### Batching des taches

- Regrouper les taches similaires pour un meme agent reduit l'overhead de contexte.
- Exemple : au lieu de 5 code reviews separees, les grouper en une seule session.
- Le CTO peut configurer le batching via Paperclip.

### Cache memoire (Mem0)

- Avant de lancer une inference, verifier si la reponse existe deja dans Mem0.
- Les decisions deja prises ne doivent pas etre recalculees.
- Le cache evite les doublons et reduit la consommation de tokens.

### Heartbeat tuning

| Activite de l'agent | Intervalle heartbeat recommande |
|----------------------|---------------------------------|
| Tres actif (CTO)     | 30 secondes                     |
| Actif (Leads)        | 60 secondes                     |
| Modere (Specialists) | 120 secondes                    |
| Faible (CFO)         | 300 secondes                    |

### Optimisation des prompts

- Eliminer les instructions redondantes dans les prompts systeme.
- Utiliser des references memoire plutot que de repeter le contexte.
- Limiter les exemples dans les prompts (1-2 suffisent generalement).
- Mesurer le nombre de tokens du prompt systeme et viser < 2000 tokens.

---

## References

- [dashboards--agent-metrics](../global/dashboards--agent-metrics.md) : dashboard des metriques agents
- [monitoring--alerting-rules](./monitoring--alerting-rules.md) : regles d'alerte et de monitoring
