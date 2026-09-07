# A theme for slopegraphs

Keep category labels at the top and remove the y axis. Slopegraphs print
values at the ends of their lines, so readers can read the values
directly.

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
