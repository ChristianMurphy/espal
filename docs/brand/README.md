# Espal logo

The mark is an espalier, a fruit tree trained flat against a frame. Two outer stems cross above a forked center stem. Each branch thins from base to tip and ends in a leaf. The wordmark uses a single 3.5-unit line with round ends.

The SVG files contain no fonts and no external references.

## Files

| File | Use |
| --- | --- |
| `espal-lockup.svg` | Mark and wordmark side by side. Use this one by default. |
| `espal-stacked.svg` | Mark above the wordmark, for square spaces. |
| `espal-mark.svg` | The mark alone. |
| `espal-wordmark.svg` | The wordmark alone. |
| `favicon.svg` | Browser tab icon. The mark sits on a green tile, and its top leaves grow past the edge. |
| `favicon.ico` | The favicon at 16, 32 and 48 px, for browsers that don't load SVG icons. |
| `app-icon.svg` | Full square icon with no transparent edge, for home screens and app manifests. |
| `apple-touch-icon.png`, `icon-192.png`, `icon-512.png` | `app-icon.svg` at 180, 192 and 512 px. |

The lockup, stacked, mark and wordmark files come in three versions. The plain file switches colors with the viewer's light or dark setting through a `prefers-color-scheme` rule. The `-on-light` and `-on-dark` files keep one set of colors, for tools and pages that ignore that setting.

## Colors

| Part | Light background | Dark background |
| --- | --- | --- |
| Branches and wordmark | `#23352A` | `#E6EDE4` |
| Leaves | `#3E8E4F` | `#6CC17D` |
| Favicon tile | `#1F3A2B` | `#2E5640` |

On the favicon tile and the app icon, branches use `#F2F5EF` and leaves use `#8FD49C`. Branches and leaves reach at least 3:1 contrast against the color behind them, the WCAG minimum for graphics. The favicon tile itself sits at about 2.2:1 against a dark page, so its pale branches carry the shape there.

## On a web page

```html
<link rel="icon" href="/favicon.ico" sizes="32x32">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

The `sizes="32x32"` on the ICO link keeps Chrome from picking the ICO over the SVG.

## In a GitHub README

GitHub can pick an image to match the reader's theme with a `<picture>` element. Use the fixed-color files there:

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/brand/espal-lockup-on-dark.svg">
  <img alt="Espal" src="docs/brand/espal-lockup-on-light.svg" width="300">
</picture>
```

## Spacing and size

Leave clear space of at least a quarter of the mark's height on every side. The plain mark keeps its shape down to 24 px. For 16 px, as in a browser tab, use the favicon.

## Geometry

The marks use a 64-unit grid. The leaves share one path, placed with `translate`, `rotate` and `scale`. Each branch outline follows a center line whose width tapers from 7 units at the base to 2.6 at the tip.
