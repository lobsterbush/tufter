# Bar charts with the gridlines erased through the bars

Tufte's bar chart redesign is the clearest case of erasing redundant
data-ink. The gridlines are needed, because readers have to recover
values from bar heights. But a gridline crossing a bar is drawn on top
of ink that already encodes the same information, so it is erased there
instead of being drawn over the bar. The result is a bar with white
rules through it, which reads as a ruler laid against the data.

## Usage

``` r
geom_col_tufte(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "stack",
  ...,
  sides = c("y", "x"),
  rule_colour = "white",
  rule_linewidth = 0.6,
  minor = FALSE,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)

geom_bar_tufte(
  mapping = NULL,
  data = NULL,
  stat = "count",
  position = "stack",
  ...,
  sides = c("y", "x"),
  rule_colour = "white",
  rule_linewidth = 0.6,
  minor = FALSE,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)
```

## Arguments

- mapping, data, stat, position, na.rm, show.legend, inherit.aes, ...:

  Standard `ggplot2` layer arguments. See
  [`layer()`](https://ggplot2.tidyverse.org/reference/layer.html).

- sides:

  Which axis's breaks to erase through the bars. `"y"` (the default)
  suits vertical bars; `"x"` suits horizontal ones.

- rule_colour:

  Colour of the erased rules. Defaults to `"white"`, which is correct on
  a white page; set it to your background colour otherwise.

- rule_linewidth:

  Width of the erased rules. Defaults to `0.6`.

- minor:

  Logical. Erase minor breaks as well as major ones? Defaults to
  `FALSE`.

## Value

A `ggplot2` layer.

## Details

Use with
[`theme_tufte()`](https://lobsterbush.github.io/tufter/reference/theme_tufte.md)
and `grid = "none"`: this layer draws the white rules, and the theme
should not add grey ones underneath.

## Examples

``` r
library(ggplot2)
d <- data.frame(
  who = c("Reagan", "Bush", "Clinton", "Bush", "Obama"),
  value = c(3.5, 2.3, 3.9, 2.1, 2.5)
)
ggplot(d, aes(who, value)) +
  geom_col_tufte(fill = "grey70") +
  theme_tufte()
```
