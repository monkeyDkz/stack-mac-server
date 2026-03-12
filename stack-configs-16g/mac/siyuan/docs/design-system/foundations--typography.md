# Systeme Typographique

*Echelle modulaire 1.25, font stack systeme-first, responsive*

## Principes

1. **Hierarchie claire** — un seul H1 par page, descente logique H2 > H3 > H4
2. **Lisibilite** — 60-80 caracteres par ligne, line-height genereux
3. **Consistance** — memes tailles partout, pas de valeurs arbitraires
4. **Performance** — font stack systeme en priorite, polices custom en progressive enhancement

## Font Stack

```css
:root {
  /* Sans-serif — corps de texte, UI */
  --font-sans: 'Inter', ui-sans-serif, system-ui, -apple-system,
    BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue',
    Arial, sans-serif;

  /* Monospace — code, donnees tabulaires */
  --font-mono: 'JetBrains Mono', 'Fira Code', ui-monospace,
    SFMono-Regular, 'SF Mono', Menlo, Consolas,
    'Liberation Mono', monospace;

  /* Serif — citations longues (usage rare) */
  --font-serif: 'Georgia', 'Times New Roman', serif;
}
```

### Chargement des polices

```html
<!-- Preload pour eviter le FOUT -->
<link rel="preload" href="/fonts/inter-var.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/fonts/jetbrains-mono-var.woff2" as="font" type="font/woff2" crossorigin>
```

```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter-var.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap; /* Afficher le fallback immediatement */
}

@font-face {
  font-family: 'JetBrains Mono';
  src: url('/fonts/jetbrains-mono-var.woff2') format('woff2');
  font-weight: 100 800;
  font-display: swap;
}
```

## Echelle typographique (ratio 1.25 — Major Third)

| Token | Taille | Line-height | Letter-spacing | Usage |
|-------|:------:|:-----------:|:--------------:|-------|
| `--text-xs` | 12px / 0.75rem | 16px / 1.33 | 0.02em | Badges, labels, meta |
| `--text-sm` | 14px / 0.875rem | 20px / 1.43 | 0.01em | Texte secondaire, inputs, aside |
| `--text-base` | 16px / 1rem | 24px / 1.5 | 0 | Corps de texte par defaut |
| `--text-lg` | 18px / 1.125rem | 28px / 1.56 | -0.01em | Sous-titres, lead text |
| `--text-xl` | 20px / 1.25rem | 28px / 1.4 | -0.01em | H4, titres de section |
| `--text-2xl` | 24px / 1.5rem | 32px / 1.33 | -0.02em | H3, titres de carte |
| `--text-3xl` | 30px / 1.875rem | 36px / 1.2 | -0.02em | H2, titres de page |
| `--text-4xl` | 36px / 2.25rem | 40px / 1.11 | -0.03em | H1, hero |

### Calcul de l'echelle

```
Base: 16px
Ratio: 1.25 (Major Third)

16 × 1.25^-2 = 10.24 → arrondi a 12px (xs)
16 × 1.25^-1 = 12.8  → arrondi a 14px (sm)
16 × 1.25^0  = 16px  (base)
16 × 1.25^1  = 20px  (xl)
16 × 1.25^2  = 25px  → arrondi a 24px (2xl)
16 × 1.25^3  = 31.25 → arrondi a 30px (3xl)
16 × 1.25^4  = 39.06 → arrondi a 36px (4xl)
```

## Poids (font-weight)

| Token | Poids | Usage |
|-------|:-----:|-------|
| `--font-light` | 300 | Usage rare, grands titres decoratifs |
| `--font-normal` | 400 | Corps de texte, paragraphes |
| `--font-medium` | 500 | Labels, navigation, sous-titres discrets |
| `--font-semibold` | 600 | Sous-titres, titres de section |
| `--font-bold` | 700 | Titres principaux, emphase forte |

## Styles de headings

```css
h1, .h1 {
  font-size: var(--text-4xl);    /* 36px */
  font-weight: var(--font-bold); /* 700 */
  line-height: 40px;
  letter-spacing: -0.03em;
  margin-bottom: var(--space-6); /* 24px */
}

h2, .h2 {
  font-size: var(--text-3xl);       /* 30px */
  font-weight: var(--font-bold);    /* 700 */
  line-height: 36px;
  letter-spacing: -0.02em;
  margin-top: var(--space-12);      /* 48px */
  margin-bottom: var(--space-4);    /* 16px */
}

h3, .h3 {
  font-size: var(--text-2xl);       /* 24px */
  font-weight: var(--font-semibold);/* 600 */
  line-height: 32px;
  letter-spacing: -0.02em;
  margin-top: var(--space-8);       /* 32px */
  margin-bottom: var(--space-3);    /* 12px */
}

h4, .h4 {
  font-size: var(--text-xl);        /* 20px */
  font-weight: var(--font-semibold);/* 600 */
  line-height: 28px;
  margin-top: var(--space-6);       /* 24px */
  margin-bottom: var(--space-2);    /* 8px */
}
```

## Code et monospace

```css
code, kbd, samp, pre {
  font-family: var(--font-mono);
  font-size: 0.875em; /* 1 cran plus petit que le contexte */
}

/* Code inline */
code:not(pre code) {
  background: var(--color-surface-raised);
  padding: 2px 6px;
  border-radius: 4px;
  font-size: var(--text-sm);
  color: var(--color-text-code);
}

/* Code block */
pre {
  background: var(--color-surface-card);
  border: 1px solid var(--color-border-default);
  border-radius: 8px;
  padding: var(--space-4);
  overflow-x: auto;
  font-size: var(--text-sm);
  line-height: 1.6;
}
```

## Regles responsive

```css
/* Mobile-first : base = mobile */
:root {
  --text-base: 16px;
  --text-4xl: 28px; /* Plus petit sur mobile */
  --text-3xl: 24px;
}

/* Tablet (>= 768px) */
@media (min-width: 768px) {
  :root {
    --text-4xl: 32px;
    --text-3xl: 28px;
  }
}

/* Desktop (>= 1024px) */
@media (min-width: 1024px) {
  :root {
    --text-4xl: 36px;
    --text-3xl: 30px;
  }
}
```

## Regles d'utilisation

| Regle | Detail |
|-------|--------|
| Un seul H1 par page | Le titre principal uniquement |
| Ne pas sauter de niveau | H1 > H2 > H3 (pas H1 > H3) |
| Max 3 niveaux visibles | H1, H2, H3 suffisent (H4 = rare) |
| Ligne de texte : 60-80 car | `max-width: 65ch` sur les paragraphes |
| Pas de texte tout en majuscules | Sauf badges / labels courts |
| Pas de soulignement | Reserve aux liens |
| Italique avec parcimonie | Pour les citations uniquement |

## CSS Custom Properties (copier-coller)

```css
:root {
  --font-sans: 'Inter', ui-sans-serif, system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;

  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;

  --font-light: 300;
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;

  --leading-tight: 1.2;
  --leading-normal: 1.5;
  --leading-relaxed: 1.6;
}
```
