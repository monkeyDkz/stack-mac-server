# PostgreSQL — Reference

## Conventions

### Nommage

| Element | Convention | Exemple |
|---------|-----------|---------|
| Tables | snake_case, **pluriel** | `users`, `task_comments` |
| Colonnes | snake_case | `created_at`, `user_id` |
| Primary keys | `id` (UUID ou BIGSERIAL) | `id UUID DEFAULT gen_random_uuid()` |
| Foreign keys | `<table_singulier>_id` | `user_id`, `project_id` |
| Index | `idx_<table>_<colonnes>` | `idx_users_email` |
| Unique | `uniq_<table>_<colonnes>` | `uniq_users_email` |
| Check | `chk_<table>_<description>` | `chk_users_age_positive` |

### Types recommandes

| Usage | Type PostgreSQL | Pas ca |
|-------|----------------|--------|
| Identifiant | `UUID` ou `BIGSERIAL` | `INT` |
| Texte court (<255) | `VARCHAR(n)` | `CHAR(n)` |
| Texte long | `TEXT` | `VARCHAR(10000)` |
| Date+heure | `TIMESTAMPTZ` | `TIMESTAMP` (sans TZ) |
| Argent | `NUMERIC(12,2)` | `FLOAT`, `MONEY` |
| Boolean | `BOOLEAN` | `INT 0/1` |
| JSON | `JSONB` | `JSON` (pas indexable) |
| Enum | `CREATE TYPE ... AS ENUM` | `VARCHAR` avec check |

## Indexation

### Quand creer un index

```sql
-- Colonnes dans WHERE frequents
CREATE INDEX idx_users_email ON users(email);

-- Colonnes dans JOIN
CREATE INDEX idx_tasks_user_id ON tasks(user_id);

-- Colonnes dans ORDER BY
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);

-- Recherche partielle
CREATE INDEX idx_tasks_active ON tasks(status) WHERE status = 'active';

-- Recherche full-text
CREATE INDEX idx_docs_search ON documents USING GIN(to_tsvector('french', content));

-- JSONB
CREATE INDEX idx_meta_project ON memories USING GIN((metadata->'project'));
```

### Anti-patterns

| Anti-pattern | Probleme | Solution |
|-------------|----------|----------|
| Index sur chaque colonne | Ralentit les INSERT/UPDATE | Indexer uniquement ce qui est requis par les queries |
| Index sur petites tables (<1000 lignes) | Overhead > benefice | Seq scan est plus rapide |
| Index non utilise | Occupe de l'espace | `SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0` |

## Requetes performantes

### Explain Analyze

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.name, COUNT(t.id) as task_count
FROM users u
LEFT JOIN tasks t ON t.user_id = u.id
WHERE u.status = 'active'
GROUP BY u.id
ORDER BY task_count DESC
LIMIT 10;
```

Toujours verifier : `Seq Scan` sur grandes tables = index manquant.

### Eviter le N+1

```sql
-- MAL : N+1 queries
SELECT * FROM users;
-- puis pour chaque user :
SELECT * FROM tasks WHERE user_id = ?;

-- BIEN : une seule query
SELECT u.*, json_agg(t.*) as tasks
FROM users u
LEFT JOIN tasks t ON t.user_id = u.id
GROUP BY u.id;
```

### Pagination

```sql
-- Offset (simple mais lent sur grandes tables)
SELECT * FROM tasks ORDER BY created_at DESC LIMIT 20 OFFSET 100;

-- Cursor-based (performant)
SELECT * FROM tasks
WHERE created_at < '2026-03-10T12:00:00Z'
ORDER BY created_at DESC
LIMIT 20;
```

## Migrations

### Regles zero-downtime

1. **Jamais de `DROP COLUMN` directement** — d'abord arreter de lire/ecrire, deployer, puis drop
2. **Jamais de `ALTER TABLE ... ADD COLUMN ... NOT NULL`** sans default — bloque la table
3. **Creer les index `CONCURRENTLY`** — pas de lock

```sql
-- BIEN : ajout safe
ALTER TABLE users ADD COLUMN phone VARCHAR(20);  -- nullable d'abord
-- deployer le code qui ecrit phone
-- backfill les anciennes lignes
UPDATE users SET phone = '' WHERE phone IS NULL;
-- puis
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
ALTER TABLE users ALTER COLUMN phone SET DEFAULT '';

-- Index sans bloquer
CREATE INDEX CONCURRENTLY idx_users_phone ON users(phone);
```

### Outils

| Outil | Stack | Usage |
|-------|-------|-------|
| Prisma Migrate | TypeScript | Schema-first, auto-generate |
| Alembic | Python | Code-first, SQLAlchemy |
| dbmate | Agnostic | SQL pur, simple |

## Backup & Restore

```bash
# Backup
pg_dump -Fc -h localhost -U postgres mydb > backup_$(date +%Y%m%d).dump

# Restore
pg_restore -h localhost -U postgres -d mydb backup_20260311.dump

# Backup automatique (cron)
0 2 * * * pg_dump -Fc mydb > /backups/mydb_$(date +\%Y\%m\%d).dump
```

## Monitoring

```sql
-- Connections actives
SELECT count(*) FROM pg_stat_activity WHERE state = 'active';

-- Requetes lentes (> 1s)
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND (now() - pg_stat_activity.query_start) > interval '1 second'
ORDER BY duration DESC;

-- Taille des tables
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Index inutilises
SELECT indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
```
