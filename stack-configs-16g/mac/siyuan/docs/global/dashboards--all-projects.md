# Dashboard : Tous les Projets

*Requetes SQL pour SiYuan — utiliser via query embeds ou l'API /api/query/sql*

## Projets actifs

```sql
SELECT DISTINCT a.value AS projet
FROM attributes a
JOIN blocks b ON a.block_id = b.id
WHERE a.name = 'custom-project'
  AND a.value != 'global'
  AND b.type = 'd'
ORDER BY a.value
```

## Documents recents (tous projets)

```sql
SELECT b.content, b.hpath,
       a1.value AS projet,
       a2.value AS type
FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type'
WHERE b.type = 'd'
  AND a1.value != 'global'
ORDER BY b.updated DESC
LIMIT 20
```

## ADRs actifs (tous projets)

```sql
SELECT b.content, b.hpath,
       a1.value AS projet,
       a3.value AS status
FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type' AND a2.value = 'adr'
JOIN attributes a3 ON b.id = a3.block_id AND a3.name = 'custom-status'
WHERE b.type = 'd'
  AND a3.value IN ('active', 'review')
ORDER BY b.updated DESC
```

## Documents en review

```sql
SELECT b.content, b.hpath,
       a1.value AS projet,
       a2.value AS type
FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type'
JOIN attributes a3 ON b.id = a3.block_id AND a3.name = 'custom-status' AND a3.value = 'review'
WHERE b.type = 'd'
ORDER BY b.updated DESC
```

## Documents bookmarkes

```sql
SELECT b.content, b.hpath,
       a1.value AS projet,
       a2.value AS type
FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project'
JOIN attributes a2 ON b.id = a2.block_id AND a2.name = 'custom-type'
WHERE b.type = 'd'
  AND b.ial LIKE '%bookmark%'
ORDER BY b.updated DESC
```

## Compteur par notebook

```sql
SELECT b.box, count(*) AS doc_count
FROM blocks b
WHERE b.type = 'd'
GROUP BY b.box
ORDER BY doc_count DESC
```

## Compteur par type de document

```sql
SELECT a.value AS type, count(*) AS count
FROM attributes a
JOIN blocks b ON a.block_id = b.id
WHERE a.name = 'custom-type'
  AND b.type = 'd'
GROUP BY a.value
ORDER BY count DESC
```

## Compteur par projet

```sql
SELECT a.value AS project, count(*) AS count
FROM attributes a
JOIN blocks b ON a.block_id = b.id
WHERE a.name = 'custom-project'
  AND b.type = 'd'
GROUP BY a.value
ORDER BY count DESC
```

## Documents modifies dans les 7 derniers jours

```sql
SELECT b.content, b.hpath, b.updated,
       a1.value AS projet
FROM blocks b
JOIN attributes a1 ON b.id = a1.block_id AND a1.name = 'custom-project'
WHERE b.type = 'd'
  AND b.updated > strftime('%Y%m%d%H%M%S', datetime('now', '-7 days'))
ORDER BY b.updated DESC
LIMIT 30
```

---

*Utiliser ces requetes SQL via SiYuan query embeds ou l'API `/api/query/sql`.*
*Les query embeds SiYuan s'inserent avec la syntaxe : `{{SELECT ...}}`*
