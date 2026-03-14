# Stack Finale — Plateforme Dev & IA Self-Hosted

> 28 outils · 2 machines · 100% local · Tout connecté

---

## 1. Machines

### MacBook Pro 14" M5 Pro

| Spec     | Valeur                             |
| -------- | ---------------------------------- |
| Puce     | M5 Pro (15 CPU, 16 GPU, 16 Neural) |
| RAM      | 48 Go unifiée                      |
| Stockage | SSD 1 To                           |

### Serveur — HP OMEN Obelisk 875 (Homelab)

| Spec     | Valeur                                              |
| -------- | --------------------------------------------------- |
| CPU      | Intel Core i7-9700F (8 coeurs, 3.0 / 4.7 GHz Turbo) |
| RAM      | 16 Go DDR4 2666 MHz                                 |
| Stockage | SSD 256 Go NVMe (OS) + HDD 2 To (data)              |
| OS       | Debian 12                                            |

> **Note** : Toute l'IA (Ollama) tourne sur le Mac M5 Pro (48 Go).
> 21 services serveur utilisent ~4.6 Go RAM (29%) — très confortable.

---

## 2. Les 28 outils

### MacBook Pro — 7 outils

| #  | Outil             | Role                                              |
|----|-------------------|----------------------------------------------------|
| 1  | **Ollama**        | LLM local (Apple Silicon, 48 Go RAM)               |
| 2  | **Paperclip**     | Orchestrateur agents IA (11 agents)                 |
| 3  | **SiYuan Note**   | Knowledge base structuree (8 notebooks)             |
| 4  | **Mem0**          | Memoire persistante partagee entre agents           |
| 5  | **Chroma**        | Base vectorielle pour embeddings                    |
| 6  | **LobeChat**      | Interface chat IA : Ollama + memoire + plugins      |
| 7  | **LiteLLM**       | Proxy API : traduit Claude API → Ollama local       |

### Serveur HP OMEN — 21 outils

| #  | Outil             | Role                                              | RAM estimee |
|----|-------------------|----------------------------------------------------|-------------|
| 1  | **PostgreSQL 16** | Base de donnees partagee (7 bases)                  | ~400 Mo     |
| 2  | **Redis**         | Cache et queues (Twenty, Nextcloud, Firecrawl)      | ~50 Mo      |
| 3  | **Caddy**         | Reverse proxy HTTPS automatique                     | ~50 Mo      |
| 4  | **CrowdSec**      | IDS/IPS + bouncer Caddy                             | ~200 Mo     |
| 5  | **Authelia**      | SSO / authentification unique                       | ~30 Mo      |
| 6  | **NetBird**       | VPN mesh (installe sur le host)                     | ~100 Mo     |
| 7  | **Gitea**         | Git self-hosted : repos, PRs, CI/CD                 | ~200 Mo     |
| 8  | **Dokploy**       | Deploiement apps (installe sur le host, Swarm)      | ~300 Mo     |
| 9  | **Firecrawl**     | Web scraper -> Markdown (API REST)                  | ~300 Mo     |
| 10 | **Playwright**    | Tests E2E automatises                               | ~0 (demande)|
| 11 | **n8n**           | Automatisation workflows — connecte TOUT            | ~300 Mo     |
| 12 | **Uptime Kuma**   | Monitoring + alertes + status page                  | ~150 Mo     |
| 13 | **Oak**           | Dashboard page d'accueil                            | ~50 Mo      |
| 14 | **Dockge**        | UI web pour gerer les Docker Compose                | ~100 Mo     |
| 15 | **Twenty CRM**    | CRM : contacts, pipeline, deals                     | ~1 Go       |
| 16 | **BillionMail**   | Serveur mail + email marketing                      | ~500 Mo     |
| 17 | **ntfy**          | Notifications push mobile                           | ~10 Mo      |
| 18 | **Cal.com**       | Scheduling (alternative Calendly)                   | ~500 Mo     |
| 19 | **Umami**         | Analytics web privacy-first                         | ~200 Mo     |
| 20 | **Nextcloud**     | Cloud perso : fichiers, calendrier, sync            | ~500 Mo     |
| 21 | **Duplicati**     | Backup chiffre AES-256, incremental                 | ~200 Mo     |
|    |                   |                                                    | **~4.6 Go** |

> **RAM utilisee : ~4.6 Go sur 16 Go = 29%**

---

