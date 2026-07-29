# WCAG contrast ratio between two colours

The ratio of the relative luminances of two colours, as defined by the
Web Content Accessibility Guidelines. It runs from 1, for two identical
colours, to 21, for black on white. The guidelines ask for at least 4.5
for body text and at least 3 for large text and for graphical objects
such as the marks and rules on a chart.

## Usage

``` r
contrast_ratio(colour, background = "white")
```

## Arguments

- colour, background:

  Colours, in any form
  [`col2rgb`](https://rdrr.io/r/grDevices/col2rgb.html) accepts. Vectors
  are recycled against each other.

## Value

A numeric vector of contrast ratios.

## See also

[`check_contrast()`](https://lobsterbush.github.io/tufter/reference/check_contrast.md),
which applies this to a whole plot.

## Examples

``` r
contrast_ratio("black", "white")
#> [1] 21
contrast_ratio(c("grey20", "grey50", "grey80"), "white")
#> [1] 12.634654  4.004107  1.605929
```
