# Docker — Best Practices

## Dockerfile

### Multi-stage builds

Toujours utiliser des multi-stage builds pour reduire la taille de l'image :

```dockerfile
# Stage 1 : Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# Stage 2 : Production
FROM node:20-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 app
COPY --from=builder --chown=app:app /app/dist ./dist
COPY --from=builder --chown=app:app /app/node_modules ./node_modules
USER app
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### Ordre des layers (cache optimization)

```dockerfile
# 1. Base image (change rarement)
FROM node:20-alpine

# 2. Dependencies systeme (change rarement)
RUN apk add --no-cache curl

# 3. Dependencies app (change parfois)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# 4. Code source (change souvent) — EN DERNIER
COPY . .
RUN pnpm build
```

**Regle** : les instructions qui changent le moins en haut, celles qui changent le plus en bas.

### .dockerignore

Toujours avoir un `.dockerignore` :

```
node_modules
.git
.env
.env.*
*.md
dist
coverage
.nyc_output
.vscode
.idea
```

### Securite

```dockerfile
# Toujours specifier la version exacte
FROM node:20.11-alpine3.19

# Ne JAMAIS tourner en root
RUN addgroup -S app && adduser -S app -G app
USER app

# Pas de secrets dans le Dockerfile
# Utiliser --mount=type=secret pour le build
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm install

# Scanner les vulnerabilites
# docker scout quickview <image>
```

### Health checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
```

## Docker Compose

### Structure standard

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/app
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  db:
    image: postgres:16-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### Regles

| Regle | Pourquoi |
|-------|----------|
| `depends_on` avec `condition: service_healthy` | Attendre que la dep soit prete |
| `restart: unless-stopped` | Redemarrage auto sauf arret manuel |
| `deploy.resources.limits` | Prevenir les OOM |
| Volumes nommes | Persistance propre |
| Pas de `latest` tag | Reproductibilite |

## Commandes essentielles

```bash
# Demarrer
docker compose up -d

# Demarrer avec rebuild
docker compose up -d --build

# Logs
docker compose logs -f <service>

# Shell dans un container
docker compose exec <service> sh

# Arreter
docker compose down

# Arreter + supprimer volumes (ATTENTION: perte de donnees)
docker compose down -v

# Etat
docker compose ps

# Stats ressources
docker stats
```

## Apple Silicon (ARM64)

```yaml
# Forcer la plateforme si l'image est x86 only
services:
  legacy-app:
    image: some-x86-image:latest
    platform: linux/amd64  # Emulation via Rosetta
```

Preferer les images `*-alpine` qui supportent nativement ARM64.

## Networking pour notre stack

```yaml
# Les containers accedent a Ollama natif via :
extra_hosts:
  - "host.docker.internal:host-gateway"

# Ou via environment :
environment:
  - OLLAMA_HOST=http://host.docker.internal:11434
```
