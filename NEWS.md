# tufter 0.6.2

Ten more from a third audit. The first is a regression from 0.6.1.

* `geom_quartileframe()` no longer errors when an axis has fewer than four
  distinct values, which is any discrete axis and most integer ones. The 0.6.1
  fix that moved the summary into data space padded the degenerate axis with a
  constant and passed it on as though it were a real summary, so every segment
  inverted and grid was handed a zero-length unit.
* `sides` and `gap` are checked. `"BL"` and `"LB"`, the natural typos for
  `"bl"`, matched nothing and the layer drew nothing without a word; a `gap`
  wide enough to swallow every segment did the same, and a negative one
  widened the segments instead of breaking them.
* `check_contrast()` measures only text the figure draws. A styled subtitle
  colour on a plot with no subtitle was measured, failed, and counted as a
  violation. A fully transparent panel fill is no longer read as an opaque
  background, which had every mark on the plot failing against black.
* `tufte_audit()` checks its own `width` and `height`. The individual measures
  reject a bad size, but the audit caught their errors, so an impossible canvas
  silently dropped four checks, one of them graded, and under-reported the
  violation count.
* A minor grid asked for on one axis only, in `panel.grid.minor.x` or `.y`, is
  found. Only the parent element was read.
* `geom_text_last()` and `geom_text_first()` accept a vector `nudge_x` or
  `nudge_y`, as `geom_text()` does. `||` on a vector is an error.
* `sparkline()` labels the rightmost point rather than the last row. On
  unsorted input the line's right-hand end and the printed final value were
  different observations, and `sparklines()` disagreed with it on identical
  data.
* `slopegraph()` counts the periods present. An unused factor level counted as
  a period and warned about labelling that was complete.
* `audit_figures()` keeps the names it was given. One unnamed element replaced
  every supplied name, breaking the documented drill-in.
* `theme_sparkline()` and `theme_slopegraph()` document their own base font
  sizes, 9 and 11, rather than inheriting `theme_tufte()`'s 12.

# tufter 0.6.1

Twenty-one fixes from two independent audits, one by a Claude subagent and one
by Codex. Codex could not run R in its sandbox, so its findings were static
traces; every one was confirmed by hand before being fixed.

## Measurement

* `check_contrast()` holds text layers to the 4.5:1 text minimum. Every layer
  was a "data mark" at 3:1, so grey label text at 4.48:1 passed a check whose
  own documentation promises 4.5:1 for words.
* `data_density()` counts the variables actually drawn. Plot and layer mappings
  were pooled, so a layer overriding an aesthetic added a column rather than
  replacing one, and `inherit.aes = FALSE` was ignored. A plot showing two
  variables reported three. A graphic with no mapped variable was also rounded
  up to one, inventing a data matrix for a figure that carries none.
* `bank_to_45()` measures the slopes as drawn. It divided the built columns by
  the panel ranges without going through the coord, so under `coord_flip()` it
  measured neither the data slopes nor the drawn ones.
* `bank_to_45()` refuses a step chart. `GeomStep` builds its stairs inside
  `draw_panel()`, so differencing the built points banked a diagonal it
  never draws, while every segment it does draw sits at 0 or 90 degrees.
* `lie_factor()` measures a rectangle only when it really is a bar. `GeomRect` counted
  as a bar, so a background band or an interval rectangle was given the panel
  floor for a baseline and a fabricated distortion figure.
* `data_density()`, `data_ink_ratio()`, `check_labels_fit()` and `bank_to_45()`
  reject any width or height other than a positive finite number. Zero gave an
  infinite density and a negative width a negative banked height, silently.

## Drawing

* Cleveland leader lines follow the coord. The dots delegate to `GeomPoint` and
  flipped, while the leaders read the untransformed orientation and stayed
  horizontal, at right angles to the dots they belong to.
* `geom_tufteboxplot()` says why it won't draw sideways instead of failing
  with ggplot2's "requires the following missing aesthetics".
* `slopegraph()` warns when given more than two periods, since the labels sit
  outside the panel on either side and a middle period has nowhere to put its
  numbers.

## Documentation that disagreed with the code

* `check_labels_fit()` measures axis labels and strips on all four sides, not
  only the bottom, the left and the top. Its title no longer claims to check
  every text element: text a layer draws inside the panel goes unmeasured,
  and the help now says so.

## Earlier in this release

* `geom_quartileframe()` breaks where the axis labels sit on any scale. It took
  quantiles of the scale-transformed values while `quartile_breaks()` took them
  of the raw data, and type-7 quantiles survive an affine transform but not a
  log or a square root. On a log10 axis the label read 5050 and the frame broke
  at 1000. The summary is computed in data space and sent through the coord,
  which also puts it on the right side under `coord_flip()`.
* `audit_figures()` keeps its per-figure detail when a figure fails. Assigning
  `NULL` into a list element deleted it rather than storing it, shifting every
  later name, so the documented drill-in returned `NULL` for every figure after
  the first failure.
