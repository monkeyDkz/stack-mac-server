# Guidelines Testing

*Base : goldbergyoni/javascript-testing-best-practices, Google Testing Blog*

## Principes fondamentaux

1. **Les tests sont de la documentation executable** — ils decrivent le comportement attendu
2. **Rapides et deterministes** — un test doit donner le meme resultat a chaque execution
3. **Independants** — aucun test ne depend de l'execution d'un autre
4. **Lisibles** — un test qui echoue doit etre comprehensible sans lire le code source

## Pyramide de tests

```
         /\
        /  \       E2E (Playwright)          ~10 tests critiques
       /    \      Integration (API, DB)     ~50 tests
      /      \     Composants / Services     ~200 tests
     /________\    Unitaires                 ~500+ tests
```

| Niveau | Scope | Vitesse | Fiabilite | Outil TS | Outil Python |
|--------|-------|:-------:|:---------:|----------|--------------|
| Unit | Fonction, classe | < 10ms | Haute | vitest | pytest |
| Integration | API endpoint, DB | < 500ms | Moyenne | supertest | httpx + pytest |
| Component | UI isolee | < 1s | Moyenne | testing-library | - |
| E2E | Parcours complet | < 30s | Basse | Playwright | Playwright |

## Pattern AAA (Arrange-Act-Assert)

Chaque test DOIT suivre ce pattern :

```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a user with valid input', async () => {
      // Arrange — preparer les donnees et le contexte
      const input: CreateUserInput = {
        email: 'alice@example.com',
        name: 'Alice',
        role: 'user',
      };
      const mockRepo = createMockUserRepo();

      // Act — executer l'action testee (une seule action)
      const result = await createUser(input, { userRepo: mockRepo });

      // Assert — verifier le resultat attendu
      expect(result.ok).toBe(true);
      expect(result.value).toMatchObject({
        email: 'alice@example.com',
        name: 'Alice',
      });
      expect(mockRepo.save).toHaveBeenCalledOnce();
    });
  });
});
```

```python
class TestUserService:
    def test_create_user_with_valid_input(self, mock_repo):
        # Arrange
        input_data = CreateUserInput(email="alice@example.com", name="Alice")

        # Act
        result = user_service.create(input_data, repo=mock_repo)

        # Assert
        assert result.is_ok
        assert result.value.email == "alice@example.com"
        mock_repo.save.assert_called_once()
```

## Nommage des tests

### Convention : `should [behavior] when [scenario]`

```typescript
// BIEN — descriptif, lisible dans les rapports
it('should return 404 when user does not exist')
it('should hash password before saving')
it('should reject duplicate email with 409')
it('should paginate results with cursor')

// MAL — vague, non descriptif
it('works')
it('test createUser')
it('handles error')
```

### Structure des fichiers

```
tests/
  unit/
    services/
      user-service.test.ts
      payment-service.test.ts
    utils/
      date-helper.test.ts
  integration/
    api/
      users.test.ts
      auth.test.ts
    db/
      user-repository.test.ts
  e2e/
    login.spec.ts
    checkout.spec.ts
  fixtures/
    users.ts
    factories.ts
```

## Unit vs Integration vs E2E

### Tests unitaires

- Tester UNE fonction ou UNE classe isolee
- Mocker toutes les dependances externes (DB, API, filesystem)
- Executer en memoire, pas de I/O
- Rapide : < 10ms par test

```typescript
// Unit test — logique pure, pas de I/O
describe('calculateDiscount', () => {
  it('should apply 10% for orders above 100', () => {
    const result = calculateDiscount(150);
    expect(result).toBe(15);
  });

  it('should apply no discount for orders below 100', () => {
    const result = calculateDiscount(50);
    expect(result).toBe(0);
  });
});
```

### Tests d'integration

- Tester l'interaction entre composants reels (API + DB, service + cache)
- Utiliser une vraie base de donnees (testcontainers ou DB de test)
- Reset l'etat entre chaque test (transaction rollback ou truncate)

```typescript
// Integration test — vrai endpoint, vraie DB
describe('POST /api/v1/users', () => {
  it('should create user and return 201', async () => {
    const res = await request(app)
      .post('/api/v1/users')
      .send({ email: 'test@example.com', name: 'Test' })
      .expect(201);

    expect(res.body.data.id).toBeDefined();

    // Verifier en DB
    const user = await db.user.findUnique({ where: { email: 'test@example.com' } });
    expect(user).not.toBeNull();
  });
});
```

