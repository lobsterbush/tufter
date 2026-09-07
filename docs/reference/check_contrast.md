# Check contrast in a plot

Pale colours can make a figure hard to read. This function checks
data-mark colours and rendered theme text against the plot's background.
That includes axis labels and legend text with their own style settings.

## Usage

``` r
check_contrast(plot, background = NULL, text_min = 4.5, mark_min = 3)
```

## Arguments

- plot:

  A `ggplot` object.

- background:

  The colour to measure against. By default this is taken from the
  plot's own panel or plot background, falling back to white.

- text_min, mark_min:

  Minimum acceptable ratios for text and for data marks. Default to 4.5
  and 3.

## Value

A tibble with one row per distinct colour: what it's used for, the
colour, its contrast ratio against the background, the threshold
applied, and whether it passes.

## Details

The default thresholds follow WCAG 2.1: 4.5 to 1 for text and 3 to 1 for
marks. Transparent colours are composited onto the background before
checking.

There are limits. The check doesn't resolve overlapping marks, text on
filled labels, or separate legend and strip backgrounds. I'd also
inspect the figure where it'll be used, particularly if it's going on a
projector.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
check_contrast(p)
#> # A tibble: 3 × 5
#>   role       colour ratio threshold passes
#>   <chr>      <chr>  <dbl>     <dbl> <lgl> 
#> 1 axis text  grey20  12.6       4.5 TRUE  
#> 2 data mark  black   21         3   TRUE  
#> 3 axis title black   21         4.5 TRUE  

# A figure drawn too faintly to read.
check_contrast(
  ggplot(mtcars, aes(wt, mpg)) + geom_point(colour = "grey85") + theme_tufte()
)
#> # A tibble: 3 × 5
#>   role       colour ratio threshold passes
#>   <chr>      <chr>  <dbl>     <dbl> <lgl> 
#> 1 data mark  grey85  1.41       3   FALSE 
#> 2 axis text  grey20 12.6        4.5 TRUE  
#> 3 axis title black  21          4.5 TRUE  
```
