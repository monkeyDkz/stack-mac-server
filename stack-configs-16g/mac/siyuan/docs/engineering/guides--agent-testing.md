# Guide de test des agents

> Ce document decrit la strategie de test pour le systeme multi-agent.
> Il couvre les quatre niveaux de test, les scenarios par agent,
> les outils disponibles et la matrice de couverture.

---

## Principes de test

- Chaque agent doit etre teste **individuellement** et **en interaction** avec les autres.
- Les tests doivent etre **reproductibles** et **automatisables**.
- Chaque modification de prompt ou de configuration doit declencher les tests de regression.
- Les resultats de test sont stockes dans Mem0 pour tracabilite.

---

## Niveaux de test

### Niveau 1 : Test de prompt

**Objectif** : valider que le prompt de l'agent produit le comportement attendu.

**Methode** :
1. Preparer un scenario d'entree (message utilisateur ou tache Paperclip).
2. Envoyer le scenario a l'agent via curl vers Ollama (ou LiteLLM).
3. Verifier la sortie par rapport aux criteres attendus.

**Criteres de validation** :
- L'agent suit ses regles non-negociables definies dans son prompt systeme.
- L'agent utilise le bon format de memoire (schema Mem0 conforme).
- L'agent ne depasse pas son perimetre de responsabilite.
- Le ton et le format de la reponse sont conformes aux conventions.

**Exemple de test de prompt** :

```bash
#!/bin/bash
# test-prompt.sh - Test de prompt basique
AGENT_ID="$1"
SCENARIO="$2"

RESPONSE=$(curl -s http://localhost:11434/api/chat \
  -d "{
    \"model\": \"qwen2.5:14b\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"$(cat prompts/${AGENT_ID}.md)\"},
      {\"role\": \"user\", \"content\": \"${SCENARIO}\"}
    ],
    \"stream\": false
  }" | jq -r '.message.content')

echo "Reponse de l'agent ${AGENT_ID}:"
echo "$RESPONSE"

# Verifications basiques
if echo "$RESPONSE" | grep -q "MEMORY_SAVE"; then
  echo "PASS: L'agent tente de sauvegarder en memoire"
else
  echo "FAIL: L'agent ne sauvegarde pas en memoire"
fi
```

---

### Niveau 2 : Test de memoire

**Objectif** : valider que l'agent lit et ecrit correctement dans Mem0.

**Methode** :
1. Executer une tache qui devrait produire une sauvegarde memoire.
2. Interroger Mem0 pour verifier que la memoire a ete creee.
3. Valider le schema et les metadonnees de la memoire.

**Assertions obligatoires** :
- La memoire est sauvegardee avec le **type correct** (decision, architecture, bug, etc.).
- Les **metadonnees sont completes** : `type`, `project`, `confidence`, `source_task`.
- **Pas de duplication** : aucune memoire existante avec un cosine > 0.92.
- Les **relations sont correctes** : `supersedes` pointe vers la bonne memoire precedente,
  `depends_on` reference les bonnes dependances.

**Script de validation memoire** :

```bash
#!/bin/bash
# test-memory.sh - Validation memoire post-tache
AGENT_ID="$1"
TASK_ID="$2"

echo "=== Verification memoire pour ${AGENT_ID} apres tache ${TASK_ID} ==="

# Recuperer les memoires recentes de l'agent
MEMORIES=$(curl -s "http://localhost:8050/memories?user_id=${AGENT_ID}&limit=5")

# Verifier que le type est present
SANS_TYPE=$(echo "$MEMORIES" | jq '[.[] | select(.metadata.type == null)] | length')
if [ "$SANS_TYPE" -gt 0 ]; then
  echo "FAIL: ${SANS_TYPE} memoire(s) sans type"
else
  echo "PASS: Toutes les memoires ont un type"
fi

# Verifier que le project est present
SANS_PROJECT=$(echo "$MEMORIES" | jq '[.[] | select(.metadata.project == null)] | length')
if [ "$SANS_PROJECT" -gt 0 ]; then
  echo "FAIL: ${SANS_PROJECT} memoire(s) sans project"
else
  echo "PASS: Toutes les memoires ont un project"
fi

# Verifier que la confidence est presente
SANS_CONF=$(echo "$MEMORIES" | jq '[.[] | select(.metadata.confidence == null)] | length')
if [ "$SANS_CONF" -gt 0 ]; then
  echo "FAIL: ${SANS_CONF} memoire(s) sans confidence"
else
  echo "PASS: Toutes les memoires ont une confidence"
fi

# Verifier la source_task
SANS_SOURCE=$(echo "$MEMORIES" | jq '[.[] | select(.metadata.source_task == null)] | length')
if [ "$SANS_SOURCE" -gt 0 ]; then
  echo "WARN: ${SANS_SOURCE} memoire(s) sans source_task (orphelines)"
fi

echo "=== Fin de verification ==="
```

