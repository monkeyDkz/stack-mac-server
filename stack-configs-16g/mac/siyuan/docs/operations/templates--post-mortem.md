# Post-Mortem : [Titre de l'incident]

*Format : Google SRE Post-Mortem — blameless, factuel, actionnable*

## Resume

| Champ | Valeur |
|-------|--------|
| **Date de l'incident** | YYYY-MM-DD HH:MM — HH:MM (duree: Xh Xmin) |
| **Detecte par** | [Monitoring automatique / Utilisateur / Agent] |
| **Severite** | P0 (critique) / P1 (majeur) / P2 (mineur) / P3 (faible) |
| **Impact utilisateur** | [Description de l'impact : qui, combien, quoi] |
| **Services affectes** | [Liste des services impactes] |
| **Responsable du post-mortem** | [Agent / Personne] |
| **Statut** | Draft / Review / Valide |

### Classification de severite

| Niveau | Definition | SLA resolution |
|--------|-----------|:--------------:|
| **P0** | Service principal completement indisponible | < 1h |
| **P1** | Fonctionnalite majeure degradee, workaround possible | < 4h |
| **P2** | Fonctionnalite mineure affectee, impact limite | < 24h |
| **P3** | Anomalie detectee, pas d'impact utilisateur immediat | < 1 semaine |

## Impact detaille

| Metrique | Valeur |
|----------|--------|
| Duree totale d'indisponibilite | [X minutes / heures] |
| Nombre d'utilisateurs / agents impactes | [N] |
| Requetes echouees | [N] (X% du trafic) |
| Donnees perdues | [Aucune / Description] |
| SLA impacte | [Oui/Non — quel SLO ?] |
| Cout financier estime | [Si applicable] |

## Timeline

| Heure (UTC) | Evenement | Source |
|:-----------:|-----------|--------|
| HH:MM | [Deploiement / changement qui a cause l'incident] | [Commit, PR, config change] |
| HH:MM | [Premier symptome visible] | [Log, metrique, erreur] |
| HH:MM | [Alerte declenchee] | [Uptime Kuma, monitoring] |
| HH:MM | [Agent/personne commence l'investigation] | [Qui] |
| HH:MM | [Hypothese 1 testee — resultat] | [Commande, test] |
| HH:MM | [Hypothese 2 testee — resultat] | [Commande, test] |
| HH:MM | [Cause racine identifiee] | [Evidence] |
| HH:MM | [Fix applique / rollback effectue] | [Commit, action] |
| HH:MM | [Service restaure] | [Health check OK] |
| HH:MM | [Verification complete terminee] | [Smoke tests] |

## Cause racine — Analyse 5 Whys

```
1. Pourquoi le service etait down ?
   → [Reponse directe : ex. "le container crashait en boucle"]

2. Pourquoi le container crashait ?
   → [Reponse : ex. "erreur de connexion a la base de donnees"]

3. Pourquoi la connexion DB echouait ?
   → [Reponse : ex. "le pool de connexions etait epuise"]

4. Pourquoi le pool etait epuise ?
   → [Reponse : ex. "une requete lente bloquait toutes les connexions"]

5. Pourquoi la requete etait lente ?
   → [Cause racine : ex. "index manquant sur la colonne 'created_at'
      apres la migration de la veille"]
```

### Cause racine (resume)

[Description technique precise de la cause fondamentale en 2-3 phrases.]

### Facteurs contributifs

- [Facteur 1 : ex. "pas de limite de timeout sur les requetes DB"]
- [Facteur 2 : ex. "monitoring ne couvrait pas les metriques DB"]
- [Facteur 3 : ex. "migration non testee avec les volumes de production"]

## Detection

### Ce qui a fonctionne

- [Alerte X a fonctionne correctement]
- [Le monitoring a detecte le probleme en Y minutes]

### Ce qui n'a PAS fonctionne

- [L'alerte Y n'a pas ete declenchee]
- [Le health check ne testait pas la connexion DB]
- [Pas de monitoring sur les connexions pool]

### Temps de detection

| Metrique | Valeur | Cible |
|----------|:------:|:-----:|
| Temps avant premier symptome | [X min] | - |
| Temps avant alerte | [X min] | < 5 min |
| Temps avant investigation | [X min] | < 15 min |
| Temps avant identification cause | [X min] | < 30 min |
| Temps avant resolution | [X min] | Depend de la severite |

## Resolution

### Actions effectuees

1. [Action 1 : ex. "Rollback du deploy vers v1.2.2"]
2. [Action 2 : ex. "Ajout de l'index manquant"]
3. [Action 3 : ex. "Restart du pool de connexions"]

### Verification

- [ ] Health check OK
- [ ] Smoke tests OK
- [ ] Metriques revenues a la normale
- [ ] Logs propres (pas d'erreur recurrente)

## Actions correctives (Action Items)

### Immediat (cette semaine)

| # | Action | Type | Responsable | Deadline | Status |
|---|--------|------|-------------|----------|:------:|
| 1 | [Action concrete et verifiable] | [Bug fix / Process / Monitoring] | [Agent] | [Date] | TODO |
| 2 | [Action concrete et verifiable] | [Bug fix / Process / Monitoring] | [Agent] | [Date] | TODO |

### Court terme (ce sprint)

| # | Action | Type | Responsable | Deadline | Status |
|---|--------|------|-------------|----------|:------:|
| 3 | [Action] | [Type] | [Agent] | [Date] | TODO |
| 4 | [Action] | [Type] | [Agent] | [Date] | TODO |

### Moyen terme (ce trimestre)

| # | Action | Type | Responsable | Deadline | Status |
|---|--------|------|-------------|----------|:------:|
| 5 | [Action systeme ou process] | [Architecture / Process] | [Agent] | [Date] | TODO |

## Lecons apprises

### Ce qui a bien fonctionne

- [Point positif 1]
- [Point positif 2]

### Ce qui doit etre ameliore

- [Point d'amelioration 1]
- [Point d'amelioration 2]

### Ou on a eu de la chance

- [Element qui aurait pu aggraver l'incident mais ne l'a pas fait]

## Principes post-mortem

### Blameless

- **On analyse les systemes, pas les personnes** — "le processus n'a pas prevenu l'erreur" et non "X a fait une erreur"
- Chaque incident est une opportunite d'ameliorer le systeme
- L'objectif est de rendre l'incident impossible a reproduire, pas de trouver un coupable

### Suivi

- Tous les action items doivent avoir un ticket Paperclip
- Review des action items a chaque sprint planning
- Post-mortem archive dans SiYuan (notebook operations)
- Memoire sauvegardee dans Mem0

## Metadata

- Agent : [responsable post-mortem]
- Date : YYYY-MM-DD
- Confiance : validated
- Mem0 ID : [id]
- Paperclip Task : PAPER-XX
