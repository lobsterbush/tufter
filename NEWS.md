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
