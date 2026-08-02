# tufter 0.4.1

More defects found by pointing the package at awkward plots. Two of these
changed reported numbers.

## Orientation

* `lie_factor()` read a horizontal bar chart along the wrong axis, measuring the
  category position instead of the bar's length. A sixteenfold distortion came
  back as 1.4, which sits close enough to honest to be believed. Horizontal
  bars, bars written with `coord_flip()` and ordinary vertical bars now all
  report the same lie factor for the same distortion.
* `tufte_audit()` had the same fault in its baseline check. It reached the right
  verdict by accident and then named the wrong axis, so the explanation pointed
  a reader at an axis that was fine. It now names the axis they can see.
* `coord_flip()` on an honest bar chart returned 1.004 rather than 1, because
  the baseline came from the category range.

## Banking

* `bank_to_45()` normalised every panel by the first panel's ranges. Under free
  scales that rescales every other panel's slopes by the wrong factor: two lines
  each running corner to corner of their own panel came back at 2 instead of 1.
  Each panel is now normalised by its own ranges, and the answer still differs
  between fixed and free scales, as it should.

## Fewer false alarms

* The audit accused any plot that sets two fixed colours outside `aes()` of
  carrying a legend. Red points under a blue fit line draw no key at all. It now
  asks the assembled figure whether a guide box is really there.

## Elsewhere

* `slopegraph()` warns when a unit has more than one value in a period instead
  of printing two labels on top of each other, and draws the first.
* `tufte_principles()` puts `NA` in `implemented_by` for the principles no
  function reaches, rather than prose in a column of function names. A test now
  asserts that every function it does name is exported by the package, so a
  rename can't leave the table pointing at nothing.

# tufter 0.4.0

## A second gallery, on real data

