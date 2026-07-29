# Changelog

## tufter 0.2.1

Bug fixes found by auditing the package against itself. Three of these
changed reported numbers, so figures measured with 0.2.0 should be
measured again.

### Measurement correctness

- [`geom_rangeframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  and
  [`geom_quartileframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  returned an unnamed grob, so
  [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md)
  counted the frame as furniture rather than as data. Adding a range
  frame therefore *lowered* the measured ratio, inverting the package’s
  own advice. Frames are now named like every other layer; the ratio for
  a framed scatterplot rises from 0.60 to 0.73.
- [`data_density()`](https://lobsterbush.github.io/tufter/reference/data_density.md)
  summed rows across layers, so a range frame and a dot-dash drawn over
  the same thirty-two observations were counted as ninety-six entries.
  Layers are now grouped by the data they read, and a layer carrying its
  own data still counts separately.
- [`data_density()`](https://lobsterbush.github.io/tufter/reference/data_density.md)
  counted `factor(cyl)` and `cyl` as two variables. Aesthetics are now
  resolved to the columns they actually read.
- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  sorted points by x and discarded segments with no horizontal extent,
  which silently assumed every path was a function of x. A circle
  returned an aspect ratio of 0.016 instead of 1. Segments are now read
  in drawn order and verticals are kept as the infinite slopes they are.
  A path that is more than half vertical is refused rather than answered
  wrongly.

### Fewer false alarms

- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  no longer reports a continuous colour scale as “22 distinct colours”.
  A gradient is one code, not a set of competing hues.
- Redundant encoding is now detected through a transformation, so
  `x = factor(cyl)` with `colour = cyl` is caught.
- [`lie_factor()`](https://lobsterbush.github.io/tufter/reference/lie_factor.md)
  returned 1 for a bar chart on a log scale, which read as a clean bill
  of health for one of the more distorting things you can do to a bar.
  It now returns `NA`, and the audit fails the plot with an explanation.

### Documentation

- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  claimed
  [`save_tufte()`](https://lobsterbush.github.io/tufter/reference/save_tufte.md)
  would bank for you. It will not, and never did; the cross-reference
  now says so.

## tufter 0.2.0

### Measuring

- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  computes the aspect ratio that brings a plot’s slopes nearest 45
  degrees, where slope is judged most accurately. Two methods:
  Cleveland’s median absolute slope, and mean absolute orientation,
  optionally weighted by segment length.
- [`check_contrast()`](https://lobsterbush.github.io/tufter/reference/check_contrast.md)
  and
  [`contrast_ratio()`](https://lobsterbush.github.io/tufter/reference/contrast_ratio.md)
  measure every colour a plot draws with against its background, using
  the WCAG 2.1 minima. Transparency is composited first, so a colour is
  judged as the reader sees it. Erasing ink is only a virtue up to the
  point where what remains can still be seen.
- [`audit_figures()`](https://lobsterbush.github.io/tufter/reference/audit_figures.md)
  runs the audit across every figure in a paper, given a list of plots
  or a directory of saved ones, and returns them worst first with the
  failing checks named.

### Drawing

- [`geom_cleveland_dot()`](https://lobsterbush.github.io/tufter/reference/geom_cleveland_dot.md)
  draws a dot plot with leader lines. This is the second answer to a bar
  chart whose baseline is not zero, and until now the audit recommended
  it without the package providing it.

### Auditing

- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  gains two checks: whether the given aspect ratio banks the slopes near
  45 degrees, and whether the ink is dark enough to see.

## tufter 0.1.0

First release.

### Generative

- [`theme_tufte()`](https://lobsterbush.github.io/tufter/reference/theme_tufte.md),
  [`theme_sparkline()`](https://lobsterbush.github.io/tufter/reference/theme_sparkline.md),
  [`theme_slopegraph()`](https://lobsterbush.github.io/tufter/reference/theme_slopegraph.md).
- [`geom_rangeframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md),
  [`geom_quartileframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  and
  [`quartile_breaks()`](https://lobsterbush.github.io/tufter/reference/quartile_breaks.md).
- [`geom_tufteboxplot()`](https://lobsterbush.github.io/tufter/reference/geom_tufteboxplot.md),
  with `"point"`, `"line"` and `"offset"` variants.
- [`geom_dotdash()`](https://lobsterbush.github.io/tufter/reference/geom_dotdash.md)
  for marginal distributions on the axes.
- [`geom_col_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
  and
  [`geom_bar_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md),
  which erase the gridlines where they cross the bars.
- [`slopegraph()`](https://lobsterbush.github.io/tufter/reference/slopegraph.md),
  [`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md),
  [`sparklines()`](https://lobsterbush.github.io/tufter/reference/sparklines.md)
  and
  [`sparkline_grob()`](https://lobsterbush.github.io/tufter/reference/sparkline_grob.md).
- [`facet_tufte()`](https://lobsterbush.github.io/tufter/reference/facet_tufte.md)
  for small multiples, with scales fixed.
- [`geom_text_last()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md)
  and
  [`geom_text_first()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md)
  for direct labelling.
- [`tufte_pal()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md),
  [`tufte_colours()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md)
  and the `scale_*_tufte()` family.
- [`label_source()`](https://lobsterbush.github.io/tufter/reference/label_source.md)
  and
  [`save_tufte()`](https://lobsterbush.github.io/tufter/reference/save_tufte.md).

### Evaluative

- [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md),
  estimated by rendering the plot with and without its data layers and
  comparing weighted non-background pixels.
- [`lie_factor()`](https://lobsterbush.github.io/tufter/reference/lie_factor.md),
  for numeric vectors and for bar charts with a truncated baseline.
- [`data_density()`](https://lobsterbush.github.io/tufter/reference/data_density.md).
- [`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md),
  which catches clipped titles and overlapping axis labels at the
  intended print size.
- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md),
  which runs all of the above plus the structural checks.
- [`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md),
  listing every principle and whether it can be audited.
