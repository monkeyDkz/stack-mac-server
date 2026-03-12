# Rapport d'Audit Securite : [Scope]

## Resume executif

| Champ | Valeur |
|-------|--------|
| **Date** | YYYY-MM-DD |
| **Scope** | [Service / application / infrastructure auditee] |
| **Version** | [Version ou commit hash] |
| **Auditeur** | [Agent security] |
| **Duree de l'audit** | [X heures / jours] |
| **Resultat global** | [X critiques, Y hautes, Z moyennes, W basses] |
| **Score global** | [A / B / C / D / F] |

### Echelle de scoring

| Score | Criteres |
|:-----:|----------|
| **A** | 0 critique, 0 haute, <= 2 moyennes |
| **B** | 0 critique, <= 2 hautes, <= 5 moyennes |
| **C** | 0 critique, <= 5 hautes |
| **D** | 1+ critique OU > 5 hautes |
| **F** | Multiples critiques, systeme compromis |

---

## Methodologie

### Approche

- [ ] Revue de code statique (SAST)
- [ ] Analyse dynamique (DAST)
- [ ] Audit des dependances (SCA)
- [ ] Test d'injection (SQL, XSS, SSRF, command)
- [ ] Verification des headers HTTP
- [ ] Verification CORS / CSP
- [ ] Audit authentification et sessions
- [ ] Verification des permissions (authz)
- [ ] Audit de la configuration serveur
- [ ] Verification du chiffrement (TLS, at-rest)
- [ ] Revue de la gestion des secrets
- [ ] Audit des logs et monitoring

### Outils utilises

