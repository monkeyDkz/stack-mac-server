# Accessibilite — WCAG 2.1 AA

*Checklist complete, techniques de remediation, outils de test*

## Principes POUR (WCAG 2.1)

| Principe | Description | Exemples |
|----------|-------------|----------|
| **P**erceptible | Le contenu est perceptible par tous les sens | Alt text, contraste, sous-titres |
| **O**perable | L'interface est utilisable de toutes les manieres | Clavier, temps suffisant, pas de flash |
| **U**nderstandable | Le contenu et l'interface sont comprehensibles | Langue, labels, messages d'erreur |
| **R**obust | Le contenu fonctionne avec les technologies d'assistance | HTML valide, ARIA, screen readers |

## Contraste des couleurs

### Exigences WCAG AA

| Type de contenu | Ratio minimum | Comment verifier |
|----------------|:-------------:|-----------------|
| Texte normal (< 18px) | 4.5:1 | Contrast checker |
| Texte large (>= 18px ou >= 14px bold) | 3:1 | Contrast checker |
| Composants UI (bordures, icones) | 3:1 | Contrast checker |
| Texte decoratif, logos | Exempt | - |

### Verifier le contraste

```bash
# Chrome DevTools
# 1. Inspecter l'element
# 2. Cliquer sur le carre de couleur dans Styles
# 3. Lire le ratio de contraste affiche

# Outils en ligne
# https://webaim.org/resources/contrastchecker/
# https://colorable.jxnblk.com/

# Audit complet
# Lighthouse > Accessibility
# axe DevTools extension
```

### Regles pour nos tokens

```css
/* BIEN — texte secondaire sur fond page */
/* #475569 sur #ffffff = 6.0:1 (AA OK) */
color: var(--color-text-secondary);
background: var(--color-surface-page);

/* BIEN — texte sur bouton primary */
/* #ffffff sur #2563eb = 4.6:1 (AA OK) */
color: var(--color-text-on-primary);
background: var(--color-primary-600);

/* ATTENTION — texte tertiaire */
/* #94a3b8 sur #ffffff = 3.2:1 (AA Large text OK, Normal text NON) */
/* Utiliser uniquement pour du texte >= 18px ou des labels non essentiels */
```

## Focus management

### Focus visible obligatoire

```css
/* Style de focus par defaut */
:focus-visible {
  outline: 2px solid var(--color-border-focus);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

/* Ne JAMAIS faire */
*:focus {
  outline: none; /* INTERDIT — rend impossible la navigation clavier */
}

/* Acceptable : personnaliser le focus, pas le supprimer */
.btn:focus-visible {
  outline: 2px solid var(--color-primary-500);
  outline-offset: 2px;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.3);
}
```

### Ordre de focus logique

```html
<!-- BIEN — ordre naturel du DOM = ordre de focus -->
<nav>
  <a href="/">Accueil</a>
  <a href="/dashboard">Dashboard</a>
  <a href="/settings">Settings</a>
</nav>
<main>
  <h1>Dashboard</h1>
  <button>Action</button>
</main>

<!-- MAL — tabindex positif casse l'ordre naturel -->
<button tabindex="3">Troisieme</button>
<button tabindex="1">Premier</button>
<button tabindex="2">Deuxieme</button>
```

### Focus trapping (modales)

```typescript
// Quand une modale s'ouvre :
// 1. Deplacer le focus vers la modale
// 2. Pieger le focus (Tab cycle dans la modale)
// 3. Escape ferme la modale
// 4. Restaurer le focus a l'element declencheur

function trapFocus(modal: HTMLElement) {
  const focusable = modal.querySelectorAll(
    'a[href], button, textarea, input, select, [tabindex]:not([tabindex="-1"])'
  );
  const first = focusable[0] as HTMLElement;
  const last = focusable[focusable.length - 1] as HTMLElement;

  modal.addEventListener('keydown', (e) => {
    if (e.key === 'Tab') {
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    }
    if (e.key === 'Escape') {
      closeModal();
    }
  });

  first.focus();
}
```

## Navigation clavier

### Touches standard

| Touche | Action | Contexte |
|--------|--------|----------|
| Tab | Avancer au prochain element focusable | Partout |
| Shift+Tab | Reculer | Partout |
| Enter | Activer le bouton/lien | Boutons, liens |
| Space | Activer le bouton, toggle checkbox | Boutons, checkboxes |
| Escape | Fermer modale/dropdown/tooltip | Overlays |
| Fleches | Naviguer dans les listes/tabs/menus | Composants complexes |
| Home/End | Premier/dernier element | Listes |

### Composants et patterns clavier