---

### Niveau 3 : Test de workflow

**Objectif** : valider qu'un workflow multi-agent complete de bout en bout.

**Methode** :
1. Lancer un workflow complet en mode test (par exemple : nouvelle feature, de PRD a deploiement).
2. Suivre chaque etape du workflow et verifier les sorties intermediaires.
3. Valider que les handoffs entre agents sont corrects.
4. Verifier que la chaine de memoire (memory trail) est complete.

**Points de verification** :
- Chaque etape produit le bon **output** dans le format attendu.
- Les **handoffs** sont corrects : la tache est assignee au bon agent suivant.
- La **chaine de memoire** est tracable de bout en bout (source_task, depends_on).
- Les **etats de tache** sont mis a jour correctement dans Paperclip.
- Aucune **perte d'information** entre les etapes.

**Exemple de workflow de test** :

```bash
#!/bin/bash
# test-workflow.sh - Test de workflow bout en bout
WORKFLOW="feature-delivery"

echo "=== Test workflow : ${WORKFLOW} ==="

# Etape 1 : CPO cree le PRD
echo "Etape 1 : Creation PRD par CPO..."
TASK_1=$(curl -s -X POST "http://localhost:3001/api/tasks" \
  -H "Content-Type: application/json" \
  -d '{"title": "Creer PRD test", "assignee": "cpo", "type": "prd"}' | jq -r '.id')
echo "Tache creee : ${TASK_1}"

# Attendre completion
sleep 30

# Verifier que le PRD existe dans Mem0
PRD_COUNT=$(curl -s "http://localhost:8050/search" \
  -H "Content-Type: application/json" \
  -d '{"query": "PRD test", "user_id": "cpo", "filters": {"type": "prd"}}' | jq 'length')

if [ "$PRD_COUNT" -gt 0 ]; then
  echo "PASS: PRD cree dans Mem0"
else
  echo "FAIL: PRD non trouve dans Mem0"
fi

# Etape 2 : CTO cree l'ADR
echo "Etape 2 : Verification handoff vers CTO..."
# ... (verification similaire)

echo "=== Fin du test workflow ==="
```

---

### Niveau 4 : Test de regression

**Objectif** : detecter les regressions comportementales apres modification de prompt ou configuration.

**Methode** :
1. Maintenir une suite de scenarios de reference avec les sorties attendues.
2. Apres chaque modification, rejouer tous les scenarios.
3. Comparer les outputs avant et apres la modification.
4. Signaler toute divergence significative.

**Criteres de regression** :
- L'agent ne respecte plus ses non-negociables.
- Le format de memoire a change.
- Le comportement de handoff est different.
- La qualite des reponses a diminue (evaluation manuelle si necessaire).

**Structure du repertoire de regression** :

```
tests/
  regression/
    ceo/
      scenario-01-input.json
      scenario-01-expected.json
      scenario-02-input.json
      scenario-02-expected.json
    cto/
      ...
```

---

## Scenarios de test par agent

### CEO (3 scenarios)

1. **Recruter un agent** : envoyer une demande de recrutement → verifier que la reponse
   contient la section ONBOARDING et que le prompt systeme est genere.
2. **Arbitrer un conflit** : soumettre un conflit entre deux agents → verifier qu'un
   Decision Record est cree dans Mem0 avec le type `decision`.
3. **Knowledge review** : demander une revue des connaissances → verifier que la tache
   est deleguee au CTO via Paperclip.

### CTO (3 scenarios)

