# The Cleveland dot plot

A dot plot is useful when you want to compare values in a narrow range.
Dots show position on a scale, so the axis can exclude zero without
changing what the length of a mark represents.

## Usage

``` r
geom_cleveland_dot(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  ...,
  orientation = c("y", "x"),
  leader = c("axis", "full", "none"),
  leader_colour = "grey80",
  leader_linetype = "dotted",
  leader_linewidth = 0.3,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)
```

## Arguments

- mapping, data, stat, position, na.rm, show.legend, inherit.aes, ...:

  Standard `ggplot2` layer arguments. See
  [`layer()`](https://ggplot2.tidyverse.org/reference/layer.html).

- orientation:

  Which axis holds the categories. `"y"`, the default, puts categories
  down the left and values across. This leaves room for category names.
  `"x"` transposes the layout.

- leader:

  One of `"axis"` (the default), which draws the leader from the axis to
  the dot, `"full"`, which runs it the whole width of the panel, or
  `"none"`.

- leader_colour, leader_linetype, leader_linewidth:

  Appearance of the leader line. Keep it light enough to distinguish
  from the dots.

## Value

A `ggplot2` layer.

## Details

Cleveland's leader lines help readers follow each row to its value. You
can extend them across the panel or turn them off.

If rank is the comparison you want, sort the categories by value before
plotting. Use
[`stats::reorder()`](https://rdrr.io/r/stats/reorder.factor.html) or
[`forcats::fct_reorder()`](https://forcats.tidyverse.org/reference/fct_reorder.html).

## Examples

``` r
library(ggplot2)
d <- data.frame(
  country = c("Japan", "Korea", "Australia", "New Zealand", "Singapore"),
  value = c(41.2, 32.9, 38.4, 29.7, 22.5)
)

ggplot(d, aes(value, stats::reorder(country, value))) +
  geom_cleveland_dot() +
  labs(x = "Share (%)", y = NULL) +
  theme_tufte()
```
