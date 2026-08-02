# Many sparklines at once

Draws one sparkline per series, stacked, with the series name to the
left and the final value to the right. This is the form Tufte uses for
tables of indicators, where the reader wants shape and level together.

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

Each series keeps its own vertical scale, because a sparkline reports
the shape of one series rather than inviting comparison of levels across
series. If you do want levels compared, use
[`facet_tufte()`](https://lobsterbush.github.io/tufter/reference/facet_tufte.md),
which fixes the scales.

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
