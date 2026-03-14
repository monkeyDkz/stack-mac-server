# Guide de Déploiement Complet — Stack Self-Hosted

> **MacBook Pro M5 Pro** (dev + IA) + **HP OMEN i7-9700F** (serveur Debian 12, 16 Go RAM)
> 33 outils — 7 phases

## Installation rapide (recommande)

```bash
# Sur le serveur, apres avoir copie stack-configs-16g dans /opt/stacks :
cd /opt/stacks
chmod +x setup.sh
sudo ./setup.sh
```

Le script `setup.sh` fait tout automatiquement :
- Genere tous les secrets (sauvegardes dans `secrets.env`)
- Cree les `.env` de chaque service
- Deploie les 5 phases dans l'ordre
- Installe Dokploy et NetBird sur le host

> **Apres l'installation** : sauvegarder `secrets.env` dans KeePassXC puis le supprimer du serveur.

Le guide ci-dessous detaille chaque etape si tu preferes installer manuellement ou en cas de debug.

---

## Table des matières

1. [Pré-requis matériel](#1-pré-requis-matériel)
2. [Phase 0 — Fondations serveur](#2-phase-0--fondations-serveur)
3. [Phase 1 — Sécurité & monitoring](#3-phase-1--sécurité--monitoring)
4. [Phase 2 — DevOps core](#4-phase-2--devops-core)
5. [Phase 3 — Apps métier](#5-phase-3--apps-métier)
6. [Phase 4 — Cloud & services](#6-phase-4--cloud--services)
7. [Phase 5 — Tests & CI](#7-phase-5--tests--ci)
8. [Phase Mac — IA & Knowledge](#8-phase-mac--ia--knowledge)
9. [Connexions inter-services](#9-connexions-inter-services)
10. [Vérifications finales](#10-vérifications-finales)
11. [Maintenance courante](#11-maintenance-courante)
12. [Dépannage](#12-dépannage)

---

## 1. Pré-requis matériel

### HP OMEN (serveur)

```
CPU  : Intel i7-9700F (8 cœurs, 3.0-4.7 GHz)
RAM  : 16 Go DDR4 2666 MHz
SSD  : 256 Go (OS) + disque data recommandé (1 To+)
OS   : Debian 12 (Bookworm) — installation fraîche
```

> **Note RAM** : 16 Go suffisent largement (~3-4 Go utilisés par les 19 services).
> L'IA (Ollama) tourne exclusivement sur le Mac M5 Pro.

**Optionnel :** SSD/HDD supplémentaire pour les données (Nextcloud, backups)

### MacBook Pro M5 Pro

```
RAM  : 48 Go unifié
OS   : macOS avec Homebrew, Docker Desktop, Node.js
```

### Réseau

- Les deux machines sur le même réseau local OU NetBird installé pour VPN mesh
- Routeur avec possibilité de DNS local ou fichier `/etc/hosts`

---

## 2. Phase 0 — Fondations serveur

> **Objectif** : Debian prêt, Docker installé, PostgreSQL + Redis + Caddy opérationnels
> **Durée estimée** : 1-2 heures

### 2.1 — Installer Debian 12 sur le HP OMEN

Si pas déjà fait, installer Debian 12 Bookworm (installation minimale, pas d'environnement de bureau).

Après l'installation, se connecter en SSH :

```bash
ssh user@IP_DU_SERVEUR
```

### 2.2 — Préparer le système

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer les outils de base
sudo apt install -y curl wget git htop nano ufw

# Configurer le pare-feu (ouvrir SSH + HTTP/HTTPS)
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25/tcp      # SMTP (BillionMail)
sudo ufw allow 587/tcp     # SMTP submission
sudo ufw allow 993/tcp     # IMAPS
sudo ufw allow 2222/tcp    # Gitea SSH
sudo ufw enable
```

### 2.3 — Installer Docker

```bash
# Installer Docker via le script officiel
curl -fsSL https://get.docker.com | sudo sh

# Ajouter ton user au groupe docker (pas besoin de sudo après)
sudo usermod -aG docker $USER

# Se reconnecter pour que le groupe prenne effet
exit
# ... puis se reconnecter en SSH

# Vérifier
docker --version
docker compose version
```

### 2.4 — Créer la structure de répertoires

```bash
# Répertoire principal pour toutes les stacks
sudo mkdir -p /opt/stacks
sudo chown $USER:$USER /opt/stacks

# Copier les configs (depuis ton Mac via scp ou git)
# Option A : scp depuis le Mac
scp -r stack-configs/serveur/* user@IP_SERVEUR:/opt/stacks/

# Option B : cloner un repo git
cd /opt/stacks && git clone https://ton-repo/stack-configs.git .
```

### 2.5 — Créer le réseau Docker partagé

```bash
docker network create stack-network
```

> **Pourquoi ?** Tous les containers communiquent via ce réseau interne.
> Par exemple, Caddy peut joindre `umami:3000` sans exposer le port publiquement.

### 2.6 — Déployer le Core (PostgreSQL + Redis)

```bash
cd /opt/stacks/core

# Créer le .env à partir du template
cp .env.example .env

# Éditer et remplacer TOUS les CHANGE_ME par des vrais mots de passe
nano .env
```

**Générer des mots de passe sécurisés :**
```bash
# Exécuter cette commande pour chaque mot de passe
openssl rand -base64 24
```

**Contenu du .env à remplir :**
```
POSTGRES_ADMIN_USER=admin
POSTGRES_ADMIN_PASSWORD=<généré>
REDIS_PASSWORD=<généré>
GITEA_DB_PASSWORD=<généré>
TWENTY_DB_PASSWORD=<généré>
CALCOM_DB_PASSWORD=<généré>
UMAMI_DB_PASSWORD=<généré>
N8N_DB_PASSWORD=<généré>
AUTHELIA_DB_PASSWORD=<généré>
NEXTCLOUD_DB_PASSWORD=<généré>
```

> **IMPORTANT** : Note tous ces mots de passe quelque part (KeePassXC !).
> Tu en auras besoin pour configurer chaque service.

```bash
# Lancer PostgreSQL + Redis
docker compose up -d

# Vérifier que tout est healthy
docker compose ps
# → postgres et redis doivent afficher "healthy"

# Vérifier que les 7 bases ont été créées
docker exec postgres psql -U admin -c "\l"
# → Tu dois voir : gitea_db, twenty_db, calcom_db, umami_db, n8n_db, authelia_db, nextcloud_db
```

### 2.7 — Déployer Caddy + CrowdSec (réseau)

```bash
cd /opt/stacks/network

cp .env.example .env
nano .env
# Remplir CROWDSEC_API_KEY (on le générera après le premier lancement)
```

**Avant de lancer**, éditer le Caddyfile pour remplacer les domaines si nécessaire :
```bash
nano Caddyfile
# Les domaines *.home sont déjà configurés
# Ils fonctionneront avec un DNS local ou /etc/hosts
```

```bash
docker compose up -d
docker compose ps
# → caddy et crowdsec doivent être running

# Générer la clé bouncer CrowdSec (NE PAS utiliser openssl)
docker exec crowdsec cscli bouncers add caddy-bouncer
# → Copier la clé affichée et la mettre dans .env → CROWDSEC_BOUNCER_KEY
# Puis redémarrer Caddy : docker compose restart caddy

# Tester que Caddy répond
curl -k https://localhost
# → Devrait retourner une erreur 404 (normal, aucun service encore)
```

### Checkpoint Phase 0

```
✅ Debian 12 installé et à jour
✅ Docker + Docker Compose fonctionnels
✅ Réseau stack-network créé
✅ PostgreSQL healthy avec 7 bases de données
✅ Redis healthy
✅ Caddy + CrowdSec running
```

---

## 3. Phase 1 — Sécurité & monitoring

> **Objectif** : SSO Authelia actif, monitoring opérationnel, Dockge pour gérer les stacks
> **Durée estimée** : 30-45 minutes

### 3.1 — Authelia (SSO)

```bash
cd /opt/stacks/auth

cp .env.example .env
nano .env
# Remplir :
# - AUTHELIA_JWT_SECRET (openssl rand -base64 64)
# - AUTHELIA_SESSION_SECRET (openssl rand -base64 64)
# - AUTHELIA_STORAGE_ENCRYPTION_KEY (openssl rand -base64 64)
# - AUTHELIA_DB_PASSWORD (le même que dans core/.env)
# - AUTHELIA_SMTP_PASSWORD (mot de passe BillionMail, à configurer plus tard)
```

**Créer le premier utilisateur :**
```bash
# Générer le hash du mot de passe
docker run --rm authelia/authelia:latest \
  authelia crypto hash generate argon2 --password 'TON_MOT_DE_PASSE'
# → Copier le hash affiché

# Éditer le fichier utilisateurs
nano users_database.yml
# Remplacer <HASH> par le hash généré
# Remplacer admin@yourdomain.com par ton email
```

```bash
docker compose up -d

# Vérifier
docker compose ps
# → authelia doit être healthy

# Tester l'accès
curl -k https://auth.home
# → Doit afficher la page de login Authelia (ou un redirect)
```

> **Comment ça marche ?** Quand tu accèdes à un service protégé (ex: gitea.home),
> Caddy demande à Authelia si tu es authentifié (via `forward_auth`).
> Si non → redirect vers auth.home pour login.
> Si oui → Caddy te laisse passer vers le service.

### 3.2 — Monitoring (Uptime Kuma + Oak)

```bash
cd /opt/stacks/monitoring

docker compose up -d
docker compose ps
```

**Configurer Uptime Kuma :**
1. Accéder à `https://monitor.home` (ou `http://IP:3001`)
2. Créer un compte admin
3. Ajouter les monitors pour chaque service :
   - `http://postgres:5432` → TCP ping
   - `http://caddy:80` → HTTP
   - `http://authelia:9091` → HTTP
   - (ajouter les autres au fur et à mesure)
4. Configurer les notifications → ntfy (à faire en Phase 2)

**Oak** est accessible sur `https://dash.home` (ou `http://IP:3004`) — dashboard système.

### 3.3 — Dockge (gestionnaire Docker)

```bash
cd /opt/stacks/dockge

docker compose up -d
```

1. Accéder à `https://docker.home` (ou `http://IP:5001`)
2. Créer un compte admin
3. Tu verras toutes les stacks dans `/opt/stacks`

> **Dockge** est ton panneau de contrôle visuel pour toutes les stacks.
> Tu peux démarrer/arrêter/mettre à jour chaque service depuis l'interface web.
> À partir de maintenant, tu peux utiliser Dockge au lieu de la CLI pour gérer les stacks.

### Checkpoint Phase 1

```
✅ Authelia SSO fonctionnel (auth.home)
✅ Uptime Kuma surveille les services (monitor.home)
✅ Oak affiche les métriques système (dash.home)
✅ Dockge gère les stacks Docker (docker.home)
```

---

## 4. Phase 2 — DevOps core

> **Objectif** : Git, automatisation, notifications
> **Durée estimée** : 30-45 minutes

### 4.1 — Gitea (Git)

```bash
cd /opt/stacks/gitea

cp .env.example .env
nano .env
# Remplir GITEA_DB_PASSWORD (le même que dans core/.env)
# Remplir GITEA_SECRET_KEY (openssl rand -base64 32)
# Remplir GITEA_INTERNAL_TOKEN (gitea generate secret INTERNAL_TOKEN — ou openssl rand -base64 64)
```

```bash
docker compose up -d
```

**Premier accès :**
1. Aller sur `https://gitea.home` (ou `http://IP:3000`)
2. L'assistant d'installation s'affiche au premier lancement
3. La DB est déjà configurée via DATABASE_URL — juste valider
4. Créer le compte admin
5. Les inscriptions sont désactivées (DISABLE_REGISTRATION=true)

**Configurer la clé SSH :**
```bash
# Sur ton Mac
cat ~/.ssh/id_ed25519.pub
# Copier la clé publique

# Dans Gitea → Settings → SSH Keys → Add Key
# Coller la clé

# Tester
git clone ssh://git@IP_SERVEUR:2222/ton-user/un-repo.git
```

### 4.2 — n8n (automatisation)

```bash
cd /opt/stacks/n8n

cp .env.example .env
nano .env
# Remplir N8N_DB_PASSWORD (le même que dans core/.env)
# Remplir N8N_ENCRYPTION_KEY (openssl rand -base64 32)
```

```bash
docker compose up -d
```

1. Accéder à `https://n8n.home` (ou `http://IP:5678`)
2. Créer le compte admin
3. n8n est l'orchestrateur central — il connectera tous les services entre eux

### 4.3 — ntfy (notifications)

```bash
cd /opt/stacks/ntfy

docker compose up -d
```

**Créer un utilisateur admin :**
```bash
docker exec -it ntfy ntfy user add --role=admin admin
# Entrer un mot de passe quand demandé
```

**Créer un topic pour les alertes :**
```bash
docker exec -it ntfy ntfy access admin alerts rw
```

1. Accéder à `https://notify.home` (ou `http://IP:8085`)
2. Se connecter avec admin / le mot de passe choisi
3. Installer l'app ntfy sur ton iPhone/Android
4. S'abonner au topic `alerts` avec l'URL `https://notify.home/alerts`

**Connecter Uptime Kuma → ntfy :**
1. Dans Uptime Kuma → Settings → Notifications
2. Type : ntfy
3. URL : `http://ntfy:80` (réseau interne Docker)
4. Topic : `alerts`
5. Username/Password : admin / ton mot de passe

### 4.4 — Firecrawl (web scraper)

```bash
cd /opt/stacks/firecrawl
docker compose up -d
```

1. API accessible sur `https://scrape.home` (ou `http://IP:3008`)
2. Scrape une page : `curl -X POST http://localhost:3008/v0/scrape -H "Content-Type: application/json" -d '{"url": "https://example.com"}'`
3. Résultat en Markdown propre, idéal pour alimenter Chroma via n8n

> **Intégration n8n** : créer un workflow HTTP Request vers `http://firecrawl-api:3002/v0/scrape`
> pour automatiser le scraping et indexer dans Chroma.

### 4.5 — Dokploy (PaaS / déploiement apps)

> **Note** : Dokploy s'installe directement sur le host (comme NetBird).
> Il utilise Docker Swarm et gère sa propre PostgreSQL interne.
> Ce sont les 2 seuls outils installés hors Docker Compose.

```bash
cd /opt/stacks/dokploy

chmod +x install.sh
./install.sh
# → Initialise Docker Swarm si nécessaire
# → Déploie Dokploy avec sa PostgreSQL interne
```

1. Accéder à `https://deploy.home` (ou `http://IP:3000`)
2. Créer le compte admin au premier accès
3. Connecter Gitea comme source de déploiement

### Checkpoint Phase 2

```
✅ Gitea opérationnel (gitea.home) — push/pull via SSH:2222
✅ n8n prêt pour les workflows (n8n.home)
✅ ntfy envoie des notifications (notify.home)
✅ Uptime Kuma → ntfy connecté (alertes sur mobile)
✅ Firecrawl scrape le web en Markdown (scrape.home)
✅ Dokploy déploie les apps (deploy.home) — installé sur le host
```

---

## 5. Phase 3 — Apps métier

> **Objectif** : CRM, planning, analytics, email
> **Durée estimée** : 45-60 minutes

### 5.1 — Twenty CRM

```bash
cd /opt/stacks/twenty

cp .env.example .env
nano .env
# Remplir TWENTY_DB_PASSWORD, TWENTY_APP_SECRET, REDIS_PASSWORD
# Tous avec : openssl rand -base64 32
```

```bash
docker compose up -d

# Attendre ~30-60 secondes que le server + worker démarrent
docker compose logs -f twenty-server
# Attendre de voir "Application started"
```

1. Accéder à `https://crm.home` (ou `http://IP:3002`)
2. Créer le compte admin
3. Twenty est un CRM complet (contacts, entreprises, deals, tâches)

### 5.2 — Cal.com

```bash
cd /opt/stacks/calcom

cp .env.example .env
nano .env
# Remplir CALCOM_DB_PASSWORD, CALCOM_NEXTAUTH_SECRET, CALCOM_ENCRYPTION_KEY
# Remplir SMTP_PASSWORD (BillionMail, voir 5.4)
```

```bash
docker compose up -d
```

1. Accéder à `https://cal.home` (ou `http://IP:3003`)
2. Créer le compte → configurer les disponibilités
3. Les emails de confirmation passent par BillionMail

### 5.3 — Umami (analytics)

```bash
cd /opt/stacks/umami

cp .env.example .env
nano .env
# Remplir UMAMI_DB_PASSWORD, UMAMI_APP_SECRET
```

```bash
docker compose up -d
```

1. Accéder à `https://stats.home` (ou `http://IP:3005`)
2. **Login par défaut : admin / umami** → changer immédiatement !
3. Ajouter tes sites web à tracker
4. Le script de tracking est renommé `s.js` (anti-adblock)

**Ajouter le tracking sur tes services :**
```html
<script defer src="https://stats.home/s.js" data-website-id="ID_DU_SITE"></script>
```

### 5.4 — BillionMail (email)

```bash
cd /opt/stacks/billionmail

cp .env.example .env
nano .env
# Remplir BILLIONMAIL_ADMIN_PASSWORD
```

**Avant de lancer**, important :
- Ton domaine doit avoir les enregistrements DNS suivants :
  - `MX` → mail.yourdomain.com
  - `A` → mail.yourdomain.com → IP publique du serveur
  - `TXT` (SPF) → `v=spf1 ip4:TON_IP_PUBLIQUE -all`
  - `TXT` (DKIM) → à récupérer après le premier lancement
  - `TXT` (DMARC) → `v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com`

> **Si tu n'as pas de domaine public** ou que le serveur est uniquement local,
> BillionMail fonctionne quand même pour l'envoi interne entre containers
> (Gitea, Cal.com, Nextcloud, Authelia utilisent le SMTP interne).

```bash
docker compose up -d

# Récupérer la clé DKIM (pour le DNS)
docker exec billionmail cat /etc/opendkim/keys/yourdomain.com/default.txt
```

1. Accéder à `https://mail.home` (ou `http://IP:8025`)
2. Se connecter avec admin@yourdomain.com / le mot de passe choisi
3. Créer les adresses email pour les services :
   - `calcom@yourdomain.com` (Cal.com)
   - `nextcloud@yourdomain.com` (Nextcloud)
   - `gitea@yourdomain.com` (Gitea)
   - `authelia@yourdomain.com` (Authelia)
   - `noreply@yourdomain.com` (adresse d'envoi générique)

**Mettre à jour les mots de passe SMTP** dans les .env des autres services maintenant que BillionMail est configuré.

> **SMTP_PASSWORD** : C'est le mot de passe du compte email créé dans BillionMail.
> Le **même mot de passe** doit être copié dans les .env de : Gitea, Cal.com, Nextcloud, Authelia.
> Chaque service utilise une adresse email différente (gitea@, calcom@, etc.) mais peut partager le même mot de passe SMTP.

### Checkpoint Phase 3

```
✅ Twenty CRM opérationnel (crm.home)
✅ Cal.com planifie les rendez-vous (cal.home)
✅ Umami collecte les analytics (stats.home)
✅ BillionMail gère les emails (mail.home)
✅ SMTP interne fonctionnel entre les services
```

---

## 6. Phase 4 — Cloud & services

> **Objectif** : Stockage cloud, backups, terminal SSH, accès distant
> **Durée estimée** : 45-60 minutes

### 6.1 — Nextcloud

```bash
cd /opt/stacks/nextcloud

cp .env.example .env
nano .env
# Remplir NEXTCLOUD_DB_PASSWORD (le même que dans core/.env)
# Remplir NEXTCLOUD_ADMIN_PASSWORD
# Remplir SMTP_PASSWORD
```

```bash
docker compose up -d

# Le premier démarrage est lent (~1-2 minutes) car Nextcloud
# initialise la base de données
docker compose logs -f nextcloud
# Attendre "Apache started"
```

1. Accéder à `https://cloud.home` (ou `http://IP:8080`)
2. Se connecter avec admin / le mot de passe choisi
3. Installer les apps recommandées (Calendar, Contacts, Notes, Talk)

**Optimisations post-installation :**
```bash
# Configurer le cron en arrière-plan (recommandé)
docker exec -u www-data nextcloud php occ background:cron

# Ajouter un cron job sur le host
echo "*/5 * * * * docker exec -u www-data nextcloud php -f /var/www/html/cron.php" | sudo tee /etc/cron.d/nextcloud
```

### 6.2 — Duplicati (backups)

```bash
cd /opt/stacks/duplicati

docker compose up -d
```

1. Accéder à `https://backup.home` (ou `http://IP:8200`)
2. Configurer un mot de passe d'accès à l'interface
3. Créer les jobs de backup :

**Backup recommandé — Stacks Docker :**
- Source : `/source/stacks` (monté en read-only)
- Destination : disque externe, NAS, ou cloud (Backblaze B2, S3, etc.)
- Fréquence : quotidien à 3h du matin
- Rétention : 7 quotidiens, 4 hebdomadaires, 3 mensuels
- Chiffrement : AES-256 (activer + noter le mot de passe !)

**Backup recommandé — Volumes Docker :**
- Source : `/source/docker-volumes`
- Même destination + fréquence
- Inclure surtout : postgres, nextcloud, gitea

> **CRITIQUE** : Sans backups, une panne disque = perte totale.
> Configurer Duplicati est une priorité absolue.

### 6.3 — Termix (terminal SSH web)

```bash
cd /opt/stacks/termix

docker compose up -d
```

1. Accéder à `https://termix.home` (ou `http://IP:3006`)
2. Configurer la connexion SSH vers localhost ou d'autres machines

### 6.4 — NetBird (VPN mesh)

NetBird connecte ton Mac et le serveur dans un réseau privé.

> **Note** : NetBird s'installe directement sur le host (pas en Docker).
> Avec Dokploy, ce sont les 2 seuls outils serveur non-containerisés.
> NetBird a besoin du réseau host (VPN), Dokploy utilise Docker Swarm.

**Sur le serveur :**
```bash
curl -fsSL https://pkgs.netbird.io/install.sh | sudo sh
sudo netbird up
# → Un lien d'authentification s'affiche, l'ouvrir dans le navigateur
```

**Sur le Mac :**
```bash
brew install netbird
sudo netbird up
# → Même procédure d'authentification
```

**Configurer le DNS privé :**
1. Dans le dashboard NetBird (app.netbird.io) → DNS
2. Ajouter une zone DNS : `home`
3. Pointer `*.home` → IP NetBird du serveur

> **Après cette étape**, depuis ton Mac, `gitea.home`, `n8n.home`, etc.
> résolvent vers le serveur via le VPN. Plus besoin d'IP !

### Checkpoint Phase 4

```
✅ Nextcloud opérationnel (cloud.home)
✅ Duplicati sauvegarde quotidiennement (backup.home)
✅ Termix donne un terminal web (termix.home)
✅ NetBird connecte Mac ↔ Serveur (VPN mesh + DNS *.home)
```

---

## 7. Phase 5 — Tests & CI

> **Objectif** : Tests automatisés, pipeline CI/CD
> **Durée estimée** : 15-30 minutes

### 7.1 — Playwright

```bash
cd /opt/stacks/playwright

docker compose up -d
```

Playwright reste en veille (`sleep infinity`). Il est déclenché par n8n ou Gitea CI.

**Exemple : lancer un test manuellement**
```bash
# Copier tes tests dans le volume
docker cp mes-tests/ playwright:/tests/

# Exécuter
docker exec playwright npx playwright test
```

**Intégration avec Gitea CI (Actions) :**
Dans ton repo Gitea, créer `.gitea/workflows/test.yml` :
```yaml
name: Tests E2E
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Playwright
        run: |
          npx playwright install --with-deps
          npx playwright test
```

### Checkpoint Phase 5

```
✅ Playwright prêt pour les tests E2E
✅ Pipeline CI/CD configurable via Gitea Actions
```

---

## 8. Phase Mac — IA & Knowledge

> **Objectif** : Environnement IA local sur le MacBook
> **Prérequis** : Docker Desktop installé sur Mac

### Installation rapide (recommande)

```bash
cd stack-configs-16g
chmod +x setup-mac.sh
./setup-mac.sh
```

Le script `setup-mac.sh` fait tout automatiquement :
- Installe les outils natifs (Ollama, KeePassXC, LocalSend, NetBird)
- Telecharge les modeles Ollama (llama3.2, nomic-embed-text, codellama)
- Deploie les 6 stacks Docker dans l'ordre (Chroma, Mem0, LobeChat, etc.)
- 100% local via Ollama — aucune cle API requise

Le detail ci-dessous est utile pour le debug ou une installation manuelle.

### 8.1 — Outils natifs (installes par setup-mac.sh)

- **Ollama** (LLM local, tourne nativement sur Apple Silicon)
- **KeePassXC** (gestionnaire mots de passe)
- **LocalSend** (transfert fichiers local)
- **NetBird** (VPN mesh vers le serveur)
- Modèles Ollama : llama3.2:3b, nomic-embed-text, codellama:7b

### 8.2 — Chroma (base vectorielle)

```bash
cd stack-configs/mac/chroma

docker compose up -d

# Vérifier
curl http://localhost:8000/api/v1/heartbeat
# → {"nanosecond heartbeat": ...}
```

> **Chroma** stocke les embeddings (vecteurs) pour la recherche sémantique.
> Utilisé par Mem0.

### 8.3 — Mem0 (mémoire IA persistante)

```bash
cd stack-configs/mac/mem0

# Vérifier que config.yaml pointe vers les bons hosts
cat config.yaml

docker compose up -d

# Tester
curl http://localhost:8050/health
```

> **Mem0** donne une mémoire persistante à tes outils IA.
> LobeChat, Paperclip peuvent tous y stocker/récupérer du contexte.

### 8.4 — LobeChat

```bash
cd stack-configs/mac/lobechat
docker compose up -d
```

1. Accéder à `http://localhost:3210`
2. LobeChat détecte automatiquement Ollama local
3. Interface chat avec accès à tous tes modèles locaux

### 8.5 — Paperclip (orchestrateur IA)

```bash
cd stack-configs/mac/paperclip
docker compose up -d
```

1. Accéder à `http://localhost:8060`
2. Paperclip coordonne les agents IA (Ollama + Mem0)

### Checkpoint Phase Mac

```
✅ Ollama tourne nativement (Apple Silicon, ~3x plus rapide que Docker)
✅ Chroma stocke les embeddings (localhost:8000)
✅ Mem0 gère la mémoire IA (localhost:8050)
✅ SiYuan Note knowledge base (localhost:6806)
✅ LobeChat interface les modèles (localhost:3210)
✅ Paperclip orchestre les agents (localhost:8060)
✅ 100% local — aucune clé API cloud
```

---

## 9. Connexions inter-services

Une fois tout déployé, voici les connexions clés à configurer dans n8n.

### 9.1 — Workflows n8n essentiels

Accéder à `https://n8n.home` et créer ces workflows :

**Workflow 1 : Gitea → Dokploy (auto-deploy)**
```
Trigger: Gitea Webhook (push sur main)
  → HTTP Request vers Dokploy API
  → ntfy notification (succès/échec)
```

**Workflow 2 : Monitoring → Alertes**
```
Trigger: Webhook depuis Uptime Kuma
  → ntfy notification avec détails du service down
  → Optionnel : Twenty CRM → créer une tâche de résolution
```

**Workflow 3 : Gitea → Playwright (tests)**
```
Trigger: Gitea Webhook (push)
  → SSH/exec dans container Playwright
  → Résultats → ntfy notification
```

**Workflow 4 : Cal.com → Twenty CRM**
```
Trigger: Cal.com Webhook (nouveau RDV)
  → Twenty API → créer/mettre à jour le contact
  → ntfy notification
```

### 9.2 — Webhooks à configurer

| Source | Destination | URL webhook |
|--------|-------------|-------------|
| Gitea | n8n | `http://n8n:5678/webhook/gitea-push` |
| Cal.com | n8n | `http://n8n:5678/webhook/calcom-event` |
| Uptime Kuma | ntfy | `http://ntfy:80/alerts` |
| Uptime Kuma | n8n | `http://n8n:5678/webhook/uptime-alert` |

> Les URLs utilisent les noms de containers (réseau Docker interne).

---

## 10. Vérifications finales

### Checklist complète

```bash
# Sur le serveur — vérifier que tous les containers tournent
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Services à vérifier :**

| Service | URL | Test |
|---------|-----|------|
| PostgreSQL | — | `docker exec postgres pg_isready` |
| Redis | — | `docker exec redis redis-cli ping` |
| Caddy | https://IP | Certificats valides |
| CrowdSec | — | `docker exec crowdsec cscli metrics` |
| Authelia | https://auth.home | Page de login |
| Uptime Kuma | https://monitor.home | Dashboard vert |
| Oak | https://dash.home | Métriques système |
| Dockge | https://docker.home | Liste des stacks |
| Gitea | https://gitea.home | Push/pull test |
| n8n | https://n8n.home | Workflow test |
| ntfy | https://notify.home | Envoyer une notif test |
| Twenty | https://crm.home | Créer un contact |
| Cal.com | https://cal.home | Créer un créneau |
| Umami | https://stats.home | Dashboard analytics |
| BillionMail | https://mail.home | Envoyer un email test |
| Nextcloud | https://cloud.home | Upload un fichier |
| Duplicati | https://backup.home | Job de backup configuré |
| Termix | https://termix.home | Connexion SSH |

**Test de notification bout-en-bout :**
```bash
# Depuis le serveur
curl -d "Test notification de bout en bout" http://localhost:8085/alerts
# → Doit arriver sur ton téléphone via ntfy
```

**Test SSO Authelia :**
1. Ouvrir `https://gitea.home` en navigation privée
2. → Doit rediriger vers `https://auth.home`
3. Se connecter → redirect automatique vers Gitea

---

## 11. Maintenance courante

### Mises à jour des containers

```bash
# Via Dockge (recommandé) : cliquer "Update" sur chaque stack

# Ou en CLI :
cd /opt/stacks/NOM_STACK
docker compose pull
docker compose up -d
```

### Backups manuels PostgreSQL

```bash
# Dump complet de toutes les bases
docker exec postgres pg_dumpall -U admin > backup_$(date +%Y%m%d).sql

# Dump d'une base spécifique
docker exec postgres pg_dump -U admin gitea_db > gitea_$(date +%Y%m%d).sql
```

### Logs

```bash
# Voir les logs d'un service
docker logs -f NOM_CONTAINER --tail 100

# Logs CrowdSec (attaques détectées)
docker exec crowdsec cscli alerts list

# Logs Caddy (accès web)
docker exec caddy cat /data/access.log | tail -20
```

### Espace disque

```bash
# Voir l'espace utilisé par Docker
docker system df

# Nettoyer les images/containers inutilisés
docker system prune -a --volumes
# ⚠️ Attention : supprime les volumes non utilisés !
# Préférer sans --volumes pour être safe :
docker system prune -a
```

### Redémarrage complet (après reboot serveur)

Tous les services ont `restart: unless-stopped`, ils redémarrent automatiquement.
Si besoin de tout relancer manuellement :

```bash
# Ordre important (dépendances)
cd /opt/stacks/core && docker compose up -d
cd /opt/stacks/network && docker compose up -d
cd /opt/stacks/auth && docker compose up -d
# ... puis le reste dans n'importe quel ordre
```

---

## 12. Dépannage

### Un container ne démarre pas

```bash
# Voir les logs d'erreur
docker logs NOM_CONTAINER

# Causes fréquentes :
# - Variable d'environnement manquante → vérifier .env
# - Port déjà utilisé → vérifier avec: ss -tlnp | grep PORT
# - Base de données pas prête → attendre que postgres soit healthy
# - Permissions fichier → vérifier les volumes montés
```

### PostgreSQL — connexion refusée

```bash
# Vérifier que postgres tourne
docker exec postgres pg_isready

# Vérifier qu'une base existe
docker exec postgres psql -U admin -c "\l" | grep NOM_DB

# Recréer une base manuellement si le script init n'a pas tourné
docker exec postgres psql -U admin -c "CREATE DATABASE ma_db;"
```

### Caddy — erreur 502 Bad Gateway

Signifie que Caddy ne peut pas joindre le service en amont.

```bash
# Vérifier que le service cible tourne
docker ps | grep NOM_SERVICE

# Vérifier qu'il est sur stack-network
docker network inspect stack-network | grep NOM_SERVICE

# Tester la connexion depuis Caddy
docker exec caddy wget -qO- http://NOM_SERVICE:PORT/
```

### Authelia — boucle de redirect

```bash
# Vérifier la config Authelia
docker logs authelia

# Causes fréquentes :
# - Cookie domain incorrect dans configuration.yml
# - NEXTAUTH_URL / base URL mal configuré côté service
# - Caddy forward_auth mal configuré
```

### Espace disque plein

```bash
# Identifier les plus gros volumes
docker system df -v

# Nettoyer les logs Docker (peuvent être énormes)
sudo truncate -s 0 /var/lib/docker/containers/CONTAINER_ID/CONTAINER_ID-json.log

# Limiter la taille des logs (ajouter dans /etc/docker/daemon.json) :
# {
#   "log-driver": "json-file",
#   "log-opts": { "max-size": "10m", "max-file": "3" }
# }
# Puis : sudo systemctl restart docker
```

---

## Récapitulatif des ports

| Port | Service | Accès |
|------|---------|-------|
| 25 | BillionMail SMTP | Externe |
| 80 | Caddy HTTP | Externe → redirect HTTPS |
| 443 | Caddy HTTPS | Externe |
| 587 | BillionMail SMTP submission | Externe |
| 993 | BillionMail IMAPS | Externe |
| 2222 | Gitea SSH | Externe |
| 3000 | Gitea Web | Interne (via Caddy) |
| 3001 | Uptime Kuma | Interne (via Caddy) |
| 3008 | Firecrawl | Interne (via Caddy) |
| 3002 | Twenty CRM | Interne (via Caddy) |
| 3003 | Cal.com | Interne (via Caddy) |
| 3004 | Oak | Interne (via Caddy) |
| 3005 | Umami | Interne (via Caddy) |
| 3006 | Termix | Interne (via Caddy) |
| 5001 | Dockge | Interne (via Caddy) |
| 5432 | PostgreSQL | Interne uniquement |
| 5678 | n8n | Interne (via Caddy) |
| 6379 | Redis | Interne uniquement |
| 8025 | BillionMail Web | Interne (via Caddy) |
| 8080 | Nextcloud | Interne (via Caddy) |
| 8085 | ntfy | Interne (via Caddy) |
| 8200 | Duplicati | Interne (via Caddy) |
| 9091 | Authelia | Interne (via Caddy) |

---

## Récapitulatif des secrets

> **Note** : `setup.sh` génère tous les secrets automatiquement et les sauvegarde dans `secrets.env`.
> La section ci-dessous est uniquement pour référence en cas d'installation manuelle.
>
> ```bash
> # Générer un secret :
> openssl rand -base64 32
> ```
