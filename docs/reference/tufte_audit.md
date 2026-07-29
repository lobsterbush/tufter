# Audit a plot against Tufte's principles

Runs every check the package knows how to make against an existing
`ggplot`, and reports which of Tufte's principles it satisfies. Some
checks are structural, and read the plot's specification. Others are
measurements, and render the plot to take them.

## Usage

``` r
tufte_audit(plot, width = 6.5, height = 4, measure = TRUE)
```

## Arguments

- plot:

  A `ggplot` object.

- width, height:

  Intended printed size in inches, used by the checks that depend on it.
  Defaults to 6.5 by 4.

- measure:

  Logical. Run the rendering-based measurements, which are the slow
  part? Defaults to `TRUE`.

## Value

An object of class `tufte_audit`: a tibble of checks with a `score`
attribute and the underlying measurements attached.

## Details

The score is the share of applicable checks passed. It is a prompt, not
a verdict: a plot can pass every check and still be pointless, since
Tufte's first principle is that content counts most of all, and no
function can evaluate that. What the audit is good for is catching the
failures that are mechanical, and that authors stop seeing after the
fifth draft.

## See also

[`tufte_principles()`](https://lobsterbush.github.io/tufter/reference/tufte_principles.md)
for the full list of principles and the functions that implement them.

## Examples

``` r
library(ggplot2)
tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#> 
#> ── Tufte audit ──
#> 
#> 9/13 checks passed (69%), at 6.5in x 4in.
#> 
#> ── Failing 
#> ✖ The panel is filled with #EBEBEBFF. A tinted panel is ink that never varies
#>   with the data.
#> Erase non-data ink (VDQI ch. 4)
#> ✖ Minor gridlines are drawn. They divide space the reader is not reading to
#>   that precision.
#> Erase redundant data-ink (VDQI ch. 4)
#> ✖ No caption. A graphic should name its source on the graphic, so the claim can
#>   be checked without hunting through the text. See label_source().
#> Documentation (Beautiful Evidence ch. 6)
#> ✖ Data-ink ratio is 0.06: 6% of the ink in this figure varies with the data.
#> Maximise the data-ink ratio (VDQI ch. 4)
#> 
#> ── Worth a look 
#> ℹ No frame at all. That is defensible, but geom_rangeframe() would give the
#>   axis something to say.
#> 
#> ── Passing 
#> • No pie chart
#> • Lie factor near one
#> • No legend to decode
#> • Colour stays a code
#> • No variable encoded twice
#> • Comparison by repetition
#> • The figure tends toward the horizontal
#> • The figure earns its space
#> • Nothing is clipped at the printed size
```
