#!/bin/bash
# ============================================
# SETUP MASTER — Déploiement complet de la stack
# ============================================
# Usage : chmod +x setup.sh && sudo ./setup.sh
#
# Ce script :
#   1. Vérifie les prérequis (Docker, etc.)
#   2. Génère tous les secrets automatiquement
#   3. Crée les .env de chaque service
#   4. Déploie tout dans le bon ordre (5 phases)
#   5. Installe les outils host (Dokploy, NetBird)
#   6. Sauvegarde tous les secrets dans secrets.env
#
# Temps estimé : ~5-10 minutes
# ============================================

set -euo pipefail

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

STACK_DIR="$(cd "$(dirname "$0")/serveur" && pwd)"
SECRETS_FILE="$(dirname "$0")/secrets.env"

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
info() { echo -e "${BLUE}[>>]${NC} $1"; }
fail() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# ============================================
# FONCTIONS UTILITAIRES
# ============================================

secret()  { openssl rand -base64 "$1" | tr -d '\n'; }
secret32() { secret 32; }
secret64() { secret 64; }
hex32()   { openssl rand -hex 32 | tr -d '\n'; }

wait_healthy() {
    local container="$1"
    local max_wait="${2:-60}"
    local elapsed=0
    info "Attente que $container soit healthy..."
    while [ $elapsed -lt $max_wait ]; do
        status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "not_found")
        if [ "$status" = "healthy" ]; then
            log "$container est healthy"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    fail "$container n'est pas healthy apres ${max_wait}s"
}

deploy_stack() {
    local name="$1"
    local dir="$STACK_DIR/$name"
    info "Deploiement de $name..."
    (cd "$dir" && docker compose up -d)
    log "$name demarre"
}

# ============================================
# VERIFICATION PREREQUIS
# ============================================

echo ""
echo "========================================"
echo "  SETUP STACK SELF-HOSTED"
echo "========================================"
echo ""

# Vérifier Docker
command -v docker &>/dev/null || fail "Docker non installe. Lancer : curl -fsSL https://get.docker.com | sudo sh"
command -v docker compose version &>/dev/null 2>&1 || docker compose version &>/dev/null || fail "Docker Compose non installe"
log "Docker + Compose detectes"

# Vérifier qu'on est root ou docker group
if ! docker ps &>/dev/null; then
    fail "Impossible de lancer docker. Verifier les permissions (sudo usermod -aG docker \$USER)"
fi

# ============================================
# PHASE 0 — GENERATION DES SECRETS
# ============================================

echo ""
info "=== PHASE 0 : Generation des secrets ==="

# Mots de passe partagés (core)
POSTGRES_ADMIN_PASSWORD=$(secret32)
REDIS_PASSWORD=$(secret32)

# Mots de passe DB par service
GITEA_DB_PASSWORD=$(secret32)
TWENTY_DB_PASSWORD=$(secret32)
CALCOM_DB_PASSWORD=$(secret32)
UMAMI_DB_PASSWORD=$(secret32)
N8N_DB_PASSWORD=$(secret32)
AUTHELIA_DB_PASSWORD=$(secret32)
NEXTCLOUD_DB_PASSWORD=$(secret32)

# Secrets applicatifs
AUTHELIA_JWT_SECRET=$(secret64)
AUTHELIA_SESSION_SECRET=$(secret64)
AUTHELIA_STORAGE_ENCRYPTION_KEY=$(secret64)

GITEA_SECRET_KEY=$(secret32)
GITEA_INTERNAL_TOKEN=$(secret64)

N8N_ENCRYPTION_KEY=$(secret32)

TWENTY_APP_SECRET=$(secret32)

CALCOM_NEXTAUTH_SECRET=$(secret32)
CALCOM_ENCRYPTION_KEY=$(hex32)

UMAMI_APP_SECRET=$(secret32)

NEXTCLOUD_ADMIN_PASSWORD=$(secret 16)
BILLIONMAIL_ADMIN_PASSWORD=$(secret 16)

FIRECRAWL_BULL_KEY=$(secret32)

# Mot de passe SMTP (placeholder — sera mis a jour apres config BillionMail)
SMTP_PASSWORD="CONFIGURE_APRES_BILLIONMAIL"

log "Tous les secrets generes"

