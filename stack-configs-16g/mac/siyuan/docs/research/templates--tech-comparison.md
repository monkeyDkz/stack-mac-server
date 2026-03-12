# Template : Comparaison Technologique

## Titre : [Technologie A] vs [Technologie B] vs [Technologie C]

**Auteur** : researcher
**Date** : YYYY-MM-DD
**Statut** : draft | en-cours | termine
**Projet** : [slug projet]

## Contexte

### Probleme a resoudre
> Decrire le besoin technique qui motive cette comparaison.

### Criteres de decision
> Lister les criteres ponderes (total = 100%)

| Critere | Poids | Description |
|---------|-------|-------------|
| Performance | 25% | Temps de reponse, throughput |
| Facilite d'integration | 20% | Compatibilite avec notre stack |
| Communaute / Support | 15% | Stars GitHub, activite, docs |
| Cout (licence + infra) | 15% | TCO sur 12 mois |
| Courbe d'apprentissage | 10% | Temps pour l'equipe d'etre productive |
| Securite | 10% | CVE connues, audit, compliance |
| Scalabilite | 5% | Passage a l'echelle si besoin |

## Candidats

### Option A : [Nom]

| Aspect | Detail |
|--------|--------|
| Site | [URL] |
| Version | [version evaluee] |
| Licence | [MIT/Apache/Commercial] |
| Stars GitHub | [nombre] |
| Derniere release | [date] |

**Forces** :
- ...

**Faiblesses** :
- ...

### Option B : [Nom]

*(meme structure)*

### Option C : [Nom]

*(meme structure)*

## Matrice de comparaison

| Critere (Poids) | Option A | Option B | Option C |
|-----------------|----------|----------|----------|
| Performance (25%) | 8/10 | 7/10 | 9/10 |
| Integration (20%) | 9/10 | 6/10 | 7/10 |
| Communaute (15%) | 7/10 | 9/10 | 5/10 |
| Cout (15%) | 10/10 | 8/10 | 6/10 |
| Learning curve (10%) | 8/10 | 7/10 | 4/10 |
| Securite (10%) | 7/10 | 8/10 | 8/10 |
| Scalabilite (5%) | 6/10 | 9/10 | 9/10 |
| **Score pondere** | **8.1** | **7.5** | **6.9** |

## POC / Tests

### Methodologie
> Decrire les tests realises (benchmark, integration test, prototype)

### Resultats

| Test | Option A | Option B | Option C |
|------|----------|----------|----------|
| Temps de setup | 15 min | 45 min | 2h |
| Requetes/s | 12,000 | 8,500 | 15,000 |
| Memoire utilisee | 120 MB | 350 MB | 80 MB |
| Integration stack OK | Oui | Partiel | Oui |

## Recommandation

**Option recommandee** : Option A

**Justification** :
> Expliquer le choix en 2-3 phrases.

**Risques identifies** :
- Risque 1 : mitigation
- Risque 2 : mitigation

**Prochaines etapes** :
1. ADR a creer : `architecture/projects/[slug]/adrs/ADR-NNN-[titre]`
2. POC approfondi si necessaire
3. Validation CTO

## References

- [Lien 1]
- [Lien 2]
- [Benchmark source]
