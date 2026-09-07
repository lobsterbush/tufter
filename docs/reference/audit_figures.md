# Audit every figure in a paper at once

Give this function a set of plots or a directory of saved plots. It runs
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
on each one and returns a row per figure. I find this useful when
reviewing a paper's figures together.

## Usage

``` r
audit_figures(plots, width = 6.5, height = 4, measure = TRUE)
```

## Arguments

- plots:

  One of: a named list of `ggplot` objects; a single `ggplot`; or a path
  to a directory, in which case every `.rds` file is read and any that
  contains a `ggplot` is audited.

- width, height:

  Intended printed size in inches, applied to every figure. Pass a
  vector as long as `plots` to give each its own size.

- measure:

  Logical. Report the data-ink ratio and the data density? Defaults to
  `TRUE`. Setting it to `FALSE` skips only those two, which are
  ungraded, so the ordering by unmet criteria is the same either way.
  This avoids the extra rendering needed for those measurements.

## Value

An object of class `tufte_audit_batch`: a tibble with one row per
figure, giving `figure`, `violations`, `met`, `skipped` (checks that
couldn't run), and `failing`, a comma-separated list of the criteria not
met. The full audits are attached as the `"audits"` attribute, named by
figure.

## Details

The table lists the unmet criteria and any checks that couldn't run.
Full results are attached to the table so you can inspect a particular
figure.

Figures with more unmet criteria come first. Use that order to decide
where to look; it doesn't tell you which figure is substantively more
useful. Check the skipped count too, since an incomplete audit can miss
a problem.

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
