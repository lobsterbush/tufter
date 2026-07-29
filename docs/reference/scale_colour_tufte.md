# Tufte colour and fill scales

Discrete and continuous scales built on
[`tufte_pal()`](https://lobsterbush.github.io/tufter/reference/tufte_pal.md).

## Usage

``` r
scale_colour_tufte(palette = "grey", ..., reverse = FALSE)

scale_color_tufte(palette = "grey", ..., reverse = FALSE)

scale_fill_tufte(palette = "grey", ..., reverse = FALSE)

scale_colour_tufte_c(palette = "divergent", ..., reverse = FALSE)

scale_fill_tufte_c(palette = "divergent", ..., reverse = FALSE)
```

## Arguments

- palette:

  One of `"grey"`, `"accent"`, `"muted"`, `"divergent"`.

- ...:

  Passed to
  [`discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html)
  or
  [`continuous_scale()`](https://ggplot2.tidyverse.org/reference/continuous_scale.html).

- reverse:

  Logical. Reverse the palette order?

## Value

A `ggplot2` scale.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  scale_colour_tufte("accent") +
  theme_tufte()
```
