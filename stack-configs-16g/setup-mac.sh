#!/bin/bash
# ============================================
# SETUP MAC — Installation complete IA & Knowledge
# ============================================
# Usage : chmod +x setup-mac.sh && ./setup-mac.sh
#
# Ce script :
#   1. Installe les outils natifs (Homebrew, Ollama, apps)
#   2. Telecharge les modeles IA (100% local)
#   3. Deploie toutes les stacks Docker dans l'ordre
#
# Tout tourne en local via Ollama — aucune cle API requise.
# Prerequis : macOS avec Docker Desktop installe
# ============================================

set -euo pipefail

# --- Couleurs ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

MAC_DIR="$(cd "$(dirname "$0")/mac" && pwd)"

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
info() { echo -e "${BLUE}[>>]${NC} $1"; }
fail() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

echo ""
echo "========================================"
echo "  SETUP MAC — IA & Knowledge (100% local)"
echo "========================================"
echo ""

# ============================================
# PREREQUIS
# ============================================

if ! command -v docker &>/dev/null; then
    fail "Docker Desktop non installe. Telecharger : https://www.docker.com/products/docker-desktop/"
fi
if ! docker ps &>/dev/null; then
    fail "Docker Desktop n'est pas demarre. Le lancer d'abord."
fi
log "Docker Desktop detecte"

# ============================================
# ETAPE 1 — OUTILS NATIFS
# ============================================

info "=== Etape 1 : Outils natifs ==="

# Homebrew
if ! command -v brew &>/dev/null; then
    info "Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log "Homebrew installe"
else
    log "Homebrew deja present"
fi

install_brew() {
    local name="$1"
    local type="${2:-formula}"
    if [ "$type" = "cask" ]; then
        if brew list --cask "$name" &>/dev/null; then
            log "$name deja installe"
        else
            info "Installation de $name..."
            brew install --cask "$name" && log "$name installe" || warn "$name : echec (non bloquant)"
        fi
    else
        if brew list "$name" &>/dev/null; then
            log "$name deja installe"
        else
            info "Installation de $name..."
            brew install "$name" && log "$name installe" || warn "$name : echec (non bloquant)"
        fi
    fi
}

# CLI
install_brew ollama
install_brew node
install_brew netbird

# Apps GUI
install_brew obsidian cask
install_brew keepassxc cask
install_brew localsend cask

log "Outils natifs installes"

# ============================================
# ETAPE 2 — MODELES OLLAMA
# ============================================

echo ""
info "=== Etape 2 : Modeles Ollama ==="

# Démarrer Ollama si pas deja en cours
if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
    info "Demarrage d'Ollama..."
    ollama serve &>/dev/null &
    sleep 3
    log "Ollama demarre"
else
    log "Ollama deja en cours"
fi

pull_model() {
    local model="$1"
    if ollama list 2>/dev/null | grep -q "$model"; then
        log "Modele $model deja telecharge"
    else
        info "Telechargement de $model..."
        ollama pull "$model" && log "$model telecharge" || warn "$model : echec telechargement"
    fi
}

pull_model "llama3.2:3b"
pull_model "nomic-embed-text"
pull_model "codellama:7b"

log "Modeles Ollama prets"

# ============================================
# ETAPE 3 — DEPLOIEMENT DES STACKS DOCKER
# ============================================

echo ""
info "=== Etape 3 : Deploiement des stacks Docker ==="

deploy_stack() {
    local name="$1"
    local dir="$MAC_DIR/$name"
    info "Deploiement de $name..."
    (cd "$dir" && docker compose up -d)
    log "$name demarre"
}

# Chroma d'abord (dependance des autres)
deploy_stack "chroma"

info "Attente que Chroma soit pret..."
for i in $(seq 1 15); do
    if curl -sf http://localhost:8000/api/v1/heartbeat &>/dev/null; then
        log "Chroma pret"
        break
    fi
    sleep 2
done

# Mem0 (depend de Chroma + Ollama)
deploy_stack "mem0"

# Le reste (independants)
deploy_stack "lobechat"
deploy_stack "surfsense"
deploy_stack "open-notebook"
deploy_stack "paperclip"

# ============================================
# VERIFICATION
# ============================================

echo ""
info "=== Verification ==="
echo ""

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort

echo ""
echo "========================================"
echo -e "  ${GREEN}SETUP MAC TERMINE${NC}"
echo "========================================"
echo ""
echo "Tout tourne en local via Ollama — aucune cle API."
echo ""
echo "Services :"
echo ""
echo "  localhost:3210   — LobeChat (interface chat IA)"
echo "  localhost:3007   — SurfSense (recherche perso)"
echo "  localhost:8501   — Open Notebook (analyse docs)"
echo "  localhost:8060   — Paperclip (orchestrateur IA)"
echo "  localhost:8000   — Chroma (base vectorielle)"
echo "  localhost:8050   — Mem0 (memoire IA)"
echo "  localhost:11434  — Ollama (LLM local)"
echo ""
echo "Outils natifs :"
echo ""
echo "  ollama           — LLM local (Apple Silicon)"
echo "  Obsidian         — Notes / second brain"
echo "  KeePassXC        — Mots de passe"
echo "  LocalSend        — Transfert fichiers"
echo ""
echo "Prochaines etapes :"
echo "  1. Configurer NetBird : sudo netbird up"
echo "  2. Configurer Obsidian (vault + sync Gitea)"
echo "  3. Ouvrir LobeChat (localhost:3210) — Ollama detecte automatiquement"
echo ""
