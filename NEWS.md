# tufter 0.2.1

Bug fixes found by auditing the package against itself. Three of these changed
reported numbers, so figures measured with 0.2.0 should be measured again.

## Measurement correctness

* `geom_rangeframe()` and `geom_quartileframe()` returned an unnamed grob, so
  `data_ink_ratio()` counted the frame as furniture rather than as data. Adding
  a range frame therefore *lowered* the measured ratio, inverting the package's
  own advice. Frames are now named like every other layer; the ratio for a
  framed scatterplot rises from 0.60 to 0.73.
* `data_density()` summed rows across layers, so a range frame and a dot-dash
  drawn over the same thirty-two observations were counted as ninety-six
  entries. Layers are now grouped by the data they read, and a layer carrying
  its own data still counts separately.
* `data_density()` counted `factor(cyl)` and `cyl` as two variables. Aesthetics
  are now resolved to the columns they actually read.
* `bank_to_45()` sorted points by x and discarded segments with no horizontal
  extent, which silently assumed every path was a function of x. A circle
  returned an aspect ratio of 0.016 instead of 1. Segments are now read in
  drawn order and verticals are kept as the infinite slopes they are. A path
  that is more than half vertical is refused rather than answered wrongly.

## Fewer false alarms

* `tufte_audit()` no longer reports a continuous colour scale as "22 distinct
  colours". A gradient is one code, not a set of competing hues.
* Redundant encoding is now detected through a transformation, so `x =
  factor(cyl)` with `colour = cyl` is caught.
* `lie_factor()` returned 1 for a bar chart on a log scale, which read as a
  clean bill of health for one of the more distorting things you can do to a
  bar. It now returns `NA`, and the audit fails the plot with an explanation.

## Documentation

* `bank_to_45()` claimed `save_tufte()` would bank for you. It will not, and
  never did; the cross-reference now says so.

# tufter 0.2.0

## Measuring

* `bank_to_45()` computes the aspect ratio that brings a plot's slopes nearest
  45 degrees, where slope is judged most accurately. Two methods: Cleveland's
  median absolute slope, and mean absolute orientation, optionally weighted by
  segment length.
* `check_contrast()` and `contrast_ratio()` measure every colour a plot draws
  with against its background, using the WCAG 2.1 minima. Transparency is
  composited first, so a colour is judged as the reader sees it. Erasing ink is
  only a virtue up to the point where what remains can still be seen.
* `audit_figures()` runs the audit across every figure in a paper, given a list
  of plots or a directory of saved ones, and returns them worst first with the
  failing checks named.

## Drawing

* `geom_cleveland_dot()` draws a dot plot with leader lines. This is the second
  answer to a bar chart whose baseline is not zero, and until now the audit
  recommended it without the package providing it.

## Auditing

* `tufte_audit()` gains two checks: whether the given aspect ratio banks the
  slopes near 45 degrees, and whether the ink is dark enough to see.

# tufter 0.1.0

First release.

## Generative

* `theme_tufte()`, `theme_sparkline()`, `theme_slopegraph()`.
* `geom_rangeframe()`, `geom_quartileframe()` and `quartile_breaks()`.
* `geom_tufteboxplot()`, with `"point"`, `"line"` and `"offset"` variants.
* `geom_dotdash()` for marginal distributions on the axes.
* `geom_col_tufte()` and `geom_bar_tufte()`, which erase the gridlines where
  they cross the bars.
* `slopegraph()`, `sparkline()`, `sparklines()` and `sparkline_grob()`.
* `facet_tufte()` for small multiples, with scales fixed.
* `geom_text_last()` and `geom_text_first()` for direct labelling.
* `tufte_pal()`, `tufte_colours()` and the `scale_*_tufte()` family.
* `label_source()` and `save_tufte()`.

## Evaluative

* `data_ink_ratio()`, estimated by rendering the plot with and without its data
  layers and comparing weighted non-background pixels.
* `lie_factor()`, for numeric vectors and for bar charts with a truncated
  baseline.
* `data_density()`.
* `check_labels_fit()`, which catches clipped titles and overlapping axis
  labels at the intended print size.
* `tufte_audit()`, which runs all of the above plus the structural checks.
* `tufte_principles()`, listing every principle and whether it can be audited.

<!-- HIDDEN FOR NOW, alongside the disclosure itself in README.md.

## Documentation

* Added an AI usage disclosure to the README, naming what was model-generated,
  what was human-verified and how, and what remains unverified.

END OF HIDDEN SECTION -->
