# tufter

**Documentation: <https://lobsterbush.github.io/tufter/>** — including a
[gallery built entirely on simulated data](https://lobsterbush.github.io/tufter/articles/simulated-examples.html)
and a walk through [what each measurement actually computes](https://lobsterbush.github.io/tufter/articles/measuring.html).

Edward Tufte's principles of graphical design, as working `ggplot2` code and as
measurements you can apply to a figure you have already drawn.

Most Tufte packages give you a theme. A theme is one principle out of about
twenty, and it is the easiest one. Tufte's actual argument is that statistical
graphics can be *evaluated* rather than merely preferred, and he gives the
quantities to do it with: the data-ink ratio, the lie factor, data density.
`tufter` implements both halves.

![Default ggplot2 next to the same plot with a quartile frame and theme_tufte, with measured data-ink ratios of 0.05 and 0.48](man/figures/README-before-after.png)

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
| `geom_cleveland_dot()` | Dot plot with leader lines: position instead of length, so no zero baseline is needed |
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
| `bank_to_45()` | The aspect ratio that puts the slopes nearest 45 degrees, where they are judged best |
| `check_contrast()`, `contrast_ratio()` | Whether the ink is dark enough to see, against the WCAG minima |
| `check_labels_fit()` | Whether any text will be clipped at the printed size |
| `tufte_audit()` | All of the above, plus the structural checks, scored |
| `audit_figures()` | The same across every figure in a paper, worst first |

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
#> 74% of the ink in this figure varies with the data.
```

## The audit

```r
tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#> ── Tufte audit ──
#> 10/14 checks passed (71%), at 6.5in x 4in.
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
#> ✖ Data-ink ratio is 0.06: 6% of the ink in this figure varies with the data.
#>   Maximise the data-ink ratio (VDQI ch. 4)
```

For a whole paper at once, `audit_figures()` takes the list of plots you built
and returns them worst first, with the failing checks named.

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

**Where this duplicates existing work.** [`ggthemes`](https://github.com/jrnold/ggthemes)
has a `theme_tufte()`, a `geom_rangeframe()` and a `geom_tufteboxplot()`. It is
actively maintained and widely used. If the theme is all you want, it is the
lighter dependency, and you should use it. Note that loading both packages
masks `theme_tufte()`.

For labels that must not collide, [`directlabels`](https://cran.r-project.org/package=directlabels)
and [`ggrepel`](https://cran.r-project.org/package=ggrepel) solve the general
problem properly; `geom_text_last()` here is the narrow case of labelling the
end of a series.

**Where it fills a gap.** As far as I can find, no R package computes the
data-ink ratio, the lie factor or data density, and none scores a plot against
design principles. A search of every CRAN package title and description turns
up no hits for "data-ink", "lie factor" or "chartjunk". The nearest neighbours
do something adjacent but different: `ggcheck` introspects built ggplot objects
to autograde student code, `ggalttext` does so to write alt text, and
[`GGenemy`](https://cran.r-project.org/package=GGenemy) audits plots for
*accessibility* — WCAG contrast, colour-vision deficiency — rather than for
Tufte's criteria. `check_contrast()` here overlaps GGenemy on contrast
deliberately: a package that tells you to erase ink has an obligation to check
that what survives is still visible. GGenemy goes further on accessibility,
including colour-vision simulation, and is the better tool if that is your
question. The only implementation of the data-ink ratio I could find in
any language is a Java repository, archived in 2025 and last worked on in 2010,
which requires the user to segment the image by hand before it will count
anything.

A note on what the numbers are for. The empirical literature does not support
maximising the data-ink ratio as an objective, and has not since the mid
nineties. The measurements here are descriptive diagnostics, meant to tell you
where a figure spends its ink, not a score to push towards one. The
[measuring article](https://lobsterbush.github.io/tufter/articles/measuring.html#and-a-larger-caveat-the-principle-itself-is-contested)
sets out that argument and the evidence against the principle.

Several Tufte forms are also currently unmaintained or absent in R.
`CGPfunctions`, which provided `newggslopegraph()`, was removed from CRAN in
November 2025; `leeper/slopegraph` has not moved since 2018; and `ggtufte`,
Jeff Arnold's own attempt to spin the Tufte parts out of `ggthemes`, was
abandoned in 2018. I could find no existing implementation of the bar chart
with gridlines erased through the bars, no first-class dot-dash geom, and no
Tufte colour palette (`ggthemes` ships Few, Cleveland, Tableau and Ptol
palettes, but not one from Tufte).

The measurement half is the reason this package exists. The drawing half is
partly convenience and partly consolidation.

<!-- HIDDEN FOR NOW. Restore before any public release, and before any JOSS or
     journal submission, where a disclosure of this kind is usually required.
     Delete this comment marker and the closing one below the "Standing
     caveat" paragraph to bring it back.

## AI usage disclosure

This package was written with substantial assistance from a large language
model (Anthropic's Claude, via Claude Code), and I think readers of the code
are entitled to know which parts that covers and what was checked by a person.

**What the model did.** It produced essentially all of the R source in `R/`,
the test suite, the roxygen documentation, the vignette and the two articles,
and the first draft of this README. It also carried out the survey of existing
packages summarised in the section above.

**What I did.** I specified the package: the decision to implement Tufte's
measurements rather than only his aesthetics, which principles to cover, and
where the honest limits of the exercise lie. I reviewed the code and the prose,
and I ran the checks below.

**What was verified, and how.** All 150 tests pass and `R CMD check` returns no
errors, warnings or notes. Every figure in the README, the vignette and the
articles was rendered and inspected visually, which is how three real bugs were
caught: a median dot drawn off the whisker in the offset box plot, colliding
axis labels from `quartile_breaks()`, and sparkline panels ordered
alphabetically rather than as supplied. The `data_ink_ratio()` results were
sanity-checked against plots whose answer is known in advance, such as a plot
with no data layers, which must return approximately zero.

**What is not verified.** The empirical citations in the
[measuring article](https://lobsterbush.github.io/tufter/articles/measuring.html#and-a-larger-caveat-the-principle-itself-is-contested)
are named inline and their DOIs have **not** been checked against Crossref; do
not carry them into a paper without verifying them first. The claim that no
other package computes these quantities rests on a search of CRAN titles and
descriptions plus GitHub, which cannot rule out an implementation that does not
describe itself in those terms. Neither the model nor I have independently
replicated the human-subjects findings cited against the data-ink principle.

**Standing caveat.** Errors that survive are mine. If you find one, please
[open an issue](https://github.com/lobsterbush/tufter/issues) rather than
assuming the measurement is right because a computer produced it, which is
advice this package would give about any number on a graph.

     END OF HIDDEN SECTION -->

## Sources

- Tufte, E. R. (2001). *The Visual Display of Quantitative Information*, 2nd ed.
- Tufte, E. R. (1990). *Envisioning Information*.
- Tufte, E. R. (1997). *Visual Explanations*.
- Tufte, E. R. (2006). *Beautiful Evidence*.

## Author

Charles Crabtree, Senior Lecturer, School of Social Sciences, Monash University
and K-Club Professor, University College, Korea University.

MIT licensed.
