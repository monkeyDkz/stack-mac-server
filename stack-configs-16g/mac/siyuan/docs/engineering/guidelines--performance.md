# Guidelines Performance

## Regles d'or

1. **Mesurer avant d'optimiser** — pas d'optimisation prematuree
2. **Profiler, ne pas deviner** — utiliser les outils
3. **Optimiser le chemin critique** — les 20% qui causent 80% de la latence
4. **Budget performance** — definir les seuils AVANT le developpement

## Budgets performance

| Metrique | Seuil acceptable | Objectif | Critique |
|----------|-----------------|----------|----------|
| Time to First Byte (TTFB) | < 400ms | < 200ms | > 800ms |
| Largest Contentful Paint (LCP) | < 2.5s | < 1.5s | > 4s |
| First Input Delay (FID) | < 100ms | < 50ms | > 300ms |
| Cumulative Layout Shift (CLS) | < 0.1 | < 0.05 | > 0.25 |
| API response time (p95) | < 500ms | < 200ms | > 1s |
| API response time (p99) | < 1s | < 500ms | > 3s |
| Bundle size (JS) | < 200KB gzip | < 100KB | > 500KB |
| Database query time | < 100ms | < 50ms | > 500ms |

## Backend

### N+1 Queries

```typescript
// MAL — N+1 : 1 query users + N queries tasks
const users = await db.user.findMany();
for (const user of users) {
  user.tasks = await db.task.findMany({ where: { userId: user.id } });
}

// BIEN — 1 seule query avec JOIN/include
const users = await db.user.findMany({
  include: { tasks: true }
});
```

### Pagination

```typescript
// MAL — offset (lent sur grandes tables)
const items = await db.item.findMany({ skip: 10000, take: 20 });

// BIEN — cursor-based
const items = await db.item.findMany({
  take: 20,
  cursor: { id: lastId },
  orderBy: { createdAt: 'desc' }
});
```

### Caching

```typescript
// Cache en memoire pour les donnees lues frequemment
const cache = new Map<string, { data: any; expires: number }>();

function cached<T>(key: string, ttlMs: number, fn: () => Promise<T>): Promise<T> {
  const entry = cache.get(key);
  if (entry && entry.expires > Date.now()) return entry.data;

  const data = await fn();
  cache.set(key, { data, expires: Date.now() + ttlMs });
  return data;
}

// Usage
const config = await cached('app-config', 60_000, () => db.config.findFirst());
```

### Index database

```sql
-- Ajouter des index sur les colonnes dans WHERE, JOIN, ORDER BY
-- Verifier avec EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM tasks WHERE user_id = 'xxx' AND status = 'active';

-- Si "Seq Scan" apparait sur une grande table → ajouter un index
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
```

### Connection pooling

```typescript
// Limiter les connections DB
const pool = new Pool({
  max: 20,           // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});
```

## Frontend

### Bundle size

```bash
# Analyser le bundle
npx webpack-bundle-analyzer stats.json

# Regles
# - Pas de lodash entier → import { debounce } from 'lodash-es/debounce'
# - Lazy loading des routes
# - Dynamic imports pour les gros composants
# - Tree shaking : utiliser des libs ESM
```

### Lazy loading

```typescript
// Routes
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

// Composants lourds
const Chart = lazy(() => import('./components/Chart'));
```

### Images

```html
<!-- Toujours specifier width/height (evite CLS) -->
<img src="photo.webp" width="800" height="600" loading="lazy" alt="..." />

<!-- Format moderne -->
<picture>
  <source srcset="photo.avif" type="image/avif" />
  <source srcset="photo.webp" type="image/webp" />
  <img src="photo.jpg" alt="..." />
</picture>
```

### Debounce/Throttle

```typescript
// Recherche : debounce 300ms
const onSearch = debounce((query: string) => {
  fetchResults(query);
}, 300);

// Scroll handler : throttle 16ms (60fps)
const onScroll = throttle(() => {
  updatePosition();
}, 16);
```

## Profiling

### Backend

```bash
# Node.js CPU profiling
node --prof app.js
node --prof-process isolate-*.log > profile.txt

# Memory
node --inspect app.js
# Ouvrir chrome://inspect → Memory → Heap snapshot
```

### Database

```sql
-- Activer le log des requetes lentes
ALTER SYSTEM SET log_min_duration_statement = 100; -- 100ms
SELECT pg_reload_conf();

-- Top requetes par temps total
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

### Frontend

```
Chrome DevTools → Performance tab → Record
  → Chercher les "Long Tasks" (> 50ms)
  → Chercher les "Layout Shifts"

Lighthouse → Performance audit
  → Score > 90 en production
```

## Checklist pre-deploy

- [ ] Pas de N+1 queries (verifier avec query logging)
- [ ] Index DB pour les requetes frequentes
- [ ] Cache en place pour les donnees statiques
- [ ] Pagination cursor-based pour les listes
- [ ] Bundle JS < 200KB gzip
- [ ] Images optimisees (WebP/AVIF, lazy loading)
- [ ] API p95 < 500ms (load test)
- [ ] Pas de memory leak (heap stable sur 1h)