* `coord_radial()` pie charts are caught. The check tested only for
  `CoordPolar`, and `coord_radial()` doesn't inherit from it.
* A variable mapped to both position and colour is caught on either axis. Only
  `x` was consulted, so horizontal bar charts passed.
* A white panel counts as white however the colour was spelled. The check
  compared strings, so `grey100`, `gray100`, `#fff` and the eight-digit
  `#FFFFFFFF` all read as coloured panels. ggplot2 4.0 returns eight-digit hex
  from `complete_theme()`, so that spelling is the common one, and the false
  fail inflated the violation count.
* `bank_to_45(method = "average_orientation")` refuses when no aspect ratio
  reaches 45 degrees. It returned the bracket bound instead: a panel three
  billion inches tall for a mostly flat series, or an aspect ratio of two
  billionths for a mostly vertical one, both silently. The suggestion to use
  this method when the median one refuses has been corrected, since the two
  fail at the same threshold.
* A continuous legend of any aesthetic is no longer told to label its series.
  Only colour and fill were exempt, so a continuous `size` key was advised to
  use `geom_text_last()` on series it doesn't have.
* `data_density()` handles a plot with no layers. `ggplot()$data` is a waiver
  rather than `NULL`, so the fallback never fired and the result object came
  back malformed.
* `check_labels_fit()` is invisible when everything fits, as documented.
* `geom_col_tufte(minor = TRUE)` draws each rule once. `get_breaks_minor()`
  includes the majors, so every major rule was drawn twice.
* `geom_text_last()` documents `label` as required, which it always was. Its
  argument documentation claimed a default that never existed. A paragraph of
  `audit_figures()` documentation was stranded inside a parameter description,
  and its opening line called the count a score.

# tufter 0.6.0

* `data_ink_ratio()` counts the ink of every geom. It identified data layers by
  a grob name beginning with "geom", but ggplot2 names only some of them that
  way: `GeomPath`, `GeomLine`, `GeomStep`, `GeomText` and `GeomSegment` return
  bare grid grobs called `GRID.polyline`, `GRID.text` and `GRID.segments`.
  Those were never stripped, so they stayed in the furniture rendering and were
  subtracted from the data ink. A plain line chart measured a data-ink ratio of
  exactly zero. The furniture is now named instead, being the grill, the panel
  border and ggplot2's zeroGrob placeholders, and anything else in the panel is
  a layer.
* `geom_col_tufte()` and `geom_bar_tufte()` work out which axis to erase the
  rules along, so `sides` defaults to `NULL`. Horizontal bars drew no rules at
  all, whether written as `aes(value, category)`, passed
  `orientation = "y"`, or flipped by the coord. An explicit `sides` pointing at
  a scale with no numeric breaks now warns instead of silently drawing nothing.
* Which axis carries a bar's length is settled in one place, `.bar_axes()`, and
  the five-number summary behind the quartile frame and its labels in another,
  `.five_number()`. Three separate answers to the first question and two to the
  second were five separate bugs.

# tufter 0.5.4

* `geom_col_tufte()` draws its erased rules under `coord_flip()`. It chose the
  panel scale from `sides` alone, so a flip left it reading the discrete
  category scale, whose breaks aren't numbers, and the layer drew nothing at
  all. Paired with `theme_tufte(grid = "none")` that left bars with no rules of
  any kind to read values against.

# tufter 0.5.3

* The `"accent"` palette always contains its accent. It took the first `n` of a
  fixed vector whose third element was the signal colour, so two series gave
  two greys and no signal, which is the one thing that palette exists to
  provide. The signal is now the last level at every `n`, and the greys fill in
  ahead of it.

# tufter 0.5.2

* `quartile_breaks()` puts the axis labels where the quartile frame actually
  breaks. It used `stats::fivenum()` while the frame used
  `stats::quantile(type = 7)`, so for most sample sizes the printed labels sat
  somewhere other than the gaps they were meant to name. At n = 8 the axis read
  56 next to a break at 53.4. With too few distinct values for a summary it now
  returns the two ends, matching the plain range the frame draws there.
* `tufte_audit(measure = FALSE)` no longer changes a figure's verdict. The
  clipping check was gated behind `measure` although it's a stated criterion,
  so a figure with a subtitle too wide to fit reported no violations on the
  fast path. `measure` now governs only the data-ink ratio and the data
  density, which are ungraded.

# tufter 0.5.1

* `tufte_audit()` no longer counts categories along a discrete axis as
  overlaid series. A dot plot of five countries reported "5 series overlaid in
  one panel" and recommended small multiples, which would have put one point
  in each panel. Only a non-positional aesthetic separates series now.
* `data_ink_ratio()` documents the case where the number runs the wrong way: a
  pie chart of continental population measures 0.75 against 0.16 for the dot
  plot that replaces it, because filled interiors count and dots are small.
  The graded criteria separate them correctly, six unmet against one, which is
  why the audit reports the ratio rather than scoring it.
