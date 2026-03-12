# Strategie RAG - Systeme Multi-Agent Paperclip

> Guide de reference pour la strategie de Retrieval-Augmented Generation (RAG) utilisee par le systeme multi-agent Paperclip. Ce document couvre l'architecture a 3 couches, les pipelines d'indexation, l'optimisation des requetes et la maintenance.

---

## Architecture RAG Paperclip

### Vue d'ensemble

Le systeme RAG de Paperclip repose sur 3 couches complementaires, chacune ayant un role distinct dans la gestion des connaissances :

| Couche | Role | Port | Description |
|--------|------|------|-------------|
| **Mem0** | Memoire operationnelle | `8050` | 21+ endpoints REST. Stocke les decisions, preferences, faits durables et le contexte agent. |
| **Chroma** | Base vectorielle | `8000` | Index de recherche semantique. Stocke les embeddings de code patterns, conventions et architecture. |
| **SiYuan** | Documentation structuree | `6806` | Documents longs, specifications, guidelines et templates lisibles par les humains. |

### Modele d'embedding

- **Modele** : `nomic-embed-text`
- **Fournisseur** : Ollama (port `11434`)
- **Dimension** : 768
- **Usage** : Toutes les operations d'embedding (indexation et requetes) passent par Ollama en local

### Quand utiliser chaque couche

#### Mem0 - Memoire operationnelle

Utiliser Mem0 pour stocker et recuperer :

- **Decisions** : choix architecturaux, trade-offs valides, decisions techniques
- **Preferences** : conventions d'equipe, preferences de style, choix de librairies
- **Faits durables** : configurations validees, credentials de services, parametres d'environnement
- **Contexte agent** : etat courant d'un agent, historique de ses actions recentes, objectifs en cours

Mem0 expose 21+ endpoints et constitue la **source de verite** pour tout ce qui concerne les decisions et les faits.

#### Chroma - Base vectorielle

Utiliser Chroma pour indexer et rechercher :

- **Code patterns** : patterns recurrents dans la codebase, idiomes, anti-patterns documentes
- **Conventions** : regles de nommage, structure de fichiers, conventions de commit
- **Architecture** : diagrammes indexes, descriptions de composants, interfaces entre services
- **Resultats d'audit** : findings de securite, recommendations de performance

Chroma est un **index de recherche** : il peut etre entierement reconstruit a partir de Mem0 et SiYuan.

#### SiYuan - Documentation structuree

Utiliser SiYuan pour maintenir :

- **Documentation longue** : guides d'architecture, documentation d'API, tutorials
- **Specifications** : specs fonctionnelles, specs techniques, RFC
- **Guidelines** : guides de contribution, standards de qualite, processus
- **Templates** : modeles de documents, templates de PR, checklists

SiYuan est le format **humain-lisible** de la connaissance du systeme.

---

## Strategie d'indexation Chroma

### Collections recommandees

Organiser les donnees dans Chroma en collections thematiques :

| Collection | Contenu | Frequence de mise a jour |
|------------|---------|--------------------------|
| `architecture` | Descriptions de composants, diagrammes, decisions d'architecture | A chaque changement structurel |
| `conventions` | Regles de nommage, style de code, conventions d'equipe | Hebdomadaire |
| `codebase-patterns` | Patterns recurrents, idiomes, exemples de code | A chaque nouvelle decouverte |
| `security-audits` | Resultats d'audits, vulnerabilites connues, remediations | Apres chaque audit |
| `research-findings` | Resultats de POC, benchmarks, comparaisons techniques | A chaque conclusion de recherche |

### Granularite des chunks

- **Niveau de decoupe** : par section de document (niveau H2), pas par document entier
- **Raison** : un chunk par H2 permet un matching plus precis et evite de retourner du contenu non pertinent
- **Exception** : les documents courts (< 500 tokens) peuvent etre indexes en un seul chunk

### Taille optimale des chunks

```
Taille recommandee : 500 - 1000 tokens par chunk
Overlap : 100 tokens entre chunks adjacents
```

- En dessous de 500 tokens : risque de perte de contexte
- Au dessus de 1000 tokens : risque de dilution de la pertinence
- L'overlap de 100 tokens assure la continuite semantique entre chunks voisins

### Metadata a indexer

Chaque chunk doit inclure les metadata suivantes :

```json
{
  "source": "/chemin/vers/le/document.md",
  "type": "convention | pattern | architecture | security | research",
  "agent": "nom-de-l-agent-createur",
  "project": "nom-du-projet",
  "date": "2026-03-11",
  "section": "titre-de-la-section-h2",
  "collection": "nom-de-la-collection"
}
```

- `source` : chemin complet du fichier source (pour tracabilite et deduplication)
- `type` : categorie du contenu (permet le filtrage lors des requetes)
- `agent` : identifiant de l'agent qui a cree le chunk (pour audit)
- `project` : nom du projet concerne (permet le filtrage par projet)
- `date` : date de creation ou derniere modification (pour la fraicheur)

---

## Pipeline d'indexation

### Flux complet

Le pipeline d'indexation suit ces etapes :

