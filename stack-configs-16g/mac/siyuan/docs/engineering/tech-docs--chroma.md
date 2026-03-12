# ChromaDB — Reference

## Architecture

Chroma stocke des **collections** de documents avec leurs **embeddings vectoriels** pour la recherche semantique (RAG).

```
Document texte → Embedding model (nomic-embed-text) → Vecteur [0.12, -0.34, ...]
                                                              ↓
                                                    Chroma Collection
                                                              ↓
                                              Query "architecture" → Top K resultats
```

## API (REST v2)

Base URL : `http://localhost:8000/api/v2`

### Health check

```bash
curl http://localhost:8000/api/v2/heartbeat
# {"nanosecond heartbeat": 1710000000}
```

### Collections

```bash
# Creer une collection
curl -X POST http://localhost:8000/api/v2/tenants/default_tenant/databases/default_database/collections \
  -H "Content-Type: application/json" \
  -d '{
    "name": "architecture",
    "metadata": {"description": "Architecture decisions and patterns"}
  }'

# Lister les collections
curl http://localhost:8000/api/v2/tenants/default_tenant/databases/default_database/collections

# Supprimer
curl -X DELETE http://localhost:8000/api/v2/tenants/default_tenant/databases/default_database/collections/architecture
```

### Ajouter des documents

```bash
curl -X POST http://localhost:8000/api/v2/tenants/default_tenant/databases/default_database/collections/<collection-id>/add \
  -H "Content-Type: application/json" \
  -d '{
    "ids": ["doc-001", "doc-002"],
    "documents": [
      "Nous utilisons PostgreSQL pour la persistence des donnees",
      "Le pattern CQRS separe les lectures des ecritures"
    ],
    "metadatas": [
      {"type": "decision", "project": "global", "agent": "cto"},
      {"type": "pattern", "project": "global", "agent": "cto"}
    ]
  }'
```

### Recherche semantique (query)

```bash
curl -X POST http://localhost:8000/api/v2/tenants/default_tenant/databases/default_database/collections/<collection-id>/query \
  -H "Content-Type: application/json" \
  -d '{
    "query_texts": ["quelle base de donnees utiliser"],
    "n_results": 5,
    "where": {"type": "decision"},
    "include": ["documents", "metadatas", "distances"]
  }'
```

### Filtrage (where)

```json
// Egal
{"type": "decision"}

// Et
{"$and": [{"type": "decision"}, {"project": "saas-app"}]}

// Ou
{"$or": [{"agent": "cto"}, {"agent": "lead-backend"}]}

// Comparaison
{"confidence": {"$gte": 0.8}}

// Contient
{"tags": {"$in": ["architecture", "database"]}}
```

## Collections recommandees

| Collection | Contenu | Qui ecrit | Qui lit |
|-----------|---------|-----------|---------|
| `architecture` | ADRs, patterns, decisions techniques | CTO, Lead Backend | Tous les devs |
| `conventions` | Regles de code, naming, standards | CTO | Tous |
| `codebase` | Extraits de code indexes | Devs | Devs, QA |
| `research` | Veille technologique, benchmarks | Researcher | CTO, Devs |
| `security` | Vulnerabilites, policies | Security | Tous |
| `incidents` | Post-mortems, root causes | DevOps | Tous |

## Integration avec Mem0

Mem0 utilise Chroma comme backend vectoriel. La config :

```yaml
vector_store:
  provider: chroma
  config:
    host: chroma
    port: 8000
    collection_name: mem0_memories
```

**Ne pas ecrire directement dans la collection `mem0_memories`** — utiliser l'API Mem0.

## Python SDK

```python
import chromadb

client = chromadb.HttpClient(host="localhost", port=8000)

# Creer/recuperer une collection
collection = client.get_or_create_collection(
    name="architecture",
    metadata={"hnsw:space": "cosine"}  # Similarite cosine
)

# Ajouter
collection.add(
    ids=["adr-001"],
    documents=["Utiliser PostgreSQL pour toutes les donnees relationnelles"],
    metadatas=[{"type": "adr", "status": "accepted"}]
)

# Chercher
results = collection.query(
    query_texts=["base de donnees recommandee"],
    n_results=3,
    where={"type": "adr"}
)
```

## Performance

| Parametre | Valeur recommandee | Impact |
|-----------|-------------------|--------|
| `hnsw:space` | `cosine` | Similarite normalisee (meilleur pour du texte) |
| `hnsw:M` | 16 (default) | Plus haut = meilleure precision, plus de RAM |
| `hnsw:construction_ef` | 100 (default) | Plus haut = index plus lent mais meilleur |
| `hnsw:search_ef` | 50 (default) | Plus haut = recherche plus precise mais plus lente |

Pour notre usage (< 100k documents), les defaults sont suffisants.
