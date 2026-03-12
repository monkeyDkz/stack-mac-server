# Template : Proof of Concept (POC)

## Titre : POC — [Nom de la technologie/approche]

**Auteur** : researcher
**Date** : YYYY-MM-DD
**Statut** : planifie | en-cours | termine | abandonne
**Projet** : [slug projet]
**Duree estimee** : [X jours]
**Duree reelle** : [X jours]

## 1. Objectif

### Hypothese a valider
> Formuler clairement : "Nous pensons que [technologie/approche] peut [resoudre probleme X] avec [contraintes Y]"

### Criteres de succes (Go/No-Go)

| # | Critere | Seuil minimum | Ideal |
|---|---------|--------------|-------|
| 1 | Performance | < 200ms p95 | < 50ms p95 |
| 2 | Integration | API fonctionnelle | Full pipeline |
| 3 | Fiabilite | Pas de crash en 1h | 24h stable |
| 4 | Complexite | < 500 LOC | < 200 LOC |

### Hors scope
- Ce que le POC ne couvre PAS
- Ce qui sera traite dans une phase ulterieure

## 2. Plan d'execution

| Jour | Tache | Livrable |
|------|-------|----------|
| J1 | Setup environnement, hello world | Env fonctionnel |
| J2 | Integration basique avec notre stack | Endpoint qui marche |
| J3 | Tests de charge, edge cases | Rapport benchmark |
| J4 | Documentation, nettoyage, decision | POC termine, ADR draft |

## 3. Environnement

```bash
# Outils / versions
Node.js 20.x
Docker 24.x
[Technologie evaluee] v[X.Y.Z]
```

### Setup

```bash
# Instructions pour reproduire le POC
git clone <repo>
cd poc-[nom]
docker compose up -d
# ...
```

## 4. Implementation

### Architecture du POC

```
[Diagramme simplifie]
```

### Code cle

```typescript
// Extrait du code le plus important du POC
// avec commentaires explicatifs
```

### Decisions techniques prises pendant le POC

| Decision | Raison |
|----------|--------|
| ... | ... |

## 5. Resultats

### Criteres de succes

| # | Critere | Resultat | Verdict |
|---|---------|----------|---------|
| 1 | Performance < 200ms | 45ms p95 | PASS |
| 2 | Integration API | Fonctionnel | PASS |
| 3 | Fiabilite 1h | 24h sans crash | PASS |
| 4 | < 500 LOC | 180 LOC | PASS |

### Metriques collectees

| Metrique | Valeur |
|----------|--------|
| Temps de reponse p50 | X ms |
| Temps de reponse p95 | X ms |
| Temps de reponse p99 | X ms |
| Throughput max | X req/s |
| Memoire utilisee | X MB |
| CPU moyen | X% |

### Problemes rencontres

| Probleme | Impact | Resolution |
|----------|--------|-----------|
| ... | ... | ... |

## 6. Conclusion

### Verdict : GO / NO-GO

**GO** — [justification en 2-3 phrases]

### Forces decouvertes
- ...

### Risques identifies
- ...

### Effort estime pour production
| Phase | Effort |
|-------|--------|
| MVP | [X] story points |
| Production-ready | [X] story points |
| Monitoring/Alerting | [X] story points |

### Prochaines etapes
1. Creer ADR : `ADR-NNN-[titre]`
2. Creer les issues Paperclip
3. Planifier le sprint d'implementation

## 7. Artefacts

- Code source : `[lien repo/branche]`
- Rapport benchmark : `[lien]`
- Screenshots/demos : `[lien]`
