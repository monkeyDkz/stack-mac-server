# Guidelines Python

*Base : Google Python Style Guide + PEP 8 + PEP 484*

## Principes

1. **Explicit is better than implicit** — Zen of Python
2. **Type hints partout** — `mypy --strict` doit passer
3. **Un fichier, une responsabilite** — modules courts et focuses

## Configuration

### pyproject.toml

```toml
[tool.mypy]
strict = true
warn_return_any = true
warn_unused_configs = true

[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "SIM", "TCH"]
```

## Nommage

| Element | Convention | Exemple |
|---------|-----------|---------|
| Variables, fonctions | snake_case | `get_user_by_id`, `is_active` |
| Classes | PascalCase | `UserService`, `HttpClient` |
| Constantes | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Modules/fichiers | snake_case | `user_service.py`, `api_client.py` |
| Packages/dossiers | snake_case (court) | `auth/`, `utils/` |
| Private | prefix `_` | `_parse_response`, `_cache` |
| Dunder | double underscore | `__init__`, `__repr__` |
| Type variables | PascalCase | `T`, `TResult`, `UserT` |
| Booleans | prefix `is_`, `has_`, `can_` | `is_valid`, `has_permission` |

### Nommage interdit

```python
# NON — single char (sauf i/j/k dans boucles, x/y en math)
d = datetime.now()  # → now = datetime.now()

# NON — abbreviations
usr_mgr = ...       # → user_manager = ...
calc_ttl = ...      # → calculate_total = ...

# NON — type dans le nom
user_list = []      # → users = []
name_string = ""    # → name = ""
```

## Type Hints

### Regles

```python
# Toujours annoter les fonctions
def create_user(name: str, email: str, role: str = "member") -> User:
    ...

# Toujours annoter les attributs de classe
class Config:
    host: str
    port: int
    debug: bool = False

# Collections typees
from collections.abc import Sequence, Mapping

def process_items(items: Sequence[Item]) -> list[Result]:
    ...

# Optional = Union[X, None]
def find_user(user_id: str) -> User | None:
    ...

# TypedDict pour les dicts structures
from typing import TypedDict

class UserData(TypedDict):
    name: str
    email: str
    age: int | None
```

### Types avances

```python
from typing import TypeVar, Generic, Protocol, Final

# Generiques
T = TypeVar("T")

class Repository(Generic[T]):
    def get(self, id: str) -> T | None: ...
    def save(self, entity: T) -> T: ...

# Protocol (structural typing)
class Serializable(Protocol):
    def to_dict(self) -> dict[str, Any]: ...

# Final (constante)
MAX_RETRIES: Final = 3

# Literal
from typing import Literal
Status = Literal["active", "inactive", "suspended"]
```

## Docstrings (Google Style)

```python
def calculate_score(
    ratings: dict[str, float],
    weights: dict[str, float],
) -> float:
    """Calculate weighted score from ratings and weights.

    Args:
        ratings: Mapping of criterion name to score (0-10).
        weights: Mapping of criterion name to weight (0-1).
            Must sum to 1.0.

    Returns:
        Weighted score between 0 and 10.

    Raises:
        ValueError: If weights don't sum to 1.0.
        KeyError: If a rating is missing for a weighted criterion.

    Example:
        >>> calculate_score({"perf": 8, "ux": 9}, {"perf": 0.6, "ux": 0.4})
        8.4
    """
```

### Quand documenter

| Element | Docstring requise |
|---------|------------------|
| Module | Oui — description du module en haut |
| Classe publique | Oui — role, usage |
| Methode publique | Oui — args, returns, raises |
| Fonction privee | Non — sauf si complexe |
| Constante | Non — sauf si nom pas evident |

## Imports

```python
# Ordre (enforce par isort/ruff) :

# 1. Standard library
import os
import sys
from collections.abc import Sequence
from datetime import datetime, timedelta
from pathlib import Path

# 2. Third-party
import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select

# 3. Local
from app.models import User
from app.services.auth import verify_token
from .utils import format_date
```

### Regles

```python
# BIEN — import du module
import os
os.path.join(...)

# BIEN — import specifique
from os.path import join
join(...)

# MAL — wildcard import
from os import *

# BIEN — regrouper les imports du meme module
from fastapi import FastAPI, HTTPException, Depends
```

## Error Handling

```python
# Erreurs custom avec hierarchy
class AppError(Exception):
    """Base error for the application."""
    def __init__(self, message: str, code: str, status_code: int = 500) -> None:
        super().__init__(message)
        self.code = code
        self.status_code = status_code

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str) -> None:
        super().__init__(f"{resource} {id} not found", "NOT_FOUND", 404)

class ValidationError(AppError):
    def __init__(self, message: str) -> None:
        super().__init__(message, "VALIDATION_ERROR", 400)
```

### Regles

```python
# Toujours catcher des exceptions specifiques
# MAL
try:
    user = get_user(id)
except Exception:
    return None

# BIEN
try:
    user = get_user(id)
except UserNotFoundError:
    return None
except DatabaseError as e:
    logger.error("DB error fetching user %s: %s", id, e)
    raise

# Ne JAMAIS silencer les exceptions
# MAL
try:
    process()
except Exception:
    pass

# BIEN
try:
    process()
except SpecificError as e:
    logger.warning("Non-critical error: %s", e)
```

## Classes

```python
# Utiliser dataclasses pour les data containers
from dataclasses import dataclass, field

@dataclass(frozen=True)  # frozen = immutable
class User:
    id: str
    name: str
    email: str
    roles: list[str] = field(default_factory=list)

# Pydantic pour la validation
from pydantic import BaseModel, EmailStr, Field

class CreateUserRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    role: str = "member"

# Protocole pour dependency injection
from typing import Protocol

class UserRepository(Protocol):
    async def get(self, id: str) -> User | None: ...
    async def save(self, user: User) -> User: ...
```

## Async

```python
# Toujours async pour l'I/O
async def fetch_user(client: httpx.AsyncClient, user_id: str) -> User:
    response = await client.get(f"/api/users/{user_id}")
    response.raise_for_status()
    return User(**response.json())

# Parallelisme avec gather
async def fetch_all_users(ids: list[str]) -> list[User]:
    async with httpx.AsyncClient() as client:
        tasks = [fetch_user(client, id) for id in ids]
        return await asyncio.gather(*tasks)
```

## Structure projet

```
project/
├── pyproject.toml
├── src/
│   └── app/
│       ├── __init__.py
│       ├── main.py              # Entrypoint
│       ├── config.py            # Configuration
│       ├── models/              # Data models
│       │   ├── __init__.py
│       │   └── user.py
│       ├── services/            # Business logic
│       │   ├── __init__.py
│       │   └── user_service.py
│       ├── api/                 # HTTP handlers
│       │   ├── __init__.py
│       │   └── users.py
│       └── repositories/        # Data access
│           ├── __init__.py
│           └── user_repo.py
├── tests/
│   ├── conftest.py
│   ├── unit/
│   └── integration/
└── scripts/
```

## Outils

| Outil | Usage | Commande |
|-------|-------|----------|
| ruff | Linting + formatting | `ruff check . && ruff format .` |
| mypy | Type checking | `mypy --strict src/` |
| pytest | Tests | `pytest -v --cov=src/` |
| pre-commit | Git hooks | `pre-commit run --all-files` |
