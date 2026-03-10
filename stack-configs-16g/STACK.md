# Stack Finale — Plateforme Dev & IA Self-Hosted

> 34 outils · 2 machines · 100% local · Tout connecté

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
> 20 services serveur utilisent ~4.6 Go RAM (29%) — très confortable.

---

## 2. Les 34 outils

### MacBook Pro — 13 outils

| #  | Outil             | Role                                              |
|----|-------------------|----------------------------------------------------|
| 1  | **Ollama**        | LLM local (Apple Silicon, 48 Go RAM)               |
| 2  | **Paperclip**     | Orchestrateur agents IA                             |
| 3  | **Obsidian**      | Knowledge base Markdown                             |
| 4  | **SurfSense**     | RAG unifie : connecteurs, search hybride, Ollama    |
| 5  | **Mem0**          | Memoire persistante partagee entre agents           |
| 6  | **Chroma**        | Base vectorielle pour embeddings                    |
| 7  | **LobeChat**      | Interface chat IA : Ollama + memoire + plugins      |
| 8  | **Handy**         | Dictee vocale 100% offline (Whisper)                |
| 9  | **Open Notebook** | NotebookLM local : docs, podcasts, Ollama           |
| 10 | **Termix**        | Gestion serveur a distance (SSH)                    |
| 11 | **LocalSend**     | Transfert fichiers Mac <-> Serveur, P2P chiffre     |
| 12 | **KeePassXC**     | Gestionnaire mots de passe local                    |
| 13 | **Shannon**       | Pentesting IA autonome sur tes apps web             |

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
║   ┌────────┐  ┌───────────┐  ┌────────┐  ┌──────────────┐  ║
║   │ Mem0   │  │ SurfSense │  │ Chroma │  │Open Notebook │  ║
║   │Memoire │  │ RAG 25+   │  │Vector  │  │Recherche &   │  ║
║   │agents  │  │connecteurs│  │DB      │  │Podcasts      │  ║
║   └───┬────┘  └────┬──────┘  └───┬────┘  └──────────────┘  ║
║       └────────────┼─────────────┘                           ║
║                    │                                         ║
║             ┌──────▼──────┐                                  ║
║             │   Ollama    │                                  ║
║             │  LLM local  │                                  ║
║             │  48 Go RAM  │                                  ║
║             └──────┬──────┘                                  ║
║                    │                                         ║
║   ┌────────────────┼────────────────┐                        ║
║   ▼                ▼                ▼                        ║
║ LobeChat      Paperclip         Handy                       ║
║ (chat IA)   (orchestrateur)  (dictee vocale)                ║
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
| 1 | Handy -> Obsidian | Texte colle | Dictee vocale -> notes markdown |
| 2 | Obsidian -> SurfSense | Connecteur natif | Indexation notes dans knowledge base |
| 3 | SurfSense -> Chroma | API embeddings | Vecteurs pour recherche semantique |
| 4 | SurfSense -> Ollama | LiteLLM | Inference RAG |
| 5 | Mem0 -> Ollama | API | Memoire agents + inference |
| 6 | Mem0 -> Paperclip | API | Contexte persistant par agent |
| 7 | LobeChat -> Ollama | API locale | Chat IA conversationnel |
| 8 | LobeChat -> Mem0 | Plugin | Memoire persistante dans chat |
| 9 | Open Notebook -> Ollama | API locale | Recherche docs + podcasts |
| 10 | Paperclip -> Ollama | API locale | Orchestration agents IA |

### Mac -> Serveur

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 11 | Paperclip -> Gitea | HTTP | Agent DevOps -> API repos |
| 12 | Paperclip -> Dokploy | HTTP | Agent DevOps -> deploiement |
| 13 | Paperclip -> n8n | HTTP | Agent -> webhooks workflows |
| 14 | Paperclip -> BillionMail | HTTP | Agent Marketing -> campagnes |
| 15 | Paperclip -> ntfy | HTTP | Agent -> notifications |
| 16 | Termix -> Serveur | SSH via NetBird | Administration serveur |
| 17 | LocalSend -> Mac <-> Serveur | P2P chiffre | Transfert fichiers |
| 18 | Nextcloud -> Mac <-> Serveur | WebDAV sync | Cloud perso, fichiers |
| 19 | NetBird -> Mac <-> Serveur <-> Tel | WireGuard mesh | Acces securise partout |
| 20 | Shannon -> Gitea | Analyse code | Scan vulnerabilites |
| 21 | Shannon -> Paperclip | Rapport | Cree issues securite |

