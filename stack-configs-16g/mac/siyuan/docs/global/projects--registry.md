# Registre des Projets

Tous les projets actifs geres par l'equipe d'agents.

## Projets actifs

| Slug | Nom | Lead | Paperclip ID | Status | Stack | Cree |
|------|-----|------|:------------:|:------:|-------|------|
| *(aucun projet encore)* | | | | | | |

## Status possibles

| Status | Description | Couleur |
|--------|-------------|---------|
| `discovery` | Phase de recherche et definition | Bleu |
| `development` | En cours de developpement | Vert |
| `staging` | En test sur l'environnement de staging | Jaune |
| `production` | Deploye et operationnel | Vert fonce |
| `maintenance` | En mode maintenance (bug fixes seulement) | Gris |
| `archived` | Archive, plus actif | Gris clair |
| `paused` | En pause temporaire | Orange |

## Ajouter un projet

### Via bootstrap-project.sh

```bash
# Creer un nouveau projet
bash mac/siyuan/bootstrap-project.sh <slug> [paperclip-id] [lead-agent] [description]

# Exemple
bash mac/siyuan/bootstrap-project.sh auth-service PAPER-42 cto "Service d'authentification OAuth2/JWT"
```

Le script va :
1. Creer les sous-dossiers dans chaque notebook (ADRs, specs, etc.)
2. Ajouter le projet a ce registre
3. Poser les attributs custom `custom-project` sur les docs
4. Sauvegarder dans Mem0

### Manuellement

Pour ajouter un projet manuellement, ajouter une ligne au tableau ci-dessus :

| Champ | Format | Exemple |
|-------|--------|---------|
| Slug | kebab-case, unique | `auth-service` |
| Nom | Nom complet | "Service d'Authentification" |
| Lead | Nom de l'agent principal | `cto` |
| Paperclip ID | ID du projet dans Paperclip | `PAPER-42` |
| Status | Voir tableau des status | `development` |
| Stack | Technologies principales | `FastAPI, PostgreSQL, Redis` |
| Cree | Date de creation | `2026-03-11` |

## Structure d'un projet dans SiYuan

Quand un projet est cree via `bootstrap-project.sh`, les dossiers suivants sont crees dans chaque notebook pertinent :

```
architecture/
  └── projets/
      └── {slug}/
          └── (ADRs du projet)

engineering/
  └── projets/
      └── {slug}/
          └── (specs techniques, docs API)

produit/
  └── projets/
      └── {slug}/
          └── (PRDs, user stories)

operations/
  └── projets/
      └── {slug}/
          └── (runbooks specifiques, post-mortems)

security/
  └── projets/
      └── {slug}/
          └── (audits specifiques)
```

## Conventions

- Le slug du projet est utilise comme valeur de `custom-project` dans les attributs SiYuan
- Le slug est aussi le `project` dans les metadata Mem0
- Un projet peut avoir plusieurs agents qui y contribuent
- Le lead est l'agent responsable, pas le seul contributeur
- Les projets `archived` ne doivent plus recevoir de nouvelles memoires

## Requetes utiles

```bash
# Trouver tous les docs d'un projet
curl -X POST "http://host.docker.internal:6806/api/query/sql" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"stmt": "SELECT b.content, b.hpath FROM blocks b JOIN attributes a ON b.id = a.block_id WHERE a.name = '\''custom-project'\'' AND a.value = '\''auth-service'\'' AND b.type = '\''d'\'' ORDER BY b.updated DESC"}'

# Trouver toutes les memoires d'un projet
curl -X POST "http://host.docker.internal:8050/search/filtered" \
  -d '{"query": "*", "user_id": "cto", "filters": {"project": {"$eq": "auth-service"}}, "limit": 50}'

# Compter les docs par projet
curl -X POST "http://host.docker.internal:6806/api/query/sql" \
  -H "Authorization: Token paperclip-siyuan-token" \
  -d '{"stmt": "SELECT a.value AS project, count(*) AS doc_count FROM attributes a JOIN blocks b ON a.block_id = b.id WHERE a.name = '\''custom-project'\'' AND b.type = '\''d'\'' GROUP BY a.value ORDER BY doc_count DESC"}'
```

---

*Mis a jour par `bootstrap-project.sh` a chaque creation de projet.*