### Tests E2E

- Tester un parcours utilisateur complet (navigateur reel)
- Limiter au strict minimum (parcours critiques uniquement)
- Accepter une certaine fragilite (retries, waits)

```typescript
// E2E — parcours complet
test('user can login and see dashboard', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[data-testid="email"]', 'alice@example.com');
  await page.fill('[data-testid="password"]', 'securepassword');
  await page.click('[data-testid="submit"]');

  await expect(page).toHaveURL('/dashboard');
  await expect(page.locator('h1')).toContainText('Bienvenue Alice');
});
```

## Mocking : regles strictes

### Ce qu'on mock

- Appels reseau (APIs externes, services tiers)
- Base de donnees (en unit tests uniquement)
- Filesystem, horloge, random
- Services couteux (email, SMS, paiement)

### Ce qu'on ne mock PAS

- La logique metier qu'on teste
- Les utilitaires purs (formatters, validators)
- Le framework lui-meme (Express, FastAPI)

### Types de test doubles

| Type | Description | Quand l'utiliser |
|------|-------------|-----------------|
| Stub | Retourne une valeur predefinnie | Simuler une reponse externe |
| Mock | Verifie les appels (combien, avec quels args) | Verifier les interactions |
| Spy | Comme mock mais appelle le vrai code | Observer sans modifier |
| Fake | Implementation simplifiee (in-memory DB) | Tests d'integration legers |

```typescript
// Stub — on definit le retour
vi.spyOn(userRepo, 'findById').mockResolvedValue(fakeUser);

// Mock — on verifie l'appel
expect(emailService.send).toHaveBeenCalledWith({
  to: 'alice@example.com',
  template: 'welcome',
});

// Fake — implementation simplifiee
class FakeUserRepository implements UserRepository {
  private users = new Map<string, User>();

  async save(user: User): Promise<void> {
    this.users.set(user.id, user);
  }

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) ?? null;
  }
}
```

## Coverage guidelines

| Composant | Coverage minimum | Justification |
|-----------|:----------------:|---------------|
| Logique metier (services) | 90% | Coeur de l'application |
| Endpoints API | 100% des routes | Chaque route doit etre appelee au moins une fois |
| Utilitaires partages | 95% | Utilises partout, regressions couteuses |
| UI composants | 70% | Focus sur la logique, pas le rendu |
| Config / bootstrap | 0% | Pas de logique a tester |

### Ce que la coverage ne mesure PAS

- La qualite des assertions (un test sans assert = faux positif)
- Les edge cases (coverage 100% != tous les cas testes)
- La pertinence des tests (tester des getters triviaux = bruit)

## Integration CI

```yaml
# .github/workflows/test.yml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: pnpm install --frozen-lockfile
    - run: pnpm test -- --coverage
    - run: pnpm test:integration
    # Fail si coverage < seuil
    - run: |
        COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
        if (( $(echo "$COVERAGE < 80" | bc -l) )); then
          echo "Coverage $COVERAGE% is below 80% threshold"
          exit 1
        fi
```

## Anti-patterns a eviter

| Anti-pattern | Probleme | Solution |
|-------------|----------|----------|
| Test sans assertion | Faux positif | Toujours au moins un `expect` / `assert` |
| Tests dependants | Echecs en cascade | Chaque test setup son propre etat |
| Sleep dans les tests | Lent et fragile | Utiliser `waitFor`, `eventually`, `poll` |
| Tester l'implementation | Tests cassants au refactoring | Tester le comportement observable |
| Snapshot excessif | Approuve sans lire les diffs | Limiter aux outputs stables (API response shape) |
| Mocker le sujet du test | Ne teste rien | Mocker les dependances, pas le SUT |
| Test trop gros | Difficile a debugger | Un test = un scenario precis |
| Donnees magiques | Incomprehensible | Utiliser des factories avec des noms explicites |

## Factories et fixtures

```typescript
// factories.ts — creer des objets de test facilement
function createUser(overrides: Partial<User> = {}): User {
  return {
    id: randomUUID(),
    email: `test-${randomUUID().slice(0, 8)}@example.com`,
    name: 'Test User',
    role: 'user',
    createdAt: new Date(),
    ...overrides,
  };
}

// Usage dans un test
const admin = createUser({ role: 'admin', name: 'Admin' });
const suspended = createUser({ status: 'suspended' });
```
