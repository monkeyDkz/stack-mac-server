# Process Product Discovery

*Base : Teresa Torres (Opportunity Solution Tree), Double Diamond, JTBD*

## Principes

1. **Decouvrir avant de delivrer** — comprendre le probleme avant de coder la solution
2. **Evidence-based** — chaque decision basee sur des donnees, pas des opinions
3. **Iterer rapidement** — valider vite, echouer tot, pivoter sans cout
4. **Continu** — la discovery n'est pas une phase, c'est un process permanent

## Double Diamond

```
    DECOUVRIR          DEFINIR          DEVELOPPER         DELIVRER
   (diverger)        (converger)       (diverger)        (converger)
       /\               /\               /\               /\
      /  \             /  \             /  \             /  \
     /    \           /    \           /    \           /    \
    / ESPACE \       / BON   \       / IDEES \       / BONNE \
   / PROBLEME \     / PROBLEME\     / SOLUTION\     / SOLUTION\
  /            \   /           \   /           \   /           \
```

### Diamant 1 : Comprendre le probleme

| Phase | Activites | Outils |
|-------|-----------|--------|
| Decouvrir | Interviews, observation, analytics | Guide d'interview, Umami |
| Definir | Synthese, personas, JTBD, problem statement | Affinity diagram, How Might We |

### Diamant 2 : Trouver la solution

| Phase | Activites | Outils |
|-------|-----------|--------|
| Developper | Ideation, prototypage, alternatives | Brainstorm, Crazy 8s, POC |
| Delivrer | Tests utilisateurs, MVP, mesure | Prototype, A/B test, metriques |

## Jobs To Be Done (JTBD)

### Format

> Quand [situation], je veux [motivation], pour [resultat attendu].

### Exemples

> Quand je commence ma journee de travail, je veux voir rapidement l'etat de tous les services, pour savoir s'il y a un probleme a traiter en priorite.

> Quand je fais une code review, je veux acceder aux conventions de l'equipe, pour verifier que le code respecte nos standards.

### Les 3 dimensions d'un Job

| Dimension | Question | Exemple |
|-----------|----------|---------|
| **Fonctionnel** | Que veut accomplir l'utilisateur ? | "Deployer mon service en production" |
| **Emotionnel** | Comment veut-il se sentir ? | "Confiant que rien ne va casser" |
| **Social** | Comment veut-il etre percu ? | "Fiable et professionnel aupres de l'equipe" |

## Opportunity Solution Tree (OST)

```
                    [Outcome desire]
                   /       |        \
          [Opportunite 1] [Opp 2]  [Opp 3]
          /     |     \
    [Sol A]  [Sol B]  [Sol C]
       |        |        |
  [Exp 1]   [Exp 2]  [Exp 3]
```

### Comment construire l'arbre

1. **Outcome** : metrique business qu'on veut impacter (ex: "reduire le temps de deploy de 30 min a 5 min")
2. **Opportunites** : problemes/besoins utilisateurs decouverts en interview
3. **Solutions** : au moins 3 idees par opportunite (eviter la premiere idee)
4. **Experiences** : petit test pour valider chaque solution (POC, prototype, interview)

### Regles

- Au moins 3 solutions par opportunite (forcer la creativite)
- Chaque solution doit etre testable en < 1 semaine
- Preferer les tests les moins couteux d'abord

## Techniques d'interview

### Guide d'interview (30 min)

```
1. CONTEXT (5 min)
   - Parle-moi de ton role / ta journee type
   - Quels outils utilises-tu au quotidien ?

2. STORY (15 min)
   - Raconte-moi la derniere fois que tu as [action liee au probleme]
   - Qu'est-ce qui etait le plus frustrant ?
   - Comment as-tu contourne le probleme ?
   - Combien de temps ca t'a pris ?

3. NEEDS (8 min)
   - Si tu avais une baguette magique, que changerais-tu ?
   - Qu'est-ce qui te ferait gagner le plus de temps ?
   - Qu'est-ce qui te donne le plus de stress ?

4. WRAP-UP (2 min)
   - Y a-t-il quelque chose d'important qu'on n'a pas aborde ?
   - Qui d'autre je devrais interroger sur ce sujet ?
```

### Regles d'interview

