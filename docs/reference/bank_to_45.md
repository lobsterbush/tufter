# Bank the aspect ratio to 45 degrees

Changing a panel's height changes how steep a line looks. Banking
chooses a height, for a given width, that brings the slopes closer to 45
degrees. This implements Cleveland's approach to comparing slopes and
relates to Tufte's advice that graphics should tend toward the
horizontal.

## Usage

``` r
bank_to_45(
  plot,
  width = 6.5,
  method = c("median_slope", "average_orientation"),
  weighted = TRUE
)
```

## Arguments

- plot:

  A `ggplot` object.

- width:

  Panel width in inches to solve the height for. Defaults to 6.5.

- method:

  Either `"median_slope"` or `"average_orientation"`.

- weighted:

  For `"average_orientation"`, weight each segment by its length?
  Defaults to `TRUE`. Ignored by the other method.

## Value

An object of class `tufte_banking`: a list with the recommended `aspect`
(height divided by width), the `height` that implies at the given
`width`, the `method` used, and `n_segments`, the number of line
segments the answer was computed from.

The aspect ratio describes the *panel*, since that's where the slopes
are drawn. A saved figure needs room for axis labels and titles on top
of it, so pass something larger than `height` to
[`save_tufte()`](https://lobsterbush.github.io/tufter/reference/save_tufte.md)
and check the result with
[`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md).

## Details

The default, `"median_slope"`, makes the median absolute slope 45
degrees. It's less sensitive to unusually steep segments.
`"average_orientation"` makes the mean absolute orientation 45 degrees
and can weight segments by length.

The function reads lines, paths and smooths. It rejects step charts and
plots without line-like layers. I treat the height as a starting point:
check whether it helps readers see the change you're interested in.

## See also

[`save_tufte()`](https://lobsterbush.github.io/tufter/reference/save_tufte.md).
Banking isn't applied automatically: pass the `height` it returns
yourself, so that the choice stays visible in your code.

## Examples

``` r
library(ggplot2)
d <- data.frame(year = 1:100, value = sin(seq(0, 6 * pi, length.out = 100)))
p <- ggplot(d, aes(year, value)) + geom_line() + theme_tufte()

b <- bank_to_45(p, width = 6.5)
b
#> 
#> ── Banking to 45 degrees 
#> Aspect ratio 0.147 (height / width), from 99 segments by "median_slope".
#> At 6.5in wide, that's a panel 0.95in tall. Allow more for axis labels and
#> titles.

# Save at the banked height rather than a height chosen by habit.
if (FALSE) { # \dontrun{
save_tufte("figure.pdf", p, width = 6.5, height = b$height)
} # }
```