1. **Decision architecture** : poser une question d'architecture → verifier qu'un ADR
   est cree, qu'une memoire est sauvegardee et que la propagation est effectuee.
2. **Code review** : soumettre du code → verifier que le feedback est conforme aux
   conventions etablies et reference les bonnes memoires.
3. **Cross-agent status** : demander le statut inter-agents → verifier la lecture
   multi-agent dans Mem0 et la synthese correcte.

### CPO (3 scenarios)

1. **Creer un PRD** : demander la creation d'un PRD → verifier le format, la sauvegarde
   Mem0 avec `type=prd` et la delegation aux leads.
2. **Prioriser le backlog** : soumettre des items → verifier le classement et la
   justification dans la memoire.
3. **Review sprint** : demander un bilan de sprint → verifier la collecte de metriques
   aupres des agents concernes.

### CFO (3 scenarios)

1. **Rapport hebdomadaire** : declencher le rapport cout → verifier le format et
   l'exhaustivite des donnees par agent.
2. **Alerte budget** : simuler un depassement → verifier l'alerte CEO et la
   recommandation d'optimisation.
3. **Tendance mensuelle** : demander l'analyse tendancielle → verifier les graphiques
   et comparaisons mois sur mois.

### Lead Backend (3 scenarios)

1. **Concevoir une API** : demander une spec API → verifier que le format OpenAPI
   est conforme et complet.
2. **Sauvegarder un pattern** : identifier un pattern recurrent → verifier que la
   memoire contient les metadonnees correctes (`type=pattern`, `confidence`, `project`).
3. **Performance fix** : rapporter un probleme de performance → verifier qu'un
   learning est cree avec les metriques avant/apres.

### Lead Frontend (3 scenarios)

1. **Concevoir un composant** : demander une spec de composant → verifier la
   conformite au design system.
2. **Audit Lighthouse** : declencher un audit → verifier le format du rapport
   et la sauvegarde des metriques.
3. **Accessibilite** : soumettre un composant → verifier les recommandations
   WCAG et la memoire associee.

### DevOps (3 scenarios)

1. **Deploiement** : declencher un deploiement → verifier les etapes, les logs
   et la mise a jour du statut.
2. **Incident** : signaler un incident → verifier la creation de la memoire
   d'incident et les notifications.
3. **Infrastructure review** : demander une revue → verifier la collecte des
   metriques et les recommandations.

### Security (3 scenarios)

1. **Audit securite** : declencher un audit → verifier le scan, le rapport
   et les memoires de vulnerabilite.
2. **Vulnerabilite critique** : signaler une CVE → verifier l'alerte immediate,
   la memoire avec `severity=critical` et le plan de remediation.
3. **Review dependances** : verifier les dependances → verifier la liste des
   packages obsoletes et les recommandations.

### QA (3 scenarios)

1. **Plan de test** : demander un plan de test → verifier la couverture des
   cas et le format.
2. **Rapport de bug** : soumettre un bug → verifier la memoire creee avec
   `type=bug`, la severite et les etapes de reproduction.
3. **Bilan qualite** : demander un bilan → verifier la collecte des metriques
   de coverage et de bugs.

### Designer (3 scenarios)

1. **Nouveau composant UI** : demander un design → verifier la conformite
   au design system et la documentation.
2. **Review design** : soumettre un mockup → verifier le feedback et les
   references aux patterns existants.
3. **Guide de style** : demander une mise a jour → verifier la coherence
   avec le design system existant.

### Researcher (3 scenarios)

1. **Veille technologique** : demander une recherche → verifier le digest
   avec sources, resume et recommandations.
2. **Benchmark** : demander une comparaison → verifier le format structuree
   avec pros/cons et conclusion.
3. **State of the art** : demander un etat de l'art → verifier l'exhaustivite
   et la sauvegarde dans Mem0 avec `type=research`.

---

## Outils de test

### Script principal

