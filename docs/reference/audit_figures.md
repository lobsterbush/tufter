# Audit every figure in a paper at once

Running
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
on one plot is useful while you're drawing it. Running it on all of
them, the evening before you submit, is when it earns its keep: the
figure with the truncated subtitle is never the one you were looking at.

## Usage

``` r
audit_figures(plots, width = 6.5, height = 4, measure = TRUE)
```

## Arguments

- plots:

  One of: a named list of `ggplot` objects; a single `ggplot`; or a path
  to a directory, in which case every `.rds` file in it's read and any
  that contains a `ggplot` is audited.

- width, height:

  Intended printed size in inches, applied to every figure. Pass a
  vector as long as `plots` to give each its own size.

- measure:

  Logical. Report the data-ink ratio and the data density? Defaults to
  `TRUE`. Setting it to `FALSE` skips only those two, which are
  ungraded, so the ordering by unmet criteria is the same either way and
  roughly twice as fast to get. Figures are ordered by the number of
  stated criteria they fail, most first. That's a count and not a score:
  it's comparable across figures because every figure is being counted
  against the same criteria, whereas a proportion would divide by a
  denominator that changes with the plot type.

## Value

An object of class `tufte_audit_batch`: a tibble with one row per
figure, giving `figure`, `violations`, `met` and `failing`, a
comma-separated list of the criteria not met. The full audits are
attached as the `"audits"` attribute, named by figure.

## Details

Give it the plots you built, or a directory of saved ones. It returns a
row per figure with the score and the checks that failed, and keeps the
full per-check detail attached so you can drill into any of them.

## See also

[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
for a single plot.

## Examples

``` r
library(ggplot2)
figures <- list(
  scatter = ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte(),
  boxes = ggplot(mtcars, aes(factor(cyl), mpg)) + geom_tufteboxplot()
)
audit_figures(figures, measure = FALSE)
#> 
#> ── Tufte audit: 2 figures ──
#> 
#> ── Stated criteria not met, most first 
#> boxes (3 not met)
#> Panel carries no background fill, No minor gridlines, The figure names its
#> source
#> scatter (1 not met)
#> The figure names its source
#> 
#> ℹ Full detail for any one figure: `attr(x, "audits")[["<name>"]]`
```
