# Lie factor

Tufte's measure of graphical integrity: the size of the effect shown in
the graphic divided by the size of the effect in the data. A truthful
graphic has a lie factor of one. Tufte treats anything outside roughly
0.95 to 1.05 as distortion.

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

Two ways in. Given two numeric vectors, the first the underlying values
and the second the sizes actually drawn, `lie_factor()` compares the
proportional change in each. Given a `ggplot` containing bars or
columns, it computes the distortion introduced by a baseline that
doesn't start at zero, which is by far the most common way a real figure
lies: a bar whose length no longer is the quantity it stands for.

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
