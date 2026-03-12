# Politique de Gestion des Dependances

*Audit, lockfiles, CVE monitoring, supply chain security*

## Principes

1. **Moins de dependances = moins de surface d'attaque** — chaque dep est un risque
2. **Lock files = reproducibilite** — meme version partout, toujours
3. **Zero CVE critique en production** — jamais de compromis
4. **Automatiser l'audit** — pas de process manuel qui sera oublie

## Regles de base

| Regle | Detail | Frequence |
|-------|--------|-----------|
| Lock files commites | `pnpm-lock.yaml`, `poetry.lock` | A chaque modification |
| Audit des CVE | `pnpm audit`, `pip-audit` | Hebdomadaire + CI |
| Zero CVE critique | Aucune en production | Permanent |
| CVE haute | Corrigee dans les 72h | Quand detectee |
| CVE moyenne | Corrigee au prochain sprint | Sprint planning |
| CVE basse | Evaluee et priorisee | Mensuel |
| Mise a jour mineure | Deps a jour | Mensuelle |
| Mise a jour majeure | Evaluation d'impact avant | Quand disponible |

## Audit des dependances

### Node.js (pnpm)

```bash
# Audit des vulnerabilites
pnpm audit

# Audit avec severite minimum
pnpm audit --audit-level=high

# Voir les packages obsoletes
pnpm outdated

# Mettre a jour les mineurs/patchs
pnpm update

# Mettre a jour un package specifique (majeur)
pnpm update package-name --latest

# Verifier la taille du bundle (frontend)
npx bundlephobia-cli package-name
```

### Python (pip / poetry)

```bash
# Audit avec pip-audit
pip-audit

# Audit avec safety
safety check

# Voir les packages obsoletes
pip list --outdated

# Avec poetry
poetry show --outdated
poetry update
```

### Docker images

```bash
# Audit avec Docker Scout
docker scout cves IMAGE_NAME

# Audit avec trivy
trivy image IMAGE_NAME

# Verifier les images de base
docker scout recommendations IMAGE_NAME
```

## Integration CI

```yaml
# .github/workflows/security.yml
name: Security Audit

on:
  schedule:
    - cron: '0 8 * * 1'  # Chaque lundi a 8h
  pull_request:
    branches: [main]

jobs:
  audit-node:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - run: pnpm install --frozen-lockfile
      - run: pnpm audit --audit-level=high
        continue-on-error: false  # Fail le CI si CVE haute

  audit-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - run: pip install pip-audit
      - run: pip-audit -r requirements.txt

  audit-docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker scout cves --exit-code --only-severity critical,high .
```

## Procedure d'ajout de dependance

Avant d'ajouter une nouvelle dependance :

### 1. Evaluer la necessite

- [ ] Peut-on l'implementer simplement sans dependance ? (< 50 lignes)
- [ ] Existe-t-il deja une dependance dans le projet qui fait ca ?
- [ ] Est-ce que la stdlib/builtins couvre le besoin ?

### 2. Evaluer la qualite

| Critere | Seuil minimum | Comment verifier |
|---------|:-------------:|-----------------|
| Dernier commit | < 6 mois | GitHub |
| Stars GitHub | > 500 | GitHub |
| Telecharges / semaine | > 5000 | npm / PyPI |
| CVE connues | 0 critique, 0 haute | `npm audit`, Snyk |
| Mainteneurs actifs | >= 2 | GitHub |
| Licence compatible | MIT, Apache 2.0, BSD, ISC | `package.json` / `setup.py` |
| Types TypeScript | Inclus ou @types/ disponible | npm |
| Taille du bundle | < 50KB gzipped (frontend) | bundlephobia.com |

### 3. Licences acceptees

| Licence | Statut | Notes |
|---------|:------:|-------|
| MIT | OK | Aucune restriction |
| Apache 2.0 | OK | Mention dans les notices |
| BSD (2/3 clause) | OK | Aucune restriction |
| ISC | OK | Equivalent MIT |
| MPL 2.0 | OK avec attention | Fichiers modifies restent MPL |
| LGPL | Attention | OK si linkage dynamique |
| GPL | Interdit | Contamination virale |
| AGPL | Interdit | Contamination reseau |
| SSPL | Interdit | |
| Unlicensed | Interdit | Pas de licence = tous droits reserves |

```bash
# Verifier les licences de toutes les deps
npx license-checker --summary
npx license-checker --failOn "GPL;AGPL"

# Python
pip-licenses --format=table
```

### 4. Documenter le choix

```bash
# Sauvegarder dans Mem0
curl -X POST http://host.docker.internal:8050/memories \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Ajout de zod@3.22 pour la validation de schemas TypeScript. Alternatives evaluees: joi (trop lourd), yup (moins bon TS support). Licence: MIT. Bundle: 13KB gzipped.",
    "user_id": "cto",
    "metadata": {
      "type": "decision",
      "project": "PROJECT_SLUG",
      "confidence": "tested"
    }
  }'
```

## Supply chain security

### Menaces connues

| Menace | Description | Mitigation |
|--------|-------------|------------|
| Typosquatting | Package au nom similaire malveillant | Verifier le nom exact |
| Dependency confusion | Package prive vs public | Scope @company/ + registry prive |
| Compromised maintainer | Mainteneur pirate | Lock files + audit |
| Malicious update | Version patchee avec malware | Lock files + review des diffs |
| Install scripts | `postinstall` malveillant | `pnpm install --ignore-scripts` puis review |

### Bonnes pratiques

```bash
# Utiliser des lock files (toujours)
pnpm install --frozen-lockfile  # CI
poetry install --no-update       # CI

# Verifier l'integrite des packages (npm/pnpm)
# Le lockfile contient les hashes SHA-512
# pnpm verifie automatiquement

# Limiter les install scripts
# .npmrc
ignore-scripts=true
# Puis autoriser au cas par cas

# Epingler les versions exactes en production
# package.json
"dependencies": {
  "express": "4.18.2"       // Exact, pas "^4.18.2"
}
```

## Renovate / Dependabot

### Configuration Renovate recommandee

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 8am on Monday"],
  "labels": ["dependencies"],
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"]
  },
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true,
      "automergeType": "branch"
    },
    {
      "matchUpdateTypes": ["minor"],
      "automerge": false,
      "groupName": "minor updates"
    },
    {
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["breaking-change"]
    }
  ]
}
```

## Checklist periodique (mensuelle)

- [ ] `pnpm audit` : 0 vulnerabilite haute ou critique
- [ ] `pip-audit` : 0 vulnerabilite haute ou critique
- [ ] `docker scout cves` : 0 critique sur les images en prod
- [ ] Lock files a jour et commites
- [ ] Renovate/Dependabot PRs reviewees et mergees
- [ ] Licences verifiees (`npx license-checker`)
- [ ] Deps inutilisees supprimees (`npx depcheck`)
