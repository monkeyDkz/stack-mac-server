# Systeme d'Espacement

*Grille 4px, echelle lineaire, tokens semantiques*

## Principes

1. **Grille 4px** — toutes les valeurs sont des multiples de 4
2. **Tokens, pas de valeurs brutes** — jamais `margin: 13px`, toujours `margin: var(--space-3)`
3. **Relation = espacement** — des elements proches visuellement sont lies logiquement (loi de proximite Gestalt)
4. **Vertical > Horizontal** — privilegier les espacements verticaux genereux pour la lisibilite

## Echelle d'espacement

| Token | Valeur | rem | Usage courant |
|-------|:------:|:---:|---------------|
| `--space-0` | 0px | 0 | Reset |
| `--space-0.5` | 2px | 0.125 | Micro-ajustement (border gap) |
| `--space-1` | 4px | 0.25 | Entre icone et texte |
| `--space-1.5` | 6px | 0.375 | Padding compact (badge) |
| `--space-2` | 8px | 0.5 | Padding interne minimal, gap inline |
| `--space-3` | 12px | 0.75 | Padding inputs, gap entre labels et champs |
| `--space-4` | 16px | 1 | Padding standard (cards, boutons) |
| `--space-5` | 20px | 1.25 | Gap entre elements dans une liste |
| `--space-6` | 24px | 1.5 | Gap entre sections internes d'un composant |
| `--space-8` | 32px | 2 | Marge entre sections d'un composant complexe |
| `--space-10` | 40px | 2.5 | Marge entre blocs de contenu |
| `--space-12` | 48px | 3 | Separation de sections principales |
| `--space-16` | 64px | 4 | Separation de blocs majeurs |
| `--space-20` | 80px | 5 | Espacement hero, top/bottom de page |
| `--space-24` | 96px | 6 | Marge de page, section landing |

## Espacement des composants

### Boutons

```css
.btn {
  padding: var(--space-2) var(--space-4);     /* 8px 16px */
  gap: var(--space-1.5);                       /* 6px entre icone et texte */
}

.btn-sm {
  padding: var(--space-1.5) var(--space-3);   /* 6px 12px */
}

.btn-lg {
  padding: var(--space-3) var(--space-6);     /* 12px 24px */
}
```

### Cards

```css
.card {
  padding: var(--space-6);                    /* 24px */
  gap: var(--space-4);                        /* 16px entre enfants */
  border-radius: var(--radius-lg);            /* 12px */
}

.card-header {
  padding-bottom: var(--space-4);             /* 16px */
  margin-bottom: var(--space-4);              /* 16px */
  border-bottom: 1px solid var(--color-border-default);
}
```

### Formulaires

```css
.form-field {
  margin-bottom: var(--space-5);              /* 20px entre champs */
}

.form-label {
  margin-bottom: var(--space-1.5);            /* 6px entre label et input */
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
}

.form-input {
  padding: var(--space-2.5) var(--space-3);   /* 10px 12px */
}

.form-helper {
  margin-top: var(--space-1);                 /* 4px sous l'input */
  font-size: var(--text-xs);
}
```

### Listes

```css
.list-item {
  padding: var(--space-3) var(--space-4);     /* 12px 16px */
}

.list-item + .list-item {
  border-top: 1px solid var(--color-border-default);
}

/* Stack vertical (composants empiles) */
.stack > * + * {
  margin-top: var(--space-4);                 /* 16px par defaut */
}

.stack--tight > * + * {
  margin-top: var(--space-2);                 /* 8px */
}

.stack--loose > * + * {
  margin-top: var(--space-8);                 /* 32px */
}
```

## Layout et espacement de page

```css
/* Container principal */
.container {
  width: 100%;
  max-width: var(--container-max);
  margin-inline: auto;
  padding-inline: var(--space-4);             /* 16px mobile */
}

@media (min-width: 768px) {
  .container {
    padding-inline: var(--space-8);           /* 32px tablet */
  }
}

@media (min-width: 1024px) {
  .container {
    padding-inline: var(--space-12);          /* 48px desktop */
  }
}
```

## Breakpoints

| Token | Valeur | Nom | Colonnes |
|-------|:------:|-----|:--------:|
| `--breakpoint-sm` | 640px | Mobile large | 4 |
| `--breakpoint-md` | 768px | Tablet | 8 |
| `--breakpoint-lg` | 1024px | Desktop | 12 |
| `--breakpoint-xl` | 1280px | Desktop large | 12 |
| `--breakpoint-2xl` | 1536px | Wide | 12 |

## Container widths

| Token | Valeur | Usage |
|-------|:------:|-------|
| `--container-sm` | 640px | Formulaires, login |
| `--container-md` | 768px | Articles, docs |
| `--container-lg` | 1024px | Dashboard |
| `--container-xl` | 1280px | Layout principal |
| `--container-max` | 1440px | Maximum absolu |

## Border radius

| Token | Valeur | Usage |
|-------|:------:|-------|
| `--radius-sm` | 4px | Badges, tags |
| `--radius-md` | 6px | Inputs, boutons |
| `--radius-lg` | 8px | Cards |
| `--radius-xl` | 12px | Modales, panels |
| `--radius-2xl` | 16px | Sections hero |
| `--radius-full` | 9999px | Avatars, pills |

## CSS Custom Properties (copier-coller)

```css
:root {
  /* Spacing */
  --space-0: 0;
  --space-0\.5: 2px;
  --space-1: 4px;
  --space-1\.5: 6px;
  --space-2: 8px;
  --space-2\.5: 10px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 20px;
  --space-6: 24px;
  --space-8: 32px;
  --space-10: 40px;
  --space-12: 48px;
  --space-16: 64px;
  --space-20: 80px;
  --space-24: 96px;

  /* Breakpoints (for reference, use in media queries) */
  --breakpoint-sm: 640px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 1024px;
  --breakpoint-xl: 1280px;
  --breakpoint-2xl: 1536px;

  /* Container */
  --container-sm: 640px;
  --container-md: 768px;
  --container-lg: 1024px;
  --container-xl: 1280px;
  --container-max: 1440px;

  /* Radius */
  --radius-sm: 4px;
  --radius-md: 6px;
  --radius-lg: 8px;
  --radius-xl: 12px;
  --radius-2xl: 16px;
  --radius-full: 9999px;
}
```

## Regles d'utilisation

| Regle | Detail |
|-------|--------|
| Jamais de valeur arbitraire | Toujours un token de l'echelle |
| Loi de proximite | Elements lies = espacement court, elements distincts = espacement long |
| Padding interne < marge externe | Le contenu interne d'une card est plus serre que l'espace entre les cards |
| Mobile-first | Commencer avec moins d'espace, ajouter aux breakpoints |
| Tester avec du vrai contenu | Pas de Lorem Ipsum pour valider les espacements |
