# Ports Reference

## Services locaux (Mac)

| Port | Service | Protocol | Auth | Status Check |
|------|---------|----------|------|-------------|
| **3210** | LobeChat | HTTP | Aucune | `curl http://localhost:3210` |
| **6806** | SiYuan Note | HTTP | Cookie session | `POST /api/system/version` |
| **8000** | Chroma | HTTP | Aucune | `GET /api/v2/heartbeat` |
| **8050** | Mem0 | HTTP | Aucune | `GET /health` |
| **8060** | Paperclip | HTTP | Bearer token | `GET /api/health` |
| **11434** | Ollama | HTTP | Aucune | `GET /api/tags` |

## Services serveur (HP OMEN via VPN)

| Port | Service | Protocol | Auth |
|------|---------|----------|------|
| **3000** | Gitea | HTTPS | Token |
| **5678** | n8n | HTTPS | Webhook key |
| **3100** | Paperclip API (si serveur) | HTTPS | Bearer |
| **8025** | BillionMail | HTTPS | API key |
| **9090** | Prometheus | HTTP | Basic |
| **3001** | Grafana | HTTPS | Login |
| **8080** | Firecrawl | HTTPS | API key |
| **4317** | Twenty CRM | HTTPS | API key |
| **9999** | ntfy | HTTPS | Topic-based |

## Acces depuis les containers Docker

Les containers accedent aux services natifs via :

```
# Ollama (natif sur le Mac)
http://host.docker.internal:11434

# Autres containers Docker
http://localhost:<port>
# ou via le nom du container Docker
http://<container-name>:<port>
```

## Verification rapide

```bash
# Tous les services locaux d'un coup
for svc in "Ollama:11434/api/tags" "Chroma:8000/api/v2/heartbeat" \
           "LobeChat:3210" "Mem0:8050/health" "SiYuan:6806" \
           "Paperclip:8060"; do
    name="${svc%%:*}"
    url="http://localhost:${svc#*:}"
    if curl -sf "$url" &>/dev/null; then
        echo "[OK] $name"
    else
        echo "[!!] $name ne repond pas"
    fi
done
```

## Ports reserves (ne pas utiliser)

| Range | Usage |
|-------|-------|
| 3210-3220 | LobeChat + extensions |
| 5432 | PostgreSQL (interne Docker) |
| 6806-6810 | SiYuan |
| 8000-8010 | Chroma |
| 8050-8060 | Mem0 + Paperclip |
| 11434 | Ollama |
