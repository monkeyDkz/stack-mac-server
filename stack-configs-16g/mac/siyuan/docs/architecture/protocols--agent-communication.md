# Protocole de communication inter-agents

*Reference : protocole complet dans le playbook Paperclip `23-agent-communication-protocol.md`*

---

## 1. Canaux de communication

| Canal | Usage | Quand |
|-------|-------|-------|
| **Paperclip Issues** | Delegation formelle (tache, checkout, release) | Toute action executable |
| **Mem0 memories** | Knowledge persistant (decisions, conventions, learnings) | Information durable utile aux autres agents |
| **SiYuan docs** | Documentation structuree (specs, guidelines, rapports) | Contenu reference long terme |
| **n8n webhooks** | Notifications event-driven (deploy, alerte, CRM) | Evenement necessitant reaction immediate |

**Format webhook n8n** : `POST $N8N_WEBHOOK_URL/agent-event` avec body `{ event, agent, task_id, payload }`

### Arbre de decision

- **Tache a realiser** → Paperclip Issue
- **Savoir court et factuel** → Mem0 memory
- **Savoir long et structure** → SiYuan document
- **Evenement a signaler** → n8n webhook

---

## 2. Matrice de visibilite Mem0

| Agent | Lit les memories de |
|-------|---------------------|
| **CEO** | cto, cpo, cfo, monitoring, analytics, crm |
| **CTO** | ceo, lead-backend, lead-frontend, devops, security, qa, monitoring, deployments, git-events |
| **CPO** | ceo, cto, designer, analytics, crm, calendar |
| **CFO** | ceo, analytics, crm |
| **Lead Backend** | cto, lead-frontend, qa, monitoring, git-events |
| **Lead Frontend** | cto, lead-backend, designer, qa, monitoring, git-events |
| **DevOps** | cto, security, monitoring, deployments, git-events, security-events |
| **Security** | cto, lead-backend, lead-frontend, devops, researcher, security-events, monitoring |
| **QA** | cto, lead-backend, lead-frontend, monitoring |
| **Designer** | cpo |
| **Researcher** | cto, monitoring |

**Regles** : aucun agent ne lit ses propres memories. Les user_ids systeme (`monitoring`, `analytics`, `crm`, `calendar`, `deployments`, `git-events`, `security-events`) sont alimentes par n8n.

---

## 3. Protocole de delegation (5 etapes)

### Etape 1 — Recherche contexte

Le demandeur cherche dans Mem0 les memories liees au sujet (`POST /memories/search`). Objectif : eviter les doublons et fournir le contexte.

### Etape 2 — Creation tache

Creer une Paperclip issue avec :
- **Titre** : clair et actionnable
- **Description** : contexte suffisant
- **context_memories** : liste des memory IDs pertinents
- **acceptance_criteria** : criteres mesurables de validation

### Etape 3 — Checkout

L'assignee prend en charge la tache, charge les `context_memories` referencees. Un seul agent par tache.

### Etape 4 — Execution et livraison

L'assignee execute, sauvegarde ses learnings dans Mem0 (`type: learning` ou `bug`), puis livre le resultat. Toujours sauvegarder au moins un learning, meme en cas de succes.

### Etape 5 — Validation

Le demandeur valide contre les criteres d'acceptation :
- `accepted` → tache close
- `changes_requested` → retour a l'etape 4

Maximum 2 cycles de corrections avant escalade.

---

## 4. Protocole d'escalade

### Chemins par domaine

| Domaine | Chemin |
|---------|--------|
| **Technique** | Engineer → Lead → CTO → CEO |
| **Produit** | Designer/Lead → CPO → CEO |
| **Securite** | N'importe qui → Security → CTO → CEO *(bypass hierarchie)* |
| **Finance** | N'importe qui → CFO → CEO |

### Triggers

| Trigger | Action |
|---------|--------|
| Blocker > 1 heartbeat cycle | Escalader au niveau superieur |
| Decision hors scope | Escalader au decideur competent |
| Conflit entre agents de meme niveau | Escalader au superieur commun |
| Incident securite | Escalade IMMEDIATE (pas besoin de justifier) |

### Regles

- Toujours joindre le contexte (memories, tentatives, options)
- Ne jamais escalader a vide — documenter ce qui a ete essaye
- L'agent qui escalade reste disponible pour fournir des informations

---

## 5. Pattern multi-agent (collaboration)

Pour les taches necessitant 2+ agents.

### Roles

- **Coordinateur** : possede le workflow, decompose, aggrege (typiquement Lead ou CTO)
- **Contributeurs** : executent les sous-taches assignees

### Deroulement

1. **Decomposition** : le coordinateur cree les sous-taches et les assigne
2. **Tagging partage** : toutes les memories taguees `project: X, phase: Y`
3. **Execution parallele** : chaque contributeur travaille independamment
4. **Point de sync** : le coordinateur verifie toutes les sous-taches avant de continuer
5. **Merge et livraison** : le coordinateur aggrege et livre le resultat final

### Regles

- Un seul coordinateur par workflow
- Les contributeurs ne communiquent pas directement entre eux — tout passe par le coordinateur via Paperclip issues
- Le tag `project` doit etre identique sur toutes les memories liees
- Le coordinateur est responsable des deadlines et de l'escalade

---

## 6. Anti-patterns a eviter

| Anti-pattern | Probleme | Solution |
|--------------|----------|----------|
| **Appels directs agent-a-agent** | Pas de tracabilite ni visibilite | Toujours passer par Paperclip issues |
| **Pollution memoire** | Degrade la qualite des recherches Mem0 | Ne sauvegarder que decisions finales, learnings confirmes, conventions |
| **Echecs silencieux** | Le meme echec sera repete | Toujours sauvegarder un learning apres une erreur |
| **Escalade prematuree** | Surcharge les agents superieurs | Tenter au moins une solution avant d'escalader |
| **Duplication de taches** | Gaspillage de ressources | Verifier Mem0 et Paperclip issues avant de creer |

---

## 7. Timeouts et SLAs

| Type | SLA | Timeout |
|------|-----|---------|
| **Tache simple** | < 2 heartbeat cycles | Escalade automatique au superieur |
| **Tache complexe** | < 5 heartbeat cycles | Escalade automatique au superieur |
| **Incident securite** | Immediat | Pas de delai |

**Regles** :
- Escalade automatique si timeout depasse
- Notification CEO si tache > 24h sans activite (via n8n webhook `task-timeout`)
- L'agent en timeout doit sauvegarder un learning expliquant le blocage

---

## Voir aussi

- [conventions--api-design](./conventions--api-design.md) — Conventions REST pour les endpoints utilises dans les communications inter-agents
- [stack--overview](./stack--overview.md) — Architecture globale de la stack et ports des services
