# Audit a plot against Tufte's principles

Reports what a plot does against what Tufte actually wrote, and is
careful about the difference between the two kinds of thing he wrote.

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

  Logical. Run the rendering-based measurements, which are the slow
  part? Defaults to `TRUE`.

## Value

An object of class `tufte_audit`: a tibble with one row per check, whose
`status` is `"fail"` for a stated criterion that's not met, `"pass"` for
one that's, `"report"` for a measurement Tufte gives no threshold for,
and `"skip"` for a check that could not run. The number of unmet
criteria is attached as the `"violations"` attribute.

## Details

For some principles Tufte states a criterion a graphic either meets or
does not: bars are measured from zero, the lie factor lies between 0.95
and 1.05, graphics tend toward the horizontal, non-data ink comes off
the page. Those are reported as met or not met.

For others he states only a direction. He asks that the data-ink ratio
be maximised "within reason" and that data density be increased, and he
nowhere says how much is enough, because the answer depends on the
content. Those are measured and reported without a verdict. Earlier
versions of this package invented thresholds for them, which put a
number of mine in the same voice as a principle of his; the numbers were
never his and are now gone.

The consequence is that there's no score. Counting satisfied principles
would mean weighting them against each other, and Tufte offers no
exchange rate between a pie chart and a missing source note. What the
audit gives you is a list of stated criteria that aren't met, and a set
of measurements to compare against another draft of the same figure.

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
#> ✖ The panel is filled with #EBEBEBFF. The fill is identical whatever the
#>   numbers are, so it's non-data ink and Tufte's instruction is to erase it.
#> Erase non-data ink - VDQI ch. 4
#> ✖ Minor gridlines are drawn. They subdivide the scale past the precision anyone
#>   reads off a graphic, so they're non-data ink.
#> Erase non-data ink - VDQI ch. 4
#> ✖ No caption. Tufte asks that evidence be thoroughly described and its sources
#>   named on the graphic itself, so a reader can check the claim without hunting
#>   through the surrounding text. See label_source().
#> Documentation - Beautiful Evidence ch. 6
#> 
#> ── Measured, not graded 
#> Tufte states a direction for these rather than a threshold. Read them against
#> another draft of the same figure.
#> • Data-ink ratio 0.06: 6% of the ink varies with the data. Tufte asks that this
#>   be maximised within reason and names no threshold, so read it against another
#>   draft of this figure rather than against a target.
#> • Data density 3.1 numbers per square inch: 64 entries over 20.8 square inches.
#>   Tufte ranks published graphics by this and sets no minimum.
#> • 1 distinct colour in use. Tufte's advice on colour is qualitative, so this is
#>   a count and not a verdict.
#> • 1 series overlaid in one panel. facet_tufte() would show the same data as
#>   small multiples. Tufte gives no number at which to switch.
#> 
#> ── Met 
#> • No full panel border
#> • No pie chart
#> • Lie factor within Tufte's band
#> • No legend to decode
#> • No variable encoded twice
#> • Wider than it is tall
#> • Ink clears the WCAG contrast minimum
#> • Nothing is clipped at the printed size
```
