# Data-ink ratio

Tufte defines the data-ink ratio as the share of a graphic's ink devoted
to the non-redundant display of data. This function estimates it by
rendering the plot twice, with and without its data layers, and
comparing the pixels.

## Usage

``` r
data_ink_ratio(plot, width = 6.5, height = 4, res = 150, background = "white")
```

## Arguments

- plot:

  A `ggplot` object.

- width, height:

  Rendering size in inches. Defaults to 6.5 by 4, the single-column
  figure size.

- res:

  Rendering resolution in pixels per inch. Defaults to 150. Higher
  values are slower and slightly more accurate at the edges.

- background:

  Background colour to measure ink against. Defaults to `"white"`.

## Value

An object of class `tufte_data_ink`: a list with the estimated `ratio`,
and the `data_ink`, `non_data_ink` and `total_ink` it was computed from,
in pixel-equivalents.

## Details

Pixels are weighted by their distance from the background colour.
Overlapping marks count once. Redundant marks still count as data ink
because the function can't determine whether they repeat information.
These choices matter, particularly for dense scatterplots and large
filled shapes.

A pie chart can have a higher ratio than a dot plot of the same numbers
because its filled wedges occupy more of the canvas. That doesn't tell
us which chart is easier to read. I use the estimate to compare drafts
at the same size and resolution, alongside
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
and a look at the figure itself.

## Examples

``` r
library(ggplot2)
base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
data_ink_ratio(base + theme_grey())
#> 
#> ── Data-ink ratio 
#> 6% of the ink in this figure varies with the data.
#> • data ink: 2103 pixel-equivalents
#> • non-data ink: 35748
#> • measured at 6.5in x 4in, 150 dpi
data_ink_ratio(base + geom_rangeframe() + theme_tufte())
#> 
#> ── Data-ink ratio 
#> 74% of the ink in this figure varies with the data.
#> • data ink: 3548 pixel-equivalents
#> • non-data ink: 1245
#> • measured at 6.5in x 4in, 150 dpi
```