# Sauvegarder les secrets
cat > "$SECRETS_FILE" <<EOF
# ============================================
# SECRETS GENERES — $(date '+%Y-%m-%d %H:%M:%S')
# SAUVEGARDER CE FICHIER DANS KEEPASSXC !
# SUPPRIMER DE CE SERVEUR APRES SAUVEGARDE !
# ============================================

# --- Core ---
POSTGRES_ADMIN_PASSWORD=$POSTGRES_ADMIN_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD

# --- DB passwords ---
GITEA_DB_PASSWORD=$GITEA_DB_PASSWORD
TWENTY_DB_PASSWORD=$TWENTY_DB_PASSWORD
CALCOM_DB_PASSWORD=$CALCOM_DB_PASSWORD
UMAMI_DB_PASSWORD=$UMAMI_DB_PASSWORD
N8N_DB_PASSWORD=$N8N_DB_PASSWORD
AUTHELIA_DB_PASSWORD=$AUTHELIA_DB_PASSWORD
NEXTCLOUD_DB_PASSWORD=$NEXTCLOUD_DB_PASSWORD

# --- Authelia ---
AUTHELIA_JWT_SECRET=$AUTHELIA_JWT_SECRET
AUTHELIA_SESSION_SECRET=$AUTHELIA_SESSION_SECRET
AUTHELIA_STORAGE_ENCRYPTION_KEY=$AUTHELIA_STORAGE_ENCRYPTION_KEY

# --- Gitea ---
GITEA_SECRET_KEY=$GITEA_SECRET_KEY
GITEA_INTERNAL_TOKEN=$GITEA_INTERNAL_TOKEN

# --- n8n ---
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY

# --- Twenty ---
TWENTY_APP_SECRET=$TWENTY_APP_SECRET

# --- Cal.com ---
CALCOM_NEXTAUTH_SECRET=$CALCOM_NEXTAUTH_SECRET
CALCOM_ENCRYPTION_KEY=$CALCOM_ENCRYPTION_KEY

# --- Umami ---
UMAMI_APP_SECRET=$UMAMI_APP_SECRET

# --- Nextcloud ---
NEXTCLOUD_ADMIN_PASSWORD=$NEXTCLOUD_ADMIN_PASSWORD

# --- BillionMail ---
BILLIONMAIL_ADMIN_PASSWORD=$BILLIONMAIL_ADMIN_PASSWORD

# --- Firecrawl ---
FIRECRAWL_BULL_KEY=$FIRECRAWL_BULL_KEY

# --- SMTP (a configurer apres BillionMail) ---
SMTP_PASSWORD=$SMTP_PASSWORD
EOF
chmod 600 "$SECRETS_FILE"
log "Secrets sauvegardes dans secrets.env (chmod 600)"

# ============================================
# PHASE 0 — CREATION DES .ENV
# ============================================

info "=== Creation des fichiers .env ==="

# Core
cat > "$STACK_DIR/core/.env" <<EOF
POSTGRES_ADMIN_USER=admin
POSTGRES_ADMIN_PASSWORD=$POSTGRES_ADMIN_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
GITEA_DB_PASSWORD=$GITEA_DB_PASSWORD
TWENTY_DB_PASSWORD=$TWENTY_DB_PASSWORD
CALCOM_DB_PASSWORD=$CALCOM_DB_PASSWORD
UMAMI_DB_PASSWORD=$UMAMI_DB_PASSWORD
N8N_DB_PASSWORD=$N8N_DB_PASSWORD
AUTHELIA_DB_PASSWORD=$AUTHELIA_DB_PASSWORD
NEXTCLOUD_DB_PASSWORD=$NEXTCLOUD_DB_PASSWORD
EOF

# Network (CrowdSec bouncer key sera genere apres)
cat > "$STACK_DIR/network/.env" <<EOF
CROWDSEC_BOUNCER_KEY=PLACEHOLDER_GENERE_APRES_LANCEMENT
EOF

# Auth
cat > "$STACK_DIR/auth/.env" <<EOF
AUTHELIA_JWT_SECRET=$AUTHELIA_JWT_SECRET
AUTHELIA_SESSION_SECRET=$AUTHELIA_SESSION_SECRET
AUTHELIA_STORAGE_ENCRYPTION_KEY=$AUTHELIA_STORAGE_ENCRYPTION_KEY
AUTHELIA_DB_PASSWORD=$AUTHELIA_DB_PASSWORD
SMTP_PASSWORD=$SMTP_PASSWORD
EOF

