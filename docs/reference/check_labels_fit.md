# Check that the labels fit inside the canvas

A subtitle that fits in a preview can still be cut off in the saved
figure. This function measures text at the width and height you plan to
use.

## Usage

``` r
check_labels_fit(plot, width = 6.5, height = 4)
```

## Arguments

- plot:

  A `ggplot` object.

- width, height:

  Intended size in inches. Defaults to 6.5 by 4.

## Value

A tibble with one row per element checked: what it needs, what it has,
and whether it fits. Invisibly returns the same tibble when all elements
fit.

## Details

It checks the title, subtitle, caption, axis titles and tick labels on
all four sides, legend, and facet strips. If something doesn't fit, try
a line break, a wider figure, or a smaller font, then inspect the saved
file.

Text inside the panel, including labels from
[`geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
and
[`geom_text_last()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md),
isn't measured. Its clipping depends on the panel range and coordinate
settings. Check those labels yourself and add room with
[`expansion()`](https://ggplot2.tidyverse.org/reference/expansion.html)
where needed. This check can't certify that every label is readable or
free of overlap.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  labs(subtitle = paste(rep("A very long subtitle indeed", 6), collapse = " "))
check_labels_fit(p, width = 6.5, height = 4)
#> Warning: 1 element will be clipped at 6.5in x 4in.
#> ✖ subtitle needs 10.79in but has 5.97in.
#> ℹ Hard-wrap the text, widen the canvas, or reduce the font size.
#> # A tibble: 7 × 4
#>   element                      required_in available_in fits 
#>   <chr>                              <dbl>        <dbl> <lgl>
#> 1 layout (non-panel width)           0.533         6.5  TRUE 
#> 2 layout (non-panel height)          0.724         4    TRUE 
#> 3 subtitle                          10.8           5.97 FALSE
#> 4 x axis title                       0.153         5.97 TRUE 
#> 5 y axis title                       0.292         3.28 TRUE 
#> 6 x axis labels (side by side)       0.278         5.97 TRUE 
#> 7 y axis labels (stacked)            0.583         3.28 TRUE 
```
