# Audit a plot against Tufte's principles

Use this to check a figure while you're working on it. The output
identifies unmet criteria and gives you measurements to compare across
drafts.

## Usage

``` r
tufte_audit(plot, width = 6.5, height = 4, measure = TRUE)
```

## Arguments

- plot:

  A `ggplot` object.

- width, height:

  Intended printed size in inches, used by the checks and measurements
  that depend on it. Defaults to 6.5 by 4.

- measure:

  Logical. Report the data-ink ratio and the data density, which are the
  slow part? Defaults to `TRUE`. This governs only those two, which
  Tufte states no threshold for and the audit therefore doesn't grade.
  Every stated criterion is checked either way, so the count of
  violations means the same thing whichever you pass.

## Value

An object of class `tufte_audit`: a tibble with one row per check, whose
`status` is `"fail"` for a stated criterion that's not met, `"pass"` for
one that's met, `"report"` for a measurement Tufte gives no threshold
for, and `"skip"` for a check that couldn't run. The count of unmet
criteria, a single integer, is attached as the `"violations"` attribute.

## Details

I've kept a distinction between principles with a stated criterion and
those without one. Bars measured from zero and a lie factor between 0.95
and 1.05 can be checked against explicit rules. The audit also checks
the advice that graphics tend toward the horizontal and that non-data
ink be removed.

Tufte asks that the data-ink ratio be maximised "within reason" and that
data density increase, but he doesn't give either a numerical target.
Those measurements are reported without a pass or fail.

I haven't combined the results into a score. That would require me to
decide how much each criterion matters. Read the individual results and
check whether the suggested changes help someone understand your figure.

## See also

[`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md),
which marks which principles carry a stated criterion and which don't.

## Examples

``` r
library(ggplot2)
tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#> 
#> ── Tufte audit ──
#> 
#> At 6.5in x 4in: 3 stated criteria not met.
#> 
#> ── Not met 
#> ✖ The panel uses a #EBEBEBFF background fill. Try removing it and compare
#>   whether the figure is easier to read.
#> Erase non-data ink - VDQI ch. 4
#> ✖ Minor gridlines are drawn. Consider whether readers need this level of detail
#>   to estimate values.
#> Erase non-data ink - VDQI ch. 4
#> ✖ No caption is present. Add the data source with label_source() so readers can
#>   check where the numbers came from.
#> Documentation - Beautiful Evidence ch. 6
#> 
#> ── Measured, not graded 
#> Tufte states a direction for these rather than a threshold. Read them against
#> another draft of the same figure.
#> • Data-ink ratio 0.06: an estimated 6% of the ink comes from data layers.
#>   Compare drafts at the same dimensions; there's no target value.
#> • Data density 3.1 entries per square inch: 64 estimated entries over 20.8
#>   square inches. Read this alongside the figure and entry count.
#> • 1 distinct colour in use. This is a count, not a verdict on whether the
#>   colours help readers.
#> • One series in one panel. There's no series grouping to separate into small
#>   multiples.
#> 
#> ── Met 
#> • No full panel border
#> • No pie chart
#> • Lie factor within Tufte's band
#> • No legend to decode
#> • No variable encoded twice
#> • Wider than it is tall
#> • Ink clears the WCAG contrast minimum
#> • Measured labels fit at the printed size
```
