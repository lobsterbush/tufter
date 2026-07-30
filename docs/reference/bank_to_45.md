# Bank the aspect ratio to 45 degrees

Tufte's advice on shape, that graphics should tend toward the
horizontal, is the informal version of a result Cleveland made precise:
the slope of a line is judged most accurately when it sits near 45
degrees, and the aspect ratio of the panel is what puts it there.
Banking chooses the height, for a given width, that brings the slopes in
the data closest to 45 degrees.

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

## Details

The same series can look like a gentle drift or a cliff depending only
on how tall the panel is, and neither reading is the data's fault.
Banking replaces that choice with a rule.

Two methods are offered. `"median_slope"` is Cleveland's original: pick
the aspect ratio that makes the median absolute slope exactly 45
degrees. It resists outliers and is the default. `"average_orientation"`
instead makes the mean absolute orientation 45 degrees, optionally
weighting by its length so that long segments count for more, which is
closer to what the eye does with a line that varies in density.

Only line-like layers are read: lines, paths, steps and smooths. A plot
with no such layer has no slopes to bank, and the function says so
rather than guessing.

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
#> At 6.5in wide, draw it 0.95in tall.

# Save at the banked height rather than a height chosen by habit.
if (FALSE) { # \dontrun{
save_tufte("figure.pdf", p, width = 6.5, height = b$height)
} # }
```
