# A theme for sparklines

Remove axes, labels and the frame, and leave a small margin. This gives
a sparkline room to sit beside the text that explains it.

## Usage

``` r
theme_sparkline(base_size = 9, base_family = "")
```

## Arguments

- base_size:

  Base font size in points. Defaults to 9.

- base_family:

  Base font family. Defaults to the device default.

## Value

A `ggplot2` theme object.

## Examples

``` r
library(ggplot2)
d <- data.frame(t = 1:50, v = cumsum(rnorm(50)))
ggplot(d, aes(t, v)) + geom_line() + theme_sparkline()
```