```html
<!-- Tabs : fleches gauche/droite pour naviguer -->
<div role="tablist">
  <button role="tab" aria-selected="true" tabindex="0">Tab 1</button>
  <button role="tab" aria-selected="false" tabindex="-1">Tab 2</button>
  <button role="tab" aria-selected="false" tabindex="-1">Tab 3</button>
</div>
<div role="tabpanel">Contenu tab 1</div>

<!-- Dropdown menu : fleches haut/bas -->
<button aria-haspopup="true" aria-expanded="false">Menu</button>
<ul role="menu" hidden>
  <li role="menuitem" tabindex="-1">Option 1</li>
  <li role="menuitem" tabindex="-1">Option 2</li>
</ul>
```

## ARIA (Accessible Rich Internet Applications)

### Landmarks

```html
<header role="banner">
  <nav role="navigation" aria-label="Navigation principale">...</nav>
</header>
<main role="main">
  <section aria-labelledby="section-title">
    <h2 id="section-title">Titre de section</h2>
  </section>
</main>
<aside role="complementary" aria-label="Sidebar">...</aside>
<footer role="contentinfo">...</footer>
```

### Attributs ARIA essentiels

| Attribut | Usage | Exemple |
|----------|-------|---------|
| `aria-label` | Label invisible (icone-only buttons) | `<button aria-label="Fermer">X</button>` |
| `aria-labelledby` | Reference un element visible comme label | `<section aria-labelledby="heading-1">` |
| `aria-describedby` | Description additionnelle | `<input aria-describedby="email-help">` |
| `aria-expanded` | Etat ouvert/ferme | `<button aria-expanded="true">` |
| `aria-hidden` | Cache aux screen readers | `<span aria-hidden="true">🔍</span>` |
| `aria-live` | Annonce les changements | `<div aria-live="polite">3 resultats` |
| `aria-required` | Champ obligatoire | `<input aria-required="true">` |
| `aria-invalid` | Champ en erreur | `<input aria-invalid="true">` |
| `role` | Role semantique | `<div role="alert">Erreur!</div>` |

### Regle d'or ARIA

> **Pas d'ARIA est meilleur que du mauvais ARIA.**
> Utiliser les elements HTML natifs en priorite (`<button>`, `<nav>`, `<input>`).
> ARIA ne donne que des hints aux screen readers, il ne change pas le comportement.

## Formulaires accessibles

```html
<!-- BIEN — label explicite, aide, erreur associee -->
<div class="form-field">
  <label for="email">Adresse email</label>
  <input
    type="email"
    id="email"
    name="email"
    required
    aria-required="true"
    aria-describedby="email-help email-error"
    aria-invalid="true"
  >
  <p id="email-help" class="form-helper">Nous ne partagerons jamais votre email.</p>
  <p id="email-error" class="form-error" role="alert">L'adresse email est invalide.</p>
</div>

<!-- MAL — pas de label, placeholder comme label -->
<input type="email" placeholder="Email">
```

## Motion et animations

```css
/* Respecter les preferences utilisateur */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

/* Animations par defaut : courtes et subtiles */
.transition {
  transition: all 150ms ease-in-out;
}
```

### Regles pour les animations

- Pas de flash > 3 fois par seconde (risque d'epilepsie)
- Pas d'animation automatique > 5 secondes sans controle utilisateur
- Fournir un moyen de mettre en pause les animations
- Les transitions UI < 300ms (perceptible mais pas distrayant)

## Screen reader

### Contenu cache visuellement mais accessible

```css
/* Classe utilitaire : visible pour screen reader, invisible visuellement */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

/* Usage */
/* <span class="sr-only">Ouvrir le menu de navigation</span> */
```

### Annonces dynamiques

```html
<!-- Zone de notification pour screen readers -->
<div aria-live="polite" aria-atomic="true" class="sr-only" id="announcer">
  <!-- Le contenu injecte ici sera annonce -->
</div>
```

```typescript
function announce(message: string): void {
  const el = document.getElementById('announcer');
  if (el) el.textContent = message;
}

// Usage
announce('3 resultats trouves');
announce('Formulaire soumis avec succes');
```

## Checklist de test

### Automatise (CI)

- [ ] Lighthouse Accessibility score >= 90
- [ ] axe-core : 0 violations critiques ou graves
- [ ] HTML valide (pas d'erreurs W3C)
- [ ] Toutes les images ont un alt text

### Manuel

- [ ] Navigation complete au clavier (Tab through tout)
- [ ] Focus visible sur chaque element interactif
- [ ] Pas de piege clavier
- [ ] Modale : focus piege + Escape ferme
- [ ] VoiceOver (Mac) : parcours logique, tout est annonce
- [ ] Zoom 200% : pas de perte de contenu ni de fonctionnalite
- [ ] Contraste verifie sur chaque combinaison texte/fond
- [ ] Formulaires : labels, erreurs, aide accessible

### Outils recommandes

| Outil | Type | Usage |
|-------|------|-------|
| axe DevTools | Extension Chrome | Audit rapide |
| Lighthouse | Chrome built-in | Score global |
| VoiceOver | macOS built-in | Test screen reader |
| WAVE | Extension web | Visualisation des erreurs |
| Contrast Checker | Web | Verification des couleurs |