## 3. Architecture

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                 TOI (Operateur)                               ║
║           Telephone · MacBook Pro · Anywhere                 ║
║                    via NetBird VPN                            ║
║                                                              ║
╚════════════════════════╦═════════════════════════════════════╝
                         │
╔════════════════════════▼═════════════════════════════════════╗
║                                                              ║
║            COUCHE IA & KNOWLEDGE (Mac)                       ║
║                                                              ║
║   ┌────────┐  ┌──────────┐  ┌────────┐  ┌──────────────┐   ║
║   │ Mem0   │  │  SiYuan   │  │ Chroma │  │   LiteLLM    │   ║
║   │Memoire │  │Knowledge │  │Vector  │  │  Proxy API   │   ║
║   │agents  │  │  Base    │  │DB      │  │              │   ║
║   └───┬────┘  └────┬─────┘  └───┬────┘  └──────┬───────┘   ║
║       └────────────┼────────────┘               │           ║
║                    │                            │           ║
║             ┌──────▼──────┐                     │           ║
║             │   Ollama    │◄────────────────────┘           ║
║             │  LLM local  │                                  ║
║             │  48 Go RAM  │                                  ║
║             └──────┬──────┘                                  ║
║                    │                                         ║
║   ┌────────────────┼────────────────┐                        ║
║   ▼                ▼                ▼                        ║
║ LobeChat      Paperclip         NetBird                     ║
║ (chat IA)   (orchestrateur)  (VPN serveur)                  ║
║                                                              ║
╚════════════════════════╦═════════════════════════════════════╝
                         │
                NetBird VPN / Reseau local
                         │
╔════════════════════════▼═════════════════════════════════════╗
║                                                              ║
║           SERVEUR HP OMEN i7-9700F                           ║
║           16 Go DDR4 · SSD 256 Go · HDD 2 To                ║
║                                                              ║
║   ┌──────────── INFRA & RESEAU ──────────────┐              ║
║   │  Caddy (reverse proxy HTTPS)              │              ║
║   │  NetBird (VPN mesh)                       │              ║
║   │  Authelia (SSO / forward auth)            │              ║
║   │  Oak (dashboard)                          │              ║
║   │  Uptime Kuma (monitoring + alertes)       │              ║
║   │  Dockge (gestion Docker Compose)          │              ║
║   └───────────────────────────────────────────┘              ║
║                                                              ║
║   ┌──────────── SECURITE ─────────────────────┐              ║
║   │  CrowdSec (IDS/IPS + bouncer Caddy)       │              ║
║   │  Duplicati (backup chiffre automatique)    │              ║
║   └───────────────────────────────────────────┘              ║
║                                                              ║
║   ┌──────────── DEVOPS ───────────────────────┐              ║
║   │  Gitea (repos + PRs + CI/CD)              │              ║
║   │  Dokploy (build + deploy auto)            │              ║
║   │  Firecrawl (web scraper -> Markdown)      │              ║
║   │  Playwright (tests E2E)                   │              ║
║   └───────────────────────────────────────────┘              ║
║                                                              ║
║   ┌──────────── BUSINESS ─────────────────────┐              ║
║   │  Twenty CRM (contacts, pipeline, deals)   │              ║
║   │  BillionMail (serveur mail + marketing)   │              ║
║   │  ntfy (notifications push mobile)         │              ║
║   │  Cal.com (scheduling + prise de RDV)      │              ║
║   │  Umami (analytics web privacy-first)      │              ║
║   └───────────────────────────────────────────┘              ║
║                                                              ║
║   ┌──────────── DATA ─────────────────────────┐              ║
║   │  PostgreSQL 16 (7 bases partagees)        │              ║
║   │  Redis (cache + queues)                   │              ║
║   │  Nextcloud (fichiers, calendrier, sync)   │              ║
║   └───────────────────────────────────────────┘              ║
║                                                              ║
║   ┌──────────── AUTOMATISATION ───────────────┐              ║
║   │  n8n (ciment de tout)                     │              ║
║   └───────────────────────────────────────────┘              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 4. Toutes les connexions

### Couche IA (Mac)

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 1 | Mem0 -> Ollama | API | Memoire agents + inference |
| 2 | Mem0 -> Chroma | API embeddings | Vecteurs pour recherche semantique |
| 3 | Mem0 -> Paperclip | API | Contexte persistant par agent |
| 4 | LobeChat -> Ollama | API locale | Chat IA conversationnel |
| 5 | Paperclip -> Ollama | LiteLLM proxy | Orchestration agents IA |
| 6 | Paperclip -> SiYuan | API REST | Knowledge base (read/write docs) |
| 7 | Paperclip -> Mem0 | API REST | Memoire agents (read/write) |

