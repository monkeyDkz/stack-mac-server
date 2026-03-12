# Politique de fraicheur des connaissances

> Ce document definit les regles de fraicheur, d'expiration et d'archivage
> des memoires stockees dans Mem0. L'objectif est de garantir que la base
> de connaissances reste fiable, pertinente et a jour.

---

## Principes generaux

- Chaque memoire possede une **duree de validite** determinee par son type.
- A expiration, une action est declenchee automatiquement (re-validation, archivage, etc.).
- Le processus est orchestre par un **cron job n8n** quotidien.
- Les agents sont responsables de re-valider les memoires dont ils sont proprietaires.
- Le CTO supervise l'ensemble du processus et intervient en cas d'escalade.

---

## Regles de fraicheur par type de memoire

| Type            | Duree de validite                | Action a expiration                          |
|-----------------|----------------------------------|----------------------------------------------|
| decision        | 90 jours                         | Re-validation par l'agent owner ou CTO       |
| architecture    | 90 jours                         | Re-validation par CTO                        |
| convention      | 180 jours                        | Re-validation par CTO                        |
| bug             | 30 jours apres resolution        | Archivage automatique                        |
| hypothesis      | 14 jours                         | Promotion (tested) ou archivage              |
| context         | 7 jours                          | Expiration automatique sauf `expires` explicite |
| research        | 60 jours                         | Re-validation par Researcher                 |
| pattern         | 120 jours                        | Re-validation par l'agent owner              |
| prd             | 90 jours                         | Re-validation par CPO                        |
| report          | 30 jours                         | Archivage automatique                        |
| metrics         | 7 jours                          | Remplacement par nouvelles metriques         |
| config          | 180 jours                        | Verification par DevOps                      |
| vulnerability   | Jamais (tant que non fixe)       | Archivage seulement apres fix + verification |

### Notes sur les durees

- Les durees sont calculees a partir de la date de **derniere modification** (`updated_at`).
- Une re-validation remet le compteur a zero sans modifier le contenu.
- Les memoires de type `vulnerability` ne sont **jamais** archivees tant qu'elles ne sont pas
  marquees comme fixees et verifiees par l'agent Security.

---

## Workflow de re-validation

Le processus de re-validation se deroule en 5 etapes :

1. **Declenchement** : cron job n8n quotidien a 2h00 du matin.
2. **Identification** : requete Mem0 `GET /memories?filter=state:active` avec calcul de l'age
   de chaque memoire par rapport a sa duree de validite.
3. **Notification** : pour chaque memoire expiree, creation d'une tache Paperclip assignee
   a l'agent owner de la memoire.
4. **Escalade** : si l'agent ne re-valide pas dans un delai de 7 jours, escalade automatique
   au CTO via une tache Paperclip prioritaire.
5. **Resolution** : l'agent (ou le CTO) dispose de trois options :
   - **Re-valider** : confirme que la memoire est toujours valide (reset du timer).
   - **Deprecier** : marque la memoire comme `state: deprecated`.
   - **Archiver** : marque la memoire comme `state: archived`.

### Exemple de requete Mem0 pour identification

```bash
# Recuperer toutes les memoires actives
curl -s "http://localhost:8050/memories?filter=state:active" | \
  jq '[.[] | select(
    (now - (.updated_at | fromdateiso8601)) / 86400 > .metadata.max_age_days
  )]'
```

### Tache Paperclip generee

```json
{
  "title": "Re-validation requise : memoire #MEM-1234",
  "assignee": "agent-owner-id",
  "priority": "medium",
  "description": "La memoire de type 'architecture' a expire apres 90 jours. Veuillez re-valider, deprecier ou archiver.",
  "due_date": "+7d"
}
```

---

## Indicateurs de staleness

### Dashboards SiYuan

- Requete SQL SiYuan pour afficher le pourcentage de memoires expirees par agent.
- Requete SQL SiYuan pour afficher les memoires les plus anciennes par type.
- Graphique de tendance : nombre de memoires expirees au fil du temps.

### Requetes Mem0

