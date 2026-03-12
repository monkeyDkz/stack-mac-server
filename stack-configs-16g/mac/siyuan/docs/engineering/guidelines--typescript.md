# Guidelines TypeScript

*Base : Google TypeScript Style Guide + Airbnb JavaScript Style Guide*

## Principes

1. **Le code se lit plus qu'il ne s'ecrit** — optimiser pour la lisibilite
2. **Types stricts** — `strict: true` dans tsconfig, pas de `any`
3. **Explicite > Implicite** — preferer la clarte a la concision

## Configuration tsconfig.json

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler"
  }
}
```

## Nommage

| Element | Convention | Exemple |
|---------|-----------|---------|
| Variables, fonctions | camelCase | `getUserById`, `isActive` |
| Classes | PascalCase | `UserService`, `HttpClient` |
| Interfaces | PascalCase (pas de prefix `I`) | `User`, `Config` |
| Type aliases | PascalCase | `UserId`, `ApiResponse` |
| Enums | PascalCase, membres UPPER_CASE | `enum Status { ACTIVE, INACTIVE }` |
| Constants | UPPER_CASE | `MAX_RETRIES`, `API_BASE_URL` |
| Fichiers | kebab-case | `user-service.ts`, `api-client.ts` |
| Dossiers | kebab-case | `user-management/`, `shared-utils/` |
| Booleans | prefix `is`, `has`, `can`, `should` | `isActive`, `hasPermission` |
| Fonctions | verbe d'action | `createUser`, `validateInput` |
| Generiques | lettre majuscule descriptive | `T`, `TResult`, `TInput` |

### Nommage interdit

```typescript
// NON — prefixe I pour interface
interface IUser { }   // → interface User { }

// NON — suffixe Interface/Type
type UserType = { }   // → type User = { }

// NON — abbreviations obscures
const usrMgr = ...    // → const userManager = ...

// NON — single letter (sauf generiques et boucles)
const d = new Date()  // → const date = new Date()
```

## Types

### Preferer les interfaces pour les objets

```typescript
// BIEN — interface pour les shapes d'objet
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
}

// BIEN — type pour les unions, intersections, utilitaires
type Status = 'active' | 'inactive' | 'suspended';
type UserWithTasks = User & { tasks: Task[] };
type ReadonlyUser = Readonly<User>;
```

### Jamais `any`

```typescript
// MAL
function parse(data: any): any { }

// BIEN — type specifique
function parse(data: unknown): User { }

// BIEN — generique si le type varie
function parse<T>(data: unknown): T { }

// Si vraiment inconnu, utiliser unknown + type guards
function process(data: unknown): void {
  if (typeof data === 'string') {
    // data est string ici
  }
  if (isUser(data)) {
    // data est User ici
  }
}
```

### Type guards

```typescript
// Type predicate
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  );
}

// Discriminated union
type Result<T> =
  | { success: true; data: T }
  | { success: false; error: string };

function handleResult(result: Result<User>) {
  if (result.success) {
    console.log(result.data.name); // TypeScript sait que c'est le cas success
  } else {
    console.error(result.error);   // TypeScript sait que c'est le cas error
  }
}
```

### Enums

```typescript
// Preferer les const enums ou les unions de string literals
// pour les valeurs simples

// BIEN — union (tree-shakeable, pas de runtime overhead)
type Status = 'active' | 'inactive' | 'suspended';

// BIEN — const enum (inline a la compilation)
const enum HttpStatus {
  OK = 200,
  NOT_FOUND = 404,
  SERVER_ERROR = 500,
}

// OK — enum standard (quand on a besoin de reverse mapping)
enum Direction {
  UP = 'UP',
  DOWN = 'DOWN',
  LEFT = 'LEFT',
  RIGHT = 'RIGHT',
}
```

## Fonctions

### Parametres

```typescript
// Max 3 parametres — au-dela, utiliser un objet
// MAL
function createUser(name: string, email: string, role: string, team: string, isAdmin: boolean) { }

