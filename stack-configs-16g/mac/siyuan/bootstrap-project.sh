#!/bin/bash
# ============================================
# BOOTSTRAP PROJECT — Initialiser un projet dans les 8 notebooks SiYuan
# ============================================
# Usage : bash bootstrap-project.sh <slug> [paperclip-id] [lead-agent] [description]
# Exemple : bash bootstrap-project.sh saas-app uuid-xxx cto "Application SaaS principale"
#
# Cree la structure /projects/<slug>/ dans chaque notebook avec :
#   - Docs index avec block references vers les conventions globales
#   - Custom attributes (custom-project, custom-type, custom-status)
#   - Hub projet dans global/projects/<slug>/overview
#   - Dashboard projet dans global/projects/<slug>/status
#   - Ligne ajoutee au registre global/projects/registry
#
# Prerequis : bootstrap.sh doit avoir ete execute avant
# ============================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
info() { echo -e "${BLUE}[>>]${NC} $1"; }
fail() { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# --- Arguments ---
PROJECT_SLUG="${1:-}"
PAPERCLIP_ID="${2:-non-configure}"
LEAD_AGENT="${3:-cto}"
DESCRIPTION="${4:-Projet $PROJECT_SLUG}"
TODAY=$(date +%Y-%m-%d)

if [ -z "$PROJECT_SLUG" ]; then
    fail "Usage: bash bootstrap-project.sh <slug> [paperclip-id] [lead-agent] [description]"
fi

# Valider le slug (lowercase, alphanum + tirets)
if ! echo "$PROJECT_SLUG" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$'; then
    fail "Le slug doit etre en minuscules avec tirets (ex: saas-app, mobile-v2)"
fi

BASE="http://localhost:6806"
SIYUAN_AUTH_CODE="${SIYUAN_TOKEN:-paperclip-siyuan-token}"
COOKIE_JAR=$(mktemp /tmp/siyuan-cookies.XXXXXX)
trap "rm -f $COOKIE_JAR" EXIT
FENCE='```'

echo ""
echo "========================================"
echo "  BOOTSTRAP PROJET : $PROJECT_SLUG"
echo "========================================"
echo ""

# --- Login SiYuan (session cookie) ---
siyuan_login() {
    local resp
    resp=$(curl -sf -c "$COOKIE_JAR" -X POST "$BASE/api/system/loginAuth" \
        -H "Content-Type: application/json" \
        -d "{\"authCode\": \"$SIYUAN_AUTH_CODE\"}" 2>/dev/null)
    local code
    code=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('code',1))" 2>/dev/null || echo "1")
    if [ "$code" != "0" ]; then
        warn "SiYuan login echoue (code=$code) — tentative sans auth"
    else
        log "SiYuan login OK (session cookie)"
    fi
}

# --- Helper : curl authentifie ---
sycurl() {
    curl -sf -b "$COOKIE_JAR" "$@"
}

