# Audit every figure in a paper at once

Running
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
on one plot is useful while you are drawing it. Running it on all of
them, the evening before you submit, is when it earns its keep: the
figure with the truncated subtitle is never the one you were looking at.

## Usage

``` r
audit_figures(plots, width = 6.5, height = 4, measure = TRUE)
```

## Arguments

- plots:

  One of: a named list of `ggplot` objects; a single `ggplot`; or a path
  to a directory, in which case every `.rds` file in it is read and any
  that contains a `ggplot` is audited.

- width, height:

  Intended printed size in inches, applied to every figure. Pass a
  vector as long as `plots` to give each its own size.

- measure:

  Logical. Run the rendering-based measurements? Defaults to `TRUE`. Set
  to `FALSE` for a fast structural pass.

## Value

An object of class `tufte_audit_batch`: a tibble with one row per
figure, giving `figure`, `score`, `passed`, `failed` and `failing`, a
comma-separated list of the checks that did not pass. The full audits
are attached as the `"audits"` attribute, named by figure.

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
#> ── Needing work, worst first 
#> boxes (73%, 3 failing)
#> Panel background carries no data, Grid is no heavier than the data, The figure
#> says where its numbers came from
#> scatter (91%, 1 failing)
#> The figure says where its numbers came from
#> 
#> ℹ Full detail for any one figure: `attr(x, "audits")[["<name>"]]`
```
