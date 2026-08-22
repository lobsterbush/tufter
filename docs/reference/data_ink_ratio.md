# Data-ink ratio

Tufte defines the data-ink ratio as the share of a graphic's ink that's
devoted to the non-redundant display of data, and asks that it be pushed
towards one. `data_ink_ratio()` estimates it empirically: the plot is
rendered twice, once whole and once with every data layer removed, and
the ink in each rendering is measured from the pixels.

## Usage

``` r
data_ink_ratio(plot, width = 6.5, height = 4, res = 150, background = "white")
```

## Arguments

- plot:

  A `ggplot` object.

- width, height:

  Rendering size in inches. Defaults to 6.5 by 4, the single-column
  figure size.

- res:

  Rendering resolution in pixels per inch. Defaults to 150. Higher
  values are slower and slightly more accurate at the edges.

- background:

  Background colour to measure ink against. Defaults to `"white"`.

## Value

An object of class `tufte_data_ink`: a list with the estimated `ratio`,
and the `data_ink`, `non_data_ink` and `total_ink` it was computed from,
in pixel-equivalents.

## Details

The measurement is an estimate, for three reasons worth knowing before
you quote the number. Anti-aliased edges are counted in proportion to
how far they sit from the background colour, which is the right
treatment but not an exact one. Ink that overlaps is counted once, so a
dense scatterplot understates its own data-ink. And redundant data-ink,
which Tufte would subtract, still counts here as data-ink, because no
measurement can tell whether a mark repeats information the reader
already has. Treat the result as a comparative instrument: it's reliable
for judging whether one version of a figure is leaner than another, and
unreliable as an absolute score.

The redundancy point is worth a concrete case, because the number can
run the wrong way. Every pixel a data layer draws counts, the interiors
of filled shapes included, so a design built from large filled areas
scores high. Continental population as a pie chart measures 0.75; the
same numbers as a Cleveland dot plot measure 0.16, because dots are
small and the axis labels that make them readable are furniture. The pie
is the worse graphic and the ratio prefers it. Tufte would subtract the
wedge interiors as redundant, since the angle already carries the
number, but no measurement can decide which ink repeats what. The graded
criteria in
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
do separate the two, six unmet against one, and this is why the audit
reports the ratio rather than scoring it.

## Examples

``` r
library(ggplot2)
base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
data_ink_ratio(base + theme_grey())
#> 
#> ── Data-ink ratio 
#> 6% of the ink in this figure varies with the data.
#> • data ink: 2103 pixel-equivalents
#> • non-data ink: 35748
#> • measured at 6.5in x 4in, 150 dpi
data_ink_ratio(base + geom_rangeframe() + theme_tufte())
#> 
#> ── Data-ink ratio 
#> 74% of the ink in this figure varies with the data.
#> • data ink: 3548 pixel-equivalents
#> • non-data ink: 1245
#> • measured at 6.5in x 4in, 150 dpi
```