# --- Helper : creer un doc (lit markdown depuis stdin) ---
# Usage: create_doc NOTEBOOK_ID PATH <<'MARKDOWN'
#        contenu...
#        MARKDOWN
create_doc() {
    local notebook_id="$1"
    local path="$2"
    local markdown
    markdown=$(cat)
    local escaped
    escaped=$(python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" <<< "$markdown")
    sycurl -X POST "$BASE/api/filetree/createDocWithMd" \
        -H "Content-Type: application/json" \
        -d "{\"notebook\": \"$notebook_id\", \"path\": \"$path\", \"markdown\": $escaped}" \
        >/dev/null 2>&1 \
        && log "  $path" \
        || warn "  $path (existe deja ou erreur)"
}

# --- Helper : recuperer l'ID d'un notebook par nom ---
get_notebook_id() {
    local name="$1"
    sycurl -X POST "$BASE/api/notebook/lsNotebooks" \
        -H "Content-Type: application/json" -d '{}' \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
for n in data.get('data', {}).get('notebooks', []):
    if n['name'] == '$name':
        print(n['id'])
        break
" 2>/dev/null || echo ""
}

# --- Helper : poser les custom attributes ---
set_doc_attrs() {
    local notebook_id="$1"
    local path="$2"
    local project="$3"
    local type="$4"
    local status="${5:-active}"
    local doc_id
    doc_id=$(sycurl -X POST "$BASE/api/query/sql" \
        -H "Content-Type: application/json" \
        -d "{\"stmt\": \"SELECT id FROM blocks WHERE box='$notebook_id' AND hpath LIKE '%$path' AND type='d' LIMIT 1\"}" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('data',[]); print(r[0]['id'] if r else '')" 2>/dev/null)
    if [ -n "$doc_id" ]; then
        sycurl -X POST "$BASE/api/attr/setBlockAttrs" \
            -H "Content-Type: application/json" \
            -d "{\"id\": \"$doc_id\", \"attrs\": {\"custom-project\": \"$project\", \"custom-type\": \"$type\", \"custom-status\": \"$status\", \"custom-agent\": \"$LEAD_AGENT\"}}" \
            >/dev/null 2>&1
    fi
}

# --- Helper : recuperer le block ID d'un doc global (pour les block references) ---
get_doc_block_id() {
    local notebook_id="$1"
    local path_pattern="$2"
    sycurl -X POST "$BASE/api/query/sql" \
        -H "Content-Type: application/json" \
        -d "{\"stmt\": \"SELECT id FROM blocks WHERE box='$notebook_id' AND hpath LIKE '%$path_pattern' AND type='d' LIMIT 1\"}" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('data',[]); print(r[0]['id'] if r else '')" 2>/dev/null
}

# ============================================
# VERIFICATION PREREQUIS
# ============================================

info "Verification SiYuan..."
if ! curl -sf -X POST "$BASE/api/system/version" -H "Content-Type: application/json" -d '{}' >/dev/null 2>&1; then
    fail "SiYuan n'est pas accessible sur $BASE"
fi
log "SiYuan accessible"

# Login SiYuan (session cookie)
siyuan_login

# ============================================
# RECUPERATION DES NOTEBOOK IDs
# ============================================

info "Recuperation des notebooks..."
ARCH_ID=$(get_notebook_id "architecture")
ENG_ID=$(get_notebook_id "engineering")
PROD_ID=$(get_notebook_id "produit")
DESIGN_ID=$(get_notebook_id "design-system")
RESEARCH_ID=$(get_notebook_id "research")
OPS_ID=$(get_notebook_id "operations")
SEC_ID=$(get_notebook_id "security")
GLOBAL_ID=$(get_notebook_id "global")

# Verifier qu'au moins global existe
if [ -z "$GLOBAL_ID" ]; then
    fail "Notebook 'global' non trouve. Lancer bootstrap.sh d'abord."
fi
log "8 notebooks trouves"

# ============================================
# RECUPERATION DES BLOCK IDs DES DOCS GLOBAUX
# ============================================

info "Recuperation des references vers les docs globaux..."

REF_GIT_WORKFLOW=""
REF_CODE_REVIEW=""
REF_API_DESIGN=""
REF_ADR_TEMPLATE=""
REF_COLORS=""
REF_TYPOGRAPHY=""
REF_DEPLOY=""
REF_OWASP=""

if [ -n "$ARCH_ID" ]; then
    REF_GIT_WORKFLOW=$(get_doc_block_id "$ARCH_ID" "/conventions/git-workflow")
    REF_CODE_REVIEW=$(get_doc_block_id "$ARCH_ID" "/conventions/code-review-checklist")
    REF_API_DESIGN=$(get_doc_block_id "$ARCH_ID" "/conventions/api-design")
    REF_ADR_TEMPLATE=$(get_doc_block_id "$ARCH_ID" "/templates/adr-template")
fi
if [ -n "$DESIGN_ID" ]; then
    REF_COLORS=$(get_doc_block_id "$DESIGN_ID" "/foundations/colors")
    REF_TYPOGRAPHY=$(get_doc_block_id "$DESIGN_ID" "/foundations/typography")
fi
if [ -n "$OPS_ID" ]; then
    REF_DEPLOY=$(get_doc_block_id "$OPS_ID" "/runbooks/deploy-standard")
fi
if [ -n "$SEC_ID" ]; then
    REF_OWASP=$(get_doc_block_id "$SEC_ID" "/policies/owasp-top10")
fi

log "References globales recuperees"

# --- Helper pour creer un lien de reference SiYuan ---
make_ref() {
    local block_id="$1"
    local label="$2"
    if [ -n "$block_id" ]; then
        echo "- (($block_id '$label'))"
    else
        echo "- *$label (reference non disponible)*"
    fi
}

# ============================================
# CREATION DES DOCS PROJET DANS CHAQUE NOTEBOOK
# ============================================

echo ""
info "=== Creation des docs projet : $PROJECT_SLUG ==="

# --- architecture ---
if [ -n "$ARCH_ID" ]; then
    info "architecture/projects/$PROJECT_SLUG/"
    create_doc "$ARCH_ID" "/projects/$PROJECT_SLUG/adrs/index" <<MARKDOWN
# ADRs — $PROJECT_SLUG

Architecture Decision Records du projet **$PROJECT_SLUG**.

## Conventions applicables
$(make_ref "$REF_GIT_WORKFLOW" "Convention Git Workflow")
$(make_ref "$REF_CODE_REVIEW" "Checklist Code Review")
$(make_ref "$REF_API_DESIGN" "Conventions API Design")

## Template
$(make_ref "$REF_ADR_TEMPLATE" "Template ADR")

## ADRs du projet

*Aucun ADR encore. Creer les ADRs sous \`/projects/$PROJECT_SLUG/adrs/ADR-NNN-titre\`.*

---
Agent: $LEAD_AGENT | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$ARCH_ID" "/projects/$PROJECT_SLUG/adrs/index" "$PROJECT_SLUG" "overview"
fi

# --- engineering ---
if [ -n "$ENG_ID" ]; then
    info "engineering/projects/$PROJECT_SLUG/"
    create_doc "$ENG_ID" "/projects/$PROJECT_SLUG/tech-docs/index" <<MARKDOWN
# Tech Docs — $PROJECT_SLUG

Documentation technique specifique au projet **$PROJECT_SLUG**.

## Guidelines applicables (globales)

Les guidelines globales s'appliquent a tous les projets.
Voir le notebook \`engineering/guidelines/\` pour TypeScript, Python, testing, performance.

## Docs techniques du projet

*Aucun doc technique encore. Creer sous \`/projects/$PROJECT_SLUG/tech-docs/nom-doc\`.*

---
Agent: $LEAD_AGENT | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$ENG_ID" "/projects/$PROJECT_SLUG/tech-docs/index" "$PROJECT_SLUG" "overview"
fi

# --- produit ---
if [ -n "$PROD_ID" ]; then
    info "produit/projects/$PROJECT_SLUG/"
    create_doc "$PROD_ID" "/projects/$PROJECT_SLUG/prds/index" <<MARKDOWN
# PRDs — $PROJECT_SLUG

Product Requirements Documents du projet **$PROJECT_SLUG**.

## PRDs du projet

*Aucun PRD encore. Creer sous \`/projects/$PROJECT_SLUG/prds/PRD-NNN-titre\`.*

---
Agent: cpo | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$PROD_ID" "/projects/$PROJECT_SLUG/prds/index" "$PROJECT_SLUG" "overview"

    create_doc "$PROD_ID" "/projects/$PROJECT_SLUG/user-stories/index" <<MARKDOWN
# User Stories — $PROJECT_SLUG

User stories du projet **$PROJECT_SLUG**.

## Stories du projet

*Aucune story encore. Creer sous \`/projects/$PROJECT_SLUG/user-stories/US-NNN-titre\`.*

---
Agent: cpo | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$PROD_ID" "/projects/$PROJECT_SLUG/user-stories/index" "$PROJECT_SLUG" "overview"
fi

# --- design-system ---
if [ -n "$DESIGN_ID" ]; then
    info "design-system/projects/$PROJECT_SLUG/"
    create_doc "$DESIGN_ID" "/projects/$PROJECT_SLUG/components/index" <<MARKDOWN
# Composants — $PROJECT_SLUG

Specifications composants specifiques au projet **$PROJECT_SLUG**.

## Design System global
$(make_ref "$REF_COLORS" "Palette de Couleurs")
$(make_ref "$REF_TYPOGRAPHY" "Systeme Typographique")

## Composants du projet

*Aucun composant encore. Creer sous \`/projects/$PROJECT_SLUG/components/nom-composant\`.*

---
Agent: designer | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$DESIGN_ID" "/projects/$PROJECT_SLUG/components/index" "$PROJECT_SLUG" "overview"
fi

# --- research ---
if [ -n "$RESEARCH_ID" ]; then
    info "research/projects/$PROJECT_SLUG/"
    create_doc "$RESEARCH_ID" "/projects/$PROJECT_SLUG/pocs/index" <<MARKDOWN
# POCs & Recherche — $PROJECT_SLUG

Proofs of concept et etudes pour le projet **$PROJECT_SLUG**.

## POCs du projet

*Aucun POC encore. Creer sous \`/projects/$PROJECT_SLUG/pocs/poc-nom\`.*

---
Agent: researcher | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$RESEARCH_ID" "/projects/$PROJECT_SLUG/pocs/index" "$PROJECT_SLUG" "overview"
fi

# --- operations ---
if [ -n "$OPS_ID" ]; then
    info "operations/projects/$PROJECT_SLUG/"
    create_doc "$OPS_ID" "/projects/$PROJECT_SLUG/runbooks/index" <<MARKDOWN
# Runbooks — $PROJECT_SLUG

Procedures operationnelles du projet **$PROJECT_SLUG**.

## Runbooks globaux
$(make_ref "$REF_DEPLOY" "Runbook Deploiement Standard")

## Runbooks du projet

*Aucun runbook encore. Creer sous \`/projects/$PROJECT_SLUG/runbooks/nom-runbook\`.*

---
Agent: devops | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$OPS_ID" "/projects/$PROJECT_SLUG/runbooks/index" "$PROJECT_SLUG" "overview"

    create_doc "$OPS_ID" "/projects/$PROJECT_SLUG/post-mortems/index" <<MARKDOWN
# Post-Mortems — $PROJECT_SLUG

Incidents et analyses post-mortem du projet **$PROJECT_SLUG**.

## Post-mortems du projet

*Aucun post-mortem encore. Creer sous \`/projects/$PROJECT_SLUG/post-mortems/PM-NNN-titre\`.*

---
Agent: devops | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$OPS_ID" "/projects/$PROJECT_SLUG/post-mortems/index" "$PROJECT_SLUG" "overview"
fi

# --- security ---
if [ -n "$SEC_ID" ]; then
    info "security/projects/$PROJECT_SLUG/"
    create_doc "$SEC_ID" "/projects/$PROJECT_SLUG/audits/index" <<MARKDOWN
# Audits Securite — $PROJECT_SLUG

Rapports d'audit du projet **$PROJECT_SLUG**.

## Politiques globales
$(make_ref "$REF_OWASP" "OWASP Top 10 Checklist")

## Audits du projet

*Aucun audit encore. Creer sous \`/projects/$PROJECT_SLUG/audits/audit-YYYY-QN\`.*

---
Agent: security | Projet: $PROJECT_SLUG | Cree: $TODAY
MARKDOWN
    set_doc_attrs "$SEC_ID" "/projects/$PROJECT_SLUG/audits/index" "$PROJECT_SLUG" "overview"
fi

# ============================================
# HUB PROJET (global/projects/<slug>/overview)
# ============================================

echo ""
info "=== Hub projet : global/projects/$PROJECT_SLUG/ ==="

create_doc "$GLOBAL_ID" "/projects/$PROJECT_SLUG/overview" <<MARKDOWN
# Projet : $PROJECT_SLUG

| Champ | Valeur |
|-------|--------|
| **Slug** | $PROJECT_SLUG |
| **Paperclip ID** | $PAPERCLIP_ID |
| **Lead Agent** | $LEAD_AGENT |
| **Status** | Active |
| **Description** | $DESCRIPTION |
| **Cree** | $TODAY |

## Conventions applicables
$(make_ref "$REF_GIT_WORKFLOW" "Convention Git Workflow")
$(make_ref "$REF_CODE_REVIEW" "Checklist Code Review")
$(make_ref "$REF_API_DESIGN" "Conventions API Design")

## Design System
$(make_ref "$REF_COLORS" "Palette de Couleurs")
$(make_ref "$REF_TYPOGRAPHY" "Systeme Typographique")

## Notebooks du projet

| Domaine | Chemin |
|---------|--------|
| Architecture (ADRs) | \`architecture/projects/$PROJECT_SLUG/adrs/\` |
| Engineering (Tech Docs) | \`engineering/projects/$PROJECT_SLUG/tech-docs/\` |
| Produit (PRDs) | \`produit/projects/$PROJECT_SLUG/prds/\` |
| Produit (Stories) | \`produit/projects/$PROJECT_SLUG/user-stories/\` |
| Design System | \`design-system/projects/$PROJECT_SLUG/components/\` |
| Research (POCs) | \`research/projects/$PROJECT_SLUG/pocs/\` |
| Operations (Runbooks) | \`operations/projects/$PROJECT_SLUG/runbooks/\` |
| Operations (Post-Mortems) | \`operations/projects/$PROJECT_SLUG/post-mortems/\` |
| Security (Audits) | \`security/projects/$PROJECT_SLUG/audits/\` |

## Decisions recentes (ADRs)

${FENCE}sql
SELECT b.content, b.hpath FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project' AND a1.value = '$PROJECT_SLUG'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type' AND a2.value = 'adr'
WHERE b.type = 'd' ORDER BY b.updated DESC LIMIT 5
${FENCE}

## Activite recente

${FENCE}sql
SELECT b.content, b.hpath, a2.value AS type FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project' AND a1.value = '$PROJECT_SLUG'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type'
WHERE b.type = 'd' ORDER BY b.updated DESC LIMIT 10
${FENCE}

## Documents en review

${FENCE}sql
SELECT b.content, b.hpath FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project' AND a1.value = '$PROJECT_SLUG'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-status' AND a2.value = 'review'
WHERE b.type = 'd' ORDER BY b.updated DESC
${FENCE}
MARKDOWN
set_doc_attrs "$GLOBAL_ID" "/projects/$PROJECT_SLUG/overview" "$PROJECT_SLUG" "overview"

# Dashboard projet
create_doc "$GLOBAL_ID" "/projects/$PROJECT_SLUG/status" <<MARKDOWN
# Status : $PROJECT_SLUG

Dashboard du projet **$PROJECT_SLUG**.

## Tous les documents du projet

${FENCE}sql
SELECT b.content, b.hpath, a2.value AS type, a3.value AS status FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project' AND a1.value = '$PROJECT_SLUG'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type'
LEFT JOIN attributes a3 ON b.id = a3.block_id AND a3.name = 'custom-status'
WHERE b.type = 'd' ORDER BY b.updated DESC
${FENCE}

## ADRs

${FENCE}sql
SELECT b.content, b.hpath, a3.value AS status FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project' AND a1.value = '$PROJECT_SLUG'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type' AND a2.value = 'adr'
LEFT JOIN attributes a3 ON b.id = a3.block_id AND a3.name = 'custom-status'
WHERE b.type = 'd' ORDER BY b.updated DESC
${FENCE}

## PRDs

${FENCE}sql
SELECT b.content, b.hpath, a3.value AS status FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project' AND a1.value = '$PROJECT_SLUG'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type' AND a2.value = 'prd'
LEFT JOIN attributes a3 ON b.id = a3.block_id AND a3.name = 'custom-status'
WHERE b.type = 'd' ORDER BY b.updated DESC
${FENCE}

---
*Utiliser ces requetes SQL via SiYuan query embeds ou l'API /api/query/sql.*
*Derniere mise a jour : $TODAY*
MARKDOWN
set_doc_attrs "$GLOBAL_ID" "/projects/$PROJECT_SLUG/status" "$PROJECT_SLUG" "dashboard"

# ============================================
# MISE A JOUR DU REGISTRE
# ============================================

echo ""
info "=== Mise a jour du registre ==="

# Recuperer le block ID du registre
REGISTRY_ID=$(get_doc_block_id "$GLOBAL_ID" "/projects/registry")

if [ -n "$REGISTRY_ID" ]; then
    # Ajouter une ligne au registre via appendBlock
    NEW_ROW="| $PROJECT_SLUG | $DESCRIPTION | $LEAD_AGENT | $PAPERCLIP_ID | Active | $TODAY |"
    ESCAPED_ROW=$(python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" <<< "$NEW_ROW")
    sycurl -X POST "$BASE/api/block/appendBlock" \
        -H "Content-Type: application/json" \
        -d "{\"data\": $ESCAPED_ROW, \"dataType\": \"markdown\", \"parentID\": \"$REGISTRY_ID\"}" \
        >/dev/null 2>&1 \
        && log "Registre mis a jour" \
        || warn "Registre : erreur d'ajout"
else
    warn "Registre non trouve — creer-le avec bootstrap.sh"
fi

# ============================================
# NOTIFICATION
# ============================================

sycurl -X POST "$BASE/api/notification/pushMsg" \
    -H "Content-Type: application/json" \
    -d "{\"msg\": \"Projet '$PROJECT_SLUG' initialise dans les 8 notebooks. Lead: $LEAD_AGENT.\", \"timeout\": 30000}" \
    >/dev/null 2>&1 \
    && log "Notification envoyee" \
    || true

# ============================================
# RESUME
# ============================================

echo ""
echo "========================================"
log "Projet '$PROJECT_SLUG' bootstrap termine."
echo "========================================"
echo ""
echo "Structure creee dans les 8 notebooks :"
echo "  architecture/projects/$PROJECT_SLUG/adrs/"
echo "  engineering/projects/$PROJECT_SLUG/tech-docs/"
echo "  produit/projects/$PROJECT_SLUG/prds/"
echo "  produit/projects/$PROJECT_SLUG/user-stories/"
echo "  design-system/projects/$PROJECT_SLUG/components/"
echo "  research/projects/$PROJECT_SLUG/pocs/"
echo "  operations/projects/$PROJECT_SLUG/runbooks/"
echo "  operations/projects/$PROJECT_SLUG/post-mortems/"
echo "  security/projects/$PROJECT_SLUG/audits/"
echo ""
echo "Hub projet   : global/projects/$PROJECT_SLUG/overview"
echo "Dashboard    : global/projects/$PROJECT_SLUG/status"
echo "Registre     : global/projects/registry (mis a jour)"
echo ""
echo "Chaque doc index contient des block references vers"
echo "les conventions globales (visible dans le graph SiYuan)."
echo ""
