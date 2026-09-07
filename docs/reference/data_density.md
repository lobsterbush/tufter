# Data density

Estimate the number of data entries per square inch of a figure. This
implements Tufte's data-density measure. It can help you compare how
much information different versions of a figure occupy on the page.

## Usage

``` r
data_density(plot, width = 6.5, height = 4, panel_only = TRUE)
```

## Arguments

- plot:

  A `ggplot` object.

- width, height:

  Intended printed size in inches. Defaults to 6.5 by 4.

- panel_only:

  Logical. Measure against the panel area rather than the whole figure?
  Defaults to `TRUE`, which is what Tufte means by "the data graphic".
  The panel share is estimated by rendering the plot.

## Value

An object of class `tufte_density`: a list with `density` (entries per
square inch), `entries`, `rows`, `variables` and `area`.

## Details

Entries are counted as pooled rows times the number of distinct
variables mapped to aesthetics. Constants outside
[`aes()`](https://ggplot2.tidyverse.org/reference/aes.html) don't count.
Statistical layers and plots that combine data sources need care: the
function doesn't reconstruct a separate data matrix for each layer.

Panel area is estimated from the rendered plot. If that estimate isn't
available, the function uses the whole canvas. I'd read the result
alongside the entry count and the figure, since a high density doesn't
establish that the information is useful.

## Examples

``` r
library(ggplot2)
data_density(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#> 
#> ── Data density 
#> 3.1 numbers per square inch of data graphic.
#> • 32 rows x 2 mapped variables = 64 entries
#> • over 20.83 square inches
```
