# Changelog

## tufter 0.6.4

I’ve rewritten the site and package help in my voice, including the
audit messages. The documentation now explains each tool’s use and
limits more directly. References and example calculations are unchanged.

- Count columns addressed through `.data$x` or `.data[["x"]]` correctly;
  exclude tidy evaluation pronouns and `.env` constants from data
  density.
- Preserve quartile-frame segments on reversed axes.
- Make failed clipping checks visible and stop strict saves when a check
  can’t run. Reject unit and scale overrides that would change the
  checked size.
- Composite embedded colour transparency and evaluate contrast
  thresholds before rounding. Resolve transparent panels over their plot
  background, and inspect drawn axis and legend text, including
  element-specific overrides.
- Check truncated bar baselines across facets, negative values, and
  reversed axes. Limit numeric lie factors to supported Cartesian
  comparisons.
- Include failed measurements as skipped audit checks; report incomplete
  batch audits and reject ambiguous dimension recycling.
- Account for title margins and additional facet strip positions when
  checking labels. Clarify that panel text still needs visual
  inspection.
- Match the documentation to charlescrabtree.org, open the public
  documentation, and declare AI – Human (editor) provenance.

## tufter 0.6.3

- The minimum ggplot2 version is now 4.0.0, which introduced the
  [`complete_theme()`](https://ggplot2.tidyverse.org/reference/complete_theme.html)
  function used by the audit. Testing has used 4.0.x.
- Removed unused suggested packages: `dplyr`, `jsonlite` and `vdiffr`.
  Data-collection scripts and site-only articles are excluded from the
  build.

## tufter 0.6.2

This release fixes ten issues, including a regression in 0.6.1.

- Quartile frames work with fewer than four distinct axis values,
  including discrete axes. These cases use a plain range frame.
- `sides` and `gap` are validated so invalid settings don’t silently
  remove the frame.
- Contrast checks only measure text that’s drawn and handle fully
  transparent panel fills.
- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  validates its dimensions before running individual checks.
- Minor grids set on just one axis are detected.
- Direct labels accept vector values for `nudge_x` and `nudge_y`.
- [`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md)
  labels the rightmost point when rows are unsorted.
- [`slopegraph()`](https://lobsterbush.github.io/tufter/reference/slopegraph.md)
  counts observed periods rather than unused factor levels.
- [`audit_figures()`](https://lobsterbush.github.io/tufter/reference/audit_figures.md)
  preserves supplied names when some figures are unnamed.
- Sparkline and slopegraph themes document their own base font sizes.

## tufter 0.6.1

This release includes twenty-one fixes identified in audits by a Claude
subagent and Codex. Codex used static inspection because R wasn’t
available in its sandbox; the findings were checked before the fixes
were made.

### Measurement

- Contrast checks use the 4.5:1 text threshold for text layers.
- Data density respects layer-specific mappings and
  `inherit.aes = FALSE`. Plots without mapped variables can report zero
  entries.
- Banking accounts for coordinate transformations when measuring slopes.
- Banking rejects step charts, whose rendered segments are horizontal or
  vertical.
- Lie-factor checks exclude general rectangles that aren’t bars.
- Measurement functions reject non-positive or non-finite dimensions.

### Drawing

- Cleveland leader lines follow coordinate transformations.
- Minimal box plots report a clearer error for unsupported horizontal
  layouts.
- Slopegraphs warn when more than two periods are supplied because only
  the first and last periods are labelled.

### Documentation

- Label-fit help describes coverage of axes and strips on all four sides
  and explains that panel text needs separate inspection.

### Other fixes

- Quartile frames and their axis labels use the same data-space summary
  under nonlinear scales and coordinate flips.
- Batch audits preserve the position and details of figures after a
  failure.
- Pie-chart checks recognize
  [`coord_radial()`](https://ggplot2.tidyverse.org/reference/coord_radial.html).
- Redundant position-and-colour mappings are detected on either axis.
- Equivalent white colour specifications no longer trigger a background
  failure.
- Average-orientation banking reports an error when no aspect ratio
  reaches the target.
- Continuous guides for size, alpha and linewidth no longer prompt
  advice to label discrete series.
- Data density handles plots without layers.
- Successful label-fit checks return invisibly.
- Bar rules are drawn once when minor breaks include major breaks.
- Direct-label help identifies `label` as required. Batch-audit help
  separates its parameters from the explanation of the count.

## tufter 0.6.0

- Data-ink estimates include line, path, step, text and segment grobs
  whose names don’t begin with `geom`.
- Bar rules use the appropriate axis for the layer’s orientation. An
  explicit `sides` value without numeric breaks produces a warning.
- Shared helpers determine bar orientation and the five-number summary
  used by quartile frames and their labels.

## tufter 0.5.4

- Erased bar rules work under
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html).

## tufter 0.5.3

- The accent palette includes its accent at every requested palette
  size. The accent is assigned to the last level.

## tufter 0.5.2

- [`quartile_breaks()`](https://lobsterbush.github.io/tufter/reference/quartile_breaks.md)
  uses the same type-7 quantiles as the frame. With too few distinct
  values, it returns the endpoints used by the plain range frame.
- `tufte_audit(measure = FALSE)` still runs label-fit checks. The option
  skips only the ungraded data-ink and density measurements.

## tufter 0.5.1

- Discrete axis categories aren’t counted as separate overlaid series.
- Data-ink help explains why filled shapes can have higher ratios than
  dot plots of the same values.
- Principles-table help explains the logical `audited` and `criterion`
  columns.
- Corrected the audit return-value description.

## tufter 0.5.0

- Added “Working through a real dataset”, using `gapminder` and
  `palmerpenguins` with guarded suggested dependencies.
- Measurement and legend checks restore graphics devices and avoid
  writing `Rplots.pdf` to the working directory.
- README examples use `palmerpenguins` and `gapminder`.
- The cached API snapshot moved to `data-raw/` and is excluded from
  installation.
- Set `Language` to `en-GB` and added `inst/WORDLIST`.
- Cleveland, McGill and McGill (1988) cited by DOI in `DESCRIPTION`.
- Added an AI usage disclosure to the README.

## tufter 0.4.2

- Audits look up principle names and citations in the principles table.
- Marked two uncheckable principles with `audited = FALSE`.
- README output is generated by `data-raw/make_readme_output.R`.
- Added a test for
  [`scale_fill_tufte_c()`](https://lobsterbush.github.io/tufter/reference/scale_colour_tufte.md).

## tufter 0.4.1

- Lie factors account for horizontal bars and
  [`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html).
- Baseline messages name the visible axis.
- Banking normalizes each panel by its own ranges.
- Fixed colours outside
  [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html) don’t
  trigger a legend warning.
- Slopegraphs warn about duplicate unit-period observations.
- Principles without an implementing function use `NA` in
  `implemented_by`.

## tufter 0.4.0

- Added “Examples with live API data”, using CRAN downloads, USGS
  earthquakes, Open-Meteo ERA5 temperatures and Wikipedia pageviews. The
  fetching script saves a snapshot for the documentation build.
- Label fitting measures rotated y-axis titles against panel height.
- Sparklines accept `big.mark`, with a comma as the default.
- Banking help clarifies that its suggested height describes the panel.

## tufter 0.3.0

- Audits grade principles with stated criteria and report other
  measurements without thresholds.
- Replaced `score` with `violations`, the count used to order batch
  results.
- Added the `criterion` column to the principles table.
- Legend checks distinguish named series from continuous keys.
- Quartile breaks keep the full five-number summary by default.
- The audit cites WCAG for the contrast minimum and Cleveland for
  banking.

## tufter 0.2.1

- Range-frame grobs are named so they count as data ink.
- Data density groups layers by data source and resolves mapped columns.
- Banking uses drawn segment order and includes vertical segments. It
  rejects paths that are more than half vertical.
- Audits handle continuous colour, transformed redundant mappings, and
  bars on transformed scales. Lie factor returns `NA` for the last case.

## tufter 0.2.0

- Added banking by median absolute slope or mean absolute orientation.
- Added colour-contrast measurements using WCAG 2.1 thresholds.
- Added batch audits for plot lists and directories.
- Added Cleveland dot plots with leader lines.

## tufter 0.1.0

The first release includes themes, range and quartile frames, minimal
box plots, dot-dash margins, and bars with erased gridlines. It also
provides slopegraphs, sparklines, small multiples, direct labels and
colour scales. Source notes and export helpers support preparing figures
for use.

The measurement tools estimate data-ink ratio, lie factor and data
density, and check label space. The audit and principles table bring
those tools together.
