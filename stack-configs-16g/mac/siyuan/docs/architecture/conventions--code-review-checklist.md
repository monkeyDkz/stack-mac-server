# Checklist Code Review

*Base : Google Engineering Practices — How to do a code review*

## Principes de la review

1. **La review ameliore la qualite globale du code** — chaque CL (changelist) doit laisser la codebase en meilleur etat
2. **Vitesse de review** — repondre dans les 24h max, idealement dans l'heure
3. **Bienveillance** — critiquer le code, pas la personne
4. **Pedagogie** — expliquer le "pourquoi" derriere chaque commentaire

## Checklist pour le reviewer

### Fonctionnel

- [ ] Le code fait ce que la tache / US / ticket demande
- [ ] Les edge cases sont identifies et geres (null, vide, overflow, concurrent)
- [ ] Les erreurs sont traitees correctement (pas de `catch` silencieux)
- [ ] Les messages d'erreur sont clairs et actionnables
- [ ] Le comportement en cas de timeout / indisponibilite est gere
- [ ] Les migrations de donnees sont backward-compatible

### Design & Architecture

- [ ] Le changement est au bon endroit dans l'architecture (layer, module)
- [ ] Pas de violation des principes SOLID
- [ ] Les abstractions sont justifiees (pas de sur-ingenierie)
- [ ] Les responsabilites sont bien separees (un module = un role)
- [ ] Les dependances vont dans le bon sens (pas de dependance cyclique)
- [ ] Le design est coherent avec les patterns existants du projet

### Nommage & Lisibilite

- [ ] Les noms de variables / fonctions / classes sont descriptifs
- [ ] Les noms suivent les conventions du projet (camelCase TS, snake_case Python)
- [ ] Pas d'abbreviations obscures (`usrMgr` → `userManager`)
- [ ] Les booleans sont prefixes : `is`, `has`, `can`, `should`
- [ ] Les fonctions sont nommees avec un verbe d'action
- [ ] Le code est auto-documentant (pas besoin de commentaire pour le "quoi")

### Complexite

- [ ] Les fonctions font < 30 lignes (idealement < 20)
- [ ] Les fichiers font < 300 lignes
- [ ] La complexite cyclomatique est raisonnable (< 10 par fonction)
- [ ] Pas de nesting profond (> 3 niveaux = refactorer)
- [ ] Pas de valeurs magiques (utiliser des constantes nommees)
- [ ] Les conditions complexes sont extraites dans des fonctions nommees

```typescript
// MAL
if (user.role === 'admin' && user.lastLogin > thirtyDaysAgo && !user.suspended) { ... }

// BIEN
const isActiveAdmin = (user: User): boolean =>
  user.role === 'admin' &&
  user.lastLogin > thirtyDaysAgo &&
  !user.suspended;

if (isActiveAdmin(user)) { ... }
```

### Tests

- [ ] Tests unitaires pour la logique metier ajoutee/modifiee
- [ ] Tests d'integration pour les endpoints API
- [ ] Tests des cas d'erreur et edge cases
- [ ] Coverage >= 80% sur le code modifie
- [ ] Tests deterministes (pas de dependance a l'horloge, au random, au reseau)
- [ ] Test naming : `should [expected behavior] when [condition]`
- [ ] Pattern AAA respecte (Arrange-Act-Assert)

### Securite

- [ ] Pas d'injection SQL (queries parametrees uniquement)
- [ ] Pas de XSS (sanitization des inputs utilisateur)
- [ ] Pas de secrets en dur dans le code (utiliser env vars)
- [ ] Validation des inputs avec schema (zod, pydantic)
- [ ] Verification auth/authz sur chaque endpoint
- [ ] Pas de donnees sensibles dans les logs
- [ ] CORS configure correctement
- [ ] Rate limiting sur les endpoints publics

### Performance

- [ ] Pas de requete N+1 (utiliser JOIN, includes, dataloader)
- [ ] Pagination sur toutes les listes
- [ ] Index DB sur les colonnes filtrees/triees
- [ ] Pas de chargement inutile de donnees (SELECT specifique, pas `SELECT *`)
- [ ] Timeouts sur les appels externes
- [ ] Cache utilise la ou c'est pertinent

### Documentation

- [ ] Types/interfaces documentes (JSDoc) si complexes
- [ ] README/changelog mis a jour si changement d'API publique
- [ ] ADR cree si decision architecturale significative
- [ ] Commentaires sur la logique non evidente (le "pourquoi", pas le "quoi")

## Checklist pour l'auteur (avant de soumettre)

- [ ] La PR a un titre au format conventional commit
- [ ] La description explique le contexte, les changements et comment tester
- [ ] Le code compile et les tests passent localement
- [ ] Le linter ne produit aucune erreur
- [ ] Les fichiers non pertinents sont exclus (`.env`, `node_modules`, etc.)
- [ ] Les commits sont atomiques et bien nommes
- [ ] Self-review effectuee (relire son propre diff avant de soumettre)

## Niveaux d'approbation

| Niveau | Contexte | Reviewers requis |
|--------|----------|:----------------:|
| Standard | Feature, fix, refactor | 1 reviewer |
| Sensible | Auth, paiement, securite | 2 reviewers dont CTO |
| Architecture | Nouveau service, migration, breaking change | CTO + Lead concerne |
| Hotfix | Incident P0 en cours | 1 reviewer (post-merge review si urgence) |

## Vocabulaire de review

| Prefixe | Signification | Action attendue |
|---------|---------------|-----------------|
| `nit:` | Detail mineur, style | Optionnel a corriger |
| `suggestion:` | Proposition d'amelioration | A considerer, pas bloquant |
| `question:` | Besoin de clarification | Repondre avant merge |
| `issue:` | Probleme a corriger | Bloquant, doit etre corrige |
| `praise:` | Bon travail | Aucune, encouragement |

## Anti-patterns de review

- **Rubber stamping** : approuver sans lire → interdit
- **Gatekeeping** : bloquer pour des preferences personnelles → utiliser `nit:`
- **Scope creep** : demander des changements hors scope → creer un ticket separe
- **Drive-by review** : commenter sans approuver ni rejeter → toujours conclure
