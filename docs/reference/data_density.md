# Data density

The number of entries in the data matrix divided by the area of the data
graphic, in square inches. Tufte's complaint about most published
statistical graphics is that they are enormous and say almost nothing: a
chart carrying four numbers over half a page has a data density near
zero, and the numbers would have been better set as a sentence.

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

The data matrix here is counted as the number of rows drawn, times the
number of distinct variables mapped to aesthetics. Positional aesthetics
count; constants set outside
[`aes()`](https://ggplot2.tidyverse.org/reference/aes.html) do not,
because they carry no data.

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
