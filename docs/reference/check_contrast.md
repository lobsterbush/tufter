# Check that a plot's ink is dark enough to see

The strongest objection to maximising the data-ink ratio is that it's a
licence to draw in hairlines and pale greys, and that the result is
elegant and unreadable. This is the check that keeps the rest of the
package honest: it takes every colour the plot actually draws with,
along with the text colours the theme sets, and measures each against
the background.

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

The thresholds are the WCAG 2.1 ones: 4.5 to 1 for text, and 3 to 1 for
graphical objects, which is what data marks and rules are. These are
minima for people with moderately low vision rather than targets, and a
figure that clears them can still be hard work in a badly lit lecture
theatre.

Colours drawn with transparency are measured as if composited onto the
background, since that's what the reader sees. Theme text is read from
the rendered grobs, including axis-specific styles and legend labels.
This is a colour screening tool, not a complete accessibility
assessment: it does not resolve overlapping marks, text on filled
labels, or contrasting legend and strip backgrounds.

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