| Outil | Version | Usage |
|-------|---------|-------|
| [Outil 1] | [Version] | [Ce qu'il teste] |
| [Outil 2] | [Version] | [Ce qu'il teste] |

### Limites de l'audit

- [Ce qui n'a PAS ete teste et pourquoi]
- [Limitations de temps ou d'acces]

---

## Vulnerabilites trouvees

### Critiques (CVSS 9.0-10.0)

| # | Titre | CVSS | Categorie OWASP | Localisation | Statut |
|---|-------|:----:|:----------------:|-------------|:------:|
| C-1 | [Description courte] | [Score] | [A01-A10] | [Fichier/endpoint] | OUVERT |

**C-1 : [Titre complet]**

- **Description** : [Description technique detaillee de la vulnerabilite]
- **Impact** : [Ce qu'un attaquant peut faire en l'exploitant]
- **Reproduction** :
  ```bash
  # Etapes pour reproduire
  curl -X POST http://target/api/endpoint \
    -d '{"payload": "malicious"}'
  ```
- **Remediation** :
  ```typescript
  // Code corrige
  const sanitized = sanitize(input);
  ```
- **Priorite** : Correction immediate (< 24h)

### Hautes (CVSS 7.0-8.9)

| # | Titre | CVSS | Categorie OWASP | Localisation | Statut |
|---|-------|:----:|:----------------:|-------------|:------:|
| H-1 | [Description courte] | [Score] | [A01-A10] | [Fichier/endpoint] | OUVERT |

**H-1 : [Titre complet]**

- **Description** : [Description technique]
- **Impact** : [Impact]
- **Remediation** : [Correction recommandee]
- **Priorite** : Correction dans les 72h

### Moyennes (CVSS 4.0-6.9)

| # | Titre | CVSS | Categorie OWASP | Localisation | Statut |
|---|-------|:----:|:----------------:|-------------|:------:|
| M-1 | [Description] | [Score] | [A01-A10] | [Localisation] | OUVERT |
| M-2 | [Description] | [Score] | [A01-A10] | [Localisation] | OUVERT |

### Basses (CVSS 0.1-3.9)

| # | Titre | CVSS | Localisation | Statut |
|---|-------|:----:|-------------|:------:|
| L-1 | [Description] | [Score] | [Localisation] | OUVERT |

### Informationnelles

| # | Observation | Recommandation |
|---|-------------|---------------|
| I-1 | [Observation] | [Amelioration suggeree] |

---

## Checklist par categorie OWASP

### A01: Broken Access Control

- [ ] Permissions verifiees a chaque endpoint
- [ ] Pas d'IDOR (Insecure Direct Object Reference)
- [ ] CORS strictement configure
- [ ] Pas d'acces admin sans verification de role
- [ ] Tokens avec expiration correcte
- [ ] Default deny en place
- [ ] Directory listing desactive
- [ ] Pas de path traversal possible

### A02: Cryptographic Failures

- [ ] HTTPS/TLS 1.2+ partout
- [ ] Mots de passe hashes (argon2id/bcrypt)
- [ ] Pas de secrets dans le code source
- [ ] Pas de secrets dans les logs
- [ ] Donnees sensibles chiffrees au repos
- [ ] Pas d'algorithme faible (MD5, SHA1, DES)
- [ ] Certificats TLS valides et non expires
- [ ] HSTS active

### A03: Injection

- [ ] Queries SQL parametrees (pas de concatenation)
- [ ] Inputs valides avec schema (zod/pydantic)
- [ ] XSS prevenu (sanitization, CSP)
- [ ] Command injection prevenu (pas de shell exec avec user input)
- [ ] LDAP injection prevenu
- [ ] Template injection prevenu
- [ ] Header injection prevenu

### A04: Insecure Design

- [ ] Rate limiting sur endpoints sensibles
- [ ] Limites metier implementees
- [ ] Captcha sur formulaires publics
- [ ] Throttling sur les operations couteuses
- [ ] Principe du moindre privilege respecte

### A05: Security Misconfiguration

- [ ] Headers de securite configures (CSP, X-Frame-Options, HSTS, etc.)
- [ ] Pas de stack traces en production
- [ ] Ports inutiles fermes
- [ ] Credentials par defaut changees
- [ ] Mode debug desactive en production
- [ ] Containers Docker pas en root
- [ ] Fichiers sensibles non accessibles (.env, .git)

### A06: Vulnerable Components

- [ ] 0 CVE critique dans les dependances
- [ ] 0 CVE haute dans les dependances
- [ ] Lock files a jour
- [ ] Images Docker a jour
- [ ] Licences compatibles

### A07: Authentication Failures

- [ ] Rate limiting sur login (5/15min)
- [ ] Account lockout apres N echecs
- [ ] Mots de passe >= 12 caracteres
- [ ] Pas de credentials par defaut
- [ ] Session invalidee au logout
- [ ] Token refresh avec rotation
- [ ] MFA disponible pour les admins

### A08: Software Integrity

- [ ] Lock files utilises et verifies
- [ ] CI/CD sans secrets en clair
- [ ] Code review obligatoire
- [ ] Images Docker verifiees (hash)
- [ ] Pas de CDN non fiable

### A09: Logging Failures

- [ ] Login/logout logues
- [ ] Echecs auth logues
- [ ] Actions admin loguees
- [ ] Pas de donnees sensibles dans les logs
- [ ] Logs centralises
- [ ] Alertes sur patterns suspects

### A10: SSRF

- [ ] Validation des URLs en entree
- [ ] Blocage des IP privees
- [ ] Pas de redirection ouverte
- [ ] Timeout sur requetes sortantes

---

## Scoring CVSS

### Comment calculer

```
Base Score = f(Attack Vector, Attack Complexity, Privileges Required,
              User Interaction, Scope, Confidentiality, Integrity, Availability)

Calculateur : https://www.first.org/cvss/calculator/3.1
```

### Reference rapide

| Vecteur | Valeur haute | Valeur basse |
|---------|:-----------:|:------------:|
| Attack Vector | Network (0.85) | Physical (0.20) |
| Attack Complexity | Low (0.77) | High (0.44) |
| Privileges Required | None (0.85) | High (0.27) |
| User Interaction | None (0.85) | Required (0.62) |

---

## Recommandations prioritaires

1. **[Priorite 1 — Critique]** : [Action concrete avec deadline]
2. **[Priorite 2 — Haute]** : [Action concrete avec deadline]
3. **[Priorite 3 — Moyenne]** : [Action concrete avec deadline]
4. **[Amelioration systeme]** : [Recommendation architecturale]

## Prochaine etape

- [ ] Corriger les vulnerabilites critiques et hautes
- [ ] Re-audit apres corrections (verification)
- [ ] Planifier les corrections moyennes et basses
- [ ] Mettre a jour la politique de securite si necessaire

## Metadata

- Agent : security
- Date : YYYY-MM-DD
- Confiance : validated
- Mem0 ID : [id]
- Paperclip Task : PAPER-XX