| Regle | Explication |
|-------|-------------|
| Demander des faits, pas des opinions | "Raconte-moi la derniere fois" > "Est-ce que tu aimerais..." |
| Pas de question guidee | "Qu'en penses-tu ?" > "Tu ne trouves pas que c'est lent ?" |
| Ecouter 80%, parler 20% | L'intervieweur pose les questions, l'interviewe parle |
| Creuser avec "Pourquoi ?" (5 whys) | Aller a la racine du besoin |
| Ne jamais presenter de solution | On decouvre le probleme, pas la solution |

## Methodes de validation

| Methode | Cout | Temps | Fiabilite | Quand l'utiliser |
|---------|:----:|:-----:|:---------:|------------------|
| Interview utilisateur | Bas | 1-2h | Moyenne | Comprendre le probleme |
| Survey / sondage | Bas | 1 jour | Basse | Quantifier un besoin |
| Prototype papier | Bas | 2-4h | Moyenne | Tester un concept UI |
| Prototype interactif (Figma) | Moyen | 1-3 jours | Haute | Tester un flow complet |
| POC technique | Moyen | 2-5 jours | Haute | Valider la faisabilite |
| A/B test | Haut | 1-4 semaines | Tres haute | Mesurer l'impact reel |
| Fake door test | Bas | 1 jour | Haute | Mesurer l'interet avant de construire |

## Priorisation

### Framework RICE

| Critere | Description | Echelle |
|---------|-------------|---------|
| **R**each | Combien d'utilisateurs impactes par trimestre | Nombre |
| **I**mpact | Niveau d'impact sur chaque utilisateur | 3=massif, 2=haut, 1=moyen, 0.5=faible, 0.25=minimal |
| **C**onfidence | Niveau de certitude sur les estimations | 100%=haute, 80%=moyenne, 50%=basse |
| **E**ffort | Effort en personne-mois | Nombre |

```
Score RICE = (Reach × Impact × Confidence) / Effort
```

**Exemple** :

| Feature | Reach | Impact | Confidence | Effort | Score |
|---------|:-----:|:------:|:----------:|:------:|:-----:|
| Recherche memoire multi-agent | 8 | 2 | 80% | 1 | 12.8 |
| Dashboard temps reel | 4 | 3 | 50% | 3 | 2.0 |
| Export PDF rapports | 10 | 1 | 90% | 0.5 | 18.0 |

### Framework MoSCoW

| Categorie | Signification | Proportion |
|-----------|---------------|:----------:|
| **Must** | Obligatoire, le produit ne fonctionne pas sans | ~60% |
| **Should** | Important, forte valeur ajoutee | ~20% |
| **Could** | Nice-to-have, si le temps le permet | ~15% |
| **Won't** | Explicitement exclu de cette iteration | ~5% |

## Metriques produit

### AARRR (Pirate Metrics)

| Metrique | Question | Exemple d'indicateur |
|----------|----------|---------------------|
| **A**cquisition | Comment les utilisateurs nous trouvent ? | Nombre de nouveaux agents actifs |
| **A**ctivation | Ont-ils une bonne premiere experience ? | % qui completent l'onboarding |
| **R**etention | Reviennent-ils ? | Agents actifs par semaine |
| **R**evenue | Generent-ils de la valeur ? | Taches completees par agent |
| **R**eferral | En parlent-ils a d'autres ? | N/A (usage interne) |

### HEART (Google)

| Metrique | Mesure | Indicateur |
|----------|--------|-----------|
| **H**appiness | Satisfaction utilisateur | Score NPS, satisfaction survey |
| **E**ngagement | Niveau d'utilisation | Memoires creees/jour, requetes API/jour |
| **A**doption | Nouveaux utilisateurs | Nouveaux agents onboardes/semaine |
| **R**etention | Utilisateurs qui restent | % agents actifs apres 30 jours |
| **T**ask success | Taux de reussite | % taches Paperclip completees vs abandonnees |

## Checklist Discovery

- [ ] Probleme formule en JTBD
- [ ] Au moins 5 interviews utilisateurs
- [ ] Opportunity Solution Tree construite
- [ ] Au moins 3 solutions envisagees
- [ ] Solution choisie testee par un POC ou prototype
- [ ] PRD redige avec metriques de succes
- [ ] User stories decoupees (INVEST)
- [ ] Priorisation RICE ou MoSCoW effectuee
- [ ] Review CTO pour faisabilite technique
- [ ] Decision documentee dans Mem0
