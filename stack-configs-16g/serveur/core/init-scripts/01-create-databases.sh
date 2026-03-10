#!/bin/bash
set -e

echo "=== Création des bases de données ==="

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    -- Gitea
    CREATE USER gitea WITH PASSWORD '${GITEA_DB_PASSWORD:-gitea_pass}';
    CREATE DATABASE gitea_db OWNER gitea;
    GRANT ALL PRIVILEGES ON DATABASE gitea_db TO gitea;

    -- Twenty CRM
    CREATE USER twenty WITH PASSWORD '${TWENTY_DB_PASSWORD:-twenty_pass}';
    CREATE DATABASE twenty_db OWNER twenty;
    GRANT ALL PRIVILEGES ON DATABASE twenty_db TO twenty;

    -- Cal.com
    CREATE USER calcom WITH PASSWORD '${CALCOM_DB_PASSWORD:-calcom_pass}';
    CREATE DATABASE calcom_db OWNER calcom;
    GRANT ALL PRIVILEGES ON DATABASE calcom_db TO calcom;

    -- Umami
    CREATE USER umami WITH PASSWORD '${UMAMI_DB_PASSWORD:-umami_pass}';
    CREATE DATABASE umami_db OWNER umami;
    GRANT ALL PRIVILEGES ON DATABASE umami_db TO umami;

    -- n8n
    CREATE USER n8n WITH PASSWORD '${N8N_DB_PASSWORD:-n8n_pass}';
    CREATE DATABASE n8n_db OWNER n8n;
    GRANT ALL PRIVILEGES ON DATABASE n8n_db TO n8n;

    -- Authelia
    CREATE USER authelia WITH PASSWORD '${AUTHELIA_DB_PASSWORD:-authelia_pass}';
    CREATE DATABASE authelia_db OWNER authelia;
    GRANT ALL PRIVILEGES ON DATABASE authelia_db TO authelia;

    -- Nextcloud
    CREATE USER nextcloud WITH PASSWORD '${NEXTCLOUD_DB_PASSWORD:-nextcloud_pass}';
    CREATE DATABASE nextcloud_db OWNER nextcloud;
    GRANT ALL PRIVILEGES ON DATABASE nextcloud_db TO nextcloud;

EOSQL

echo "=== Bases créées : gitea_db, twenty_db, calcom_db, umami_db, n8n_db, authelia_db, nextcloud_db ==="