### Mac -> Serveur

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 8 | Paperclip -> Gitea | HTTP | Agent DevOps -> API repos |
| 9 | Paperclip -> Dokploy | HTTP | Agent DevOps -> deploiement |
| 10 | Paperclip -> n8n | HTTP | Agent -> webhooks workflows |
| 11 | Paperclip -> BillionMail | HTTP | Agent -> campagnes email |
| 12 | Paperclip -> ntfy | HTTP | Agent -> notifications |
| 13 | LocalSend -> Mac <-> Serveur | P2P chiffre | Transfert fichiers |
| 14 | Nextcloud -> Mac <-> Serveur | WebDAV sync | Cloud perso, fichiers |
| 15 | NetBird -> Mac <-> Serveur <-> Tel | WireGuard mesh | Acces securise partout |

### Serveur interne — DevOps

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 16 | Gitea -> Dokploy | Webhook push | Declenche build + deploy |
| 17 | Gitea -> n8n | Webhook | Declenche workflows CI/CD |
| 18 | Dokploy -> Playwright | Post-deploy hook | Lance tests E2E |
| 19 | n8n -> Dokploy | API | Controle deploiement |
| 20 | n8n -> Playwright | API | Declenche tests |
| 21 | n8n -> Firecrawl | API REST | Scrape web -> Markdown |
| 22 | Firecrawl -> Redis | BullMQ | Queues de scraping |
| 23 | Firecrawl -> Chroma (via n8n) | Workflow | Indexation contenu scrape |

### Serveur interne — Business

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 24 | n8n -> ntfy | HTTP POST | Notifications push |
| 25 | n8n -> BillionMail | API | Campagnes email auto |
| 26 | n8n -> Twenty CRM | API REST | Sync leads/deals |
| 27 | n8n -> Paperclip | API REST | Creer taches auto |
| 28 | Twenty CRM -> n8n | Webhooks | Nouveaux leads -> actions |
| 29 | Twenty CRM -> BillionMail | Via n8n | Lead -> email welcome |
| 30 | Cal.com -> n8n | Webhooks | RDV booke -> actions |
| 31 | Cal.com -> Nextcloud Calendar | CalDAV sync | Sync calendrier |
| 32 | Umami -> n8n | API REST | Donnees analytics -> workflows |
| 33 | Uptime Kuma -> n8n | Webhook alerte | Service down -> notification |
| 34 | ntfy -> Toi | Push mobile | Notifications iOS/Android |

### Serveur interne — Infra

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 35 | CrowdSec -> Caddy | Bouncer | Bloque IPs malveillantes |
| 36 | CrowdSec -> n8n | Webhook alerte | Attaque -> notification |
| 37 | Authelia -> Caddy | Forward auth | SSO pour tous les services |
| 38 | Dockge -> Tous containers | Docker API | Gestion visuelle stacks |
| 39 | Duplicati -> HDD 2 To | Destination backup | Backup local chiffre |
| 40 | KeePassXC -> Tous | Local | Mots de passe |

### Base de donnees partagee (PostgreSQL)

| # | Service | Base | User |
|---|---------|------|------|
| 41 | Gitea | gitea_db | gitea |
| 42 | Twenty CRM | twenty_db | twenty |
| 43 | Cal.com | calcom_db | calcom |
| 44 | Umami | umami_db | umami |
| 45 | n8n | n8n_db | n8n |
| 46 | Authelia | authelia_db | authelia |
| 47 | Nextcloud | nextcloud_db | nextcloud |

---

## 5. Workflows cles

### WF1 — Idee -> Code -> Deploy

```
Paperclip (cree tache)
  -> Mem0 (charge contexte)
  -> SiYuan (lit conventions)
  -> Ollama (code)
  -> git push -> Gitea
  -> Dokploy (build + deploy)
  -> Playwright (tests E2E)
  -> n8n -> ntfy "Deploy OK" ou "Tests fail"
```

### WF2 — Pipeline CI/CD (a chaque push)

```
git push -> Gitea (webhook)
  -> n8n (orchestration)
  ├── Dokploy API (build + deploy)
  │     -> Playwright (tests E2E)
  ├── Si OK :
  │     ├── ntfy -> notification "Deploy reussi"
  │     ├── Uptime Kuma -> monitoring actif
  │     └── Umami -> tracking active
  └── Si fail :
        ├── Gitea -> issue automatique
        └── ntfy -> alerte "Tests fail"
```

