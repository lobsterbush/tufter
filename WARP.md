# WARP.md

This file provides guidance to Warp when working with code in this repository.

## Project Overview

**Title**: tufter (Tufte's design principles as R code)
**Status**: Active — v0.1.0, pre-CRAN
**Description**: R package implementing Edward Tufte's principles of graphical
design as ggplot2 extensions, and as measurements applied to existing figures
**Authors**: Charles Crabtree, Senior Lecturer, School of Social Sciences,
Monash University and K-Club Professor, University College, Korea University
**Last Updated**: 2026-07-29

## Core Architecture

The package has two halves, and the split matters for where new code belongs.

**Generative** — ggplot2 extensions producing Tufte's graphical forms. These are
`ggproto` Geoms and Stats, themes, scales, and two plot constructors
(`slopegraph()`, `sparkline()`).

**Evaluative** — measurements of an existing plot. These render the plot and
read the result: `data_ink_ratio()` renders twice, once with the data layers
stripped from the panel grobs, and compares weighted non-background pixel
counts. `check_labels_fit()` measures text grobs against the intended canvas.
`tufte_audit()` composes everything.

### Package structure

```
R/
├── tufter-package.R   # package doc, @import ggplot2
├── utils.R            # .abort/.warn, layer introspection, .ggname
├── theme.R            # theme_tufte(), theme_sparkline(), theme_slopegraph()
├── scales.R           # tufte_pal(), tufte_colours(), scale_*_tufte()
├── rangeframe.R       # geom_rangeframe(), geom_quartileframe(), quartile_breaks()
├── boxplot.R          # geom_tufteboxplot() — point / line / offset variants
├── dotdash.R          # geom_dotdash()
├── bars.R             # geom_col_tufte(), geom_bar_tufte()
├── labels.R           # geom_text_last(), geom_text_first(), label_source()
├── multiples.R        # facet_tufte()
├── sparkline.R        # sparkline(), sparklines(), sparkline_grob()
├── slopegraph.R       # slopegraph()
├── integrity.R        # data_ink_ratio(), lie_factor(), data_density()
├── fit.R              # check_labels_fit()
├── audit.R            # tufte_audit() and the individual .check_* functions
├── save.R             # save_tufte()
└── principles.R       # tufte_principles()
```

### Key design patterns

1. **Geoms delegate drawing where possible.** `GeomTufteBoxplot` builds segment
   and point data frames and hands them to `GeomSegment$draw_panel()` and
   `GeomPoint$draw_panel()` rather than transforming coordinates by hand. Only
   the frame geoms (`GeomRangeFrame`, `GeomDotDash`) call `coord$transform()`
   directly, because they draw at the panel edge in npc space.

2. **Ink is measured, not counted.** `.measure_ink()` writes a PNG (via `ragg`
   when available, otherwise `grDevices::png`), reads it with `png::readPNG`,
   and sums each pixel's normalised distance from the background colour, so
   anti-aliased edges contribute fractionally. `dev.capture()` was tried first
   and does not work on macOS devices.

3. **Audit checks are independent functions.** Each `.check_*(ctx)` returns a
   row via `.row()` or `NULL` if not applicable. They are registered in a named
   list in `tufte_audit()`; a check that errors becomes a `"skip"` row labelled
   with its name, never a silent disappearance. Add a new principle by writing
   a `.check_*` and adding it to that list and to `tufte_principles()`.

4. **`tufte_principles()` is the honest inventory.** Its `audited` column marks
   which principles a function can verify. Principles that cannot be checked
   are listed anyway, with `audited = FALSE`.

## Common Commands

```r
devtools::load_all()     # Load interactively
devtools::document()     # Regenerate docs (ALWAYS after editing roxygen)
devtools::test()         # Run all tests
devtools::check()        # Full R CMD check
```

## Code Conventions

- Exported functions: `snake_case`. Geoms follow ggplot2 convention:
  `geom_thing()` plus an exported `GeomThing` ggproto object.
- Internal helpers: `.snake_case` with leading dot, `@noRd`.
- `.abort()` and `.warn()` wrap cli and forward `.envir`, so cli `{}`
  expressions evaluate in the calling function's frame.
- Never use `:::` into ggplot2. `.ggname()` in `utils.R` replaces
  `ggplot2:::ggname()`.
- All exported functions need `@param`, `@return`, `@export`, `@examples`.
  Examples must run without extra packages.

## Important Notes

### NAMESPACE and man/
Do not edit directly. Edit roxygen comments, then `devtools::document()`.

### Testing geoms
There is no vdiffr baseline. Geoms are tested by building
(`ggplot_build()`) and by rendering to a temporary PNG, which exercises
`setup_data()`, `draw_panel()` and the coord transform without a reference
image to maintain.

### Dependencies
Imports ggplot2, grid, grDevices, gtable, scales, png, rlang, cli, tibble.
`png` is an Import because `data_ink_ratio()` is core; `ragg` is a Suggest and
is used when present for steadier anti-aliasing.

### Relationship to ggthemes
`ggthemes` has its own `theme_tufte()`, range frame and Tufte box plot. Loading
both masks names. This is documented in the README; do not try to work around
it in code.
