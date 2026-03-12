#!/bin/bash
# ============================================
# SIYUAN BOOTSTRAP — Architecture complete des notebooks
# ============================================
# Usage : bash mac/siyuan/bootstrap.sh
#         bash mac/siyuan/bootstrap.sh --reset
# Prerequis : SiYuan doit etre demarre (localhost:6806)
#
# Cree 8 notebooks avec contenu pre-peuple :
#   architecture, engineering, produit, design-system,
#   research, operations, security, global
#
# Les docs sont lus depuis le dossier docs/ (pas de heredocs).
# Idempotent : peut etre relance sans risque.
# --reset : supprime tous les notebooks (sauf User Guide) avant de creer.
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
err()  { echo -e "${RED}[ERR]${NC} $1"; }

BASE="http://localhost:6806"
SIYUAN_AUTH_CODE="${SIYUAN_TOKEN:-paperclip-siyuan-token}"
COOKIE_JAR=$(mktemp /tmp/siyuan-cookies.XXXXXX)
trap "rm -f $COOKIE_JAR" EXIT

# Dossier docs relatif au script
DOCS_DIR="$(cd "$(dirname "$0")/docs" && pwd)"

# --- Flag --reset ---
RESET=false
if [ "${1:-}" = "--reset" ]; then
    RESET=true
fi

# ============================================
# HELPERS
# ============================================

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

