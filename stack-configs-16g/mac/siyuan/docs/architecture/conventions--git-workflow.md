# Convention Git Workflow

## Branching Strategy : GitHub Flow

```
main (production-ready)
  └── feature/ISSUE-123-add-auth
  └── fix/ISSUE-456-login-crash
  └── chore/update-dependencies
```

### Regles

| Regle | Detail |
|-------|--------|
| Branche principale | `main` — toujours deployable |
| Branches de travail | Prefixe `feature/`, `fix/`, `chore/`, `docs/`, `refactor/` |
| Nommage | `type/ISSUE-NNN-description-courte` (kebab-case) |
| Duree de vie | Max 3 jours, idealement < 1 jour |
| Merge | Via Pull Request uniquement, jamais de push direct sur `main` |
| Strategie merge | **Squash merge** pour features, **merge commit** pour releases |

## Conventional Commits

Format obligatoire pour tous les messages de commit :

```
<type>(<scope>): <description>

[body]

[footer]
```

### Types autorises

| Type | Usage | SemVer |
|------|-------|--------|
| `feat` | Nouvelle fonctionnalite | MINOR |
| `fix` | Correction de bug | PATCH |
| `docs` | Documentation uniquement | - |
| `style` | Formatage (pas de changement de code) | - |
| `refactor` | Restructuration sans changement fonctionnel | - |
| `perf` | Amelioration de performance | PATCH |
| `test` | Ajout ou correction de tests | - |
| `chore` | Maintenance (deps, CI, config) | - |
| `ci` | Changements CI/CD | - |
| `build` | Changements systeme de build | - |
| `revert` | Annulation d'un commit precedent | - |

### Breaking Changes

```
feat(api)!: change authentication to OAuth2

BREAKING CHANGE: The /auth endpoint now requires OAuth2 tokens
instead of API keys. All clients must update their auth flow.
```

Le `!` apres le scope ET le footer `BREAKING CHANGE:` declenchent un bump MAJOR.

### Exemples

```bash
# Feature
feat(auth): add JWT refresh token rotation

# Bug fix
fix(api): prevent SQL injection in search endpoint

Closes #456

# Chore
chore(deps): upgrade TypeScript to 5.4

# Multi-line
feat(dashboard): add real-time metrics widget

Implement WebSocket-based live metrics for:
- CPU/memory usage
- Request throughput
- Error rates

Reviewed-by: cto
Refs: #789
```

## Pull Request Workflow

### 1. Creer la branche

```bash
git checkout main
git pull origin main
git checkout -b feature/ISSUE-123-add-auth
```

### 2. Commits atomiques

- Chaque commit = **un seul changement logique**
- Commiter souvent, pas a la fin
- Les tests doivent passer a chaque commit

### 3. Pull Request

**Titre** : reprend le format conventional commit
```
feat(auth): add JWT refresh token rotation
```

**Corps** :
```markdown
## Contexte
Pourquoi ce changement est necessaire.

## Changements
- Liste des modifications principales
- Impact sur l'existant

## Tests
- [ ] Tests unitaires ajoutés
- [ ] Tests d'integration passes
- [ ] Teste manuellement sur staging

## Screenshots (si UI)
```

### 4. Code Review

- **Minimum 1 reviewer** avant merge
- L'auteur ne merge pas sa propre PR
- Repondre a TOUS les commentaires avant merge
- Utiliser la checklist de code review (voir doc dediee)

### 5. Merge

```bash
# Squash merge (default pour features)
git merge --squash feature/ISSUE-123-add-auth

# Apres merge, supprimer la branche
git branch -d feature/ISSUE-123-add-auth
git push origin --delete feature/ISSUE-123-add-auth
```

## Tags & Releases

```bash
# Versioning semantique
git tag -a v1.2.0 -m "feat: add dashboard metrics"
git push origin v1.2.0
```

| Version | Quand |
|---------|-------|
| MAJOR (1.0.0 → 2.0.0) | Breaking changes |
| MINOR (1.0.0 → 1.1.0) | Nouvelles features |
| PATCH (1.0.0 → 1.0.1) | Bug fixes |

## Git Hooks recommandes

```bash
# pre-commit : lint + format
npx lint-staged

# commit-msg : valider conventional commit
npx commitlint --edit $1

# pre-push : tests
npm test
```

## Regles pour les agents IA

1. **Toujours creer une branche** — jamais de commit direct sur main
2. **Un commit par changement logique** — pas de commits "WIP" ou "fix fix fix"
3. **Message de commit = documentation** — futur lecteur doit comprendre le pourquoi
4. **PR description obligatoire** — contexte, changements, tests, impact
5. **Attendre la review** — ne jamais force-merge sauf urgence validee par CTO