```bash
#!/bin/bash
# test-agent.sh <agent-id> <scenario-number>
# Usage : ./test-agent.sh cto 1

AGENT_ID="$1"
SCENARIO="$2"
SCENARIOS_DIR="tests/scenarios/${AGENT_ID}"
INPUT_FILE="${SCENARIOS_DIR}/scenario-${SCENARIO}-input.json"
EXPECTED_FILE="${SCENARIOS_DIR}/scenario-${SCENARIO}-expected.json"

if [ ! -f "$INPUT_FILE" ]; then
  echo "ERREUR: Scenario introuvable : ${INPUT_FILE}"
  exit 1
fi

echo "Execution du scenario ${SCENARIO} pour l'agent ${AGENT_ID}..."

# Executer le scenario
RESULT=$(curl -s http://localhost:11434/api/chat \
  -d "$(cat ${INPUT_FILE})" | jq -r '.message.content')

# Sauvegarder le resultat
echo "$RESULT" > "${SCENARIOS_DIR}/scenario-${SCENARIO}-result.txt"

echo "Resultat sauvegarde. Verification en cours..."
```

### Assertions Mem0

```bash
# Verifier qu'une memoire a ete creee avec le bon type
curl -s "http://localhost:8050/search/filtered" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"${AGENT_ID}\",
    \"filters\": {\"type\": \"${EXPECTED_TYPE}\"}
  }" | jq 'if length > 0 then "PASS" else "FAIL" end'
```

### Assertions SiYuan

```bash
# Verifier la structure d'un document SiYuan
curl -s "http://localhost:6806/api/query/sql" \
  -H "Content-Type: application/json" \
  -d "{
    \"stmt\": \"SELECT * FROM blocks WHERE hpath LIKE '%${DOC_PATH}%' LIMIT 1\"
  }" | jq 'if .data | length > 0 then "PASS" else "FAIL" end'
```

---

## Framework de validation memoire

Script complet qui verifie toutes les memoires d'un agent :

```bash
#!/bin/bash
# validate-memories.sh <agent-id>
AGENT_ID="$1"

echo "=== Validation des memoires de l'agent ${AGENT_ID} ==="

# Verifier schema compliance (toutes les memories doivent avoir un type)
SANS_TYPE=$(curl -s "http://localhost:8050/memories?user_id=${AGENT_ID}" | \
  jq '[.[] | select(.metadata.type == null)] | length')
echo "Memoires sans type : ${SANS_TYPE} (attendu : 0)"

# Verifier les doublons
DOUBLONS=$(curl -s "http://localhost:8050/memories?user_id=${AGENT_ID}" | \
  jq '[.[] | .content] | group_by(.) | map(select(length > 1)) | length')
echo "Groupes de doublons exacts : ${DOUBLONS} (attendu : 0)"

# Verifier les orphelines
ORPHELINES=$(curl -s "http://localhost:8050/memories?user_id=${AGENT_ID}" | \
  jq '[.[] | select(.metadata.source_task == null and .metadata.type != "context")] | length')
echo "Memoires orphelines : ${ORPHELINES}"

# Verifier les etats invalides
INVALIDES=$(curl -s "http://localhost:8050/memories?user_id=${AGENT_ID}" | \
  jq '[.[] | select(
    .metadata.state != "active" and
    .metadata.state != "deprecated" and
    .metadata.state != "archived" and
    .metadata.state != null
  )] | length')
echo "Memoires avec etat invalide : ${INVALIDES} (attendu : 0)"

echo "=== Fin de validation ==="
```

---

## Matrice de couverture

| Agent          | Niveau 1 (Prompt) | Niveau 2 (Memoire) | Niveau 3 (Workflow) | Niveau 4 (Regression) |
|----------------|:------------------:|:-------------------:|:-------------------:|:---------------------:|
| CEO            | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| CTO            | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| CPO            | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| CFO            | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| Lead Backend   | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| Lead Frontend  | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| DevOps         | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| Security       | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| QA             | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| Designer       | A couvrir          | A couvrir           | A couvrir           | A couvrir             |
| Researcher     | A couvrir          | A couvrir           | A couvrir           | A couvrir             |

> **Objectif** : atteindre 100% de couverture sur les niveaux 1 et 2 pour tous les agents
> avant la mise en production. Les niveaux 3 et 4 sont a implementer progressivement.

---

## References

- [guidelines--testing](./guidelines--testing.md) : conventions de test generales
- [policies--knowledge-freshness](../operations/policies--knowledge-freshness.md) : politique de fraicheur des connaissances
