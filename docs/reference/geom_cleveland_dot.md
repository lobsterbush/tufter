# The Cleveland dot plot

When the audit tells you that a bar chart's baseline isn't zero, it's
offering you two ways out: start at zero, or stop using bars. This is
the second. A dot encodes its value by position rather than by length,
so it can be read on a scale that doesn't include zero without lying
about proportions, and it uses a fraction of the ink a bar does.

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
  down the left and values across, which is what you want whenever the
  category names are words. `"x"` is the transpose.

- leader:

  One of `"axis"` (the default), which draws the leader from the axis to
  the dot, `"full"`, which runs it the whole width of the panel, or
  `"none"`.

- leader_colour, leader_linetype, leader_linewidth:

  Appearance of the leader line. It should be quiet enough to read past.

## Value

A `ggplot2` layer.

## Details

Cleveland's version adds a light leader line running from the axis to
the dot, which lets the eye track a long way along a row without
drifting into the neighbouring one. That line isn't data-ink, and it
earns its place only because the alternative is a misread row.

Sort the categories before plotting. An alphabetical dot plot wastes the
main advantage of the form, which is that rank is visible at a glance;
use [`stats::reorder()`](https://rdrr.io/r/stats/reorder.factor.html) or
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