# Gitea
cat > "$STACK_DIR/gitea/.env" <<EOF
GITEA_DB_PASSWORD=$GITEA_DB_PASSWORD
GITEA_SECRET_KEY=$GITEA_SECRET_KEY
GITEA_INTERNAL_TOKEN=$GITEA_INTERNAL_TOKEN
SMTP_PASSWORD=$SMTP_PASSWORD
EOF

# n8n
cat > "$STACK_DIR/n8n/.env" <<EOF
N8N_DB_PASSWORD=$N8N_DB_PASSWORD
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
EOF

# Twenty
cat > "$STACK_DIR/twenty/.env" <<EOF
TWENTY_DB_PASSWORD=$TWENTY_DB_PASSWORD
TWENTY_APP_SECRET=$TWENTY_APP_SECRET
REDIS_PASSWORD=$REDIS_PASSWORD
EOF

# Cal.com
cat > "$STACK_DIR/calcom/.env" <<EOF
CALCOM_DB_PASSWORD=$CALCOM_DB_PASSWORD
CALCOM_NEXTAUTH_SECRET=$CALCOM_NEXTAUTH_SECRET
CALCOM_ENCRYPTION_KEY=$CALCOM_ENCRYPTION_KEY
SMTP_PASSWORD=$SMTP_PASSWORD
EOF

# Umami
cat > "$STACK_DIR/umami/.env" <<EOF
UMAMI_DB_PASSWORD=$UMAMI_DB_PASSWORD
UMAMI_APP_SECRET=$UMAMI_APP_SECRET
EOF

# Nextcloud
cat > "$STACK_DIR/nextcloud/.env" <<EOF
NEXTCLOUD_DB_PASSWORD=$NEXTCLOUD_DB_PASSWORD
NEXTCLOUD_ADMIN_PASSWORD=$NEXTCLOUD_ADMIN_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
SMTP_PASSWORD=$SMTP_PASSWORD
EOF

# BillionMail
cat > "$STACK_DIR/billionmail/.env" <<EOF
BILLIONMAIL_ADMIN_PASSWORD=$BILLIONMAIL_ADMIN_PASSWORD
EOF

# Firecrawl
cat > "$STACK_DIR/firecrawl/.env" <<EOF
REDIS_PASSWORD=$REDIS_PASSWORD
FIRECRAWL_BULL_KEY=$FIRECRAWL_BULL_KEY
EOF

log "Tous les .env crees"

# ============================================
# PHASE 0 — RESEAU + CORE
# ============================================

echo ""
info "=== PHASE 0 : Fondations (reseau + PostgreSQL + Redis) ==="

# Créer le réseau Docker partagé
docker network inspect stack-network &>/dev/null 2>&1 || docker network create stack-network
log "Reseau stack-network pret"

# Déployer Core
deploy_stack "core"
wait_healthy "postgres"
wait_healthy "redis"

# Vérifier les bases créées
DB_COUNT=$(docker exec postgres psql -U admin -t -c "SELECT count(*) FROM pg_database WHERE datname IN ('gitea_db','twenty_db','calcom_db','umami_db','n8n_db','authelia_db','nextcloud_db');" | tr -d ' ')
if [ "$DB_COUNT" -eq 7 ]; then
    log "7 bases de donnees creees"
else
    warn "Seulement $DB_COUNT/7 bases detectees — verifier les logs de postgres"
fi

# Déployer Network (Caddy + CrowdSec)
deploy_stack "network"
sleep 5

# Générer la clé bouncer CrowdSec
BOUNCER_KEY=$(docker exec crowdsec cscli bouncers add caddy-bouncer -o raw 2>/dev/null || echo "")
if [ -n "$BOUNCER_KEY" ]; then
    # Mettre à jour le .env avec la vraie clé
    cat > "$STACK_DIR/network/.env" <<EOF
CROWDSEC_BOUNCER_KEY=$BOUNCER_KEY
EOF
    # Redémarrer Caddy avec la bonne clé
    (cd "$STACK_DIR/network" && docker compose restart caddy)
    log "CrowdSec bouncer configure"
