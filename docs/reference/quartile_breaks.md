# Axis breaks at the five-number summary

Returns a breaks function that labels the minimum, the quartiles, the
median and the maximum, so that the printed axis labels agree with what
a
[`geom_quartileframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
shows. Tufte's point is that an axis should report the distribution, not
a set of round numbers chosen by the plotting software.

## Usage

``` r
quartile_breaks(x = NULL, digits = 3, min_gap = 0.12)
```

## Arguments

- x:

  Optional numeric vector. If supplied, the breaks are computed from it
  once, which is what you want when the axis limits are wider than the
  data. If omitted, breaks are computed from the scale's own limits.

- digits:

  Number of significant digits to round the breaks to. Defaults to 3.

- min_gap:

  Minimum spacing between breaks, as a fraction of the data range.
  Breaks closer than this to the one before them are dropped, because
  their labels would overlap. Defaults to `0.12`; set to `0` to keep all
  five.

## Value

A function suitable for the `breaks` argument of a continuous scale.

## Details

Quartiles that fall close together are dropped rather than printed on
top of each other; see `min_gap`. The minimum and maximum are always
kept, since they are the two values the range frame exists to report.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_quartileframe() +
  scale_y_continuous(breaks = quartile_breaks(mtcars$mpg)) +
  theme_tufte()
```