### WF3 — Lead -> CRM -> Email

```
Formulaire web / Cal.com booking
  -> n8n (webhook)
  -> Twenty CRM (creer contact)
  -> BillionMail (email welcome)
  -> ntfy -> notification "Nouveau lead"
```

### WF4 — Monitoring -> Alerte

```
Uptime Kuma (detecte service down)
  -> n8n (webhook)
  -> ntfy -> notification push mobile
  -> Twenty CRM (creer tache resolution)
```

### WF5 — Scraping web -> Knowledge base

```
n8n (trigger schedule ou manuel)
  -> Firecrawl API (scrape URL -> Markdown)
  -> n8n (traitement)
  -> Chroma (indexation vecteurs)
  -> Mem0 (enrichit memoire agents)
```

### WF6 — Securite automatisee

```
CrowdSec (detecte attaque)
  -> n8n (webhook)
  -> ntfy -> alerte "Attaque detectee"
  -> Caddy bouncer (bloque IP)
```

### WF7 — Backup automatique

```
Duplicati (schedule quotidien 3h du matin)
  -> Sauvegarde /opt/stacks + volumes Docker
  -> Destination : HDD 2 To (chiffre AES-256)
  -> Retention : 7 quotidiens, 4 hebdomadaires, 3 mensuels
  -> ntfy (via n8n) -> notification "Backup OK/fail"
```

### WF8 — Planning -> CRM

```
Cal.com (nouveau RDV booke)
  -> n8n (webhook)
  -> Twenty CRM (creer/maj contact)
  -> Nextcloud Calendar (sync CalDAV)
  -> ntfy -> notification "RDV confirme"
```

---

## 6. URLs des services

| URL | Service | Auth |
|-----|---------|------|
| auth.home | Authelia SSO | Public (login) |
| gitea.home | Git | SSO |
| deploy.home | Dokploy | SSO |
| scrape.home | Firecrawl | SSO |
| crm.home | Twenty CRM | SSO |
| n8n.home | n8n | SSO |
| mail.home | BillionMail | Public |
| cloud.home | Nextcloud | Public |
| monitor.home | Uptime Kuma | SSO |
| dash.home | Oak | Public |
| docker.home | Dockge | SSO |
| cal.home | Cal.com | Public |
| stats.home | Umami | SSO |
| backup.home | Duplicati | SSO |
| notify.home | ntfy | Public |

---

## 7. Ports serveur

| Port | Service | Acces |
|------|---------|-------|
| 25 | BillionMail SMTP | Externe |
| 80 | Caddy HTTP | Externe -> redirect HTTPS |
| 443 | Caddy HTTPS | Externe |
| 587 | BillionMail SMTP submission | Externe |
| 993 | BillionMail IMAPS | Externe |
| 2222 | Gitea SSH | Externe |
| 3000 | Gitea / Dokploy | Interne (via Caddy) |
| 3001 | Uptime Kuma | Interne (via Caddy) |
| 3002 | Twenty CRM | Interne (via Caddy) |
| 3003 | Cal.com | Interne (via Caddy) |
| 3004 | Oak | Interne (via Caddy) |
| 3005 | Umami | Interne (via Caddy) |
| 3008 | Firecrawl | Interne (via Caddy) |
| 5001 | Dockge | Interne (via Caddy) |
| 5432 | PostgreSQL | Interne uniquement |
| 5678 | n8n | Interne (via Caddy) |
| 6379 | Redis | Interne uniquement |
| 8025 | BillionMail Web | Interne (via Caddy) |
| 8080 | Nextcloud | Interne (via Caddy) |
| 8085 | ntfy | Interne (via Caddy) |
| 8180 | CrowdSec metrics | Interne uniquement |
| 8200 | Duplicati | Interne (via Caddy) |
| 9091 | Authelia | Interne (via Caddy) |

---

## 8. Installation

```bash
# Serveur (HP OMEN) — 1 commande
cd /opt/stacks && sudo ./setup.sh

# Mac (MacBook Pro) — 1 commande
./setup-mac.sh
```

Tout est automatise : secrets, .env, deploiement dans l'ordre, verification.
Voir `GUIDE-DEPLOIEMENT.md` pour le detail etape par etape.
