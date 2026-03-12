# Palette de Couleurs

*Tokens semantiques, dark mode, conformite WCAG AA*

## Principes

1. **Semantique avant esthetique** — les couleurs expriment un sens (succes, erreur, action)
2. **Contraste suffisant** — WCAG AA minimum sur tout texte
3. **Dark mode natif** — chaque token a sa variante sombre
4. **Pas de couleur hardcodee** — toujours utiliser les CSS custom properties

## Couleurs primaires

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--color-primary-50` | `#eff6ff` | `#1e3a5f` | Background subtil |
| `--color-primary-100` | `#dbeafe` | `#1e40af` | Hover state background |
| `--color-primary-200` | `#bfdbfe` | `#1d4ed8` | Selected state |
| `--color-primary-300` | `#93c5fd` | `#2563eb` | Borders actives |
| `--color-primary-500` | `#3b82f6` | `#60a5fa` | Boutons, liens, actions principales |
| `--color-primary-600` | `#2563eb` | `#93c5fd` | Hover sur primary |
| `--color-primary-700` | `#1d4ed8` | `#bfdbfe` | Active / pressed |
| `--color-primary-900` | `#1e3a8a` | `#eff6ff` | Texte sur fond primary light |

## Couleurs semantiques

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--color-success` | `#16a34a` | `#4ade80` | Validation, operation reussie |
| `--color-success-bg` | `#f0fdf4` | `#052e16` | Background succes |
| `--color-warning` | `#d97706` | `#fbbf24` | Attention, action requise |
| `--color-warning-bg` | `#fffbeb` | `#451a03` | Background avertissement |
| `--color-error` | `#dc2626` | `#f87171` | Erreur, danger, destructif |
| `--color-error-bg` | `#fef2f2` | `#450a0a` | Background erreur |
| `--color-info` | `#2563eb` | `#60a5fa` | Information, aide |
| `--color-info-bg` | `#eff6ff` | `#1e3a5f` | Background info |

## Surfaces

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--color-surface-page` | `#ffffff` | `#0f172a` | Background de la page |
| `--color-surface-card` | `#ffffff` | `#1e293b` | Background des cards |
| `--color-surface-raised` | `#f8fafc` | `#334155` | Elements sureleves (dropdown, modal) |
| `--color-surface-overlay` | `rgba(0,0,0,0.5)` | `rgba(0,0,0,0.7)` | Overlay (modal backdrop) |
| `--color-surface-input` | `#ffffff` | `#1e293b` | Background des inputs |

## Texte

| Token | Light | Dark | Usage | Contraste min |
|-------|-------|------|-------|:-------------:|
| `--color-text-primary` | `#0f172a` | `#f8fafc` | Titres, texte principal | 12.6:1 |
| `--color-text-secondary` | `#475569` | `#94a3b8` | Texte secondaire, descriptions | 5.9:1 |
| `--color-text-tertiary` | `#94a3b8` | `#64748b` | Placeholders, labels discrets | 3.2:1 |
| `--color-text-on-primary` | `#ffffff` | `#0f172a` | Texte sur bouton primary | 8.6:1 |
| `--color-text-link` | `#2563eb` | `#60a5fa` | Liens | 4.6:1 |
| `--color-text-code` | `#be185d` | `#f472b6` | Code inline | 5.1:1 |

## Bordures

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--color-border-default` | `#e2e8f0` | `#334155` | Bordures standard |
| `--color-border-strong` | `#cbd5e1` | `#475569` | Bordures accentuees |
| `--color-border-focus` | `#3b82f6` | `#60a5fa` | Focus ring (outline) |
| `--color-border-error` | `#dc2626` | `#f87171` | Champ en erreur |

## Ratios de contraste WCAG

| Niveau | Ratio minimum | S'applique a |
|--------|:-------------:|-------------|
| **AA Normal text** | 4.5:1 | Texte < 18px (ou < 14px bold) |
| **AA Large text** | 3:1 | Texte >= 18px (ou >= 14px bold) |
| **AA UI components** | 3:1 | Icones, bordures, focus indicators |
| **AAA Normal text** | 7:1 | Objectif pour texte principal |

### Outils de verification

```bash
# Contrast checker en ligne
# https://webaim.org/resources/contrastchecker/

# Via devtools Chrome
# Elements > Styles > Color picker > Contrast ratio
```

## Strategie Dark Mode

### Principes

- Ne PAS inverser les couleurs mecaniquement (inverser les echelles : 50 ↔ 900)
- Reduire la luminosite globale, pas le contraste
- Les couleurs semantiques restent reconnaissables (rouge = erreur)
- Tester avec et sans dark mode, pas "l'un ou l'autre"

### Implementation CSS

```css
:root {
  /* Light mode (default) */
  --color-primary-500: #3b82f6;
  --color-surface-page: #ffffff;
  --color-text-primary: #0f172a;
  --color-text-secondary: #475569;
  --color-border-default: #e2e8f0;
  --color-success: #16a34a;
  --color-error: #dc2626;
  --color-warning: #d97706;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-primary-500: #60a5fa;
    --color-surface-page: #0f172a;
    --color-text-primary: #f8fafc;
    --color-text-secondary: #94a3b8;
    --color-border-default: #334155;
    --color-success: #4ade80;
    --color-error: #f87171;
    --color-warning: #fbbf24;
  }
}

/* Override manuel avec classe */
[data-theme="dark"] {
  --color-primary-500: #60a5fa;
  /* ... */
}
```

## Regles d'utilisation

| Regle | Detail |
|-------|--------|
| Jamais de couleur seule | Toujours accompagner d'une icone ou d'un label (daltonisme) |
| Pas de bleu pur sur rouge pur | Vibration visuelle, illisible |
| Max 3 couleurs par composant | Primary + 1 semantique + neutre |
| Background + texte = contraste AA | Verifier systematiquement |
| Hover = un cran plus sombre/clair | Utiliser le niveau d'echelle suivant |

## Palette etendue (reference Tailwind)

Pour les cas speciaux (graphiques, badges), utiliser l'echelle Tailwind complète :

```
slate:   50 → 950 (neutres froids)
blue:    50 → 950 (primary)
green:   50 → 950 (success)
amber:   50 → 950 (warning)
red:     50 → 950 (error)
violet:  50 → 950 (accent, badges)
```
