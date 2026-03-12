# Runbook : Migration Base de Donnees

*Zero-downtime, schema versioning, rollback scripts*

## Regles d'or

1. **Toujours un backup avant migration** — sans exception
2. **Tester sur staging d'abord** — jamais de migration directe en prod
3. **Migrations retrocompatibles** — l'ancien code doit fonctionner pendant la migration
4. **Script de rollback obligatoire** — chaque `up` a son `down`
5. **Petites migrations frequentes** — plutot qu'une grosse migration risquee

## Nommage des fichiers

```
migrations/
  20260311_120000_create_users_table.sql
  20260311_130000_add_email_index.sql
  20260312_090000_add_avatar_column.sql
  20260312_100000_rename_name_to_display_name.sql
```

Format : `YYYYMMDD_HHMMSS_description_en_snake_case.sql`

## Structure d'un fichier de migration

```sql
-- Migration: 20260311_120000_create_users_table
-- Description: Create the users table with base columns
-- Author: cto
-- Reversible: yes

-- migrate:up
BEGIN;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

COMMENT ON TABLE users IS 'Core user accounts';

COMMIT;

-- migrate:down
BEGIN;

DROP INDEX IF EXISTS idx_users_role;
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;

COMMIT;
```

## Procedure de migration

### Etape 1 : Backup

```bash
# Backup complet de la base
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump -h localhost -p 5432 -U paperclip -d paperclip \
  --format=custom \
  --file="backup_${TIMESTAMP}.dump"

# Verifier que le backup est valide
pg_restore --list "backup_${TIMESTAMP}.dump" | head -20

# Taille du backup
ls -lh "backup_${TIMESTAMP}.dump"

echo "Backup OK : backup_${TIMESTAMP}.dump"
```

### Etape 2 : Test sur staging

```bash
# Creer une base de staging a partir du backup
createdb -h localhost -U paperclip paperclip_staging
pg_restore -h localhost -U paperclip -d paperclip_staging "backup_${TIMESTAMP}.dump"

# Appliquer la migration sur staging
psql -h localhost -U paperclip -d paperclip_staging < migrations/20260311_120000_create_users_table.sql

# Verifier le resultat
psql -h localhost -U paperclip -d paperclip_staging -c "\dt"
psql -h localhost -U paperclip -d paperclip_staging -c "SELECT count(*) FROM users;"

# Tester le rollback
psql -h localhost -U paperclip -d paperclip_staging <<'SQL'
-- migrate:down (copier la section down du fichier)
SQL

# Nettoyer
dropdb -h localhost -U paperclip paperclip_staging
```

### Etape 3 : Appliquer en production

```bash
# Verifier les connexions actives
psql -h localhost -U paperclip -d paperclip -c \
  "SELECT count(*) as active_connections FROM pg_stat_activity WHERE datname = 'paperclip';"

# Appliquer la migration
psql -h localhost -U paperclip -d paperclip < migrations/20260311_120000_create_users_table.sql

# Verifier immediatement
psql -h localhost -U paperclip -d paperclip -c "\dt"
psql -h localhost -U paperclip -d paperclip -c "SELECT count(*) FROM users;"
```

### Etape 4 : Verification post-migration

```bash
# Verifier l'integrite
psql -h localhost -U paperclip -d paperclip <<'SQL'
-- Verifier les contraintes
SELECT conname, conrelid::regclass, contype
FROM pg_constraint
WHERE conrelid = 'users'::regclass;

-- Verifier les index
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'users';

-- Verifier les donnees (si migration de donnees)
SELECT count(*), min(created_at), max(created_at) FROM users;
SQL

# Verifier que l'application fonctionne
curl -sf http://localhost:PORT/health
```

### Etape 5 : Rollback (si probleme)

```bash
# Option 1 : Executer le script down
psql -h localhost -U paperclip -d paperclip <<'SQL'
-- Coller la section migrate:down ici
SQL

# Option 2 : Restaurer le backup complet
dropdb -h localhost -U paperclip paperclip
createdb -h localhost -U paperclip paperclip
pg_restore -h localhost -U paperclip -d paperclip "backup_${TIMESTAMP}.dump"
```