### Serveur interne — DevOps

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 22 | Gitea -> Dokploy | Webhook push | Declenche build + deploy |
| 23 | Gitea -> n8n | Webhook | Declenche workflows CI/CD |
| 24 | Dokploy -> Playwright | Post-deploy hook | Lance tests E2E |
| 25 | n8n -> Dokploy | API | Controle deploiement |
| 26 | n8n -> Playwright | API | Declenche tests |
| 27 | n8n -> Firecrawl | API REST | Scrape web -> Markdown |
| 28 | Firecrawl -> Redis | BullMQ | Queues de scraping |
| 29 | Firecrawl -> Chroma (via n8n) | Workflow | Indexation contenu scrape |

### Serveur interne — Business

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 30 | n8n -> ntfy | HTTP POST | Notifications push |
| 31 | n8n -> BillionMail | API | Campagnes email auto |
| 32 | n8n -> Twenty CRM | API REST | Sync leads/deals |
| 33 | n8n -> Paperclip | API REST | Creer taches auto |
| 34 | Twenty CRM -> n8n | Webhooks | Nouveaux leads -> actions |
| 35 | Twenty CRM -> BillionMail | Via n8n | Lead -> email welcome |
| 36 | Twenty CRM -> SurfSense | Via n8n | Indexer contacts CRM |
| 37 | Cal.com -> n8n | Webhooks | RDV booke -> actions |
| 38 | Cal.com -> Nextcloud Calendar | CalDAV sync | Sync calendrier |
| 39 | Umami -> n8n | API REST | Donnees analytics -> workflows |
| 40 | Uptime Kuma -> n8n | Webhook alerte | Service down -> notification |
| 41 | ntfy -> Toi | Push mobile | Notifications iOS/Android |

### Serveur interne — Infra

| # | De -> Vers | Methode | Ce qui transite |
|---|------------|---------|-----------------|
| 42 | CrowdSec -> Caddy | Bouncer | Bloque IPs malveillantes |
| 43 | CrowdSec -> n8n | Webhook alerte | Attaque -> notification |
| 44 | Authelia -> Caddy | Forward auth | SSO pour tous les services |
| 45 | Dockge -> Tous containers | Docker API | Gestion visuelle stacks |
| 46 | Duplicati -> HDD 2 To | Destination backup | Backup local chiffre |
| 47 | KeePassXC -> Tous | Local | Mots de passe |

### Base de donnees partagee (PostgreSQL)

| # | Service | Base | User |
|---|---------|------|------|
| 48 | Gitea | gitea_db | gitea |
| 49 | Twenty CRM | twenty_db | twenty |
| 50 | Cal.com | calcom_db | calcom |
| 51 | Umami | umami_db | umami |
| 52 | n8n | n8n_db | n8n |
| 53 | Authelia | authelia_db | authelia |
| 54 | Nextcloud | nextcloud_db | nextcloud |

---

## 5. Workflows cles

### WF1 — Dictee -> Code -> Deploy

```
Handy (dictee vocale)
  -> Obsidian (note #spec)
  -> SurfSense (indexe -> Chroma)
  -> Mem0 (enregistre contexte)
  -> Paperclip (cree tache)
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
  -> SurfSense / Chroma (indexation)
  -> Mem0 (enrichit memoire agents)
```

### WF6 — Securite automatisee

```
CrowdSec (detecte attaque)
  -> n8n (webhook)
  -> ntfy -> alerte "Attaque detectee"
  -> Caddy bouncer (bloque IP)

Shannon (scan periodique)
  -> Gitea (analyse code)
  -> Paperclip (cree issues securite)
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
| termix.home | Termix | SSO |

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
| 3006 | Termix | Interne (via Caddy) |
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