# --- Helper : creer un doc a partir d'un fichier markdown ---
create_doc_from_file() {
    local notebook_id="$1"
    local path="$2"
    local file="$3"
    if [ ! -f "$file" ]; then
        warn "  Fichier manquant: $file"
        return
    fi
    local escaped
    escaped=$(python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" < "$file")
    sycurl -X POST "$BASE/api/filetree/createDocWithMd" \
        -H "Content-Type: application/json" \
        -d "{\"notebook\": \"$notebook_id\", \"path\": \"$path\", \"markdown\": $escaped}" \
        >/dev/null 2>&1 \
        && log "  $path" \
        || warn "  $path (existe deja ou erreur)"
}

# --- Helper : creer un doc avec contenu inline (court) ---
create_doc_inline() {
    local notebook_id="$1"
    local path="$2"
    local markdown="$3"
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

# --- Helper : poser les custom attributes sur un doc ---
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
            -d "{\"id\": \"$doc_id\", \"attrs\": {\"custom-project\": \"$project\", \"custom-type\": \"$type\", \"custom-status\": \"$status\"}}" \
            >/dev/null 2>&1
    fi
}

# --- Helper : recuperer le block ID d'un doc ---
get_block_id() {
    local notebook_id="$1"
    local path="$2"
    sycurl -X POST "$BASE/api/query/sql" \
        -H "Content-Type: application/json" \
        -d "{\"stmt\": \"SELECT id FROM blocks WHERE box='$notebook_id' AND hpath LIKE '%$path' AND type='d' LIMIT 1\"}" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('data',[]); print(r[0]['id'] if r else '')" 2>/dev/null
}

# --- Helper : ajouter un bloc "Voir aussi" avec des refs (idempotent) ---
append_voir_aussi() {
    local doc_id="$1"
    shift
    if [ -z "$doc_id" ]; then return 0; fi
    # Verifier si "Voir aussi" existe deja
    local existing
    existing=$(sycurl -X POST "$BASE/api/query/sql" \
        -H "Content-Type: application/json" \
        -d "{\"stmt\": \"SELECT id FROM blocks WHERE root_id='$doc_id' AND markdown LIKE '%Voir aussi%' LIMIT 1\"}" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('data',[]); print(r[0]['id'] if r else '')" 2>/dev/null)
    if [ -n "$existing" ]; then
        return 0
    fi
    # Construire le markdown des refs
    local md
    md=$'\n---\n\n## Voir aussi\n'
    while [ $# -ge 2 ]; do
        local bid="$1" label="$2"
        shift 2
        if [ -n "$bid" ]; then
            md+="- (($bid '$label'))"$'\n'
        fi
    done
    local escaped
    escaped=$(python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" <<< "$md")
    sycurl -X POST "$BASE/api/block/appendBlock" \
        -H "Content-Type: application/json" \
        -d "{\"data\": $escaped, \"dataType\": \"markdown\", \"parentID\": \"$doc_id\"}" \
        >/dev/null 2>&1
}

# ============================================
# ATTENTE SIYUAN
# ============================================

info "Attente de SiYuan..."
for i in $(seq 1 30); do
    if curl -sf -X POST "$BASE/api/system/version" -H "Content-Type: application/json" -d '{}' >/dev/null 2>&1; then
        log "SiYuan pret"
        break
    fi
    [ "$i" -eq 30 ] && { warn "SiYuan pas pret apres 60s"; exit 1; }
    sleep 2
done

# Login SiYuan (session cookie)
siyuan_login

# ============================================
# MODE RESET (--reset)
# ============================================

if [ "$RESET" = true ]; then
    echo ""
    info "=== MODE RESET : suppression des notebooks ==="
    # Lister tous les notebooks
    NOTEBOOKS_JSON=$(sycurl -X POST "$BASE/api/notebook/lsNotebooks" \
        -H "Content-Type: application/json" -d '{}')
    # Supprimer tous sauf "SiYuan User Guide"
    echo "$NOTEBOOKS_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for n in data.get('data', {}).get('notebooks', []):
    if n['name'] not in ('SiYuan User Guide', 'SiYuan 用户指南'):
        print(n['id'])
" 2>/dev/null | while read -r nb_id; do
        if [ -n "$nb_id" ]; then
            sycurl -X POST "$BASE/api/notebook/removeNotebook" \
                -H "Content-Type: application/json" \
                -d "{\"notebook\": \"$nb_id\"}" >/dev/null 2>&1 \
                && log "  Supprime notebook $nb_id" \
                || warn "  Erreur suppression $nb_id"
        fi
    done
    log "Reset termine"
fi

# ============================================
# CREATION DES 8 NOTEBOOKS
# ============================================

echo ""
info "=== Creation des notebooks ==="
for nb in architecture engineering produit design-system research operations security global; do
    sycurl -X POST "$BASE/api/notebook/createNotebook" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$nb\"}" >/dev/null 2>&1 \
        && log "Notebook '$nb'" \
        || warn "Notebook '$nb' (existe deja)"
done

# Recuperer les IDs
ARCH_ID=$(get_notebook_id "architecture")
ENG_ID=$(get_notebook_id "engineering")
PROD_ID=$(get_notebook_id "produit")
DESIGN_ID=$(get_notebook_id "design-system")
RESEARCH_ID=$(get_notebook_id "research")
OPS_ID=$(get_notebook_id "operations")
SEC_ID=$(get_notebook_id "security")
GLOBAL_ID=$(get_notebook_id "global")

# ============================================
# NOTEBOOK : architecture
# ============================================

if [ -n "$ARCH_ID" ]; then
    echo ""
    info "=== Contenu : architecture ==="
    create_doc_from_file "$ARCH_ID" "/conventions/git-workflow"        "$DOCS_DIR/architecture/conventions--git-workflow.md"
    create_doc_from_file "$ARCH_ID" "/conventions/code-review-checklist" "$DOCS_DIR/architecture/conventions--code-review-checklist.md"
    create_doc_from_file "$ARCH_ID" "/conventions/api-design"          "$DOCS_DIR/architecture/conventions--api-design.md"
    create_doc_from_file "$ARCH_ID" "/stack/overview"                  "$DOCS_DIR/architecture/stack--overview.md"
    create_doc_from_file "$ARCH_ID" "/stack/ports-reference"           "$DOCS_DIR/architecture/stack--ports-reference.md"
    create_doc_from_file "$ARCH_ID" "/templates/adr-template"          "$DOCS_DIR/architecture/templates--adr-template.md"
    create_doc_from_file "$ARCH_ID" "/protocols/agent-communication"  "$DOCS_DIR/architecture/protocols--agent-communication.md"
    create_doc_from_file "$ARCH_ID" "/frameworks/workflow-execution"  "$DOCS_DIR/architecture/frameworks--workflow-execution.md"
fi

# ============================================
# NOTEBOOK : engineering
# ============================================

if [ -n "$ENG_ID" ]; then
    echo ""
    info "=== Contenu : engineering ==="
    create_doc_from_file "$ENG_ID" "/guidelines/typescript"   "$DOCS_DIR/engineering/guidelines--typescript.md"
    create_doc_from_file "$ENG_ID" "/guidelines/python"       "$DOCS_DIR/engineering/guidelines--python.md"
    create_doc_from_file "$ENG_ID" "/guidelines/testing"      "$DOCS_DIR/engineering/guidelines--testing.md"
    create_doc_from_file "$ENG_ID" "/guidelines/performance"  "$DOCS_DIR/engineering/guidelines--performance.md"
    create_doc_from_file "$ENG_ID" "/tech-docs/docker"        "$DOCS_DIR/engineering/tech-docs--docker.md"
    create_doc_from_file "$ENG_ID" "/tech-docs/postgresql"    "$DOCS_DIR/engineering/tech-docs--postgresql.md"
    create_doc_from_file "$ENG_ID" "/tech-docs/ollama"        "$DOCS_DIR/engineering/tech-docs--ollama.md"
    create_doc_from_file "$ENG_ID" "/tech-docs/chroma"        "$DOCS_DIR/engineering/tech-docs--chroma.md"
    create_doc_from_file "$ENG_ID" "/tech-docs/mem0-api"      "$DOCS_DIR/engineering/tech-docs--mem0-api.md"
    create_doc_from_file "$ENG_ID" "/guides/agent-testing"   "$DOCS_DIR/engineering/guides--agent-testing.md"
fi

# ============================================
# NOTEBOOK : produit
# ============================================

if [ -n "$PROD_ID" ]; then
    echo ""
    info "=== Contenu : produit ==="
    create_doc_from_file "$PROD_ID" "/templates/prd-template"         "$DOCS_DIR/produit/templates--prd-template.md"
    create_doc_from_file "$PROD_ID" "/templates/user-story-template"  "$DOCS_DIR/produit/templates--user-story-template.md"
    create_doc_from_file "$PROD_ID" "/guidelines/product-discovery"   "$DOCS_DIR/produit/guidelines--product-discovery.md"
fi

# ============================================
# NOTEBOOK : design-system
# ============================================

if [ -n "$DESIGN_ID" ]; then
    echo ""
    info "=== Contenu : design-system ==="
    create_doc_from_file "$DESIGN_ID" "/foundations/colors"         "$DOCS_DIR/design-system/foundations--colors.md"
    create_doc_from_file "$DESIGN_ID" "/foundations/typography"     "$DOCS_DIR/design-system/foundations--typography.md"
    create_doc_from_file "$DESIGN_ID" "/foundations/spacing"        "$DOCS_DIR/design-system/foundations--spacing.md"
    create_doc_from_file "$DESIGN_ID" "/foundations/accessibility"  "$DOCS_DIR/design-system/foundations--accessibility.md"
fi

# ============================================
# NOTEBOOK : research
# ============================================

if [ -n "$RESEARCH_ID" ]; then
    echo ""
    info "=== Contenu : research ==="
    create_doc_from_file "$RESEARCH_ID" "/templates/tech-comparison"  "$DOCS_DIR/research/templates--tech-comparison.md"
    create_doc_from_file "$RESEARCH_ID" "/templates/poc-template"     "$DOCS_DIR/research/templates--poc-template.md"
    create_doc_from_file "$RESEARCH_ID" "/guides/rag-strategy"      "$DOCS_DIR/research/guides--rag-strategy.md"
fi

# ============================================
# NOTEBOOK : operations
# ============================================

if [ -n "$OPS_ID" ]; then
    echo ""
    info "=== Contenu : operations ==="
    create_doc_from_file "$OPS_ID" "/runbooks/deploy-standard"      "$DOCS_DIR/operations/runbooks--deploy-standard.md"
    create_doc_from_file "$OPS_ID" "/runbooks/database-migration"   "$DOCS_DIR/operations/runbooks--database-migration.md"
    create_doc_from_file "$OPS_ID" "/templates/post-mortem"         "$DOCS_DIR/operations/templates--post-mortem.md"
    create_doc_from_file "$OPS_ID" "/monitoring/alerting-rules"     "$DOCS_DIR/operations/monitoring--alerting-rules.md"
    create_doc_from_file "$OPS_ID" "/runbooks/disaster-recovery"    "$DOCS_DIR/operations/runbooks--disaster-recovery.md"
    create_doc_from_file "$OPS_ID" "/policies/knowledge-freshness"  "$DOCS_DIR/operations/policies--knowledge-freshness.md"
    create_doc_from_file "$OPS_ID" "/guides/cost-analysis"          "$DOCS_DIR/operations/guides--cost-analysis.md"
fi

# ============================================
# NOTEBOOK : security
# ============================================

if [ -n "$SEC_ID" ]; then
    echo ""
    info "=== Contenu : security ==="
    create_doc_from_file "$SEC_ID" "/policies/owasp-top10"              "$DOCS_DIR/security/policies--owasp-top10.md"
    create_doc_from_file "$SEC_ID" "/policies/authentication"           "$DOCS_DIR/security/policies--authentication.md"
    create_doc_from_file "$SEC_ID" "/policies/dependency-management"    "$DOCS_DIR/security/policies--dependency-management.md"
    create_doc_from_file "$SEC_ID" "/templates/audit-report"            "$DOCS_DIR/security/templates--audit-report.md"
fi

# ============================================
# NOTEBOOK : global (dashboards + onboarding)
# ============================================

if [ -n "$GLOBAL_ID" ]; then
    echo ""
    info "=== Contenu : global ==="

    # --- Dashboards (inline court) ---
    for dash in services analytics team-activity; do
        create_doc_inline "$GLOBAL_ID" "/dashboards/$dash" "# Dashboard: $dash

En attente de donnees...

---

*Mis a jour automatiquement par n8n.*"
    done

    # --- Daily notes config ---
    sycurl -X POST "$BASE/api/notebook/setNotebookConf" \
        -H "Content-Type: application/json" \
        -d "{
            \"notebook\": \"$GLOBAL_ID\",
            \"conf\": {
                \"dailyNoteSavePath\": \"/journal/{{now | date \\\"2006/01\\\"}}/{{now | date \\\"2006-01-02\\\"}}\"
            }
        }" >/dev/null 2>&1 \
        && log "  Daily notes configurees" \
        || warn "  Daily notes (erreur)"

    # --- Onboarding (from files) ---
    create_doc_from_file "$GLOBAL_ID" "/onboarding/guide-agent"     "$DOCS_DIR/global/onboarding--guide-agent.md"
    create_doc_from_file "$GLOBAL_ID" "/onboarding/api-cheatsheet"  "$DOCS_DIR/global/onboarding--api-cheatsheet.md"

    # --- Registre des projets ---
    create_doc_from_file "$GLOBAL_ID" "/projects/registry"          "$DOCS_DIR/global/projects--registry.md"

    # --- Dashboard tous les projets ---
    create_doc_from_file "$GLOBAL_ID" "/dashboards/all-projects"    "$DOCS_DIR/global/dashboards--all-projects.md"

    # --- Sprint report template ---
    create_doc_from_file "$GLOBAL_ID" "/templates/sprint-report"    "$DOCS_DIR/global/templates--sprint-report.md"
    create_doc_from_file "$GLOBAL_ID" "/dashboards/agent-metrics"   "$DOCS_DIR/global/dashboards--agent-metrics.md"
fi

# ============================================
# CUSTOM ATTRIBUTES (custom-project, custom-type, custom-status)
# ============================================

echo ""
info "=== Attribution des metadonnees custom ==="

# Architecture
if [ -n "$ARCH_ID" ]; then
    set_doc_attrs "$ARCH_ID" "/conventions/git-workflow" "global" "convention"
    set_doc_attrs "$ARCH_ID" "/conventions/code-review-checklist" "global" "convention"
    set_doc_attrs "$ARCH_ID" "/conventions/api-design" "global" "convention"
    set_doc_attrs "$ARCH_ID" "/stack/overview" "global" "tech-doc"
    set_doc_attrs "$ARCH_ID" "/stack/ports-reference" "global" "tech-doc"
    set_doc_attrs "$ARCH_ID" "/templates/adr-template" "global" "template"
    set_doc_attrs "$ARCH_ID" "/protocols/agent-communication" "global" "protocol"
    set_doc_attrs "$ARCH_ID" "/frameworks/workflow-execution" "global" "framework"
    log "  architecture : 8 docs"
fi

# Engineering
if [ -n "$ENG_ID" ]; then
    set_doc_attrs "$ENG_ID" "/guidelines/typescript" "global" "guideline"
    set_doc_attrs "$ENG_ID" "/guidelines/python" "global" "guideline"
    set_doc_attrs "$ENG_ID" "/guidelines/testing" "global" "guideline"
    set_doc_attrs "$ENG_ID" "/guidelines/performance" "global" "guideline"
    set_doc_attrs "$ENG_ID" "/tech-docs/docker" "global" "tech-doc"
    set_doc_attrs "$ENG_ID" "/tech-docs/postgresql" "global" "tech-doc"
    set_doc_attrs "$ENG_ID" "/tech-docs/ollama" "global" "tech-doc"
    set_doc_attrs "$ENG_ID" "/tech-docs/chroma" "global" "tech-doc"
    set_doc_attrs "$ENG_ID" "/tech-docs/mem0-api" "global" "tech-doc"
    set_doc_attrs "$ENG_ID" "/guides/agent-testing" "global" "guideline"
    log "  engineering : 10 docs"
fi

# Produit
if [ -n "$PROD_ID" ]; then
    set_doc_attrs "$PROD_ID" "/templates/prd-template" "global" "template"
    set_doc_attrs "$PROD_ID" "/templates/user-story-template" "global" "template"
    set_doc_attrs "$PROD_ID" "/guidelines/product-discovery" "global" "guideline"
    log "  produit : 3 docs"
fi

# Design System
if [ -n "$DESIGN_ID" ]; then
    set_doc_attrs "$DESIGN_ID" "/foundations/colors" "global" "guideline"
    set_doc_attrs "$DESIGN_ID" "/foundations/typography" "global" "guideline"
    set_doc_attrs "$DESIGN_ID" "/foundations/spacing" "global" "guideline"
    set_doc_attrs "$DESIGN_ID" "/foundations/accessibility" "global" "guideline"
    log "  design-system : 4 docs"
fi

# Research
if [ -n "$RESEARCH_ID" ]; then
    set_doc_attrs "$RESEARCH_ID" "/templates/tech-comparison" "global" "template"
    set_doc_attrs "$RESEARCH_ID" "/templates/poc-template" "global" "template"
    set_doc_attrs "$RESEARCH_ID" "/guides/rag-strategy" "global" "guideline"
    log "  research : 3 docs"
fi

# Operations
if [ -n "$OPS_ID" ]; then
    set_doc_attrs "$OPS_ID" "/runbooks/deploy-standard" "global" "runbook"
    set_doc_attrs "$OPS_ID" "/runbooks/database-migration" "global" "runbook"
    set_doc_attrs "$OPS_ID" "/templates/post-mortem" "global" "template"
    set_doc_attrs "$OPS_ID" "/monitoring/alerting-rules" "global" "guideline"
    set_doc_attrs "$OPS_ID" "/runbooks/disaster-recovery" "global" "runbook"
    set_doc_attrs "$OPS_ID" "/policies/knowledge-freshness" "global" "policy"
    set_doc_attrs "$OPS_ID" "/guides/cost-analysis" "global" "guideline"
    log "  operations : 7 docs"
fi

# Security
if [ -n "$SEC_ID" ]; then
    set_doc_attrs "$SEC_ID" "/policies/owasp-top10" "global" "guideline"
    set_doc_attrs "$SEC_ID" "/policies/dependency-management" "global" "guideline"
    set_doc_attrs "$SEC_ID" "/policies/authentication" "global" "guideline"
    set_doc_attrs "$SEC_ID" "/templates/audit-report" "global" "template"
    log "  security : 4 docs"
fi

# Global
if [ -n "$GLOBAL_ID" ]; then
    set_doc_attrs "$GLOBAL_ID" "/dashboards/services" "global" "dashboard"
    set_doc_attrs "$GLOBAL_ID" "/dashboards/analytics" "global" "dashboard"
    set_doc_attrs "$GLOBAL_ID" "/dashboards/team-activity" "global" "dashboard"
    set_doc_attrs "$GLOBAL_ID" "/dashboards/all-projects" "global" "dashboard"
    set_doc_attrs "$GLOBAL_ID" "/projects/registry" "global" "registry"
    set_doc_attrs "$GLOBAL_ID" "/onboarding/guide-agent" "global" "guideline"
    set_doc_attrs "$GLOBAL_ID" "/onboarding/api-cheatsheet" "global" "tech-doc"
    set_doc_attrs "$GLOBAL_ID" "/templates/sprint-report" "global" "template"
    set_doc_attrs "$GLOBAL_ID" "/dashboards/agent-metrics" "global" "dashboard"
    log "  global : 9 docs"
fi

log "Attributs custom poses sur ~40 docs (custom-project: global)"

# ============================================
# LIENS INTER-DOCUMENTS (Graph View)
# ============================================

echo ""
info "=== Creation des liens inter-documents (graph) ==="

# Recuperer tous les block IDs
info "Recuperation des block IDs..."

# Architecture
ID_GIT_WORKFLOW=$(get_block_id "$ARCH_ID" "/conventions/git-workflow")
ID_CODE_REVIEW=$(get_block_id "$ARCH_ID" "/conventions/code-review-checklist")
ID_API_DESIGN=$(get_block_id "$ARCH_ID" "/conventions/api-design")
ID_STACK_OVERVIEW=$(get_block_id "$ARCH_ID" "/stack/overview")
ID_PORTS_REF=$(get_block_id "$ARCH_ID" "/stack/ports-reference")
ID_ADR_TEMPLATE=$(get_block_id "$ARCH_ID" "/templates/adr-template")
ID_AGENT_COMM=$(get_block_id "$ARCH_ID" "/protocols/agent-communication")
ID_WORKFLOW_EXEC=$(get_block_id "$ARCH_ID" "/frameworks/workflow-execution")

# Engineering
ID_TYPESCRIPT=$(get_block_id "$ENG_ID" "/guidelines/typescript")
ID_PYTHON=$(get_block_id "$ENG_ID" "/guidelines/python")
ID_TESTING=$(get_block_id "$ENG_ID" "/guidelines/testing")
ID_PERFORMANCE=$(get_block_id "$ENG_ID" "/guidelines/performance")
ID_DOCKER=$(get_block_id "$ENG_ID" "/tech-docs/docker")
ID_POSTGRESQL=$(get_block_id "$ENG_ID" "/tech-docs/postgresql")
ID_OLLAMA=$(get_block_id "$ENG_ID" "/tech-docs/ollama")
ID_CHROMA=$(get_block_id "$ENG_ID" "/tech-docs/chroma")
ID_MEM0=$(get_block_id "$ENG_ID" "/tech-docs/mem0-api")
ID_AGENT_TESTING=$(get_block_id "$ENG_ID" "/guides/agent-testing")

# Design System
ID_COLORS=$(get_block_id "$DESIGN_ID" "/foundations/colors")
ID_TYPOGRAPHY=$(get_block_id "$DESIGN_ID" "/foundations/typography")
ID_SPACING=$(get_block_id "$DESIGN_ID" "/foundations/spacing")
ID_A11Y=$(get_block_id "$DESIGN_ID" "/foundations/accessibility")

# Produit
ID_PRD_TPL=$(get_block_id "$PROD_ID" "/templates/prd-template")
ID_US_TPL=$(get_block_id "$PROD_ID" "/templates/user-story-template")
ID_DISCOVERY=$(get_block_id "$PROD_ID" "/guidelines/product-discovery")

# Research
ID_TECH_COMP=$(get_block_id "$RESEARCH_ID" "/templates/tech-comparison")
ID_POC_TPL=$(get_block_id "$RESEARCH_ID" "/templates/poc-template")
ID_RAG_STRATEGY=$(get_block_id "$RESEARCH_ID" "/guides/rag-strategy")

# Operations
ID_DEPLOY=$(get_block_id "$OPS_ID" "/runbooks/deploy-standard")
ID_DB_MIGRATION=$(get_block_id "$OPS_ID" "/runbooks/database-migration")
ID_POSTMORTEM=$(get_block_id "$OPS_ID" "/templates/post-mortem")
ID_ALERTING=$(get_block_id "$OPS_ID" "/monitoring/alerting-rules")
ID_DISASTER_REC=$(get_block_id "$OPS_ID" "/runbooks/disaster-recovery")
ID_FRESHNESS=$(get_block_id "$OPS_ID" "/policies/knowledge-freshness")
ID_COST_ANALYSIS=$(get_block_id "$OPS_ID" "/guides/cost-analysis")

# Security
ID_OWASP=$(get_block_id "$SEC_ID" "/policies/owasp-top10")
ID_DEPS=$(get_block_id "$SEC_ID" "/policies/dependency-management")
ID_AUTH_POL=$(get_block_id "$SEC_ID" "/policies/authentication")
ID_AUDIT_TPL=$(get_block_id "$SEC_ID" "/templates/audit-report")

# Global
ID_GUIDE_AGENT=$(get_block_id "$GLOBAL_ID" "/onboarding/guide-agent")
ID_CHEATSHEET=$(get_block_id "$GLOBAL_ID" "/onboarding/api-cheatsheet")
ID_AGENT_METRICS=$(get_block_id "$GLOBAL_ID" "/dashboards/agent-metrics")

log "Block IDs recuperes"

info "Ajout des liens croises..."

# --- Architecture : conventions ---
append_voir_aussi "$ID_GIT_WORKFLOW" \
    "$ID_CODE_REVIEW" "Code Review Checklist" \
    "$ID_API_DESIGN" "API Design" \
    "$ID_ADR_TEMPLATE" "Template ADR" \
    "$ID_TESTING" "Guidelines Testing"

append_voir_aussi "$ID_CODE_REVIEW" \
    "$ID_GIT_WORKFLOW" "Git Workflow" \
    "$ID_TESTING" "Guidelines Testing" \
    "$ID_API_DESIGN" "API Design" \
    "$ID_TYPESCRIPT" "Guidelines TypeScript"

append_voir_aussi "$ID_API_DESIGN" \
    "$ID_TYPESCRIPT" "Guidelines TypeScript" \
    "$ID_PYTHON" "Guidelines Python" \
    "$ID_GIT_WORKFLOW" "Git Workflow" \
    "$ID_CODE_REVIEW" "Code Review Checklist"

append_voir_aussi "$ID_STACK_OVERVIEW" \
    "$ID_DOCKER" "Docker" \
    "$ID_POSTGRESQL" "PostgreSQL" \
    "$ID_OLLAMA" "Ollama" \
    "$ID_CHROMA" "Chroma" \
    "$ID_MEM0" "Mem0 API" \
    "$ID_PORTS_REF" "Ports Reference"

append_voir_aussi "$ID_PORTS_REF" \
    "$ID_STACK_OVERVIEW" "Stack Overview"

append_voir_aussi "$ID_ADR_TEMPLATE" \
    "$ID_GIT_WORKFLOW" "Git Workflow" \
    "$ID_CODE_REVIEW" "Code Review Checklist"

log "  architecture : 6 docs lies"

# --- Engineering : guidelines ---
append_voir_aussi "$ID_TYPESCRIPT" \
    "$ID_API_DESIGN" "API Design" \
    "$ID_TESTING" "Guidelines Testing" \
    "$ID_CODE_REVIEW" "Code Review Checklist" \
    "$ID_PERFORMANCE" "Performance"

append_voir_aussi "$ID_PYTHON" \
    "$ID_API_DESIGN" "API Design" \
    "$ID_TESTING" "Guidelines Testing" \
    "$ID_CODE_REVIEW" "Code Review Checklist"

append_voir_aussi "$ID_TESTING" \
    "$ID_TYPESCRIPT" "TypeScript" \
    "$ID_PYTHON" "Python" \
    "$ID_CODE_REVIEW" "Code Review Checklist" \
    "$ID_GIT_WORKFLOW" "Git Workflow"

append_voir_aussi "$ID_PERFORMANCE" \
    "$ID_DOCKER" "Docker" \
    "$ID_POSTGRESQL" "PostgreSQL" \
    "$ID_TYPESCRIPT" "TypeScript" \
    "$ID_ALERTING" "Alerting Rules"

# --- Engineering : tech docs ---
append_voir_aussi "$ID_DOCKER" \
    "$ID_DEPLOY" "Deploy Standard" \
    "$ID_STACK_OVERVIEW" "Stack Overview" \
    "$ID_PERFORMANCE" "Performance"

append_voir_aussi "$ID_POSTGRESQL" \
    "$ID_DB_MIGRATION" "Database Migration" \
    "$ID_STACK_OVERVIEW" "Stack Overview" \
    "$ID_PERFORMANCE" "Performance"

append_voir_aussi "$ID_OLLAMA" \
    "$ID_STACK_OVERVIEW" "Stack Overview" \
    "$ID_MEM0" "Mem0 API" \
    "$ID_CHROMA" "Chroma"

append_voir_aussi "$ID_CHROMA" \
    "$ID_MEM0" "Mem0 API" \
    "$ID_OLLAMA" "Ollama" \
    "$ID_STACK_OVERVIEW" "Stack Overview"

append_voir_aussi "$ID_MEM0" \
    "$ID_CHROMA" "Chroma" \
    "$ID_OLLAMA" "Ollama" \
    "$ID_STACK_OVERVIEW" "Stack Overview" \
    "$ID_GUIDE_AGENT" "Guide Agent"

log "  engineering : 9 docs lies"

# --- Design System ---
append_voir_aussi "$ID_COLORS" \
    "$ID_TYPOGRAPHY" "Typographie" \
    "$ID_SPACING" "Spacing" \
    "$ID_A11Y" "Accessibilite"

append_voir_aussi "$ID_TYPOGRAPHY" \
    "$ID_COLORS" "Couleurs" \
    "$ID_SPACING" "Spacing" \
    "$ID_A11Y" "Accessibilite"

append_voir_aussi "$ID_SPACING" \
    "$ID_COLORS" "Couleurs" \
    "$ID_TYPOGRAPHY" "Typographie"

append_voir_aussi "$ID_A11Y" \
    "$ID_COLORS" "Couleurs" \
    "$ID_TYPOGRAPHY" "Typographie" \
    "$ID_OWASP" "OWASP Top 10"

log "  design-system : 4 docs lies"

# --- Produit ---
append_voir_aussi "$ID_PRD_TPL" \
    "$ID_US_TPL" "Template User Story" \
    "$ID_DISCOVERY" "Product Discovery" \
    "$ID_API_DESIGN" "API Design"

append_voir_aussi "$ID_US_TPL" \
    "$ID_PRD_TPL" "Template PRD" \
    "$ID_DISCOVERY" "Product Discovery"

append_voir_aussi "$ID_DISCOVERY" \
    "$ID_PRD_TPL" "Template PRD" \
    "$ID_US_TPL" "Template User Story" \
    "$ID_TECH_COMP" "Tech Comparison"

log "  produit : 3 docs lies"

# --- Research ---
append_voir_aussi "$ID_TECH_COMP" \
    "$ID_POC_TPL" "Template POC" \
    "$ID_DISCOVERY" "Product Discovery" \
    "$ID_STACK_OVERVIEW" "Stack Overview"

append_voir_aussi "$ID_POC_TPL" \
    "$ID_TECH_COMP" "Tech Comparison" \
    "$ID_ADR_TEMPLATE" "Template ADR"

log "  research : 2 docs lies"

# --- Operations ---
append_voir_aussi "$ID_DEPLOY" \
    "$ID_DOCKER" "Docker" \
    "$ID_ALERTING" "Alerting Rules" \
    "$ID_POSTMORTEM" "Post-Mortem Template" \
    "$ID_GIT_WORKFLOW" "Git Workflow"

append_voir_aussi "$ID_DB_MIGRATION" \
    "$ID_POSTGRESQL" "PostgreSQL" \
    "$ID_DEPLOY" "Deploy Standard" \
    "$ID_POSTMORTEM" "Post-Mortem Template"

append_voir_aussi "$ID_POSTMORTEM" \
    "$ID_ALERTING" "Alerting Rules" \
    "$ID_DEPLOY" "Deploy Standard"

append_voir_aussi "$ID_ALERTING" \
    "$ID_DEPLOY" "Deploy Standard" \
    "$ID_POSTMORTEM" "Post-Mortem Template" \
    "$ID_PERFORMANCE" "Performance"

log "  operations : 4 docs lies"

# --- Security ---
append_voir_aussi "$ID_OWASP" \
    "$ID_AUTH_POL" "Politique Auth" \
    "$ID_DEPS" "Gestion Dependances" \
    "$ID_AUDIT_TPL" "Template Audit" \
    "$ID_A11Y" "Accessibilite"

append_voir_aussi "$ID_AUTH_POL" \
    "$ID_OWASP" "OWASP Top 10" \
    "$ID_API_DESIGN" "API Design" \
    "$ID_AUDIT_TPL" "Template Audit"

append_voir_aussi "$ID_DEPS" \
    "$ID_OWASP" "OWASP Top 10" \
    "$ID_DOCKER" "Docker" \
    "$ID_AUDIT_TPL" "Template Audit"

append_voir_aussi "$ID_AUDIT_TPL" \
    "$ID_OWASP" "OWASP Top 10" \
    "$ID_AUTH_POL" "Politique Auth" \
    "$ID_DEPS" "Gestion Dependances"

log "  security : 4 docs lies"

# --- Global : onboarding ---
append_voir_aussi "$ID_GUIDE_AGENT" \
    "$ID_CHEATSHEET" "API Cheatsheet" \
    "$ID_MEM0" "Mem0 API" \
    "$ID_STACK_OVERVIEW" "Stack Overview" \
    "$ID_GIT_WORKFLOW" "Git Workflow"

append_voir_aussi "$ID_CHEATSHEET" \
    "$ID_GUIDE_AGENT" "Guide Agent" \
    "$ID_MEM0" "Mem0 API" \
    "$ID_STACK_OVERVIEW" "Stack Overview"

log "  global : 2 docs lies"

# --- Nouveaux docs : liens croises ---
append_voir_aussi "$ID_AGENT_COMM" \
    "$ID_STACK_OVERVIEW" "Stack Overview" \
    "$ID_API_DESIGN" "API Design" \
    "$ID_WORKFLOW_EXEC" "Workflow Execution" \
    "$ID_GUIDE_AGENT" "Guide Agent"

append_voir_aussi "$ID_WORKFLOW_EXEC" \
    "$ID_STACK_OVERVIEW" "Stack Overview" \
    "$ID_AGENT_COMM" "Communication Agents" \
    "$ID_API_DESIGN" "API Design"

append_voir_aussi "$ID_AGENT_TESTING" \
    "$ID_TESTING" "Guidelines Testing" \
    "$ID_FRESHNESS" "Knowledge Freshness" \
    "$ID_MEM0" "Mem0 API"

append_voir_aussi "$ID_RAG_STRATEGY" \
    "$ID_CHROMA" "Chroma" \
    "$ID_MEM0" "Mem0 API" \
    "$ID_OLLAMA" "Ollama"

append_voir_aussi "$ID_DISASTER_REC" \
    "$ID_DEPLOY" "Deploy Standard" \
    "$ID_ALERTING" "Alerting Rules" \
    "$ID_DOCKER" "Docker" \
    "$ID_POSTGRESQL" "PostgreSQL"

append_voir_aussi "$ID_FRESHNESS" \
    "$ID_ALERTING" "Alerting Rules" \
    "$ID_AGENT_TESTING" "Agent Testing" \
    "$ID_MEM0" "Mem0 API"

append_voir_aussi "$ID_COST_ANALYSIS" \
    "$ID_AGENT_METRICS" "Agent Metrics" \
    "$ID_ALERTING" "Alerting Rules"

append_voir_aussi "$ID_AGENT_METRICS" \
    "$ID_COST_ANALYSIS" "Cost Analysis" \
    "$ID_ALERTING" "Alerting Rules" \
    "$ID_FRESHNESS" "Knowledge Freshness"

log "  nouveaux docs : 8 docs lies"

log "Liens inter-documents crees (~90 liens, graph view operationnel)"

# ============================================
# RESUME
# ============================================

echo ""
echo "========================================"
log "SiYuan bootstrap termine."
echo "========================================"
echo ""
echo "8 notebooks crees :"
echo "  architecture   — ADRs, conventions, stack, patterns"
echo "  engineering    — Guidelines code, tech docs, best practices"
echo "  produit        — PRDs, specs, user stories, metrics"
echo "  design-system  — Tokens, composants, accessibilite"
echo "  research       — Veille, benchmarks, POCs, comparatifs"
echo "  operations     — Runbooks, incidents, monitoring, deploys"
echo "  security       — OWASP, politiques, audits, compliance"
echo "  global         — Dashboards, onboarding, digests, journal"
echo ""
echo "Contenu pre-peuple : ~48 documents (lus depuis docs/)"
echo "Attributs custom : custom-project, custom-type, custom-status"
echo "Daily notes : configurees sur 'global'"
echo "Registre projets : global/projects/registry"
echo "Dashboard : global/dashboards/all-projects"
echo ""
echo "Pour initialiser un nouveau projet :"
echo "  bash bootstrap-project.sh <slug> [paperclip-id] [lead-agent] [description]"
echo ""
if [ "$RESET" = true ]; then
    echo "(Mode --reset utilise : notebooks recrees de zero)"
    echo ""
fi
