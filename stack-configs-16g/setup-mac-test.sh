#!/bin/bash
# ============================================
# SETUP MAC TEST — Validation sur MacBook M1 16 Go
# ============================================
# Usage : chmod +x setup-mac-test.sh && ./setup-mac-test.sh
#
# Version LEGERE pour tester que tout s'installe et se connecte.
# - Modele Ollama minimal : tinyllama (~640 Mo)
# - Pas d'apps GUI (Obsidian, KeePassXC, etc.)
# - Memes stacks Docker que la version finale
#
# Cleanup apres test :
#   ./setup-mac-test.sh --cleanup
# ============================================

set -euo pipefail

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

# ============================================
# MODE CLEANUP
# ============================================

if [ "${1:-}" = "--cleanup" ]; then
    echo ""
    info "=== Cleanup : arret de tous les containers ==="
    for stack in chroma mem0 lobechat siyuan paperclip; do
        (cd "$MAC_DIR/$stack" && docker compose down 2>/dev/null) && log "$stack arrete" || true
    done

    # Restore config.yaml original si backup existe
    if [ -f "$MAC_DIR/mem0/config.yaml.bak" ]; then
        mv "$MAC_DIR/mem0/config.yaml.bak" "$MAC_DIR/mem0/config.yaml"
        log "mem0/config.yaml restaure"
    fi

    # Supprime le repo Paperclip clone
    if [ -d "$MAC_DIR/paperclip/repo" ]; then
        rm -rf "$MAC_DIR/paperclip/repo"
        log "paperclip/repo supprime"
    fi

    info "Suppression des modeles Ollama de test..."
    ollama rm tinyllama 2>/dev/null && log "tinyllama supprime" || true
    ollama rm nomic-embed-text 2>/dev/null && log "nomic-embed-text supprime" || true

    echo ""
    log "Cleanup termine. Ton Mac est propre."
    exit 0
fi

# ============================================
# INSTALLATION TEST
# ============================================

echo ""
echo "========================================"
echo "  SETUP MAC TEST — M1 16 Go (leger)"
echo "========================================"
echo ""

# Prerequis
if ! command -v docker &>/dev/null; then
    fail "Docker Desktop non installe."
fi
if ! docker ps &>/dev/null; then
    fail "Docker Desktop n'est pas demarre."
fi
log "Docker Desktop detecte"

# ============================================
# ETAPE 1 — OLLAMA + MODELE MINIMAL
# ============================================

info "=== Etape 1 : Ollama + modele minimal ==="

# Installer Ollama si absent
if ! command -v brew &>/dev/null; then
    fail "Homebrew non installe. Lancer : /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
fi

if ! command -v ollama &>/dev/null; then
    info "Installation d'Ollama..."
    brew install ollama && log "Ollama installe" || fail "Echec installation Ollama"
else
    log "Ollama deja installe"
fi

# Démarrer Ollama
if ! curl -s http://localhost:11434/api/tags &>/dev/null; then
    info "Demarrage d'Ollama..."
    ollama serve &>/dev/null &
    sleep 3
    log "Ollama demarre"
else
    log "Ollama deja en cours"
fi

# Modeles minimaux (~900 Mo total au lieu de ~7 Go)
pull_model() {
    local model="$1"
    if ollama list 2>/dev/null | grep -q "$model"; then
        log "Modele $model deja present"
    else
        info "Telechargement de $model..."
        ollama pull "$model" && log "$model telecharge" || warn "$model : echec"
    fi
}

pull_model "tinyllama"          # ~640 Mo — LLM minimal
pull_model "nomic-embed-text"   # ~270 Mo — embeddings (requis par Chroma/Mem0)

log "Modeles Ollama prets (~900 Mo total)"

# ============================================
# ETAPE 2 — PREPARATION SOURCES
# ============================================

echo ""
info "=== Etape 2 : Preparation des sources ==="

# Paperclip n'a pas d'image publique — clone depuis GitHub
if [ ! -d "$MAC_DIR/paperclip/repo" ]; then
    info "Clone de Paperclip depuis GitHub..."
    git clone --depth 1 https://github.com/paperclipai/paperclip.git "$MAC_DIR/paperclip/repo" \
        && log "Paperclip clone" \
        || warn "Paperclip : echec du clone (skip)"
else
    log "Paperclip deja clone"
fi

# Fix upstream : lockfile desynchronise (cross-env manquant)
if [ -f "$MAC_DIR/paperclip/repo/Dockerfile" ]; then
    sed -i '' 's/pnpm install --frozen-lockfile/pnpm install --no-frozen-lockfile/' "$MAC_DIR/paperclip/repo/Dockerfile"
    log "Paperclip Dockerfile patche (--no-frozen-lockfile)"
fi

# ============================================
# ETAPE 3 — DEPLOIEMENT DES STACKS
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

# Chroma d'abord
deploy_stack "chroma"

info "Attente que Chroma soit pret..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:8000/api/v2/heartbeat &>/dev/null; then
        log "Chroma pret"
        break
    fi
    [ "$i" -eq 30 ] && warn "Chroma pas pret apres 60s — on continue"
    sleep 2
done

# Mem0 avec config test (tinyllama au lieu de llama3.2:3b)
info "Deploiement de mem0 (config test : tinyllama)..."
cp "$MAC_DIR/mem0/config.yaml" "$MAC_DIR/mem0/config.yaml.bak"
cp "$MAC_DIR/mem0/config-test.yaml" "$MAC_DIR/mem0/config.yaml"
(cd "$MAC_DIR/mem0" && docker compose up -d --build)
log "mem0 demarre (tinyllama)"

# Le reste
deploy_stack "lobechat"
deploy_stack "siyuan"

# Bootstrap SiYuan (notebooks, dashboards, daily notes)
info "Bootstrap de SiYuan..."
bash "$MAC_DIR/siyuan/bootstrap.sh" && log "SiYuan bootstrap termine" || warn "SiYuan bootstrap echoue (non bloquant)"

# Paperclip — build from source (peut etre long la premiere fois)
if [ -d "$MAC_DIR/paperclip/repo" ]; then
    info "Deploiement de paperclip (build from source)..."
    (cd "$MAC_DIR/paperclip" && docker compose up -d --build)
    log "paperclip demarre"
else
    warn "Paperclip skip (repo non clone)"
fi

# ============================================
# VERIFICATION
# ============================================

echo ""
info "=== Verification ==="
echo ""

sleep 5

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sort

echo ""
echo "--- Tests de connectivite ---"
echo ""

test_service() {
    local name="$1"
    local url="$2"
    if curl -sf "$url" &>/dev/null; then
        log "$name repond"
    else
        warn "$name ne repond pas ($url)"
    fi
}

test_service "Ollama" "http://localhost:11434/api/tags"
test_service "Chroma" "http://localhost:8000/api/v2/heartbeat"
test_service "LobeChat" "http://localhost:3210"
test_service "Mem0" "http://localhost:8050/health"
test_service "SiYuan" "http://localhost:6806"
test_service "Paperclip" "http://localhost:8060"

echo ""
echo "========================================"
echo -e "  ${GREEN}TEST TERMINE${NC}"
echo "========================================"
echo ""
echo "Si tout est vert ci-dessus, la stack Mac fonctionne."
echo ""
echo "Pour tout nettoyer :"
echo "  ./setup-mac-test.sh --cleanup"
echo ""