* New article, [Examples with live API data](https://lobsterbush.github.io/tufter/articles/live-data.html),
  drawing every form in the package from four public APIs that need no key:
  CRAN download logs, the USGS earthquake catalogue, the Open-Meteo ERA5
  archive and Wikipedia pageviews.
* `data-raw/fetch_live_examples.R` does the fetching and caches the result to
  `inst/extdata/live-examples.rds`, so the article builds offline and the page
  stays reproducible. Run the script to refresh it.

## Two bugs the real data found

* `check_labels_fit()` measured a rotated y axis title along the wrong axis. The
  width of a rotated text grob is the height of the lettering, which always
  fits, so a y title running off a short panel was reported as fine. It now
  measures the length of the string against the height of the panel area.
* `sparkline()` and `sparklines()` printed their end labels with the
  \pkg{scales} default separator, a space, so 66638 came out as "66 638" and
  read as two numbers at sparkline size. Both gain a `big.mark` argument,
  defaulting to a comma.

## Elsewhere

* `bank_to_45()` says plainly that the height it returns is for the panel. A
  saved figure needs more, for the axis labels and titles, which is how the
  first of those two bugs turned up.

# tufter 0.3.0

The audit no longer invents thresholds, and no longer reports a score. This
changes its output, so anything that read `attr(a, "score")` needs updating to
`attr(a, "violations")`.

## No invented thresholds

Tufte states two different kinds of thing, and earlier versions collapsed them.
For some principles he gives a criterion a graphic either meets or does not:
bars measured from zero, the lie factor between 0.95 and 1.05, graphics wider
than they are tall, non-data ink erased. Those are still graded. For others he
gives only a direction, asking that the data-ink ratio be maximised "within
reason" and that data density be increased, and names no threshold anywhere.

Those are now measured and reported without a verdict. The cutoffs that used to
grade them were the package author's, presented in Tufte's voice, and are gone:

* a data-ink ratio below 0.5 no longer fails;
* a data density below 2 numbers per square inch no longer fails;
* a banked height more than a factor of two from the given one no longer fails,
  since Cleveland states 45 degrees as the target and no tolerance around it;
* more than seven hues no longer fails, and hues are counted instead;
* more than six overlaid series no longer draws a remark;
* a major gridline is no longer graded by an invented line weight;
* an aspect ratio above 3:1 no longer draws a remark, since Tufte states the
  criterion at 1 and nothing above it;
* `quartile_breaks()` now returns the whole five-number summary by default. The
  spacing at which labels collide depends on font and figure size, which a
  breaks function cannot see, so `min_gap` is off unless you set it.

The legend check no longer fails on a count. It fails when a legend names
series that could have been labelled on the data, and merely reports a key for
a continuous scale, where there are no series to name and Tufte keys the
shading himself.

## No score

`tufte_audit()` reported the share of checks passed. Collapsing the two kinds
of principle into one number needs a weighting between a pie chart and a
missing source note, and Tufte offers no exchange rate. The `score` attribute
is replaced by `violations`, a count of stated criteria not met.

`audit_figures()` now orders figures by that count rather than by a proportion.
A count is comparable across figures; the old proportion divided by a
denominator that changed with the plot type, so it ranked figures on numbers
that were not on the same scale.

## Elsewhere

* All the prose is rewritten: README, the vignette, both articles, the roxygen
  documentation and the audit's own messages. Contractions throughout, no dashes
  used as connectors, and none of the antithesis constructions ("not X, it's Y")
  that had crept in.
* `tufte_principles()` gains a `criterion` column marking which principles
  Tufte states a testable line for. Ten of twenty-six do.
* The audit cites WCAG rather than Tufte for the contrast minimum, and
  Cleveland rather than Tufte for banking, in the output itself.
* `tufte_pal()` no longer claims a number at which hues stop being a code; it
  warns only that the extra colours are interpolated.
* `slopegraph()`'s `min_gap` is documented as a typesetting allowance rather
  than a quantity from Tufte.

# tufter 0.2.1

Bug fixes found by auditing the package against itself. Three of these changed
reported numbers, so figures measured with 0.2.0 should be measured again.

## Measurement correctness

* `geom_rangeframe()` and `geom_quartileframe()` returned an unnamed grob, so
  `data_ink_ratio()` counted the frame as furniture rather than as data. Adding
  a range frame therefore *lowered* the measured ratio, inverting the package's
  own advice. Frames are now named like every other layer; the ratio for a
  framed scatterplot rises from 0.60 to 0.73.
* `data_density()` summed rows across layers, so a range frame and a dot-dash
  drawn over the same thirty-two observations were counted as ninety-six
  entries. Layers are now grouped by the data they read, and a layer carrying
  its own data still counts separately.
* `data_density()` counted `factor(cyl)` and `cyl` as two variables. Aesthetics
  are now resolved to the columns they actually read.
* `bank_to_45()` sorted points by x and discarded segments with no horizontal
  extent, which silently assumed every path was a function of x. A circle
  returned an aspect ratio of 0.016 instead of 1. Segments are now read in
  drawn order and verticals are kept as the infinite slopes they are. A path
  that is more than half vertical is refused rather than answered wrongly.

## Fewer false alarms

* `tufte_audit()` no longer reports a continuous colour scale as "22 distinct
  colours". A gradient is one code, not a set of competing hues.
* Redundant encoding is now detected through a transformation, so `x =
  factor(cyl)` with `colour = cyl` is caught.
* `lie_factor()` returned 1 for a bar chart on a log scale, which read as a
  clean bill of health for one of the more distorting things you can do to a
  bar. It now returns `NA`, and the audit fails the plot with an explanation.

## Documentation

* `bank_to_45()` claimed `save_tufte()` would bank for you. It will not, and
  never did; the cross-reference now says so.

# tufter 0.2.0

## Measuring

* `bank_to_45()` computes the aspect ratio that brings a plot's slopes nearest
  45 degrees, where slope is judged most accurately. Two methods: Cleveland's
  median absolute slope, and mean absolute orientation, optionally weighted by
  segment length.
* `check_contrast()` and `contrast_ratio()` measure every colour a plot draws
  with against its background, using the WCAG 2.1 minima. Transparency is
  composited first, so a colour is judged as the reader sees it. Erasing ink is
  only a virtue up to the point where what remains can still be seen.
* `audit_figures()` runs the audit across every figure in a paper, given a list
  of plots or a directory of saved ones, and returns them worst first with the
  failing checks named.

## Drawing

* `geom_cleveland_dot()` draws a dot plot with leader lines. This is the second
  answer to a bar chart whose baseline is not zero, and until now the audit
  recommended it without the package providing it.

## Auditing

* `tufte_audit()` gains two checks: whether the given aspect ratio banks the
  slopes near 45 degrees, and whether the ink is dark enough to see.

# tufter 0.1.0

First release.

## Generative

* `theme_tufte()`, `theme_sparkline()`, `theme_slopegraph()`.
* `geom_rangeframe()`, `geom_quartileframe()` and `quartile_breaks()`.
* `geom_tufteboxplot()`, with `"point"`, `"line"` and `"offset"` variants.
* `geom_dotdash()` for marginal distributions on the axes.
* `geom_col_tufte()` and `geom_bar_tufte()`, which erase the gridlines where
  they cross the bars.
* `slopegraph()`, `sparkline()`, `sparklines()` and `sparkline_grob()`.
* `facet_tufte()` for small multiples, with scales fixed.
* `geom_text_last()` and `geom_text_first()` for direct labelling.
* `tufte_pal()`, `tufte_colours()` and the `scale_*_tufte()` family.
* `label_source()` and `save_tufte()`.

## Evaluative

* `data_ink_ratio()`, estimated by rendering the plot with and without its data
  layers and comparing weighted non-background pixels.
* `lie_factor()`, for numeric vectors and for bar charts with a truncated
  baseline.
* `data_density()`.
* `check_labels_fit()`, which catches clipped titles and overlapping axis
  labels at the intended print size.
* `tufte_audit()`, which runs all of the above plus the structural checks.
* `tufte_principles()`, listing every principle and whether it can be audited.

<!-- HIDDEN FOR NOW, alongside the disclosure itself in README.md.

## Documentation

* Added an AI usage disclosure to the README, naming what was model-generated,
  what was human-verified and how, and what remains unverified.

END OF HIDDEN SECTION -->
