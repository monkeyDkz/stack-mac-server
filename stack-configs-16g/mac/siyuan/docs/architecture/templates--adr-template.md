# ADR-XXX: [Titre de la decision]

*Format : MADR (Markdown Any Decision Records) v3.0*

## Statut

**Propose** | Accepte | Deprecie | Remplace par ADR-YYY

- Date de proposition : YYYY-MM-DD
- Date de decision : YYYY-MM-DD
- Decideurs : [liste des agents/personnes]

## Contexte

[Description du probleme, du besoin ou de l'opportunite qui motive cette decision. Inclure les contraintes techniques, business et organisationnelles. Etre factuel, pas opinione.]

### Forces en jeu

- [Force 1 : contrainte technique, ex. "le service doit supporter 1000 req/s"]
- [Force 2 : contrainte business, ex. "budget infra < 50 EUR/mois"]
- [Force 3 : contrainte equipe, ex. "l'equipe ne maitrise pas Go"]

## Decision

[Ce qui a ete decide. Etre precis et actionnable. Un lecteur doit pouvoir implementer la decision a partir de cette section.]

```
# Exemple de la decision en pratique (code, config, commande, etc.)
```

## Alternatives envisagees

### Alternative 1 : [Nom]

- **Description** : [comment ca marcherait]
- **Avantages** : [liste]
- **Inconvenients** : [liste]
- **Rejetee car** : [raison principale]

### Alternative 2 : [Nom]

- **Description** : [comment ca marcherait]
- **Avantages** : [liste]
- **Inconvenients** : [liste]
- **Rejetee car** : [raison principale]

### Alternative 3 : Ne rien faire

- **Consequences** : [ce qui se passe si on ne decide pas]
- **Acceptable ?** : Oui / Non — [pourquoi]

## Consequences

### Positives

- [Consequence positive 1]
- [Consequence positive 2]
- [Consequence positive 3]

### Negatives

- [Risque ou cout 1 — avec mitigation si possible]
- [Risque ou cout 2 — avec mitigation si possible]

### Neutres

- [Impact qui n'est ni positif ni negatif mais qu'il faut noter]

## Implementation

- [ ] Tache 1 : [description] — responsable : [agent]
- [ ] Tache 2 : [description] — responsable : [agent]
- [ ] Tests : [ce qui doit etre teste]
- [ ] Documentation : [ce qui doit etre documente]
- [ ] Migration : [si des donnees/configs existantes doivent etre migrees]

## Validation

| Critere | Methode de validation | Resultat |
|---------|----------------------|----------|
| [critere 1] | [comment on verifie] | En attente |
| [critere 2] | [comment on verifie] | En attente |

## Metadata

- Agent : [nom de l'agent]
- Date : YYYY-MM-DD
- Confiance : hypothesis | tested | validated
- Mem0 ID : [id de la memoire associee]
- Paperclip Task : PAPER-XX
- Notebooks lies : [liens vers docs SiYuan pertinents]

---

## Guide d'utilisation des ADR

### Quand ecrire un ADR

| Situation | ADR requis ? |
|-----------|:------------:|
| Choix d'une technologie ou framework | Oui |
| Changement d'architecture (nouveau service, migration) | Oui |
| Choix de pattern (CQRS, event sourcing, etc.) | Oui |
| Convention de code ou de process | Non (utiliser les guidelines) |
| Bug fix ou feature standard | Non |
| Breaking change sur une API | Oui |
| Decision d'infra (hosting, scaling, backup) | Oui |

### Cycle de vie d'un ADR

```
Propose → En discussion → Accepte → (optionnel) Deprecie → Remplace
```

1. **Propose** : l'agent redige l'ADR et le soumet
2. **En discussion** : les agents concernes reviewent et commentent
3. **Accepte** : le CTO (ou decideur designe) valide
4. **Deprecie** : la decision n'est plus pertinente (contexte change)
5. **Remplace** : un nouvel ADR prend le relais (lien vers le successeur)

### Bonnes pratiques

- **Un ADR = une decision** — pas de decisions multiples dans un seul ADR
- **Immutable une fois accepte** — on ne modifie pas un ADR accepte, on en cree un nouveau
- **Court et precis** — viser 1-2 pages, pas un roman
- **Factuel** — baser sur des donnees, benchmarks, POCs, pas des opinions
- **Tracer la source** — lier au Mem0 ID et au Paperclip task

### Exemples de sujets d'ADR

- ADR-001 : Choix de PostgreSQL comme base relationnelle
- ADR-002 : Architecture micro-agents avec Paperclip
- ADR-003 : Utilisation de Chroma pour la recherche vectorielle
- ADR-004 : Strategie de cache Redis avec TTL par type
- ADR-005 : Migration de REST vers gRPC pour le service X
- ADR-006 : Adoption de Ruff comme linter/formatteur Python unique

### Numerotation

```
ADR-001, ADR-002, ADR-003...
```

- Sequence monotone croissante, jamais de reutilisation de numero
- Le numero est attribue a la creation (meme si l'ADR est rejete)
- Fichier : `adr-001-choix-postgresql.md` dans le notebook architecture
