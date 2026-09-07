# Many sparklines at once

Stack one sparkline per series, with its name on the left and final
value on the right. Each series has its own vertical scale.

## Usage

``` r
sparklines(
  data,
  x,
  y,
  group,
  band = c(0.25, 0.75),
  band_fill = "grey90",
  extremes = TRUE,
  label = TRUE,
  accuracy = 0.1,
  big.mark = ",",
  colour = "grey15",
  linewidth = 0.3
)
```

## Arguments

- data:

  A data frame.

- x, y, group:

  Bare column names for position, value and series.

- band, band_fill, colour, linewidth, accuracy, big.mark:

  As in
  [`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md).

- extremes:

  Logical. Mark each series' minimum and maximum?

- label:

  Logical. Print each series' final value at the right?

## Value

A `ggplot` object.

## Details

This is useful for comparing patterns over time. To compare levels
across series on a shared scale, use
[`facet_tufte()`](https://lobsterbush.github.io/tufter/reference/facet_tufte.md).

## Examples

``` r
set.seed(1)
d <- data.frame(
  t = rep(1:40, 4),
  v = c(cumsum(rnorm(40)), cumsum(rnorm(40)), cumsum(rnorm(40)),
        cumsum(rnorm(40))),
  series = rep(c("Wheat", "Maize", "Rice", "Barley"), each = 40)
)
sparklines(d, t, v, series)
```
