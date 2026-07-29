# A sparkline as a grob

Returns a `grid` grob so that a sparkline can be placed inside another
graphic, a table cell, or an rmarkdown inline chunk, which is where
Tufte intended them to live.

## Usage

``` r
sparkline_grob(values, ...)
```

## Arguments

- values:

  Numeric vector of values, in order.

- ...:

  Passed to
  [`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md).

## Value

A `grid` grob.

## Examples

``` r
set.seed(1)
g <- sparkline_grob(cumsum(rnorm(50)))
grid::grid.newpage()
grid::grid.draw(g)
```
