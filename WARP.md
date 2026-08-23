# WARP.md

Guidance for Warp when working in this repository.

## Project overview

**Title**: tufter (Tufte's design principles as R code)
**Status**: Active, v0.6.0, preparing for CRAN
**Description**: R package implementing Edward Tufte's principles of graphical
design as ggplot2 extensions, and as measurements applied to existing figures
**Authors**: Charles Crabtree, Senior Lecturer, School of Social Sciences,
Monash University and K-Club Professor, University College, Korea University
**Last updated**: 2026-08-23

## Core architecture

The package has two halves, and the split decides where new code belongs.

Generative: ggplot2 extensions producing Tufte's graphical forms. These are
`ggproto` Geoms and Stats, themes, scales, and two plot constructors
(`slopegraph()`, `sparkline()`).

Evaluative: measurements of a plot you've already drawn. These render it and
read the result. `data_ink_ratio()` renders twice, once with the data layers
stripped out of the panel grobs, and compares weighted non-background pixel
counts. `check_labels_fit()` measures text grobs against the intended canvas.
`tufte_audit()` composes everything.

### Package structure

```
R/
├── tufter-package.R   # package doc, @import ggplot2
├── utils.R            # .abort/.warn, layer introspection, .ggname, .grob_of
├── theme.R            # theme_tufte(), theme_sparkline(), theme_slopegraph()
├── scales.R           # tufte_pal(), tufte_colours(), scale_*_tufte()
├── rangeframe.R       # geom_rangeframe(), geom_quartileframe(), quartile_breaks()
├── boxplot.R          # geom_tufteboxplot(), point / line / offset variants
├── dotdash.R          # geom_dotdash()
├── dotplot.R          # geom_cleveland_dot()
├── bars.R             # geom_col_tufte(), geom_bar_tufte()
├── labels.R           # geom_text_last(), geom_text_first(), label_source()
├── multiples.R        # facet_tufte()
├── sparkline.R        # sparkline(), sparklines(), sparkline_grob()
├── slopegraph.R       # slopegraph()
├── integrity.R        # data_ink_ratio(), lie_factor(), data_density()
├── banking.R          # bank_to_45()
├── contrast.R         # check_contrast(), contrast_ratio()
├── fit.R              # check_labels_fit()
├── audit.R            # tufte_audit() and the individual .check_* functions
├── batch.R            # audit_figures()
├── save.R             # save_tufte()
└── principles.R       # tufte_principles()

pkgdown/
└── extra.scss         # site styling: house tokens, masthead, Tufte ruling
```

### Key design patterns

1. Geoms delegate drawing where they can. `GeomTufteBoxplot` builds segment and
   point data frames and hands them to `GeomSegment$draw_panel()` and
   `GeomPoint$draw_panel()` rather than transforming coordinates by hand. Only
   the frame geoms (`GeomRangeFrame`, `GeomDotDash`) call `coord$transform()`
   directly, because they draw at the panel edge in npc space.

2. Ink is measured, not counted. `.measure_ink()` writes a PNG (via `ragg` when
   it's available, otherwise `grDevices::png`), reads it with `png::readPNG`,
   and sums each pixel's normalised distance from the background colour, so
   anti-aliased edges contribute fractionally. `dev.capture()` doesn't work on
   macOS devices, which is why the round trip through a file exists.

3. Nothing writes to the user's filesystem. Anything that needs to measure text
   goes through `.grob_of()`, which opens `pdf(NULL)` when no device is current.
   Calling `ggplotGrob()` without that leaves an unasked-for `Rplots.pdf` in the
   working directory, which CRAN rejects.

4. Every grob a geom returns gets a name from `.ggname()`. `data_ink_ratio()`
   tells data ink from furniture by grob name, so an unnamed grob is silently
   charged to the wrong side.

5. Audit checks are independent functions. Each `.check_*(ctx)` returns a row
   via `.row()`, or `NULL` when it doesn't apply. They're registered in a named
   list inside `tufte_audit()`; a check that errors becomes a `"skip"` row
   labelled with its name rather than disappearing. To add a principle, write a
   `.check_*`, register it, and add the row to `tufte_principles()`.

6. Sources live in one place. `.row()` looks the citation up in
   `tufte_principles()`, so the audit and the inventory can't drift apart. Two
   tests assert they agree.

7. There's no score. Tufte states a criterion for some principles and only a
   direction for others. The audit grades the first kind and reports the second.
   The `criterion` column in `tufte_principles()` marks which is which. Don't
   add thresholds he doesn't give.

8. Bar orientation goes through `.bar_axes()`. Flipped bars and `coord_flip()`
   are different things and combine, so anything reading bar extents asks that
   helper which axis carries the data.

## Common commands

```r
devtools::load_all()     # Load interactively
devtools::document()     # Regenerate docs (ALWAYS after editing roxygen)
devtools::test()         # Run all tests
devtools::check()        # Full R CMD check
```

The documentation site is styled in `pkgdown/extra.scss`, which sets the house
tokens (Newsreader, IBM Plex Sans, JetBrains Mono, one navy accent, radius 0)
and reshapes pkgdown's navbar into a masthead. Tables and definition lists are
ruled the way Tufte rules them: horizontals only, no verticals, no zebra, no
outer box. Colours are declared once as custom properties at the top of that
file and nowhere else. Some pkgdown rules need matching specificity to undo,
`.template-home .page-header` among them.

Site and generated assets are rebuilt from `data-raw/`: `build_site.R` builds
the pkgdown site behind its password gate, `make_readme_figures.R` and
`make_readme_output.R` regenerate the images and the fenced output blocks in
`README.md`. The README's output blocks are generated, so edit the script
rather than the block.

## Code conventions

- Exported functions: `snake_case`. Geoms follow ggplot2 convention:
  `geom_thing()` plus an exported `GeomThing` ggproto object.
- Internal helpers: `.snake_case` with a leading dot, `@noRd`.
- `.abort()` and `.warn()` wrap cli and forward `.envir`, so cli `{}`
  expressions evaluate in the calling function's frame.
- Never use `:::` into ggplot2. `.ggname()` in `utils.R` replaces
  `ggplot2:::ggname()`.
- Every exported function needs `@param`, `@return`, `@export` and
  `@examples`. Examples have to run without extra packages.
- Prose in roxygen, vignettes and the README is written in the author's voice:
  contractions, no em or en dashes as connectors, no "not X but Y".
  `python3 data-raw/check_voice.py` checks it and should print an empty total.
  It flags natural phrasings too, so read what it reports rather than fixing
  every hit.

## Important notes

### NAMESPACE and man/
Don't edit these directly. Edit the roxygen comments, then run
`devtools::document()`.

### Testing geoms
There's no vdiffr baseline. Geoms are tested by building (`ggplot_build()`) and
by rendering to a temporary PNG, which exercises `setup_data()`, `draw_panel()`
and the coord transform without a reference image to maintain.
`test-regressions.R` holds a case for every bug that's been fixed;
`test-cran.R` covers policy, including that no function writes to the working
directory.

### Vignettes
`vignettes/tufter.Rmd` and `vignettes/real-data.Rmd` ship with the package and
depend only on Suggests, guarded by `requireNamespace()`.
`vignettes/articles/` is site-only and listed in `.Rbuildignore`;
`live-data.Rmd` there hits real APIs, so it's built by hand rather than on
check.

### Dependencies
Imports ggplot2, grid, grDevices, scales, png, rlang, cli, tibble, stats and
tools. `png` is an Import because `data_ink_ratio()` is core; `ragg` is a
Suggest and gets used when it's present for steadier anti-aliasing. Keep this
list matching `DESCRIPTION`: it claimed `gtable`, which nothing uses, and
omitted `stats` and `tools`, which several functions do.

### Relationship to ggthemes
`ggthemes` has its own `theme_tufte()`, range frame and Tufte box plot. Loading
both masks names. The README says so; don't try to work around it in code.

### Outstanding before CRAN
The GitHub repo is private, so the two URLs in `DESCRIPTION` return 404 and
`--as-cran` flags them. Making the repo public clears the last note.