// BIEN
interface CreateUserInput {
  name: string;
  email: string;
  role: string;
  team: string;
  isAdmin?: boolean; // optionnel en dernier
}
function createUser(input: CreateUserInput): User { }
```

### Return types explicites

```typescript
// Toujours annoter le return type des fonctions exportees
export function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// OK de laisser inferer pour les fonctions locales simples
const double = (n: number) => n * 2;
```

### Async/Await

```typescript
// Toujours async/await (jamais .then/.catch)
// MAL
function getUser(id: string): Promise<User> {
  return fetch(`/api/users/${id}`)
    .then(res => res.json())
    .then(data => data as User);
}

// BIEN
async function getUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new HttpError(res.status, await res.text());
  return res.json() as Promise<User>;
}
```

## Error handling

```typescript
// Erreurs custom avec cause chain
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = 'AppError';
  }
}

// Usage avec cause
try {
  await db.user.create(data);
} catch (error) {
  throw new AppError(
    'Failed to create user',
    'USER_CREATE_FAILED',
    500,
    { cause: error },
  );
}

// Pattern Result (alternative aux exceptions)
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

function parseConfig(raw: string): Result<Config> {
  try {
    return { ok: true, value: JSON.parse(raw) };
  } catch (e) {
    return { ok: false, error: e as Error };
  }
}
```

## Imports

```typescript
// Ordre (enforce par eslint-plugin-import) :
// 1. Node builtins
import { readFile } from 'node:fs/promises';

// 2. External packages
import express from 'express';
import { z } from 'zod';

// 3. Internal modules (absolute)
import { UserService } from '@/services/user-service';
import { logger } from '@/lib/logger';

// 4. Relative imports
import { validateInput } from './validation';
import type { Config } from './types';

// Toujours utiliser `import type` pour les types purs
import type { User, Task } from '@/types';
```

## Null / Undefined

```typescript
// Preferer undefined a null (convention TypeScript)
// null = explicitement "pas de valeur"
// undefined = "pas encore de valeur" ou "optionnel"

// Utiliser optional chaining et nullish coalescing
const name = user?.profile?.displayName ?? 'Anonymous';

// Pas de non-null assertion (!) sauf si VRAIMENT certain
// MAL
const element = document.getElementById('app')!;

// BIEN
const element = document.getElementById('app');
if (!element) throw new Error('App element not found');
```

## Collections

```typescript
// Preferer les methodes fonctionnelles
const activeUsers = users.filter(u => u.status === 'active');
const names = users.map(u => u.name);
const total = items.reduce((sum, item) => sum + item.price, 0);

// Eviter for...in (itere sur le prototype)
// Utiliser for...of pour les iterables
for (const user of users) { }

// Map pour les lookups O(1)
const userById = new Map(users.map(u => [u.id, u]));
const user = userById.get('abc');

// Set pour les valeurs uniques
const uniqueTags = new Set(tasks.flatMap(t => t.tags));
```

## Commentaires

```typescript
// NE PAS commenter le "quoi" (le code le dit deja)
// MAL
// Increment counter by 1
counter += 1;

// Commenter le "pourquoi" uniquement
// BIEN
// Skip soft-deleted users to avoid ghost entries in the export
const activeUsers = users.filter(u => !u.deletedAt);

// JSDoc pour les fonctions/types exportes
/**
 * Calculates the weighted score based on criteria ratings.
 *
 * @param ratings - Map of criterion name to score (0-10)
 * @param weights - Map of criterion name to weight (0-1, must sum to 1)
 * @returns Weighted score between 0 and 10
 * @throws {AppError} If weights don't sum to 1
 */
export function calculateWeightedScore(
  ratings: Map<string, number>,
  weights: Map<string, number>,
): number { }
```

## Regles ESLint recommandees

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/strict-type-checked",
    "plugin:import/recommended",
    "plugin:import/typescript"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-non-null-assertion": "warn",
    "@typescript-eslint/prefer-nullish-coalescing": "error",
    "@typescript-eslint/prefer-optional-chain": "error",
    "@typescript-eslint/strict-boolean-expressions": "error",
    "import/order": ["error", {
      "groups": ["builtin", "external", "internal", "parent", "sibling"],
      "newlines-between": "always"
    }]
  }
}
```
