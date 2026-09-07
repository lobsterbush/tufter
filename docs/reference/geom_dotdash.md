# Dot-dash-plot marginal distributions

Add a short tick for each observation along the plot's margins. Tufte's
dot-dash plot uses these ticks to show the marginal distributions beside
a scatterplot.

## Usage

``` r
geom_dotdash(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  ...,
  sides = "bl",
  tick_length = grid::unit(0.02, "npc"),
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

  Which margins to draw on, as a string containing any of `"b"`, `"l"`,
  `"t"`, `"r"`. Defaults to `"bl"`.

- tick_length:

  Tick length, as a [`unit`](https://rdrr.io/r/grid/unit.html). Defaults
  to 2 percent of the panel.

## Value

A `ggplot2` layer.

## Details

The default ticks are short and thin. Use `theme_tufte(ticks = FALSE)`
if you'd like them to replace the ordinary axis ticks.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_dotdash() +
  theme_tufte(ticks = FALSE)
```
