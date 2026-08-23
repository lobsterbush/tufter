# Changelog

## tufter 0.6.0

- [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md)
  counts the ink of every geom. It identified data layers by a grob name
  beginning with “geom”, but ggplot2 names only some of them that way:
  `GeomPath`, `GeomLine`, `GeomStep`, `GeomText` and `GeomSegment`
  return bare grid grobs called `GRID.polyline`, `GRID.text` and
  `GRID.segments`. Those were never stripped, so they stayed in the
  furniture rendering and were subtracted from the data ink. A plain
  line chart measured a data-ink ratio of exactly zero. The furniture is
  now named instead, being the grill, the panel border and ggplot2’s
  zeroGrob placeholders, and anything else in the panel is a layer.
- [`geom_col_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
  and
  [`geom_bar_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
  work out which axis to erase the rules along, so `sides` defaults to
  `NULL`. Horizontal bars drew no rules at all, whether written as
  `aes(value, category)`, passed `orientation = "y"`, or flipped by the
  coord. An explicit `sides` pointing at a scale with no numeric breaks
  now warns instead of silently drawing nothing.
- Which axis carries a bar’s length is settled in one place,
  `.bar_axes()`, and the five-number summary behind the quartile frame
  and its labels in another, `.five_number()`. Three separate answers to
  the first question and two to the second were five separate bugs.

## tufter 0.5.4

- [`geom_col_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
  draws its erased rules under
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html).
  It chose the panel scale from `sides` alone, so a flip left it reading
  the discrete category scale, whose breaks aren’t numbers, and the
  layer drew nothing at all. Paired with `theme_tufte(grid = "none")`
  that left bars with no rules of any kind to read values against.

## tufter 0.5.3

- The `"accent"` palette always contains its accent. It took the first
  `n` of a fixed vector whose third element was the signal colour, so
  two series gave two greys and no signal, which is the one thing that
  palette exists to provide. The signal is now the last level at every
  `n`, and the greys fill in ahead of it.

## tufter 0.5.2

- [`quartile_breaks()`](https://lobsterbush.github.io/tufter/reference/quartile_breaks.md)
  puts the axis labels where the quartile frame actually breaks. It used
  [`stats::fivenum()`](https://rdrr.io/r/stats/fivenum.html) while the
  frame used `stats::quantile(type = 7)`, so for most sample sizes the
  printed labels sat somewhere other than the gaps they were meant to
  name. At n = 8 the axis read 56 next to a break at 53.4. With too few
  distinct values for a summary it now returns the two ends, matching
  the plain range the frame draws there.
- `tufte_audit(measure = FALSE)` no longer changes a figure’s verdict.
  The clipping check was gated behind `measure` although it’s a stated
  criterion, so a figure with a subtitle too wide to fit reported no
  violations on the fast path. `measure` now governs only the data-ink
  ratio and the data density, which are ungraded.

## tufter 0.5.1

- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  no longer counts categories along a discrete axis as overlaid series.
  A dot plot of five countries reported “5 series overlaid in one panel”
  and recommended small multiples, which would have put one point in
  each panel. Only a non-positional aesthetic separates series now.
- [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md)
  documents the case where the number runs the wrong way: a pie chart of
  continental population measures 0.75 against 0.16 for the dot plot
  that replaces it, because filled interiors count and dots are small.
  The graded criteria separate them correctly, six unmet against one,
  which is why the audit reports the ratio rather than scoring it.
- [`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md)
  says in its documentation that `audited` and `criterion` are logical,
  and which of the two separates graded from measured.
- The description of
  [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)’s
  return value had lost a verb.

## tufter 0.5.0

- New vignette, “Working through a real dataset”, using `gapminder` and
  `palmerpenguins`. Both are suggested and guarded.
- [`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md),
  [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md),
  [`data_density()`](https://lobsterbush.github.io/tufter/reference/data_density.md)
  and
  [`sparkline_grob()`](https://lobsterbush.github.io/tufter/reference/sparkline_grob.md)
  no longer leave a graphics device open or write an `Rplots.pdf` into
  the working directory. Measuring borrows a `pdf(NULL)` device for the
  whole measurement, which covers unit conversion as well as building
  the gtable.
  [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  on a plot with a legend was a second route to the same stray file.
- README figures and example output use `palmerpenguins` and
  `gapminder`.
- The cached API data behind the live-data article has moved to
  `data-raw/` and is no longer installed with the package.
- `Language` is `en-GB`, with an `inst/WORDLIST`.
- Cleveland, McGill and McGill (1988) cited by DOI in `DESCRIPTION`.
- AI usage disclosure added to the README.

## tufter 0.4.2

- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  and
  [`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md)
  use the same names and the same citations for every principle. The
  audit looks each source up from the table.
- Two principles are marked `audited = FALSE`: nothing reports on them.
- README example output is generated by `data-raw/make_readme_output.R`.
- [`scale_fill_tufte_c()`](https://lobsterbush.github.io/tufter/reference/scale_colour_tufte.md)
  gains a test.

## tufter 0.4.1

- [`lie_factor()`](https://lobsterbush.github.io/tufter/reference/lie_factor.md)
  reads horizontal bars and
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html)
  bars along the axis that carries their length. All three orientations
  report the same distortion.
- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  names the axis a reader can see when a bar baseline isn’t zero.
- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  normalises each panel by its own ranges, which matters under free
  scales.
- A plot setting fixed colours outside
  [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html) is no
  longer reported as carrying a legend.
- [`slopegraph()`](https://lobsterbush.github.io/tufter/reference/slopegraph.md)
  warns when a unit has more than one value in a period.
- [`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md)
  uses `NA` in `implemented_by` where no function reaches a principle.

## tufter 0.4.0

- New article, “Examples with live API data”, drawing on CRAN download
  logs, the USGS earthquake catalogue, the Open-Meteo ERA5 archive and
  Wikipedia pageviews. `data-raw/fetch_live_examples.R` does the
  fetching and caches the result.
- [`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md)
  measures a rotated y axis title along the length of the string,
  against the height of the panel area.
- [`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md)
  and
  [`sparklines()`](https://lobsterbush.github.io/tufter/reference/sparklines.md)
  gain a `big.mark` argument, defaulting to a comma.
- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  documents that the height it returns is for the panel.

## tufter 0.3.0

- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  grades only the principles for which Tufte states a criterion, and
  measures the rest without a verdict. The thresholds that used to grade
  the measurements are removed.
- The `score` attribute is replaced by `violations`, a count of stated
  criteria not met.
  [`audit_figures()`](https://lobsterbush.github.io/tufter/reference/audit_figures.md)
  orders figures by that count.
- [`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md)
  gains a `criterion` column.
- The legend check fails on named series and reports a continuous key.
- [`quartile_breaks()`](https://lobsterbush.github.io/tufter/reference/quartile_breaks.md)
  returns the whole five-number summary by default.
- The audit cites WCAG for the contrast minimum and Cleveland for
  banking.

## tufter 0.2.1

- [`geom_rangeframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  and
  [`geom_quartileframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  name their grobs, so
  [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md)
  counts them as data ink.
- [`data_density()`](https://lobsterbush.github.io/tufter/reference/data_density.md)
  groups layers by the data they read, and resolves aesthetics to the
  columns they use.
- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  reads segments in drawn order and keeps vertical ones. A path that’s
  more than half vertical is refused.
- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  treats a continuous colour scale as one code, catches redundant
  encoding through a transformation, and fails a bar chart on a
  transformed scale.
  [`lie_factor()`](https://lobsterbush.github.io/tufter/reference/lie_factor.md)
  returns `NA` for the same.

## tufter 0.2.0

- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  computes the aspect ratio that brings slopes nearest 45 degrees, by
  median absolute slope or mean absolute orientation.
- [`check_contrast()`](https://lobsterbush.github.io/tufter/reference/check_contrast.md)
  and
  [`contrast_ratio()`](https://lobsterbush.github.io/tufter/reference/contrast_ratio.md)
  measure every colour a plot draws with against its background, using
  the WCAG 2.1 minima.
- [`audit_figures()`](https://lobsterbush.github.io/tufter/reference/audit_figures.md)
  runs the audit across a list of plots or a directory.
- [`geom_cleveland_dot()`](https://lobsterbush.github.io/tufter/reference/geom_cleveland_dot.md)
  draws a dot plot with leader lines.

## tufter 0.1.0

First release.

### Drawing

- [`theme_tufte()`](https://lobsterbush.github.io/tufter/reference/theme_tufte.md),
  [`theme_sparkline()`](https://lobsterbush.github.io/tufter/reference/theme_sparkline.md),
  [`theme_slopegraph()`](https://lobsterbush.github.io/tufter/reference/theme_slopegraph.md).
- [`geom_rangeframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md),
  [`geom_quartileframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md),
  [`quartile_breaks()`](https://lobsterbush.github.io/tufter/reference/quartile_breaks.md).
- [`geom_tufteboxplot()`](https://lobsterbush.github.io/tufter/reference/geom_tufteboxplot.md),
  with `"point"`, `"line"` and `"offset"` variants.
- [`geom_dotdash()`](https://lobsterbush.github.io/tufter/reference/geom_dotdash.md).
- [`geom_col_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
  and
  [`geom_bar_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md).
- [`slopegraph()`](https://lobsterbush.github.io/tufter/reference/slopegraph.md),
  [`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md),
  [`sparklines()`](https://lobsterbush.github.io/tufter/reference/sparklines.md),
  [`sparkline_grob()`](https://lobsterbush.github.io/tufter/reference/sparkline_grob.md).
- [`facet_tufte()`](https://lobsterbush.github.io/tufter/reference/facet_tufte.md).
- [`geom_text_last()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md)
  and
  [`geom_text_first()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md).
- [`tufte_pal()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md),
  [`tufte_colours()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md)
  and the `scale_*_tufte()` family.
- [`label_source()`](https://lobsterbush.github.io/tufter/reference/label_source.md)
  and
  [`save_tufte()`](https://lobsterbush.github.io/tufter/reference/save_tufte.md).

### Measuring

- [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md),
  [`lie_factor()`](https://lobsterbush.github.io/tufter/reference/lie_factor.md),
  [`data_density()`](https://lobsterbush.github.io/tufter/reference/data_density.md),
  [`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md).
- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  and
  [`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md).