## Patterns zero-downtime

### Pattern 1 : Ajouter une colonne

```sql
-- SAFE : ajouter une colonne nullable (pas de lock)
ALTER TABLE users ADD COLUMN avatar_url TEXT;

-- SAFE : ajouter une colonne avec default (PG 11+, pas de rewrite)
ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

-- UNSAFE : ajouter NOT NULL sans default sur table existante
-- ALTER TABLE users ADD COLUMN bio TEXT NOT NULL;  -- LOCK + REWRITE
```

### Pattern 2 : Renommer une colonne (multi-deploy)

```
Deploy 1 : Ajouter la nouvelle colonne
Deploy 2 : Ecrire dans les deux colonnes (ancien + nouveau)
Deploy 3 : Migrer les donnees existantes
Deploy 4 : Lire depuis la nouvelle colonne
Deploy 5 : Supprimer l'ancienne colonne
```

```sql
-- Deploy 1 : Ajouter
ALTER TABLE users ADD COLUMN display_name TEXT;

-- Deploy 3 : Migrer les donnees
UPDATE users SET display_name = name WHERE display_name IS NULL;

-- Deploy 5 : Supprimer (apres verification)
ALTER TABLE users DROP COLUMN name;
ALTER TABLE users ALTER COLUMN display_name SET NOT NULL;
```

### Pattern 3 : Ajouter un index sans lock

```sql
-- SAFE : CREATE INDEX CONCURRENTLY (pas de lock, mais plus lent)
CREATE INDEX CONCURRENTLY idx_users_created_at ON users(created_at);

-- UNSAFE : CREATE INDEX standard (lock ACCESS EXCLUSIVE)
-- CREATE INDEX idx_users_created_at ON users(created_at);

-- NOTE : CONCURRENTLY ne peut pas etre dans une transaction
-- Ne pas utiliser BEGIN/COMMIT autour
```

### Pattern 4 : Migration de donnees volumineuses

```sql
-- Par batches pour eviter les locks longs
DO $$
DECLARE
  batch_size INT := 1000;
  affected INT := 1;
BEGIN
  WHILE affected > 0 LOOP
    WITH batch AS (
      SELECT id FROM users
      WHERE new_column IS NULL
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    )
    UPDATE users SET new_column = compute_value(old_column)
    FROM batch WHERE users.id = batch.id;

    GET DIAGNOSTICS affected = ROW_COUNT;
    RAISE NOTICE 'Migrated % rows', affected;

    -- Pause entre batches pour laisser respirer la DB
    PERFORM pg_sleep(0.1);
  END LOOP;
END $$;
```

### Pattern 5 : Supprimer une colonne

```sql
-- Etape 1 : Arreter de lire la colonne (deploy code)
-- Etape 2 : Arreter d'ecrire la colonne (deploy code)
-- Etape 3 : Supprimer la colonne (migration)

-- Ne JAMAIS supprimer une colonne encore lue par le code en prod
ALTER TABLE users DROP COLUMN old_column;
```

## Operations dangereuses (a eviter)

| Operation | Risque | Alternative |
|-----------|--------|-------------|
| `DROP TABLE` | Perte de donnees | Soft delete + archive |
| `DROP COLUMN` sur table active | Erreur 500 | Deploy en 3 etapes (voir pattern 5) |
| `ALTER COLUMN SET NOT NULL` sur table existante | Lock long | Ajouter CHECK constraint d'abord |
| `ALTER COLUMN TYPE` | Lock + rewrite | Ajouter nouvelle colonne + migrer |
| `TRUNCATE` | Perte de donnees | DELETE avec WHERE |
| `CREATE INDEX` (non CONCURRENTLY) | Lock | Toujours CONCURRENTLY |

## Sauvegarder dans Mem0

```bash
curl -X POST http://host.docker.internal:8050/memories \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Migration DB: [description]. Fichier: [nom]. Tables affectees: [liste]. Rollback teste: oui.",
    "user_id": "devops",
    "metadata": {
      "type": "architecture",
      "project": "PROJECT_SLUG",
      "confidence": "validated"
    }
  }'
```
