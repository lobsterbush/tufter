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
