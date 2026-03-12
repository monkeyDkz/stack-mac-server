# Ollama — Reference

## API

Base URL : `http://localhost:11434`

### Generer une completion

```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Explain Docker in 3 sentences",
    "stream": false,
    "options": {
      "temperature": 0.7,
      "num_predict": 256
    }
  }'
```

### Chat (multi-turn)

```bash
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:32b",
    "messages": [
      {"role": "system", "content": "Tu es un architecte senior."},
      {"role": "user", "content": "Quelle DB pour 10M events/jour ?"}
    ],
    "stream": false,
    "options": {
      "temperature": 0.3
    }
  }'
```

### Embeddings

```bash
curl -X POST http://localhost:11434/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text",
    "input": "Architecture microservices avec PostgreSQL"
  }'
```

### Lister les modeles

```bash
curl http://localhost:11434/api/tags | python3 -m json.tool
```

### Telecharger un modele

```bash
ollama pull qwen2.5:32b
ollama pull deepseek-coder-v2:33b
ollama pull nomic-embed-text
```

## Parametres d'inference

| Parametre | Default | Usage |
|-----------|---------|-------|
| `temperature` | 0.8 | 0.1-0.3 pour code/facts, 0.7-1.0 pour creatif |
| `top_p` | 0.9 | Nucleus sampling (alternative a temperature) |
| `top_k` | 40 | Limiter le vocabulaire considere |
| `num_predict` | 128 | Nombre max de tokens generes |
| `repeat_penalty` | 1.1 | Penaliser les repetitions |
| `seed` | -1 | Fixer pour reproductibilite |
| `num_ctx` | 2048 | Taille de la fenetre de contexte |

### Recommandations par role

| Role agent | Modele | temperature | num_ctx | Pourquoi |
|-----------|--------|-------------|---------|----------|
| CEO, CTO | `qwen2.5:32b` | 0.4 | 8192 | Raisonnement structure, decisions |
| Lead Backend/Frontend | `deepseek-coder-v2:33b` | 0.2 | 8192 | Code precis, peu de hallucination |
| CPO | `qwen2.5:14b` | 0.5 | 4096 | Specs structurees |
| QA | `qwen2.5:14b` | 0.1 | 4096 | Tests deterministes |
| Security | `qwen2.5:14b` | 0.1 | 4096 | Analyse precise |
| Designer | `qwen2.5:14b` | 0.6 | 4096 | Creatif mais structure |
| Researcher | `qwen2.5:14b` | 0.7 | 8192 | Exploration large |

## Gestion memoire (Apple Silicon)

```bash
# Voir la memoire utilisee
ollama ps

# Decharger un modele de la RAM
ollama stop qwen2.5:32b

# Decharger tous les modeles
curl -X DELETE http://localhost:11434/api/generate
```

### Estimation RAM par modele

| Taille parametres | Quantization | RAM estimee |
|-------------------|-------------|-------------|
| 3B | Q4_K_M | ~2 Go |
| 7B | Q4_K_M | ~4.5 Go |
| 14B | Q4_K_M | ~9 Go |
| 32-33B | Q4_K_M | ~20 Go |
| 70B | Q4_K_M | ~40 Go |

**Regle** : un seul modele > 14B en RAM a la fois sur 16 Go. Sur 48 Go, 2 modeles max.

## Modelfile (custom)

```
FROM qwen2.5:14b

PARAMETER temperature 0.3
PARAMETER num_ctx 8192
PARAMETER repeat_penalty 1.2

SYSTEM """
Tu es le CTO d'une equipe de developpement.
Tu prends des decisions techniques basees sur des faits.
Tu documentes chaque decision dans un ADR.
Tu suis les conventions definies dans la knowledge base.
"""
```

```bash
ollama create cto-agent -f Modelfile
ollama run cto-agent
```

## Acces depuis Docker

Les containers Docker accedent a Ollama via :

```
http://host.docker.internal:11434
```

Configurer dans les docker-compose :

```yaml
environment:
  - OLLAMA_HOST=http://host.docker.internal:11434
extra_hosts:
  - "host.docker.internal:host-gateway"
```

## Troubleshooting

| Probleme | Solution |
|----------|----------|
| Ollama ne repond pas | `ollama serve` (demarrer le daemon) |
| OOM (Out of Memory) | Decharger le modele actuel : `ollama stop <model>` |
| Lent sur premiere requete | Normal — le modele se charge en RAM (cold start) |
| GPU non utilise | Verifier `ollama ps` — Metal (GPU) devrait etre affiche |
| Modele corrompu | `ollama rm <model>` puis `ollama pull <model>` |
