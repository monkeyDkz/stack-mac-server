# Framework d'execution de workflows

> Version condensee. Reference complete : `agents-playbook/24-workflow-execution-framework.md`
>
> Voir aussi : [stack--overview](./stack--overview.md), [conventions--api-design](./conventions--api-design.md)

---

## 1. Patterns d'orchestration

### Pattern 1 : Sequentiel

```
A → B → C → D
```

Pipeline lineaire. Chaque etape attend la precedente. Rollback possible a l'etape N-1.

### Pattern 2 : Fan-out / Fan-in

```
      ┌→ B ─┐
A ────┤→ C ─├──→ E
      └→ D ─┘
```

Parallelisation. Un coordinateur cree N taches independantes, attend toutes les completions. Si une echoue, les autres continuent (configurable).

### Pattern 3 : Pipeline continu

```
Code → Review → Test → Deploy → Monitor
  ↑                                  │
  └──────── Feedback ────────────────┘
```

Boucle de feedback. Chaque etape peut rejeter vers une etape precedente.

### Pattern 4 : Superviseur

```
CEO ──→ CTO ──→ Lead Backend
   │        └──→ Lead Frontend
   └──→ CPO ──→ Designer
```

Delegation hierarchique. Reporting periodique, escalade si bloqueur.

---

## 2. Workflows

### WF-FEAT : Feature Delivery

```
CPO(PRD) → CTO(archi+decomp) → [Backend + Frontend] → QA → Security(si requis) → DevOps
```

- **Pattern** : Sequentiel + Fan-out/Fan-in
- **Coordinateur** : CTO
- **Duree** : 5-10 heartbeat cycles
- CPO cree PRD (Mem0 `type: prd`, SiYuan `notebook: produit`)
- CTO decompose, Backend+Frontend en parallele
- QA valide, Security audite si auth/data/infra, DevOps deploie

### WF-BUG : Bug Resolution

```
QA(report) → CTO(triage) → Dev(fix) → QA(verify) → DevOps(hotfix)
```

- **Pattern** : Sequentiel
- **Coordinateur** : CTO
- **Duree** : 2-4 heartbeat cycles
- QA cree bug report (Mem0 `type: bug`), CTO triage et assigne
- Dev corrige + test de regression, QA re-valide, DevOps deploie hotfix

### WF-SEC : Security Audit

```
Security(scan) → CTO(prioritize) → [Backend + Frontend + DevOps](fix) → Security(verify)
```

- **Pattern** : Fan-out/Fan-in
- **Coordinateur** : Security
- **Duree** : 3-6 heartbeat cycles
- Security scanne, CTO priorise (critique d'abord)
- Agents corrigent en parallele par domaine, Security re-verifie

### WF-RESEARCH : Tech Research

```
CEO(objectif) → Researcher(analyse) → CTO(decision) → CEO(validation)
```

- **Pattern** : Sequentiel
- **Coordinateur** : CEO
- **Duree** : 2-4 heartbeat cycles
- Researcher utilise Firecrawl + Chroma + web, produit un rapport
- CTO evalue (Decision Record), CEO valide l'alignement strategique

### WF-COST : Cost Review

```
CFO(analyse) → CEO(decision) → CTO(optimisation) → CFO(verification)
```

- **Pattern** : Sequentiel
- **Coordinateur** : CFO
- **Duree** : 1-2 heartbeat cycles
- CFO analyse les couts (Paperclip stats), CEO ajuste le budget
- CTO optimise (model downgrades, batch), CFO verifie l'impact

### WF-DESIGN : Design Iteration

```
CPO(specs) → Designer(wireframe) → Frontend(impl) → QA(test) → Designer(review)
```

- **Pattern** : Pipeline avec feedback
- **Coordinateur** : CPO
- **Duree** : 4-8 heartbeat cycles
- Designer cree wireframes (SiYuan), Frontend implemente
- QA teste (a11y, visual), Designer boucle si non conforme

---

## 3. Gestion d'etat

**ID** : `WF-{type}-{timestamp}` (ex: `WF-FEAT-1710200400`)

**Stockage Mem0** :

```json
{
  "type": "context",
  "tags": "workflow,WF-FEAT-1710200400",
  "state": "active",
  "metadata": { "pattern": "sequentiel+fan-out", "coordinator": "cto", "phase": 3 }
}
```

**Transitions** :

```
initiated → in_progress → completed
                ↕              ↑
             blocked      failed
```

- `initiated` → `in_progress` → `completed` : flux normal
- `in_progress` ↔ `blocked` : bloqueur identifie / resolu
- `in_progress` → `failed` : echec irrecuperable
- `failed` → `initiated` : relance manuelle

**Paperclip** : issue parent (workflow) → issues enfant (etapes), labels `workflow`, `WF-{type}`, `phase-{N}`.

---

## 4. Gestion des echecs

| Mecanisme          | Description                                                        |
|--------------------|--------------------------------------------------------------------|
| **Retry**          | 1 retry auto pour taches simples (API, deploy). Delai : 1 cycle.  |
| **Escalade**       | Agent → Coordinateur → CTO → CEO                                  |
| **Circuit breaker**| > 3 echecs meme type → pause workflow + alerte CEO                 |
| **Rollback**       | DevOps via n8n (`agent-deploy`, `action: rollback`)                |
| **Post-mortem**    | Memory `type: incident` avec root cause + action preventive        |

Post-mortem Mem0 :

```json
{
  "type": "incident",
  "tags": "post-mortem,WF-ID",
  "metadata": { "failed_step": 3, "root_cause": "...", "resolution": "...", "preventive_action": "..." }
}
```

---

## 5. Template nouveau workflow

```markdown
## WF-{ID} : {Nom}

**Pattern** : {sequentiel | fan-out | pipeline | superviseur}
**Declencheur** : {evenement ou commande}
**Coordinateur** : {agent responsable}
**Participants** : {liste d'agents}
**Duree estimee** : {N heartbeat cycles}

### Etapes
1. {Agent}({action}) → output: {livrable}

### Criteres de succes
- [ ] ...

### Gestion d'echec
- Si etape N echoue: {action}
```

---

## 6. Resume

| Workflow    | Pattern                | Coord.   | Duree        |
|-------------|------------------------|----------|--------------|
| WF-FEAT     | Sequentiel + Fan-out   | CTO      | 5-10 cycles  |
| WF-BUG      | Sequentiel             | CTO      | 2-4 cycles   |
| WF-SEC      | Fan-out/Fan-in         | Security | 3-6 cycles   |
| WF-RESEARCH | Sequentiel             | CEO      | 2-4 cycles   |
| WF-COST     | Sequentiel             | CFO      | 1-2 cycles   |
| WF-DESIGN   | Pipeline + feedback    | CPO      | 4-8 cycles   |
