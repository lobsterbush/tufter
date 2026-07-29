# Package index

## Drawing

The graphical forms Tufte designed or advocated, as ggplot2 layers,
themes, scales and plot constructors.

### Themes

- [`theme_tufte()`](https://lobsterbush.github.io/tufter/reference/theme_tufte.md)
  : A maximum data-ink theme
- [`theme_sparkline()`](https://lobsterbush.github.io/tufter/reference/theme_sparkline.md)
  : A theme for sparklines
- [`theme_slopegraph()`](https://lobsterbush.github.io/tufter/reference/theme_slopegraph.md)
  : A theme for slopegraphs

### Frames and margins

Replacements for the panel border, which is the same box whatever the
numbers are.

- [`geom_rangeframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  [`geom_quartileframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  : Range frames and quartile frames
- [`quartile_breaks()`](https://lobsterbush.github.io/tufter/reference/quartile_breaks.md)
  : Axis breaks at the five-number summary
- [`geom_dotdash()`](https://lobsterbush.github.io/tufter/reference/geom_dotdash.md)
  : Dot-dash-plot marginal distributions

### Distributions and comparisons

- [`geom_tufteboxplot()`](https://lobsterbush.github.io/tufter/reference/geom_tufteboxplot.md)
  : Tufte's minimal box plot
- [`geom_col_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
  [`geom_bar_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
  : Bar charts with the gridlines erased through the bars
- [`geom_cleveland_dot()`](https://lobsterbush.github.io/tufter/reference/geom_cleveland_dot.md)
  : The Cleveland dot plot
- [`slopegraph()`](https://lobsterbush.github.io/tufter/reference/slopegraph.md)
  : Slopegraphs
- [`facet_tufte()`](https://lobsterbush.github.io/tufter/reference/facet_tufte.md)
  : Small multiples

### Word-sized graphics

- [`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md)
  : Sparklines
- [`sparklines()`](https://lobsterbush.github.io/tufter/reference/sparklines.md)
  : Many sparklines at once
- [`sparkline_grob()`](https://lobsterbush.github.io/tufter/reference/sparkline_grob.md)
  : A sparkline as a grob

### Colour and labelling

Colour as a code rather than decoration, and words on the data rather
than in a legend.

- [`tufte_pal()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md)
  [`tufte_colours()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md)
  [`tufte_colors()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md)
  : Tufte's colour palettes
- [`scale_colour_tufte()`](https://lobsterbush.github.io/tufter/reference/scale_colour_tufte.md)
  [`scale_color_tufte()`](https://lobsterbush.github.io/tufter/reference/scale_colour_tufte.md)
  [`scale_fill_tufte()`](https://lobsterbush.github.io/tufter/reference/scale_colour_tufte.md)
  [`scale_colour_tufte_c()`](https://lobsterbush.github.io/tufter/reference/scale_colour_tufte.md)
  [`scale_fill_tufte_c()`](https://lobsterbush.github.io/tufter/reference/scale_colour_tufte.md)
  : Tufte colour and fill scales
- [`geom_text_last()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md)
  [`geom_text_first()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md)
  : Label series directly instead of with a legend
- [`label_source()`](https://lobsterbush.github.io/tufter/reference/label_source.md)
  : Add a source note to a figure

## Measuring

The quantities Tufte defined, so that a finished figure can be scored
rather than admired.

- [`data_ink_ratio()`](https://lobsterbush.github.io/tufter/reference/data_ink_ratio.md)
  : Data-ink ratio
- [`lie_factor()`](https://lobsterbush.github.io/tufter/reference/lie_factor.md)
  : Lie factor
- [`data_density()`](https://lobsterbush.github.io/tufter/reference/data_density.md)
  : Data density
- [`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
  : Bank the aspect ratio to 45 degrees
- [`check_contrast()`](https://lobsterbush.github.io/tufter/reference/check_contrast.md)
  : Check that a plot's ink is dark enough to see
- [`contrast_ratio()`](https://lobsterbush.github.io/tufter/reference/contrast_ratio.md)
  : WCAG contrast ratio between two colours
- [`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md)
  : Check that every text element fits inside the canvas

### Auditing

- [`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
  : Audit a plot against Tufte's principles
- [`audit_figures()`](https://lobsterbush.github.io/tufter/reference/audit_figures.md)
  : Audit every figure in a paper at once

## Reference and output

- [`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md)
  : Tufte's principles, and what implements them
- [`save_tufte()`](https://lobsterbush.github.io/tufter/reference/save_tufte.md)
  : Save a figure, and check it before you do
- [`tufter`](https://lobsterbush.github.io/tufter/reference/tufter-package.md)
  [`tufter-package`](https://lobsterbush.github.io/tufter/reference/tufter-package.md)
  : tufter: Implement Edward Tufte's Principles of Graphical Design
