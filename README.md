# tufter

Edward Tufte's principles of graphical design, as working `ggplot2` code and as
measurements you can apply to a figure you have already drawn.

Most Tufte packages give you a theme. A theme is one principle out of about
twenty, and it is the easiest one. Tufte's actual argument is that statistical
graphics can be *evaluated* rather than merely preferred, and he gives the
quantities to do it with: the data-ink ratio, the lie factor, data density.
`tufter` implements both halves.

![Default ggplot2 next to the same plot with a quartile frame and theme_tufte, with measured data-ink ratios of 0.05 and 0.35](man/figures/README-before-after.png)

## Installation

```r
# install.packages("remotes")
remotes::install_github("lobsterbush/tufter")
```

## The two halves

**Generative.** The graphical forms Tufte designed or advocated:

| Function | What it does |
|---|---|
| `theme_tufte()` | Strips the panel, the grid, the border, the legend frame |
| `geom_rangeframe()` | An axis line spanning only the range the data occupy |
| `geom_quartileframe()` | The same, broken at the quartiles, so the axis carries the five-number summary |
| `geom_dotdash()` | Marginal distributions on both axes, in place of a frame |
| `geom_tufteboxplot()` | The box plot with the box erased; three variants |
| `geom_col_tufte()` | Bars with the gridlines erased where they cross the bars |
| `slopegraph()` | Before-and-after for many units, with every number printed |
| `sparkline()`, `sparklines()` | Word-sized graphics, with normal band and extremes |
| `facet_tufte()` | Small multiples, scales fixed so panels stay comparable |
| `geom_text_last()` | Labels on the data, in place of a legend |
| `tufte_pal()`, `scale_colour_tufte()` | Greys, greys with one accent, muted earth tones |
| `label_source()` | The documentation principle: say where the numbers came from |
| `save_tufte()` | `ggsave()` with print defaults, and a clipping check first |

**Evaluative.** The quantities Tufte defined:

| Function | What it measures |
|---|---|
| `data_ink_ratio()` | The share of ink that varies with the data, estimated by rendering the plot with and without its data layers |
| `lie_factor()` | The size of the effect shown over the size of the effect in the data |
| `data_density()` | Numbers per square inch of data graphic |
| `check_labels_fit()` | Whether any text will be clipped at the printed size |
| `tufte_audit()` | All of the above, plus the structural checks, scored |

![Four graphical forms: the box plot with the box erased, a bar chart with gridlines erased through the bars, a slopegraph, and stacked sparklines](man/figures/README-gallery.png)

## The short version

```r
library(ggplot2)
library(tufter)

base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()

data_ink_ratio(base)
#> ── Data-ink ratio
#> 6% of the ink in this figure varies with the data.

lean <- base + geom_rangeframe() + theme_tufte()

data_ink_ratio(lean)
#> ── Data-ink ratio
#> 56% of the ink in this figure varies with the data.
```

## The audit

```r
tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#> ── Tufte audit ──
#> 9/13 checks passed (69%), at 6.5in x 4in.
#>
#> ── Failing
#> ✖ The panel is filled with #EBEBEBFF. A tinted panel is ink that never
#>   varies with the data.
#>   Erase non-data ink (VDQI ch. 4)
#> ✖ Minor gridlines are drawn. They divide space the reader is not reading
#>   to that precision.
#>   Erase redundant data-ink (VDQI ch. 4)
#> ✖ No caption. A graphic should name its source on the graphic, so the claim
#>   can be checked without hunting through the text. See label_source().
#>   Documentation (Beautiful Evidence ch. 6)
```

It catches the failures that matter and that authors stop seeing after the
fifth draft: a pie chart, a bar baseline that is not zero, a variable encoded
twice, a legend with four entries that should have been direct labels, a
subtitle that will be clipped at the size you are about to save.

## What it will not tell you

`tufte_principles()` lists every principle, its source, the function that
implements it, and whether the audit can check it.

```r
p <- tufte_principles()
p[!p$audited, c("principle", "implemented_by")]
#> Show comparisons          slopegraph(), facet_tufte()
#> Show causality            annotation, not code
#> Show multivariate data    facet_tufte(), sparklines()
#> Content counts most of all  you
```

The score is a prompt, not a verdict. A figure can pass every check and still be
pointless.

## Relationship to other packages

`ggthemes` has a `theme_tufte()`, a range frame and a Tufte box plot, and they
are good. `tufter` differs in scope rather than in quality: it adds the
measurement half, which is where Tufte's argument actually lives, along with
slopegraphs, sparklines, the erased-gridline bar chart, the quartile frame and
direct labelling. If you only want the theme, `ggthemes` is the lighter
dependency.

## Sources

- Tufte, E. R. (2001). *The Visual Display of Quantitative Information*, 2nd ed.
- Tufte, E. R. (1990). *Envisioning Information*.
- Tufte, E. R. (1997). *Visual Explanations*.
- Tufte, E. R. (2006). *Beautiful Evidence*.

## Author

Charles Crabtree, Senior Lecturer, School of Social Sciences, Monash University
and K-Club Professor, University College, Korea University.

MIT licensed.
