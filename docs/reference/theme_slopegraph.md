# A theme for slopegraphs

A slopegraph carries its scale in the printed values at each end of
every line, so the y axis is redundant and is removed. Only the category
labels at the top survive.

## Usage

``` r
theme_slopegraph(base_size = 11, base_family = "")
```

## Arguments

- base_size:

  Base font size in points. Defaults to 11.

- base_family:

  Base font family. Defaults to the device default.

## Value

A `ggplot2` theme object.

## Examples

``` r
library(ggplot2)
ggplot() + theme_slopegraph()
```
