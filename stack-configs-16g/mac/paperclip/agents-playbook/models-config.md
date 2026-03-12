# Configuration des modeles LiteLLM

## Config pour 48GB RAM

### Modeles a installer sur Ollama

```bash
# Modeles de management/raisonnement (CEO, CTO, CPO)
ollama pull qwen2.5:32b

# Modeles de code (Lead Backend, Lead Frontend, DevOps)
ollama pull deepseek-coder-v2:33b
# OU alternative :
ollama pull qwen2.5-coder:32b

# Modeles legers (QA, CFO, Security, Designer, Researcher)
ollama pull qwen2.5:14b

# Modele basique (taches ponctuelles)
ollama pull llama3.1:8b

# Embeddings (mem0, RAG)
ollama pull nomic-embed-text
```

### litellm-config.yaml pour 48GB

```yaml
model_list:
  # Management / Raisonnement - CEO, CTO, CPO
  - model_name: qwen2.5:32b
    litellm_params:
      model: ollama/qwen2.5:32b
      api_base: http://host.docker.internal:11434

  # Code - Lead Backend, Lead Frontend, DevOps
  - model_name: deepseek-coder-v2:33b
    litellm_params:
      model: ollama/deepseek-coder-v2:16b
      api_base: http://host.docker.internal:11434

  # Code alternatif
  - model_name: qwen2.5-coder:32b
    litellm_params:
      model: ollama/qwen2.5-coder:32b
      api_base: http://host.docker.internal:11434

  # Taches structurees - QA, CFO, Security, Designer, Researcher
  - model_name: qwen2.5:14b
    litellm_params:
      model: ollama/qwen2.5:14b
      api_base: http://host.docker.internal:11434

  # Taches simples / fallback
  - model_name: llama3.1:8b
    litellm_params:
      model: ollama/llama3.1:8b
      api_base: http://host.docker.internal:11434

general_settings:
  drop_params: true
```

## Allocation des modeles par agent

| Agent | Modele | Taille RAM | Justification |
|-------|--------|-----------|---------------|
| CEO | `qwen2.5:32b` | ~20GB | Besoin de raisonnement complexe, tool calling, delegation |
| CTO | `qwen2.5:32b` | ~20GB | Architecture, decisions techniques, recrutement |
| CPO | `qwen2.5:14b` | ~9GB | Specs produit, priorisation (moins de tool calling) |
| CFO | `qwen2.5:14b` | ~9GB | Analyse de couts, rapports (taches structurees) |
| Lead Backend | `deepseek-coder-v2:33b` | ~20GB | Code backend de haute qualite |
| Lead Frontend | `deepseek-coder-v2:33b` | ~20GB | Code frontend de haute qualite |
| DevOps | `deepseek-coder-v2:33b` | ~20GB | Dockerfiles, CI/CD, scripts infra |
| Security | `qwen2.5:14b` | ~9GB | Audit de code, analyse (pattern matching) |
| QA | `qwen2.5:14b` | ~9GB | Tests, review, rapports de bugs |
| Designer | `qwen2.5:14b` | ~9GB | Specs textuelles, wireframes ASCII |
| Researcher | `qwen2.5:14b` | ~9GB | Recherche, comparaison, documentation |

## Note sur le fonctionnement Ollama

Ollama **charge un seul modele a la fois en memoire** par defaut.
- Si un agent utilise `qwen2.5:32b` et qu'un autre demande `deepseek-coder-v2:33b`, Ollama decharge le premier et charge le second
- Temps de switch : ~10-30 secondes
- Pour charger 2 modeles en parallele, configurer `OLLAMA_MAX_LOADED_MODELS=2` (necessite assez de RAM)

### Pour 48GB avec 2 modeles simultanees :
```bash
# Dans le .zshrc ou le docker-compose d'Ollama
export OLLAMA_MAX_LOADED_MODELS=2
# Permet : 1 modele 32b + 1 modele 14b en meme temps
# 20GB + 9GB = 29GB, reste 19GB pour le systeme
```

## Config pour 8GB RAM (machine actuelle)

### Option locale (tres limitee)
```yaml
model_list:
  - model_name: qwen2.5:3b
    litellm_params:
      model: ollama/qwen2.5:3b
      api_base: http://host.docker.internal:11434

general_settings:
  drop_params: true
```

### Option cloud gratuite (recommandee pour 8GB)
```yaml
model_list:
  # Groq - gratuit, ultra rapide
  - model_name: llama-3.1-70b
    litellm_params:
      model: groq/llama-3.1-70b-versatile
      api_key: "GROQ_API_KEY_ICI"

  # Alternative : Together AI (free tier)
  - model_name: qwen2.5-72b
    litellm_params:
      model: together_ai/Qwen/Qwen2.5-72B-Instruct-Turbo
      api_key: "TOGETHER_API_KEY_ICI"

general_settings:
  drop_params: true
```
