# WCAG contrast ratio between two colours

Compare the relative luminance of two colours using the Web Content
Accessibility Guidelines. The ratio ranges from 1 for identical colours
to 21 for black against white. The guidelines specify at least 4.5 for
body text and 3 for large text and graphical objects.

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

## Details

Embedded transparency is composited against the background. A
transparent background is first composited over white.

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
