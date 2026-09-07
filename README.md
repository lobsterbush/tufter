# tufter

<div class="package-kicker">R tools · Charles Crabtree</div>

<p class="package-lead">Draw with purpose.<br>Measure what the ink says.</p>

Edward Tufte's principles of graphical design, as working `ggplot2` code and as
measurements you can apply to a figure you've already drawn.

Most Tufte packages give you a theme. That's one principle out of about twenty,
and I think it's the easiest one. His real argument is that statistical graphics
can be *evaluated*, and he hands you the quantities to do it with: the data-ink
ratio, the lie factor, data density. This package does both halves.

![The same penguins, drawn twice. Erasing the panel, the grid and the border, then putting a quartile frame where the border was, moves the data-ink ratio from 0.22 to 0.78.](man/figures/README-before-after.png)

## Where to start

[Working through a real dataset](https://lobsterbush.github.io/tufter/articles/real-data.html)
takes `gapminder` and `palmerpenguins` through every form and every measurement.
There's also a
[gallery on simulated data](https://lobsterbush.github.io/tufter/articles/simulated-examples.html),
a third [built on live API data](https://lobsterbush.github.io/tufter/articles/live-data.html)
from CRAN logs, USGS earthquakes, Open-Meteo and Wikipedia, and a walk through
[what each measurement actually computes](https://lobsterbush.github.io/tufter/articles/measuring.html).

## Installation

Requires R 4.1 or later and ggplot2 4.0.0 or later. This is a development
release preparing for its first CRAN submission.

```r
# install.packages("remotes")
remotes::install_github("lobsterbush/tufter")
```

## The two halves

The forms Tufte designed or argued for:

| Function | What it does |
|---|---|
| `theme_tufte()` | Strips the panel, the grid, the border, the legend frame |
| `geom_rangeframe()` | An axis line spanning only the range the data occupy |
| `geom_quartileframe()` | The same, broken at the quartiles, so the axis carries the five-number summary |
| `geom_dotdash()` | Marginal distributions on both axes, in place of a frame |
| `geom_tufteboxplot()` | The box plot with the box erased; three variants |
| `geom_col_tufte()` | Bars with the gridlines erased where they cross the bars |
| `geom_cleveland_dot()` | Dot plot with leader lines, so a zero baseline isn't needed |
| `slopegraph()` | Before-and-after for many units, with every number printed |
| `sparkline()`, `sparklines()` | Word-sized graphics, with normal band and extremes |
| `facet_tufte()` | Small multiples, scales fixed so panels stay comparable |
| `geom_text_last()` | Labels on the data, in place of a legend |
| `tufte_pal()`, `scale_colour_tufte()` | Greys, greys with one accent, muted earth tones |
| `label_source()` | Say where the numbers came from, on the graphic |
| `save_tufte()` | `ggsave()` with print defaults, and a clipping check first |

The quantities he defined:

| Function | What it measures |
|---|---|
| `data_ink_ratio()` | The share of ink that varies with the data, estimated by rendering the plot with and without its data layers |
| `lie_factor()` | The size of the effect shown over the size of the effect in the data |
| `data_density()` | Numbers per square inch of data graphic |
| `bank_to_45()` | The aspect ratio that puts the slopes nearest 45 degrees, where they're judged best |
| `check_contrast()`, `contrast_ratio()` | Whether the ink is dark enough to see, against the WCAG minima |
| `check_labels_fit()` | Whether any text will be clipped at the printed size |
| `tufte_audit()` | All of the above, graded or measured as Tufte states them |
| `audit_figures()` | The same across every figure in a paper, most unmet criteria first |

![Four graphical forms: the box plot with the box erased, a bar chart with gridlines erased through the bars, a slopegraph, and stacked sparklines](man/figures/README-gallery.png)

## The short version

<!-- readme-short:start -->
```r
library(ggplot2)
library(tufter)
library(palmerpenguins)

peng <- penguins[complete.cases(penguins), ]
base <- ggplot(peng, aes(flipper_length_mm, body_mass_g)) + geom_point()

data_ink_ratio(base)
#> ── Data-ink ratio
#> 34% of the ink in this figure varies with the data.
#> • data ink: 18613 pixel-equivalents
#> • non-data ink: 36472
#> • measured at 6.5in x 4in, 150 dpi

lean <- base + geom_rangeframe() + theme_tufte()

data_ink_ratio(lean)
#> ── Data-ink ratio
#> 87% of the ink in this figure varies with the data.
#> • data ink: 24298 pixel-equivalents
#> • non-data ink: 3579
#> • measured at 6.5in x 4in, 150 dpi
```
<!-- readme-short:end -->

## The audit

<!-- readme-audit:start -->
```r
tufte_audit(base)
#> ── Tufte audit ──
#> At 6.5in x 4in: 3 stated criteria not met.
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
#> ── Measured, not graded
#> Tufte states a direction for these rather than a threshold. Read them against
#> another draft of the same figure.
#> • Data-ink ratio 0.34: 34% of the ink varies with the data. Tufte asks that
#>   this be maximised within reason and names no threshold, so read it against
#>   another draft of this figure rather than against a target.
#> • Data density 32.9 numbers per square inch: 666 entries over 20.2 square
#>   inches. Tufte ranks published graphics by this and sets no minimum.
#> • 1 distinct colour in use. Tufte's advice on colour is qualitative, so this is
#>   a count and not a verdict.
#> • One series in one panel, so there is nothing to separate into small
#>   multiples.
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
<!-- readme-audit:end -->

There's no score. Tufte says two different kinds of thing. Sometimes he gives a
criterion a graphic either meets or doesn't: bars measured from zero, a lie
factor between 0.95 and 1.05, graphics wider than they're tall, non-data ink off
the page. Those get graded. Other times he gives only a direction, asking that
the data-ink ratio be maximised "within reason" and that data density go up
without saying how much is enough. Those get measured, and the judgement stays
with you. A threshold on the second kind would be mine rather than his, and a
single number would need a weighting between a pie chart and a missing source
note that he never offers. `tufte_principles()` marks which is which in its
`criterion` column.

For a whole paper at once, `audit_figures()` orders figures by how many stated
criteria each one fails. That's a count rather than a proportion, so it's
comparable across figures. A percentage would divide by a denominator that
shifts with the plot type.

What it's good at is the mechanical stuff you stop seeing after the fifth draft.
A pie chart. A bar baseline that isn't zero. A bar chart on a log scale. A
variable encoded twice. A legend where direct labels belong. A subtitle that
gets clipped at the size you're about to save.

## What it won't tell you

`tufte_principles()` lists every principle, its source, the function that
implements it, and whether the audit can check it at all.

```r
p <- tufte_principles()
p[!p$audited, c("principle", "implemented_by")]
#> Show comparisons            slopegraph(), facet_tufte()
#> Show causality              NA
#> Show multivariate data      facet_tufte(), sparklines()
#> Content counts most of all  NA
```

The two `NA`s are the honest part. Nothing in the package reaches them.

A figure can meet every stated criterion and still be pointless. Tufte's first
principle is that content counts most of all, and no function evaluates that.

## How this sits alongside other packages

Some of this duplicates work that already exists.
[`ggthemes`](https://github.com/jrnold/ggthemes) has a `theme_tufte()`, a
`geom_rangeframe()` and a `geom_tufteboxplot()`. It's actively maintained and
widely used. If the theme is all you want, it's the lighter dependency and you
should use it. Loading both packages masks `theme_tufte()`, so watch for that.

If you need labels that can't collide,
[`directlabels`](https://cran.r-project.org/package=directlabels) and
[`ggrepel`](https://cran.r-project.org/package=ggrepel) solve the general
problem properly. `geom_text_last()` here only handles the narrow case of
labelling the end of a series.

The gap I think this fills is measurement. As far as I can tell, no R package
computes the data-ink ratio, the lie factor or data density. A search of every
CRAN title and description turns up nothing for "data-ink", "lie factor" or
"chartjunk". The near neighbours do adjacent work: `ggcheck` reads built ggplot
objects to autograde student code, `ggalttext` reads them to write alt text, and
[`GGenemy`](https://cran.r-project.org/package=GGenemy) audits plots for
accessibility, meaning WCAG contrast and colour-vision deficiency. The only
data-ink implementation I could find in any language is a Java repository,
archived in 2025 and last worked on in 2010, and it makes you segment the image
by hand before it counts anything.

`check_contrast()` overlaps GGenemy deliberately. A package that tells you to
erase ink owes you a check that what's left is still visible. GGenemy goes
further on accessibility, including colour-vision simulation, and it's the
better tool if that's your question.

One caution about what the numbers are for. The empirical literature doesn't
support maximising the data-ink ratio as an objective, and hasn't since the mid
nineties. I treat these measurements as diagnostics. They tell you where a
figure spends its ink, and I'd rather you argue with them than optimise against
them. The
[measuring article](https://lobsterbush.github.io/tufter/articles/measuring.html#and-a-larger-caveat-the-principle-itself-is-contested)
lays out the evidence against the principle.

Several Tufte forms are unmaintained or missing in R. `CGPfunctions`, which
provided `newggslopegraph()`, was removed from CRAN in November 2025.
`leeper/slopegraph` hasn't moved since 2018. `ggtufte`, Jeff Arnold's own
attempt to spin the Tufte parts out of `ggthemes`, was abandoned in 2018. I
couldn't find any implementation of the bar chart with gridlines erased through
the bars, no first-class dot-dash geom, and no Tufte colour palette. `ggthemes`
ships Few, Cleveland, Tableau and Ptol palettes, but nothing from Tufte.

The measurement half is why this package exists. The drawing half is partly
convenience and partly consolidation.

## Provenance

| Declaration | Mark and standard |
| :--- | :--- |
| AI – Human (editor) | 🤖✏️👤 · [The Latent Review provenance standard](https://thelatentreview.com/provenance/) |

Charles Crabtree is the human editor and maintainer. Anthropic's Claude, run
through Claude Code, wrote most of the original R source, tests, documentation,
and vignettes. OpenAI's Codex assisted with the release audit, fixes, and site
redesign. Charles specified the design and retains editorial responsibility.

Check results and remaining submission requirements are recorded in
[cran-comments.md](https://github.com/lobsterbush/tufter/blob/main/cran-comments.md).
The measurements are estimates with the limitations described in the
[measurement guide](https://lobsterbush.github.io/tufter/articles/measuring.html).

## Development and replication

From a clone of the repository, install the development tools and dependencies:

```r
install.packages(c("devtools", "pkgdown", "here"))
devtools::install_deps(dependencies = TRUE)
devtools::document()
devtools::test()
devtools::check(args = "--as-cran")
```

Rebuild the documentation with `Rscript data-raw/build_site.R`. The live-data
article uses the bundled snapshot; fetching new data is a separate manual step.
Regenerate the README illustrations with `Rscript data-raw/make_readme_figures.R`
and its console output with `Rscript data-raw/make_readme_output.R`.

## Sources

- Tufte, E. R. (2001). *The Visual Display of Quantitative Information*, 2nd ed.
- Tufte, E. R. (1990). *Envisioning Information*.
- Tufte, E. R. (1997). *Visual Explanations*.
- Tufte, E. R. (2006). *Beautiful Evidence*.

## Author

Charles Crabtree, Senior Lecturer, School of Social Sciences, Monash University
and K-Club Professor, University College, Korea University.

MIT licensed.
