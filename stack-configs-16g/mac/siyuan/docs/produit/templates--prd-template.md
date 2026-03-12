# PRD: [Nom de la feature]

## Resume executif

[1-2 phrases : quel probleme on resout et quelle solution on propose]

**Auteur** : [Agent / Personne]
**Date** : YYYY-MM-DD
**Statut** : Draft | Review | Approved | In Progress | Shipped
**Paperclip Task** : PAPER-XX

---

## 1. Probleme

### Description du probleme

[Description claire du probleme utilisateur ou business. Etre factuel, baser sur des donnees.]

### Evidence

| Source | Donnee | Date |
|--------|--------|------|
| [Feedback utilisateur / analytics / support] | [Chiffre ou citation] | [Date] |
| [Observation / metriques] | [Chiffre ou citation] | [Date] |

### Impact de ne rien faire

[Que se passe-t-il si on ne resout pas ce probleme ? Quantifier si possible.]

## 2. Objectifs et metriques

### Objectifs (SMART)

1. **[Objectif 1]** — mesurable par [metrique], cible : [valeur], deadline : [date]
2. **[Objectif 2]** — mesurable par [metrique], cible : [valeur], deadline : [date]

### Non-objectifs (explicitement hors scope)

- [Ce qu'on ne fait PAS dans cette iteration]
- [Fonctionnalite tentante mais reportee]
- [Optimisation prematuree a eviter]

### Metriques de succes

| Metrique | Baseline actuelle | Cible | Methode de mesure |
|----------|:-----------------:|:-----:|-------------------|
| [metrique 1] | [valeur] | [valeur] | [outil / requete] |
| [metrique 2] | [valeur] | [valeur] | [outil / requete] |
| [metrique North Star] | [valeur] | [valeur] | [outil / requete] |

## 3. Personas cibles

### Persona 1 : [Nom]

- **Role** : [description]
- **Probleme principal** : [douleur specifique]
- **Comportement actuel** : [comment il contourne le probleme aujourd'hui]
- **Attente** : [ce qu'il espere de la solution]

### Persona 2 : [Nom]

- **Role** : [description]
- **Probleme principal** : [douleur specifique]
- **Comportement actuel** : [workaround]
- **Attente** : [ce qu'il espere]

## 4. User Stories

### Epopee : [Nom de l'epic]

| ID | User Story | Priorite | Taille |
|----|-----------|:--------:|:------:|
| US-1 | En tant que [persona], je veux [action] pour [benefice] | Must | M |
| US-2 | En tant que [persona], je veux [action] pour [benefice] | Must | S |
| US-3 | En tant que [persona], je veux [action] pour [benefice] | Should | L |
| US-4 | En tant que [persona], je veux [action] pour [benefice] | Could | S |

### Criteres d'acceptation (US principales)

**US-1** :
- [ ] [Critere verifiable 1]
- [ ] [Critere verifiable 2]
- [ ] [Critere verifiable 3]

**US-2** :
- [ ] [Critere verifiable 1]
- [ ] [Critere verifiable 2]

## 5. Exigences fonctionnelles

### Flux utilisateur principal

```
[Etape 1 : Entree] → [Etape 2 : Action] → [Etape 3 : Resultat] → [Etape 4 : Confirmation]
```

### Regles metier

| ID | Regle | Exemple |
|----|-------|---------|
| R-1 | [Regle metier 1] | [Cas concret] |
| R-2 | [Regle metier 2] | [Cas concret] |
| R-3 | [Regle metier 3] | [Cas concret] |

### Etats et transitions

```
Draft → Submitted → In Review → Approved → Published
                  → Rejected → Draft (retour)
```

## 6. Exigences non-fonctionnelles

| Categorie | Exigence | Seuil |
|-----------|----------|-------|
| Performance | Temps de reponse API | < 200ms p95 |
| Performance | Temps de chargement page | < 2s LCP |
| Scalabilite | Utilisateurs simultanes | [N] |
| Disponibilite | Uptime | 99.9% |
| Securite | Authentification | JWT + MFA optionnel |
| Securite | Donnees sensibles | Chiffrees au repos |
| Accessibilite | WCAG | Niveau AA |
| Localisation | Langues | FR, EN |

## 7. UX / Wireframes

### Ecrans principaux

[Description textuelle de chaque ecran ou lien vers les maquettes]

**Ecran 1 : [Nom]**
- Layout : [description]
- Elements cles : [liste]
- Interactions : [liste]

**Ecran 2 : [Nom]**
- Layout : [description]
- Elements cles : [liste]
- Interactions : [liste]

### Cas limites UI

- Etat vide (aucune donnee)
- Etat d'erreur
- Etat de chargement
- Tres peu de donnees (1 item)
- Beaucoup de donnees (1000+ items)

## 8. Contraintes techniques

- [Contrainte 1 : ex. "doit fonctionner avec la stack existante (PostgreSQL, Docker)"]
- [Contrainte 2 : ex. "pas de nouvelle dependance lourde (< 50KB gzipped)"]
- [Contrainte 3 : ex. "compatible avec l'API Mem0 existante"]
- [Contrainte 4 : ex. "deploiement zero-downtime obligatoire"]

## 9. Timeline et phases

### Phase 1 : MVP — [estimation : X semaines]

- [ ] [Deliverable 1]
- [ ] [Deliverable 2]
- [ ] [Deliverable 3]
- **Gate** : [critere pour passer a la phase 2]

### Phase 2 : Ameliorations — [estimation : X semaines]

- [ ] [Deliverable 4]
- [ ] [Deliverable 5]
- **Gate** : [critere pour considerer la feature "done"]

### Phase 3 : Polish (optionnel) — [estimation : X semaines]

- [ ] [Optimisations, edge cases, nice-to-have]

## 10. Risques et mitigations

| Risque | Probabilite | Impact | Mitigation |
|--------|:-----------:|:------:|------------|
| [Risque technique 1] | Haute | Haut | [Plan B] |
| [Risque business 1] | Moyenne | Moyen | [Action preventive] |
| [Risque timeline 1] | Moyenne | Haut | [Scope reduction plan] |

## 11. Dependencies

| Dependance | Equipe/Agent | Status | Bloquant ? |
|------------|-------------|:------:|:----------:|
| [API endpoint X] | [Backend] | En cours | Oui |
| [Design maquettes] | [Design] | Fait | Non |
| [Migration DB] | [DevOps] | A faire | Oui |

## Metadata

- Agent : [CPO / agent auteur]
- Date : YYYY-MM-DD
- Confiance : hypothesis | tested | validated
- Mem0 ID : [id]
- Paperclip Task : PAPER-XX
- ADR lies : [liens vers ADRs pertinents]
