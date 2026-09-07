# A sparkline as a grob

Return a `grid` grob that you can place in another graphic, a table
cell, or an rmarkdown inline chunk.

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