- Filtrer par date de creation : `GET /memories?sort=created_at&order=asc`
- Filtrer par date de modification : `GET /memories?sort=updated_at&order=asc`
- Compter les memoires par tranche d'age (< 7j, 7-30j, 30-90j, > 90j).

### Seuils d'alerte

| Indicateur                               | Seuil    | Action                                  |
|------------------------------------------|----------|-----------------------------------------|
| Memoires actives expirees                | > 20%    | Alerte CTO + rapport CFO                |
| Memoires hypothesis non promues > 14j    | > 5      | Alerte CTO                              |
| Memoires sans agent owner                | > 0      | Alerte CEO (assignation requise)        |
| Memoires context sans expires > 7j       | > 10     | Archivage automatique + alerte DevOps   |

---

## Archivage automatique

L'archivage automatique est declenche par le meme cron job quotidien.
Les conditions suivantes entrainent un archivage sans intervention humaine :

### Conditions d'archivage

| Condition                                                    | Action                    |
|--------------------------------------------------------------|---------------------------|
| `state=deprecated` depuis plus de 30 jours                   | Archivage automatique     |
| `confidence=hypothesis` depuis plus de 14 jours sans update  | Archivage automatique     |
| `type=context` sans champ `expires` depuis plus de 7 jours   | Archivage automatique     |
| `type=bug` avec `state=resolved` depuis plus de 30 jours     | Archivage automatique     |

### Processus d'archivage

1. La memoire passe a `state: archived`.
2. Un evenement d'audit est enregistre dans Mem0 (metadata `archived_at`, `archived_reason`).
3. La memoire reste interrogeable mais n'apparait plus dans les recherches par defaut.
4. Les relations (`supersedes`, `depends_on`) sont conservees pour tracabilite.

### Requete d'archivage automatique

```bash
# Archiver les memoires deprecated depuis > 30 jours
curl -s "http://localhost:8050/memories?filter=state:deprecated" | \
  jq '[.[] | select(
    (now - (.updated_at | fromdateiso8601)) / 86400 > 30
  )] | .[].id' | \
  xargs -I {} curl -X PATCH "http://localhost:8050/memories/{}" \
    -H "Content-Type: application/json" \
    -d '{"state": "archived", "metadata": {"archived_reason": "deprecated_timeout"}}'
```

---

## Exceptions

### Memoires epinglees

- Les memoires taguees `pinned: true` ne sont **jamais** archivees automatiquement.
- Seul un agent avec le role CEO ou CTO peut retirer le tag `pinned`.
- Les memoires epinglees sont tout de meme signalees si elles depassent leur duree de validite,
  mais aucune action automatique n'est prise.

### Memoires validees

- Les memoires avec `confidence: validated` beneficient d'une duree de validite **doublee**.
- Exemple : une decision validee a une duree de 180 jours au lieu de 90.
- Ce multiplicateur est configurable dans la configuration n8n du workflow de fraicheur.

### Memoires critiques

- Les memoires de type `vulnerability` avec severite `critical` ou `high` ne sont jamais
  soumises a l'archivage automatique, meme apres fix.
- Elles necessitent une verification manuelle par l'agent Security ET le CTO.

---

## Configuration

### Variables n8n

| Variable                          | Valeur par defaut | Description                              |
|-----------------------------------|-------------------|------------------------------------------|
| `FRESHNESS_CRON`                  | `0 2 * * *`       | Horaire du cron de fraicheur             |
| `FRESHNESS_ESCALATION_DELAY_DAYS` | 7                 | Delai avant escalade au CTO              |
| `FRESHNESS_ARCHIVE_DEPRECATED_DAYS` | 30              | Delai d'archivage apres depreciation     |
| `FRESHNESS_VALIDATED_MULTIPLIER`  | 2                 | Multiplicateur de duree pour validated   |
| `FRESHNESS_STALENESS_THRESHOLD`   | 0.20              | Seuil d'alerte (pourcentage)             |

---

## References

- [13-memory-protocol](../architecture/protocols--memory-protocol.md) : protocole de memoire detaille
- [14-knowledge-workflows](../architecture/protocols--knowledge-workflows.md) : workflows de gestion des connaissances
- [monitoring--alerting-rules](./monitoring--alerting-rules.md) : regles d'alerte et de monitoring
