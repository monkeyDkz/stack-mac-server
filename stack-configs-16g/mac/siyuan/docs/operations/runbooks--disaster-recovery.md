# Runbook : Disaster Recovery - Systeme Paperclip

> **Derniere mise a jour** : 2026-03-11
> **Environnement** : MacBook Pro M5 Pro - Docker services
> **Responsable** : Operateur unique (systeme auto-gere)

---

## Objectifs de recuperation

Les objectifs RPO (Recovery Point Objective) et RTO (Recovery Time Objective) definissent
les limites acceptables de perte de donnees et de temps d'indisponibilite pour chaque service.

| Service | RPO | RTO | Criticite | Reconstructible |
|---------|-----|-----|-----------|-----------------|
| Mem0 (port 8050) | 1h | 15min | Critique | Non |
| SiYuan (port 6806) | 1h | 30min | Haute | Oui (depuis docs/) |
| PostgreSQL (Paperclip DB) | 0 (WAL) | 15min | Critique | Non |
| Chroma (port 8000) | 24h | 1h | Moyenne | Oui (re-index) |
| Ollama (port 11434) | N/A | 5min | Haute | Oui (re-pull models) |
| n8n (serveur, port 5678) | 1h | 30min | Haute | Non |
| LiteLLM (port 4000) | N/A | 5min | Basse | Oui (config file) |

### Lecture du tableau

- **RPO** : quantite maximale de donnees pouvant etre perdue (en temps). Un RPO de 0 signifie aucune perte toleree.
- **RTO** : duree maximale acceptable avant retour a la normale.
- **Reconstructible** : indique si le service peut etre reconstruit a partir d'autres sources sans backup.

---

## Strategie de backup

### Methode de sauvegarde des volumes Docker

Chaque volume Docker est sauvegarde via un snapshot quotidien :

```bash
docker run --rm \
  -v VOLUME:/data \
  -v /opt/backups:/backup \
  alpine tar czf /backup/VOLUME-$(date +%Y%m%d-%H%M%S).tar.gz /data
```

Cette commande monte le volume cible en lecture seule et produit une archive compressee
dans le repertoire de backup local.

### Planification

- **Heure d'execution** : 3h00 quotidien (periode de faible activite)
- **Volumes sauvegardes** :
  - `mem0-data`
  - `siyuan-workspace`
  - `paperclip-db-data` (PostgreSQL)
  - `chroma-data`
  - `n8n-data`

### Politique de retention

| Type | Frequence | Nombre conserve |
|------|-----------|-----------------|
| Quotidien | Chaque jour a 3h00 | 7 |
| Hebdomadaire | Dimanche a 3h00 | 4 |
| Mensuel | 1er du mois a 3h00 | 3 |

Les backups sont purges automatiquement selon cette politique. Un script de rotation
supprime les archives obsoletes apres chaque sauvegarde.

### Verification

- **Test de restauration mensuel** : chaque premier lundi du mois, un volume est restaure
  dans un conteneur temporaire pour valider l'integrite de l'archive.
- **Controle de checksum** : chaque archive est verifiee avec `sha256sum` apres creation.

### Emplacements de stockage

1. **Local** : `/opt/backups/` sur le MacBook Pro M5 Pro
2. **Distant** : synchronisation via Duplicati vers le serveur HP OMEN

Duplicati est configure pour chiffrer les archives avant transfert et verifier
l'integrite cote distant apres chaque synchronisation.

---

## Scenarios de panne

### Scenario 1 : Mem0 down

**Symptomes** :
- Les agents ne peuvent pas sauvegarder ni lire les memories.
- Les appels vers `http://localhost:8050` echouent ou timeout.
- Les workflows n8n dependant de Mem0 remontent des erreurs.

**Impact** :
- Les agents operent sans contexte historique.
- Les decisions prises ne sont pas persistees.
- Risque de decisions incoherentes ou redondantes.

**Diagnostic** :

```bash
# Verifier l'etat de sante du service
curl http://localhost:8050/health

# Verifier l'etat du conteneur
docker ps | grep mem0

# Consulter les logs recents
docker logs mem0 --tail 100
```

