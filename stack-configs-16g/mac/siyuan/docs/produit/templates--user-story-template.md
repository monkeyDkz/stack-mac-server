# User Story: [Titre court et descriptif]

## Format standard

> En tant que **[persona / role]**,
> je veux **[action / fonctionnalite]**
> pour **[benefice / valeur business]**.

### Exemple

> En tant que **developpeur backend**,
> je veux **voir les logs structures de chaque requete API**
> pour **diagnostiquer rapidement les erreurs en production**.

---

## Criteres INVEST

Chaque User Story DOIT respecter ces 6 criteres :

| Critere | Description | Check |
|---------|-------------|:-----:|
| **I**ndependante | Peut etre developpee et deployee seule | [ ] |
| **N**egociable | Les details peuvent etre ajustes avec le dev | [ ] |
| **V**alorisable | Apporte de la valeur a l'utilisateur final | [ ] |
| **E**stimable | L'equipe peut estimer la complexite | [ ] |
| **S**mall (petite) | Realisable en 1-3 jours max | [ ] |
| **T**estable | On peut ecrire des criteres d'acceptation clairs | [ ] |

Si un critere n'est pas rempli, la story doit etre retravaillee ou decoupee.

## Criteres d'acceptation (format Gherkin)

### Scenario 1 : [Nom du scenario principal — happy path]

```gherkin
Given [contexte initial / precondition]
  And [contexte additionnel si necessaire]
When [action effectuee par l'utilisateur]
  And [action complementaire si necessaire]
Then [resultat attendu / observable]
  And [consequence additionnelle]
```

### Scenario 2 : [Cas d'erreur]

```gherkin
Given [contexte]
When [action qui provoque une erreur]
Then [message d'erreur affiche]
  And [etat du systeme preserve]
```

### Scenario 3 : [Cas limite]

```gherkin
Given [contexte edge case]
When [action]
Then [comportement attendu dans ce cas limite]
```

### Exemples concrets

```gherkin
Feature: Recherche de memoires agent

  Scenario: Recherche avec resultats
    Given l'agent "cto" a 15 memoires actives
    When je recherche "architecture decision" avec limit 5
    Then je recois exactement 5 resultats
      And chaque resultat a un score de relevance > 0.5
      And les resultats sont tries par relevance decroissante

  Scenario: Recherche sans resultats
    Given l'agent "cto" a 15 memoires actives
    When je recherche "sujet inexistant xyz"
    Then je recois une liste vide
      And le status HTTP est 200 (pas 404)

  Scenario: Recherche avec filtres invalides
    Given l'agent "cto" a 15 memoires actives
    When je recherche avec un filtre "type" non reconnu
    Then je recois une erreur 422
      And le message indique les types valides
```

## Definition of Done (DoD)

La story est "Done" quand TOUS ces criteres sont remplis :

### Code
- [ ] Code ecrit et pousse sur la branche feature
- [ ] Code review approuvee (minimum 1 reviewer)
- [ ] Pas de `any` TypeScript ou `# type: ignore` Python non justifie
- [ ] Linter passe sans erreur ni warning

### Tests
- [ ] Tests unitaires ecrits (coverage >= 80% sur le code modifie)
- [ ] Tests d'integration pour les endpoints API
- [ ] Tous les criteres d'acceptation Gherkin verifiables par un test
- [ ] Tests passes en CI

### Documentation
- [ ] API documentee (OpenAPI / JSDoc / docstring)
- [ ] ADR cree si decision architecturale
- [ ] Memoire Mem0 sauvegardee si apprentissage significatif

### Deploiement
- [ ] Deploye en staging et verifie
- [ ] Smoke tests manuels passes
- [ ] Pas de regression sur les metriques de performance
- [ ] Deploye en production

### Validation
- [ ] QA valide (ou auto-valide si tests suffisants)
- [ ] Paperclip task mise a jour (status: done)

## Sizing (estimation de complexite)

| Taille | Points | Effort approximatif | Exemples |
|:------:|:------:|:-------------------:|----------|
| **XS** | 1 | < 2h | Fix typo, changer un label, ajouter un index |
| **S** | 2 | 2h - 4h | Ajouter un champ, nouveau endpoint CRUD simple |
| **M** | 3 | 1 - 2 jours | Nouvelle feature avec logique metier |
| **L** | 5 | 3 - 5 jours | Feature complexe, integration service externe |
| **XL** | 8 | > 5 jours | **A decouper** — trop gros pour une story |

### Regles de sizing

- Si la story est **XL**, elle doit etre decoupee en stories plus petites
- En cas de doute entre deux tailles, choisir la plus grande
- L'estimation inclut le code, les tests, la review et le deploy
- Ne PAS estimer le temps de decouverte/design (c'est un spike separe)

## Hierarchie Epic / Story / Task

```
Epic (theme strategique, dure plusieurs sprints)
  └── User Story (valeur utilisateur, 1-3 jours)
        └── Task (travail technique, < 4h)
        └── Task
  └── User Story
        └── Task
        └── Task
        └── Task
  └── Spike (exploration technique, timebox 1-2 jours)
```

### Definitions

| Niveau | Definition | Exemple |
|--------|-----------|---------|
| **Epic** | Theme strategique, objectif business large | "Systeme d'authentification complet" |
| **User Story** | Increment de valeur utilisateur | "L'utilisateur peut se connecter avec email/password" |
| **Task** | Travail technique pour realiser la story | "Creer le endpoint POST /auth/login" |
| **Spike** | Exploration technique timeboxee | "Evaluer JWT vs sessions pour notre cas d'usage" |
| **Bug** | Correction d'un comportement incorrect | "Le login echoue avec des emails en majuscules" |

### Regles de la hierarchie

- Une **Epic** contient 3-8 User Stories
- Une **User Story** contient 1-5 Tasks
- Un **Task** ne depasse jamais 4h
- Un **Spike** est toujours timebox (max 2 jours) et produit un ADR ou une decision

## Template de Paperclip issue

```
Titre: [US] [Titre court de la story]

---

**Story**: En tant que [persona], je veux [action] pour [benefice].

**Criteres d'acceptation**:
- [ ] [AC 1]
- [ ] [AC 2]
- [ ] [AC 3]

**Taille**: [XS/S/M/L]
**Epic**: [Nom de l'epic]
**Priorite**: [Must/Should/Could]
**Agent**: [agent assigne]

**Notes techniques**:
[Indications pour le developpeur, contraintes, dependances]
```

## Metadata

- Agent : [CPO]
- Date : YYYY-MM-DD
- Confiance : validated
- Paperclip Task : PAPER-XX