* `tufte_principles()` says in its documentation that `audited` and
  `criterion` are logical, and which of the two separates graded from
  measured.
* The description of `tufte_audit()`'s return value had lost a verb.

# tufter 0.5.0

* New vignette, "Working through a real dataset", using `gapminder` and
  `palmerpenguins`. Both are suggested and guarded.
* `check_labels_fit()`, `data_ink_ratio()`, `data_density()` and
  `sparkline_grob()` no longer leave a graphics device open or write an
  `Rplots.pdf` into the working directory. Measuring borrows a `pdf(NULL)`
  device for the whole measurement, which covers unit conversion as well as
  building the gtable. `tufte_audit()` on a plot with a legend was a second
  route to the same stray file.
* README figures and example output use `palmerpenguins` and `gapminder`.
* The cached API data behind the live-data article has moved to `data-raw/` and
  is no longer installed with the package.
* `Language` is `en-GB`, with an `inst/WORDLIST`.
* Cleveland, McGill and McGill (1988) cited by DOI in `DESCRIPTION`.
* AI usage disclosure added to the README.

# tufter 0.4.2

* `tufte_audit()` and `tufte_principles()` use the same names and the same
  citations for every principle. The audit looks each source up from the table.
* Two principles are marked `audited = FALSE`: nothing reports on them.
* README example output is generated by `data-raw/make_readme_output.R`.
* `scale_fill_tufte_c()` gains a test.

# tufter 0.4.1

* `lie_factor()` reads horizontal bars and `coord_flip()` bars along the axis
  that carries their length. All three orientations report the same distortion.
* `tufte_audit()` names the axis a reader can see when a bar baseline isn't
  zero.
* `bank_to_45()` normalises each panel by its own ranges, which matters under
  free scales.
* A plot setting fixed colours outside `aes()` is no longer reported as carrying
  a legend.
* `slopegraph()` warns when a unit has more than one value in a period.
* `tufte_principles()` uses `NA` in `implemented_by` where no function reaches a
  principle.

# tufter 0.4.0

* New article, "Examples with live API data", drawing on CRAN download logs, the
  USGS earthquake catalogue, the Open-Meteo ERA5 archive and Wikipedia
  pageviews. `data-raw/fetch_live_examples.R` does the fetching and caches the
  result.
* `check_labels_fit()` measures a rotated y axis title along the length of the
  string, against the height of the panel area.
* `sparkline()` and `sparklines()` gain a `big.mark` argument, defaulting to a
  comma.
* `bank_to_45()` documents that the height it returns is for the panel.

# tufter 0.3.0

* `tufte_audit()` grades only the principles for which Tufte states a criterion,
  and measures the rest without a verdict. The thresholds that used to grade the
  measurements are removed.
* The `score` attribute is replaced by `violations`, a count of stated criteria
  not met. `audit_figures()` orders figures by that count.
* `tufte_principles()` gains a `criterion` column.
* The legend check fails on named series and reports a continuous key.
* `quartile_breaks()` returns the whole five-number summary by default.
* The audit cites WCAG for the contrast minimum and Cleveland for banking.

# tufter 0.2.1

* `geom_rangeframe()` and `geom_quartileframe()` name their grobs, so
  `data_ink_ratio()` counts them as data ink.
* `data_density()` groups layers by the data they read, and resolves aesthetics
  to the columns they use.
* `bank_to_45()` reads segments in drawn order and keeps vertical ones. A path
  that's more than half vertical is refused.
* `tufte_audit()` treats a continuous colour scale as one code, catches
  redundant encoding through a transformation, and fails a bar chart on a
  transformed scale. `lie_factor()` returns `NA` for the same.

# tufter 0.2.0

* `bank_to_45()` computes the aspect ratio that brings slopes nearest 45
  degrees, by median absolute slope or mean absolute orientation.
* `check_contrast()` and `contrast_ratio()` measure every colour a plot draws
  with against its background, using the WCAG 2.1 minima.
* `audit_figures()` runs the audit across a list of plots or a directory.
* `geom_cleveland_dot()` draws a dot plot with leader lines.

# tufter 0.1.0

First release.

## Drawing

* `theme_tufte()`, `theme_sparkline()`, `theme_slopegraph()`.
* `geom_rangeframe()`, `geom_quartileframe()`, `quartile_breaks()`.
* `geom_tufteboxplot()`, with `"point"`, `"line"` and `"offset"` variants.
* `geom_dotdash()`.
* `geom_col_tufte()` and `geom_bar_tufte()`.
* `slopegraph()`, `sparkline()`, `sparklines()`, `sparkline_grob()`.
* `facet_tufte()`.
* `geom_text_last()` and `geom_text_first()`.
* `tufte_pal()`, `tufte_colours()` and the `scale_*_tufte()` family.
* `label_source()` and `save_tufte()`.

## Measuring

* `data_ink_ratio()`, `lie_factor()`, `data_density()`, `check_labels_fit()`.
* `tufte_audit()` and `tufte_principles()`.