```
1. Agent cree/modifie un document (Mem0 ou SiYuan)
          |
2. Detection de pertinence RAG
          |
3. Extraction du contenu
          |
4. Chunking par sections (H2)
          |
5. Embedding via Ollama (nomic-embed-text)
          |
6. Stockage dans Chroma avec metadata
```

### Etape 1 : Creation ou modification du document

L'agent ecrit ou met a jour un document dans Mem0 ou SiYuan. Cet evenement declenche le pipeline.

### Etape 2 : Detection de pertinence

Tous les documents ne doivent pas etre indexes dans Chroma. Criteres de pertinence :

- Le document contient des informations reutilisables (patterns, conventions, architecture)
- Le document est suffisamment stable (pas un brouillon en cours)
- Le document n'est pas une note temporaire ou un log

### Etape 3 : Extraction du contenu

```bash
# Exemple : recuperer un document depuis SiYuan
curl -s -X POST http://localhost:6806/api/export/exportMdContent \
  -H "Content-Type: application/json" \
  -H "Authorization: Token SIYUAN_API_TOKEN" \
  -d '{"id": "BLOCK_ID"}' | jq -r '.data.content'
```

### Etape 4 : Chunking par sections

Decouper le contenu au niveau H2. Exemple en Python :

```python
import re

def chunk_by_h2(content: str) -> list[dict]:
    sections = re.split(r'^## ', content, flags=re.MULTILINE)
    chunks = []
    for section in sections:
        if section.strip():
            lines = section.strip().split('\n')
            title = lines[0].strip()
            body = '\n'.join(lines[1:]).strip()
            if body:
                chunks.append({"title": title, "content": body})
    return chunks
```

### Etape 5 : Embedding via Ollama

```bash
# Generer un embedding pour un chunk
curl -s http://localhost:11434/api/embeddings \
  -d '{
    "model": "nomic-embed-text",
    "prompt": "Contenu du chunk a indexer..."
  }' | jq '.embedding'
```

### Etape 6 : Stockage dans Chroma

```bash
# Creer une collection (si elle n'existe pas)
curl -s -X POST http://localhost:8000/api/v1/collections \
  -H "Content-Type: application/json" \
  -d '{
    "name": "conventions",
    "metadata": {"hnsw:space": "cosine"}
  }'

# Ajouter un document avec son embedding
curl -s -X POST http://localhost:8000/api/v1/collections/COLLECTION_ID/add \
  -H "Content-Type: application/json" \
  -d '{
    "ids": ["conv-001"],
    "embeddings": [[0.012, -0.034, ...]],
    "metadatas": [{
      "source": "/docs/conventions/naming.md",
      "type": "convention",
      "agent": "architect-agent",
      "project": "paperclip",
      "date": "2026-03-11"
    }],
    "documents": ["Contenu du chunk..."]
  }'
```

---

## Optimisation des requetes

### Formulation des requetes

**Regle principale** : reformuler la question en statement pour un meilleur matching semantique.

| Mauvaise formulation | Bonne formulation |
|----------------------|-------------------|
| "Comment structurer les fichiers ?" | "Structure recommandee pour organiser les fichiers du projet" |
| "Quel pattern pour les API ?" | "Pattern de conception utilise pour les endpoints API REST" |
| "Securite ?" | "Regles de securite et bonnes pratiques pour le projet" |

### Parametres de recherche

#### Top-K (nombre de resultats)

- **Par defaut** : `k=5` pour les requetes ciblees
- **Recherche exploratoire** : `k=10` quand l'agent explore un sujet large
- **Verification ponctuelle** : `k=3` pour confirmer un fait precis

#### Seuil de similarite

| Score | Interpretation | Action |
|-------|---------------|--------|
| > 0.90 | **Haute confiance** | Utiliser directement dans la reponse |
| 0.75 - 0.90 | **Pertinent** | Inclure avec verification contextuelle |
| 0.50 - 0.75 | **Potentiellement pertinent** | Inclure seulement si aucun meilleur resultat |
| < 0.50 | **Non pertinent** | Exclure des resultats |

#### Re-ranking

Si plus de 5 resultats depassent le seuil de 0.75, appliquer un re-ranking par metadata :

1. **Filtrer par type** : prioriser le type correspondant a la requete (convention, pattern, etc.)
2. **Filtrer par projet** : prioriser les resultats du projet courant
3. **Filtrer par date** : prioriser les resultats les plus recents
4. **Eliminer les doublons** : si deux chunks viennent du meme document source, garder le plus pertinent

### Exemple de requete optimisee

```bash
# 1. Generer l'embedding de la requete
QUERY_EMBEDDING=$(curl -s http://localhost:11434/api/embeddings \
  -d '{"model": "nomic-embed-text", "prompt": "Conventions de nommage pour les composants React"}' \
  | jq '.embedding')

# 2. Rechercher dans Chroma
curl -s -X POST http://localhost:8000/api/v1/collections/COLLECTION_ID/query \
  -H "Content-Type: application/json" \
  -d "{
    \"query_embeddings\": [$QUERY_EMBEDDING],
    \"n_results\": 5,
    \"where\": {\"type\": \"convention\"},
    \"include\": [\"documents\", \"metadatas\", \"distances\"]
  }"
```

