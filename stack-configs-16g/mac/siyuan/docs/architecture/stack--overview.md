# Stack Overview

## Architecture globale

```
┌─────────────────────────────────────────────────────────────┐
│                     MacBook Pro (M-series)                    │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │  Ollama   │  │ LobeChat │  │  SiYuan   │  │  Paperclip   │ │
│  │  :11434   │  │  :3210   │  │  :6806    │  │  :8060       │ │
│  │  (natif)  │  │ (Docker) │  │ (Docker)  │  │  (Docker)    │ │
│  └─────┬─────┘  └────┬─────┘  └────┬──────┘  └──────┬───────┘ │
│        │              │             │                 │         │
│        │    ┌─────────┴─────────────┴─────────────────┘        │
│        │    │                                                   │
│  ┌─────┴────┴──┐  ┌──────────┐                                 │
│  │    Mem0      │  │  Chroma   │                                │
│  │   :8050      │  │  :8000    │                                │
│  │  (Docker)    │  │ (Docker)  │                                │
│  └──────────────┘  └──────────┘                                │
│                                                                 │
│  Outils natifs : Obsidian, KeePassXC, LocalSend, NetBird       │
└─────────────────────────────────────────────────────────────────┘
          │
          │ VPN (NetBird)
          ▼
┌─────────────────────────────────────────────────────────────┐
│                     Serveur (HP OMEN)                        │
│  Dokploy, Gitea, n8n, Twenty CRM, BillionMail, Firecrawl   │
│  ntfy, Plausible, Prometheus, Grafana                       │
└─────────────────────────────────────────────────────────────┘
```

## Services locaux (Mac)

| Service | Port | Type | Role | RAM estimee |
|---------|------|------|------|-------------|
| **Ollama** | 11434 | Natif | LLM inference (Apple Silicon GPU) | ~4-20 Go (selon modele) |
| **LobeChat** | 3210 | Docker | Interface chat IA multi-modeles | ~100 Mo |
| **SiYuan Note** | 6806 | Docker | Knowledge base structuree (8 notebooks) | ~200 Mo |
| **Paperclip** | 8060 | Docker | Orchestrateur agents IA (11 agents) | ~300 Mo |
| **Mem0** | 8050 | Docker | Memoire persistante agents (API custom) | ~200 Mo |
| **Chroma** | 8000 | Docker | Base vectorielle (embeddings RAG) | ~200 Mo |

## Modeles Ollama

### Configuration 16 Go RAM

| Modele | RAM | Role |
|--------|-----|------|
| `llama3.2:3b` | ~2 Go | Chat general, agents legers |
| `nomic-embed-text` | ~270 Mo | Embeddings (Mem0, Chroma) |
| `codellama:7b` | ~4 Go | Assistance code |

### Configuration 48 Go RAM

| Modele | RAM | Role |
|--------|-----|------|
| `qwen2.5:32b` | ~20 Go | CEO, CTO (raisonnement, management) |
| `deepseek-coder-v2:33b` | ~20 Go | Devs (code haute qualite) |
| `qwen2.5:14b` | ~9 Go | CPO, CFO, QA, Security, Designer, Researcher |
| `nomic-embed-text` | ~270 Mo | Embeddings (Mem0, Chroma) |

## Flux de donnees

```
Utilisateur
    │
    ▼
LobeChat (:3210) ──→ Ollama (:11434) ──→ Reponse
    │
    ▼
Paperclip (:8060) ──→ Agent selection ──→ Ollama
    │                                        │
    ├── Mem0 (:8050) ◄──── Sauvegarder/Chercher memoires
    │       │
    │       └──→ Chroma (:8000) ◄── Embeddings vectoriels
    │
    ├── SiYuan (:6806) ◄── Lire/Ecrire knowledge base
    │
    └── n8n (serveur) ◄── Webhooks events (deploy, git, notifs)
```

## Couches de memoire

| Couche | Service | Port | Contenu | Persistance |
|--------|---------|------|---------|-------------|
| **1. Memoire de travail** | Mem0 | 8050 | Decisions, patterns, bugs, contexte par agent | PostgreSQL |
| **2. Knowledge base** | SiYuan | 6806 | Docs structures, conventions, guidelines, ADRs | Filesystem |
| **3. Base vectorielle** | Chroma | 8000 | Embeddings pour RAG avance | Filesystem |

## Communication inter-services

| De | Vers | Protocol | Usage |
|----|------|----------|-------|
| Paperclip | Ollama | HTTP REST | Inference LLM |
| Paperclip | Mem0 | HTTP REST | Read/write memoires |
| Paperclip | SiYuan | HTTP REST + Cookie | Read/write knowledge |
| Mem0 | Ollama | HTTP REST | Embeddings (nomic-embed-text) |
| Mem0 | Chroma | HTTP REST | Stockage/recherche vecteurs |
| Agents | n8n | HTTP Webhook | Events (deploy, notify, scrape) |
| LobeChat | Ollama | HTTP REST | Chat direct |

## Docker networking

Tous les containers Docker accedent a Ollama (natif) via :
```
http://host.docker.internal:11434
```

Les containers communiquent entre eux via le reseau Docker bridge default.

## Volumes persistants

| Service | Volume | Contenu |
|---------|--------|---------|
| SiYuan | `./workspace:/siyuan/workspace` | Notebooks, docs, assets |
| Chroma | `./data:/chroma/chroma` | Collections vectorielles |
| Mem0 | PostgreSQL volume | Memoires, metadonnees |
| Paperclip | PostgreSQL volume | Config agents, tasks, projets |

## Securite

| Aspect | Implementation |
|--------|---------------|
| SiYuan auth | Cookie session via `/api/system/loginAuth` |
| Paperclip auth | Bearer token API |
| n8n auth | X-N8N-Agent-Key header |
| Reseau | Tout en localhost, VPN NetBird pour serveur |
| Secrets | KeePassXC local, pas de .env en git |
