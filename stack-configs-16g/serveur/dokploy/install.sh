#!/bin/bash
# ============================================
# DOKPLOY — Installation sur le host (1 commande)
# ============================================
# Usage : chmod +x install.sh && ./install.sh
#
# Dokploy utilise Docker Swarm + PostgreSQL interne.
# Installé sur le host (comme NetBird), pas dans stack-network.
# Dashboard : https://deploy.home (Caddy → localhost:3000)
# ============================================

set -euo pipefail

if ! command -v docker &> /dev/null; then
    echo "Docker non installé. Lancer d'abord la Phase 0."
    exit 1
fi

echo "Installation de Dokploy (Swarm + PostgreSQL interne)..."
curl -sSL https://dokploy.com/install.sh | sh

echo ""
echo "Dokploy installé -> http://localhost:3000"
echo "Crée ton compte admin au premier accès web."
