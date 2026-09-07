# Check that the labels fit inside the canvas

A figure that has been designed carefully and then saved at the wrong
size is a figure with a truncated subtitle. This renders the plot at the
size you intend to print it and measures the text elements against the
space available, so that clipping is caught before the figure reaches a
page.

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

Subtitles and captions are the usual offenders, because `ggplot2` does
not wrap them: text longer than the device is silently cut at the edge.
The fix is a hard line break, a wider canvas, or a smaller font, and
then a second look at the rendered file.

What gets measured is the furniture: the plot title, subtitle and
caption, the axis titles and labels on all four sides, the legend, and
the facet strips. Text drawn inside the panel by a layer, from
[`geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
or
[`geom_text_last()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md),
is not measured, because clipping there depends on the panel range and
the coord's `clip` setting rather than on the canvas. Look at those
yourself, or give the scale room with
[`expansion()`](https://ggplot2.tidyverse.org/reference/expansion.html).

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