**Resolution** :

1. Verifier que le conteneur est en cours d'execution :
   ```bash
   docker ps | grep mem0
   ```
2. Examiner les logs pour identifier la cause :
   ```bash
   docker logs mem0 --tail 100
   ```
3. Redemarrer le service :
   ```bash
   docker compose -f mac/mem0/docker-compose.yml restart
   ```
4. Si corruption du volume detectee, restaurer depuis le backup :
   ```bash
   docker compose -f mac/mem0/docker-compose.yml down
   docker volume rm mem0-data
   docker run --rm -v mem0-data:/data -v /opt/backups:/backup alpine \
     tar xzf /backup/mem0-data-DERNIER.tar.gz -C /
   docker compose -f mac/mem0/docker-compose.yml up -d
   ```

**Fallback** :
- Les agents passent en mode SiYuan read-only (pas d'ecriture memoire).
- Les decisions sont temporairement journalisees dans les logs n8n.

**Post-recovery** :
- Verifier `/stats` pour chaque agent afin de confirmer la coherence des memories.
- Re-sauvegarder manuellement les decisions prises pendant la periode de panne.
- Verifier que les workflows n8n ont repris normalement.

---

### Scenario 2 : SiYuan down

**Symptomes** :
- Les dashboards sont inaccessibles dans le navigateur.
- Le processus de bootstrap ne peut pas s'executer.
- Les agents ne peuvent plus consulter la documentation.

**Impact** :
- Les agents perdent l'acces a la documentation de reference.
- n8n ne peut pas rafraichir les dashboards.
- Le bootstrap de nouveaux agents est bloque.

**Diagnostic** :

```bash
# Verifier la version / disponibilite de l'API
curl http://localhost:6806/api/system/version

# Verifier l'etat du conteneur
docker ps | grep siyuan

# Consulter les logs
docker logs siyuan --tail 100
```

**Resolution** :

1. Verifier l'etat du conteneur Docker :
   ```bash
   docker ps | grep siyuan
   ```
2. Redemarrer le conteneur :
   ```bash
   docker compose -f mac/siyuan/docker-compose.yml restart
   ```
3. En cas de perte de donnees dans le workspace :
   ```bash
   # Restaurer depuis le backup
   docker compose -f mac/siyuan/docker-compose.yml down
   docker volume rm siyuan-workspace
   docker run --rm -v siyuan-workspace:/data -v /opt/backups:/backup alpine \
     tar xzf /backup/siyuan-workspace-DERNIER.tar.gz -C /
   docker compose -f mac/siyuan/docker-compose.yml up -d
   ```
4. Si le backup est indisponible, reconstruire depuis les sources :
   ```bash
   ./bootstrap.sh --reset
   ```

**Fallback** :
- n8n met en queue les mises a jour destinees a SiYuan.
- Les agents continuent de fonctionner avec les donnees Mem0 uniquement.

**Post-recovery** :
- Lancer les 3 workflows de rafraichissement des dashboards :
  - WF14 (dashboard principal)
  - WF15 (dashboard operationnel)
  - WF16 (dashboard recherche)
- Verifier que le contenu des notebooks correspond aux attentes.

---

### Scenario 3 : PostgreSQL crash (Paperclip DB)

**Symptomes** :
- Paperclip est totalement inaccessible.
- Aucune creation de tache possible.
- Les workflows n8n remontent des erreurs de connexion a la base.

**Impact** :
- L'orchestration des agents est completement arretee.
- Aucune tache ne peut etre creee, mise a jour ou completee.
- Blocage total du systeme Paperclip.

**Diagnostic** :

```bash
# Verifier la disponibilite de PostgreSQL
pg_isready -h localhost -p 5432

# Verifier l'etat du conteneur
docker ps | grep postgres

# Consulter les logs
docker logs paperclip-db --tail 200
```

**Resolution** :

1. Verifier l'etat du conteneur et des logs :
   ```bash
   docker ps | grep postgres
   docker logs paperclip-db --tail 200
   ```
2. Si le conteneur est en cours d'execution mais PostgreSQL est corrompu :
   ```bash
   docker compose -f mac/paperclip/docker-compose.yml down
   docker volume rm paperclip-db-data
   ```
3. Restaurer depuis le backup :
   ```bash
   docker run --rm -v paperclip-db-data:/data -v /opt/backups:/backup alpine \
     tar xzf /backup/paperclip-db-data-DERNIER.tar.gz -C /
   docker compose -f mac/paperclip/docker-compose.yml up -d
   ```
4. Verifier l'integrite de la base restauree :
   ```bash
   pg_isready -h localhost -p 5432
   ```
5. Recrire les taches qui etaient en cours au moment du crash en se basant
   sur les informations presentes dans Mem0 (les decisions y sont conservees).

**Note importante** : PostgreSQL utilise le WAL (Write-Ahead Logging) avec un RPO de 0.
Si le volume n'est pas corrompu, un simple redemarrage du conteneur devrait suffire
sans perte de donnees.

---

### Scenario 4 : Chroma corruption

**Symptomes** :
- La recherche semantique ne retourne plus de resultats.
- Les appels vers `http://localhost:8000` retournent des erreurs ou des resultats vides.
- Les agents ne trouvent plus de contexte pertinent via la recherche vectorielle.

**Impact** :
- Impact minimal sur le systeme global.
- Chroma est un index, pas une source de verite.
- Les donnees originales restent dans Mem0 et SiYuan.

**Resolution** :

1. Supprimer les collections corrompues :
   ```bash
   # Lister les collections
   curl http://localhost:8000/api/v1/collections

   # Supprimer chaque collection
   curl -X DELETE http://localhost:8000/api/v1/collections/{name}
   ```
2. Re-indexer depuis les documents SiYuan :
   ```bash
   # Declencher le workflow de re-indexation SiYuan -> Chroma
   # via l'interface n8n ou par appel API
   ```
3. Re-indexer depuis les memories validees de Mem0 :
   ```bash
   # Declencher le workflow de re-indexation Mem0 -> Chroma
   ```
4. Verifier que la recherche semantique fonctionne a nouveau :
   ```bash
   curl http://localhost:8000/api/v1/collections
   # Confirmer que les collections sont recreees avec le bon nombre de documents
   ```

**Alternative rapide** : si la re-indexation est trop longue, restaurer le volume
depuis le backup quotidien (perte maximale : 24h de donnees indexees).

---

### Scenario 5 : Crash complet du Mac

**Symptomes** :
- Tous les services sont down simultanement.
- Le MacBook Pro ne repond plus ou a necessite une reinstallation.

**Impact** :
- Indisponibilite totale du systeme Paperclip.
- Aucun agent ne peut fonctionner.

**Resolution** :

1. **Reinstaller Docker Desktop** sur le MacBook Pro M5 Pro :
   ```bash
   brew install --cask docker
   ```
2. **Restaurer les volumes** depuis les backups Duplicati (serveur HP OMEN) :
   ```bash
   # Recuperer les archives depuis le serveur HP OMEN via Duplicati
   # Puis restaurer chaque volume :
   for vol in mem0-data siyuan-workspace paperclip-db-data chroma-data n8n-data; do
     docker volume create $vol
     docker run --rm -v $vol:/data -v /opt/backups:/backup alpine \
       tar xzf /backup/$vol-DERNIER.tar.gz -C /
   done
   ```
3. **Relancer le deploiement** via le script de setup :
   ```bash
   ./setup-mac.sh --skip-install --deploy-only
   ```
   Cette option saute l'installation des dependances et ne deploie que les stacks Docker.
4. **Verifier chaque service** un par un :
   ```bash
   curl http://localhost:8050/health       # Mem0
   curl http://localhost:6806/api/system/version  # SiYuan
   pg_isready -h localhost -p 5432         # PostgreSQL
   curl http://localhost:8000/api/v1/collections  # Chroma
   curl http://localhost:11434/api/tags    # Ollama
   curl http://localhost:5678/healthz      # n8n
   curl http://localhost:4000/health       # LiteLLM
   ```
5. **Reconstruire SiYuan** si le workspace est perdu :
   ```bash
   ./bootstrap.sh
   ```
6. **Re-telecharger les modeles Ollama** :
   ```bash
   ollama pull <modele_1>
   ollama pull <modele_2>
   ```

**Duree estimee** : 1 a 2 heures pour un retour complet a la normale.

---

## Procedure de test DR

### Frequence

Tests de disaster recovery effectues **trimestriellement**. Le prochain test doit etre
planifie et documente dans le notebook `operations` de SiYuan.

### Checklist de test

#### Test 1 : Panne Mem0
- [ ] Simuler la panne : `docker stop mem0`
- [ ] Verifier que les agents basculent en fallback SiYuan read-only
- [ ] Confirmer que les workflows n8n journalisent les erreurs correctement
- [ ] Restaurer Mem0 depuis le backup
- [ ] Verifier l'integrite des donnees restaurees via `/stats`
- [ ] Confirmer le retour a la normale des agents

#### Test 2 : Panne PostgreSQL
- [ ] Simuler la panne : `docker stop paperclip-db`
- [ ] Confirmer que Paperclip est bien inaccessible
- [ ] Restaurer le volume depuis le backup
- [ ] Verifier l'integrite avec `pg_isready`
- [ ] Confirmer que les taches en cours sont toujours presentes

#### Test 3 : Corruption Chroma
- [ ] Simuler la corruption : supprimer une collection
- [ ] Confirmer que la recherche semantique echoue
- [ ] Re-indexer depuis SiYuan et Mem0
- [ ] Verifier que la recherche retourne des resultats coherents

#### Test 4 : Verification des backups
- [ ] Verifier la presence des archives dans `/opt/backups/`
- [ ] Verifier la synchronisation Duplicati vers HP OMEN
- [ ] Restaurer un volume dans un conteneur temporaire
- [ ] Valider l'integrite des donnees restaurees

### Documentation des resultats

Les resultats de chaque test DR doivent etre documentes dans SiYuan,
notebook `operations`, avec les informations suivantes :
- Date du test
- Scenarios testes
- Resultats (succes/echec)
- Temps de restauration effectif vs RTO
- Actions correctives identifiees

---

## Contacts et escalade

### Mode operatoire

Le systeme Paperclip est **entierement auto-gere**. Il n'y a pas d'equipe ops humaine
dediee. L'operateur unique est responsable de la surveillance et de la resolution
des incidents.

### Systeme de notifications

- **Canal principal** : notifications via [ntfy](https://ntfy.sh) declenchees par n8n
- **Declencheurs** : chaque healthcheck en echec genere une notification ntfy
- **Configuration** : les regles d'alerte sont definies dans les workflows n8n

### Surveillance continue

- **Uptime Kuma** surveille tous les services en continu :
  - Mem0 : `http://localhost:8050/health`
  - SiYuan : `http://localhost:6806/api/system/version`
  - PostgreSQL : verification TCP port 5432
  - Chroma : `http://localhost:8000/api/v1/heartbeat`
  - Ollama : `http://localhost:11434/api/tags`
  - n8n : `http://localhost:5678/healthz`
  - LiteLLM : `http://localhost:4000/health`

### Priorite de restauration

En cas de panne multiple, restaurer les services dans cet ordre :
1. PostgreSQL (bloque toute l'orchestration)
2. Mem0 (critique pour la continuite des agents)
3. n8n (necessaire pour l'automatisation)
4. Ollama (necessaire pour l'inference)
5. SiYuan (dashboards et documentation)
6. Chroma (reconstructible, priorite basse)
7. LiteLLM (proxy, reconstructible depuis config)

---

## Voir aussi

- [runbooks--deploy-standard](./runbooks--deploy-standard.md) : procedure de deploiement standard des stacks
- [monitoring--alerting-rules](./monitoring--alerting-rules.md) : regles d'alerte et seuils configures dans Uptime Kuma et n8n
- [tech-docs--docker](../engineering/tech-docs--docker.md) : documentation technique Docker (volumes, reseaux, configuration)
- [tech-docs--postgresql](../engineering/tech-docs--postgresql.md) : documentation technique PostgreSQL (WAL, backup, restauration)