---

## Deduplication entre couches

### Principe de separation des responsabilites

Chaque couche a un role distinct. La deduplication s'appuie sur la hierarchie suivante :

```
Mem0 (source de verite)
  |
  v
SiYuan (documentation humain-lisible)
  |
  v
Chroma (index de recherche reconstituable)
```

### Regles de deduplication

1. **Mem0 est la source de verite** pour les decisions et les faits. En cas de conflit entre couches, Mem0 fait autorite.
2. **SiYuan est la reference** pour la documentation longue. Si un document SiYuan contredit un chunk Chroma, SiYuan prevaut.
3. **Chroma est un index derivé** : il peut etre entierement reconstruit a partir des contenus de Mem0 et SiYuan.

### Priorite en cas de conflit

```
Mem0 > SiYuan > Chroma
```

### Strategie de synchronisation

- Quand un fait est mis a jour dans Mem0, verifier si un document SiYuan correspondant doit etre mis a jour
- Quand un document SiYuan est modifie, re-indexer les chunks concernes dans Chroma
- Ne jamais modifier Chroma directement : toujours passer par Mem0 ou SiYuan comme source

---

## Metriques de qualite RAG

### Indicateurs a suivre

| Metrique | Description | Objectif | Methode de mesure |
|----------|-------------|----------|-------------------|
| **Pertinence** | % de resultats effectivement utilises par l'agent dans sa reponse | > 80% | Comparer les chunks retournes vs ceux cites dans la reponse |
| **Recall** | Le bon document est-il trouve ? | > 90% | Tests manuels periodiques avec des requetes connues |
| **Latence** | Temps total de recherche (embedding + query + re-ranking) | < 2 secondes | Mesure bout-en-bout sur chaque requete |
| **Fraicheur** | Age moyen des documents retournes | < 30 jours | Calculer la moyenne du champ `date` des metadata |
| **Taux de deduplication** | % de resultats dupliques dans une requete | < 10% | Compter les chunks provenant du meme document source |

### Tests de qualite recommandes

**Test de pertinence** (hebdomadaire) :

1. Preparer 10 requetes representatives
2. Executer chaque requete et collecter les top-5 resultats
3. Evaluer manuellement la pertinence de chaque resultat (pertinent / non pertinent)
4. Calculer le score de pertinence moyen

**Test de recall** (mensuel) :

1. Pour 10 sujets connus, identifier le document attendu
2. Formuler une requete naturelle pour chaque sujet
3. Verifier si le document attendu apparait dans les top-5
4. Si absent, analyser pourquoi (chunking, embedding, metadata)

---

## Maintenance

### Re-indexation Chroma

**Frequence** : mensuelle ou apres tout changement majeur (restructuration de docs, ajout massif de contenu).

```bash
# Lister toutes les collections
curl -s http://localhost:8000/api/v1/collections | jq '.[].name'

# Supprimer une collection pour re-indexation
curl -s -X DELETE http://localhost:8000/api/v1/collections/COLLECTION_NAME

# Recreer et re-indexer (utiliser le pipeline d'indexation ci-dessus)
```

### Nettoyage des chunks orphelins

Un chunk est orphelin si son document source a ete supprime. Processus de nettoyage :

1. Lister tous les chunks d'une collection avec leur metadata `source`
2. Verifier l'existence de chaque fichier source
3. Supprimer les chunks dont le source n'existe plus

```bash
# Recuperer les chunks avec leurs metadata
curl -s -X POST http://localhost:8000/api/v1/collections/COLLECTION_ID/get \
  -H "Content-Type: application/json" \
  -d '{
    "include": ["metadatas"],
    "limit": 1000
  }' | jq '.metadatas[].source'
```

### Monitoring Mem0

Mem0 expose un endpoint `/stats` utile pour suivre l'usage par agent :

```bash
# Statistiques generales
curl -s http://localhost:8050/stats | jq '.'

# Verifier la sante du service
curl -s http://localhost:8050/health

# Lister les memoires par agent
curl -s "http://localhost:8050/v1/memories/?agent_id=architect-agent" | jq '.results | length'
```

### Calendrier de maintenance

| Tache | Frequence | Responsable |
|-------|-----------|-------------|
| Re-indexation Chroma complete | Mensuelle | Agent de maintenance |
| Nettoyage chunks orphelins | Bi-mensuelle | Agent de maintenance |
| Tests de pertinence | Hebdomadaire | Agent QA |
| Tests de recall | Mensuelle | Agent QA |
| Verification coherence inter-couches | Mensuelle | Architect agent |
| Backup des collections Chroma | Hebdomadaire | Ops |

---

## Voir aussi

- **`tech-docs--chroma`** : Documentation technique de Chroma, API detaillee, configuration et administration
- **`tech-docs--mem0-api`** : Reference complete de l'API Mem0, liste des 21+ endpoints, exemples d'utilisation
- **`tech-docs--ollama`** : Configuration d'Ollama, modeles disponibles, parametres d'embedding et de generation
