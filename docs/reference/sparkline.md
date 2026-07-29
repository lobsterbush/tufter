# Sparklines

A sparkline is a word-sized graphic: a time series drawn small enough to
sit inside a sentence, a table cell, or a margin, where the reader meets
it in the same glance as the text around it. Tufte introduced them in
*Beautiful Evidence* as the extreme case of data-ink maximisation, with
resolution traded for context.

## Usage

``` r
sparkline(
  values,
  index = seq_along(values),
  band = c(0.25, 0.75),
  band_fill = "grey90",
  extremes = TRUE,
  last_point = TRUE,
  label = TRUE,
  accuracy = 0.1,
  colour = "grey15",
  linewidth = 0.3,
  extreme_colours = c("#4a6b82", "#a1483c")
)
```

## Arguments

- values:

  Numeric vector of values, in order.

- index:

  Optional numeric vector of positions. Defaults to `seq_along(values)`.

- band:

  Either `NULL` for no band, or a length-2 numeric vector of quantiles
  defining the normal range. Defaults to `c(0.25, 0.75)`.

- band_fill:

  Fill colour of the normal-range band.

- extremes:

  Logical. Mark the minimum and maximum with dots?

- last_point:

  Logical. Mark the final value with a dot?

- label:

  Logical. Print the final value at the right-hand end?

- accuracy:

  Rounding for the printed value, passed to
  [`label_number()`](https://scales.r-lib.org/reference/label_number.html).
  Defaults to `0.1`.

- colour:

  Line colour. Defaults to a near-black grey.

- linewidth:

  Line width. Defaults to `0.3`, a hairline.

- extreme_colours:

  Length-2 vector of colours for the minimum and maximum dots.

## Value

A `ggplot` object with no axes, sized to be printed small.

## Details

The conventional furniture is a grey band showing the normal range, dots
at the minimum and maximum, and the final value printed at the
right-hand end. Everything else, including both axes, is gone.

## See also

[`sparklines()`](https://lobsterbush.github.io/tufter/reference/sparklines.md)
for many series at once,
[`sparkline_grob()`](https://lobsterbush.github.io/tufter/reference/sparkline_grob.md)
to embed one in other graphics.

## Examples

``` r
set.seed(1)
sparkline(cumsum(rnorm(80)))
```