else
    warn "CrowdSec bouncer non configure — a faire manuellement"
fi

# ============================================
# PHASE 1 — SECURITE & MONITORING
# ============================================

echo ""
info "=== PHASE 1 : Securite & monitoring ==="

deploy_stack "auth"
deploy_stack "monitoring"
deploy_stack "dockge"

log "Phase 1 terminee (Authelia, Uptime Kuma, Oak, Dockge)"

# ============================================
# PHASE 2 — DEVOPS
# ============================================

echo ""
info "=== PHASE 2 : DevOps ==="

deploy_stack "gitea"
deploy_stack "n8n"
deploy_stack "ntfy"
deploy_stack "firecrawl"

# Dokploy (installé sur le host, pas Docker Compose)
info "Installation de Dokploy (host)..."
if command -v dokploy &>/dev/null || docker service ls 2>/dev/null | grep -q dokploy; then
    log "Dokploy deja installe"
else
    curl -sSL https://dokploy.com/install.sh | sh && log "Dokploy installe" || warn "Dokploy : echec installation (non bloquant)"
fi

log "Phase 2 terminee (Gitea, n8n, ntfy, Firecrawl, Dokploy)"

# ============================================
# PHASE 3 — APPS METIER
# ============================================

echo ""
info "=== PHASE 3 : Apps metier ==="

deploy_stack "twenty"
deploy_stack "calcom"
deploy_stack "umami"
deploy_stack "billionmail"

log "Phase 3 terminee (Twenty, Cal.com, Umami, BillionMail)"

# ============================================
# PHASE 4 — CLOUD & SERVICES
# ============================================

echo ""
info "=== PHASE 4 : Cloud & services ==="

deploy_stack "nextcloud"
deploy_stack "duplicati"
deploy_stack "termix"

# NetBird (installé sur le host)
info "Installation de NetBird (host)..."
if command -v netbird &>/dev/null; then
    log "NetBird deja installe"
else
    curl -fsSL https://pkgs.netbird.io/install.sh | sh && log "NetBird installe" || warn "NetBird : echec installation (non bloquant)"
fi

log "Phase 4 terminee (Nextcloud, Duplicati, Termix, NetBird)"

# ============================================
# PHASE 5 — TESTS
# ============================================

echo ""
info "=== PHASE 5 : Tests ==="

deploy_stack "playwright"

log "Phase 5 terminee (Playwright)"

# ============================================
# VERIFICATION FINALE
# ============================================

echo ""
info "=== Verification finale ==="
echo ""

# Lister tous les containers
docker ps --format "table {{.Names}}\t{{.Status}}" | sort

echo ""
echo "========================================"
echo -e "  ${GREEN}INSTALLATION TERMINEE${NC}"
echo "========================================"
echo ""
echo "Prochaines etapes :"
echo ""
echo "  1. SAUVEGARDER secrets.env dans KeePassXC"
echo "     puis supprimer : rm secrets.env"
echo ""
echo "  2. Configurer Authelia (premier utilisateur) :"
echo "     nano $STACK_DIR/auth/users_database.yml"
echo ""
echo "  3. Configurer NetBird :"
echo "     sudo netbird up"
echo ""
echo "  4. Acceder aux services :"
echo "     auth.home     — SSO (Authelia)"
echo "     gitea.home    — Git"
echo "     deploy.home   — Deploiement (Dokploy)"
echo "     scrape.home   — Web scraper (Firecrawl)"
echo "     crm.home      — CRM (Twenty)"
echo "     n8n.home      — Automatisation"
echo "     cal.home      — Planning"
echo "     stats.home    — Analytics (Umami)"
echo "     mail.home     — Email (BillionMail)"
echo "     cloud.home    — Cloud (Nextcloud)"
echo "     monitor.home  — Monitoring"
echo "     dash.home     — Dashboard systeme"
echo "     docker.home   — Gestion Docker (Dockge)"
echo "     backup.home   — Backups (Duplicati)"
echo "     notify.home   — Notifications (ntfy)"
echo "     termix.home   — Terminal SSH web"
echo ""
echo "  5. SMTP : configurer BillionMail (mail.home) puis"
echo "     mettre a jour SMTP_PASSWORD dans les .env de :"
echo "     auth, gitea, calcom, nextcloud"
echo ""
