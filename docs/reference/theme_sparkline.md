# A theme for sparklines

Removes everything. A sparkline is a word-sized graphic meant to sit
inside running text, so it has no axes, no labels, no frame, and almost
no margin.

## Usage

``` r
theme_sparkline(base_size = 9, base_family = "")
```

## Arguments

- base_size:

  Base font size in points. Defaults to 12.

- base_family:

  Base font family. Defaults to `""` (the device default). `"serif"` is
  closer to Tufte's own books.

## Value

A `ggplot2` theme object.

## Examples

``` r
library(ggplot2)
d <- data.frame(t = 1:50, v = cumsum(rnorm(50)))
ggplot(d, aes(t, v)) + geom_line() + theme_sparkline()
```
