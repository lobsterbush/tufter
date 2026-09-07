# Lie factor

The lie factor divides the proportional change shown in a graphic by the
proportional change in the data. A value of one means those changes
agree. Tufte treats values outside roughly 0.95 to 1.05 as distortion.

## Usage

``` r
lie_factor(x, ...)

# S3 method for class 'numeric'
lie_factor(x, graphic, ...)

# S3 method for class 'ggplot'
lie_factor(x, ...)

# Default S3 method
lie_factor(x, ...)
```

## Arguments

- x:

  Either a numeric vector of underlying data values, or a `ggplot`
  object.

- ...:

  Unused.

- graphic:

  For the numeric method, a numeric vector of the same length giving the
  sizes drawn in the graphic.

## Value

A numeric lie factor, or `NA` when there's nothing to compare. The
`ggplot` method returns `1` for a plot with no bars or with a zero
baseline. For supported Cartesian bars it checks each panel and returns
the largest distortion, including negative and reversed axes. Nonlinear
coordinates and truncated stacked or floating bars return `NA` when no
supported comparison is available.

## Details

Supply two numeric vectors to compare data values with the sizes drawn.
Or supply a `ggplot` with bars to measure the effect of a non-zero
baseline. The plot method is limited to supported bar comparisons; a
result of one isn't a general assessment of the figure's accuracy.

## Examples

``` r
# Tufte's fuel-economy example: an 18 percent change drawn as 783 percent.
lie_factor(c(18.0, 27.5), c(0.6, 5.3))
#> [1] 14.84211

library(ggplot2)
d <- data.frame(g = c("a", "b"), v = c(100, 110))
lie_factor(ggplot(d, aes(g, v)) + geom_col() +
             coord_cartesian(ylim = c(95, 115)))
#> [1] 16.66667
```
