# Examples with simulated data

Everything below runs on simulated data. No file is read, nothing is
downloaded, and every chunk is reproducible from the seed at the top of
its section, so you can paste any of them into a fresh session and get
the same figure. The scenarios are the ones I actually meet in
survey-experimental work: treatment effects across conditions,
audit-study callback rates, cross-national indicators over time, and
before-and-after comparisons.

## Simulating the data

One helper, used throughout. It generates a small survey experiment: a
set of respondents, a randomly assigned condition, and an outcome with a
real but modest treatment effect.

``` r
simulate_experiment <- function(n = 900,
                                conditions = c("Control", "Information",
                                               "Norms", "Both"),
                                effects = c(0, 0.28, 0.19, 0.41),
                                seed = 20260729) {
  set.seed(seed)
  condition <- factor(sample(conditions, n, replace = TRUE),
                      levels = conditions)
  age <- round(rnorm(n, 46, 15))
  age <- pmin(pmax(age, 18), 85)
  effect <- effects[match(condition, conditions)]

  data.frame(
    id = seq_len(n),
    condition = condition,
    age = age,
    # Outcome on a 1 to 7 scale, with a mild age gradient.
    support = pmin(pmax(
      rnorm(n, 4.1 + effect + 0.012 * (age - 46), 1.15), 1
    ), 7)
  )
}

experiment <- simulate_experiment()
str(experiment)
#> 'data.frame':    900 obs. of  4 variables:
#>  $ id       : int  1 2 3 4 5 6 7 8 9 10 ...
#>  $ condition: Factor w/ 4 levels "Control","Information",..: 1 1 3 3 2 4 2 3 3 4 ...
#>  $ age      : num  43 43 20 51 61 39 35 64 59 29 ...
#>  $ support  : num  3.6 4.55 2.61 1.92 3.37 ...
```

## Distributions: the box plot with the box erased

The box in a box plot is a container for four numbers that a line and a
dot can hold on their own.
[`geom_tufteboxplot()`](https://lobsterbush.github.io/tufter/reference/geom_tufteboxplot.md)
erases it, keeping between a third and a fifth of the ink.
`geom_rangeframe(sides = "l")` puts an axis line only where the data
are.

``` r
ggplot(experiment, aes(condition, support)) +
  geom_tufteboxplot() +
  geom_rangeframe(sides = "l") +
  labs(
    x = NULL, y = "Support (1-7)",
    title = "Support for the policy, by experimental condition"
  ) +
  theme_tufte() +
  label_source("Simulated data, n = 900")
```

![](simulated-examples_files/figure-html/boxplot-1.png)

The three variants trade ink for legibility. `"point"` is the default
and the sparest: whiskers with a gap, and a dot at the median. `"line"`
keeps a thick interquartile segment. `"offset"` shifts that segment to
one side, which is what you want when the whiskers are short.

``` r
for (variant in c("line", "offset")) {
  print(
    ggplot(experiment, aes(condition, support)) +
      geom_tufteboxplot(type = variant) +
      geom_rangeframe(sides = "l") +
      labs(x = NULL, y = "Support", title = paste0('type = "', variant, '"')) +
      theme_tufte()
  )
}
```

![](simulated-examples_files/figure-html/boxplot-variants-1.png)![](simulated-examples_files/figure-html/boxplot-variants-2.png)

## Range frames and quartile frames

A panel border is the same box whatever the numbers are. A range frame
spans only the data, so the frame reports the minimum and maximum for
free. A quartile frame breaks that line at the quartiles, so the axis
carries the whole five-number summary;
[`quartile_breaks()`](https://lobsterbush.github.io/tufter/reference/quartile_breaks.md)
puts the printed labels in the same places, and drops any that would
collide.

``` r
ggplot(experiment, aes(age, support)) +
  geom_point(alpha = 0.25, size = 1) +
  geom_quartileframe() +
  scale_x_continuous(breaks = quartile_breaks(experiment$age)) +
  scale_y_continuous(breaks = quartile_breaks(experiment$support)) +
  labs(x = "Age", y = "Support") +
  theme_tufte()
```

![](simulated-examples_files/figure-html/frames-1.png)

[`geom_dotdash()`](https://lobsterbush.github.io/tufter/reference/geom_dotdash.md)
goes further still, replacing the frame with the data themselves: a
short tick at every observation, on both margins. Turn the theme ticks
off, or you get two sets of marks saying the same thing.

``` r
ggplot(experiment, aes(age, support)) +
  geom_point(alpha = 0.25, size = 1) +
  geom_dotdash() +
  labs(x = "Age", y = "Support") +
  theme_tufte(ticks = FALSE)
```

![](simulated-examples_files/figure-html/dotdash-1.png)

## Bars with the gridlines erased through them

Bar charts need gridlines, because readers recover values from bar
heights. But a gridline crossing a bar sits on top of ink that already
encodes that value, so Tufte erases it there rather than drawing over
the bar.

Here is a simulated audit study: callback rates by applicant name and
occupation.

``` r
set.seed(11)
callbacks <- data.frame(
  name = rep(c("Emily", "Greg", "Lakisha", "Jamal"), each = 2),
  occupation = rep(c("Sales", "Administrative"), 4)
)
callbacks$rate <- round(
  c(10.8, 9.4, 10.2, 9.1, 6.6, 5.9, 6.4, 5.5) + rnorm(8, 0, 0.3), 1
)

ggplot(callbacks, aes(name, rate)) +
  geom_col_tufte(fill = "grey72") +
  facet_tufte(~ occupation) +
  labs(x = NULL, y = "Callback rate (%)",
       title = "Simulated callback rates by name and occupation") +
  theme_tufte() +
  label_source("Simulated data; not real audit-study results")
```

![](simulated-examples_files/figure-html/bars-1.png)

Note the bars start at zero.
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
will tell you if they do not, and
[`lie_factor()`](https://lobsterbush.github.io/tufter/reference/lie_factor.md)
will tell you by how much the figure exaggerates.

## Dots, when a zero baseline is not wanted

Sometimes zero is a long way from the data and starting there wastes
most of the panel. That is the case for using dots rather than bars: a
dot encodes its value by position, so it can be read against a scale
that excludes zero without lying about proportions, and it costs a
fraction of the ink. Cleveland’s leader lines let the eye run along a
row without drifting into the next one.

Sort before plotting. An alphabetical dot plot throws away the form’s
main advantage, which is that rank is visible at a glance.

``` r
support <- aggregate(support ~ condition, experiment, mean)

ggplot(support, aes(support, stats::reorder(condition, support))) +
  geom_cleveland_dot() +
  labs(x = "Mean support (1-7)", y = NULL) +
  theme_tufte() +
  label_source("Simulated data, n = 900")
```

![](simulated-examples_files/figure-html/cleveland-1.png)

## Banking the aspect ratio

The same series looks like a gentle drift or a cliff depending only on
how tall the panel is, and neither reading is the data’s fault.
Cleveland’s rule is that slope is judged most accurately near 45
degrees, and the aspect ratio is what puts it there.
[`bank_to_45()`](https://lobsterbush.github.io/tufter/reference/bank_to_45.md)
computes the height that does it.

``` r
cycles <- data.frame(
  month = 1:240,
  value = sin(seq(0, 12 * pi, length.out = 240)) + seq(0, 2, length.out = 240)
)

series <- ggplot(cycles, aes(month, value)) +
  geom_line(linewidth = 0.3) +
  geom_rangeframe(sides = "l") +
  labs(x = "Month", y = "Index") +
  theme_tufte()

banked <- bank_to_45(series, width = 6.5)
banked
#> 
#> ── Banking to 45 degrees
#> Aspect ratio 0.133 (height / width), from 239 segments by "median_slope".
#> At 6.5in wide, draw it 0.86in tall.
```

Drawn at roughly that height, the panel is short and wide, the rising
and falling flanks of each cycle sit near 45 degrees, and the slow
upward drift underneath the oscillation is the first thing you see:

``` r
series
```

![](simulated-examples_files/figure-html/banked-figure-1.png)

Here is the same data in a conventionally proportioned panel. Nothing is
hidden, and for reading the individual cycles it is arguably the better
picture. But the vertical stretch exaggerates every flank towards the
vertical, the oscillation dominates, and the trend it is riding on takes
noticeably longer to notice:

``` r
series
```

![](simulated-examples_files/figure-html/unbanked-figure-1.png)

Which of those you want depends on the question. Banking is a rule for
reading *slopes*, so it helps when the rate of change is the finding and
hurts when the levels are. It is a defensible default and not an
obligation.

## Is it dark enough to read?

Erasing ink is a virtue only up to the point where what survives can
still be seen.
[`check_contrast()`](https://lobsterbush.github.io/tufter/reference/check_contrast.md)
measures every colour the plot draws with against the background, using
the WCAG minima of 4.5 to 1 for text and 3 to 1 for marks.

``` r
check_contrast(
  ggplot(experiment, aes(age, support)) +
    geom_point(colour = "grey80", size = 0.8) +
    theme_tufte()
)
#> # A tibble: 5 × 5
#>   role       colour    ratio threshold passes
#>   <chr>      <chr>     <dbl>     <dbl> <lgl> 
#> 1 data mark  grey80     1.61       3   FALSE 
#> 2 caption    grey40     5.74       4.5 TRUE  
#> 3 subtitle   grey30     8.45       4.5 TRUE  
#> 4 axis text  grey20    12.6        4.5 TRUE  
#> 5 strip text #1A1A1AFF 17.4        4.5 TRUE
```

Grey 80 on white is elegant and, for a good number of readers,
invisible.

## Small multiples

The answer to multivariate data is repetition rather than complication:
the same graphic, at the same scale, once per condition.
[`facet_tufte()`](https://lobsterbush.github.io/tufter/reference/facet_tufte.md)
fixes the scales, and warns if you try to free them, because free scales
destroy the comparison the design exists to make.

``` r
ggplot(experiment, aes(age, support)) +
  geom_point(alpha = 0.3, size = 0.8) +
  geom_smooth(method = "lm", se = FALSE, colour = "grey20", linewidth = 0.4,
              formula = y ~ x) +
  geom_rangeframe() +
  facet_tufte(~ condition, ncol = 4) +
  labs(x = "Age", y = "Support") +
  theme_tufte()
```

![](simulated-examples_files/figure-html/multiples-1.png)

## Direct labelling instead of a legend

A legend makes the reader look away, hold a colour in memory, look back,
and match.
[`geom_text_last()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md)
puts the name where the eye already is: at the end of the line.

``` r
set.seed(4)
countries <- c("Australia", "Japan", "Korea", "New Zealand")
panel <- do.call(rbind, lapply(seq_along(countries), function(i) {
  data.frame(
    year = 2000:2024,
    country = countries[i],
    trust = cumsum(rnorm(25, 0.1 * (i - 2.5), 1.1)) + 45 + 4 * i
  )
}))

ggplot(panel, aes(year, trust, colour = country)) +
  geom_line(linewidth = 0.4) +
  # Labels take a fixed dark grey rather than the line colour: a label in the
  # lightest grey of a sequential palette is legible as a line and not as text.
  geom_text_last(aes(label = country), size = 3, colour = "grey15") +
  geom_rangeframe(sides = "l") +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.18))) +
  scale_colour_tufte("grey") +
  labs(x = NULL, y = "Institutional trust index") +
  theme_tufte() +
  theme(legend.position = "none") +
  label_source("Simulated panel, four countries, 2000-2024")
```

![](simulated-examples_files/figure-html/direct-1.png)

[`geom_text_last()`](https://lobsterbush.github.io/tufter/reference/geom_text_last.md)
places each label at its series’ final point and does no collision
avoidance, so two series ending at nearly the same value will overprint.
When that happens, nudge one with `nudge_y`, or swap in
[`ggrepel::geom_text_repel()`](https://ggrepel.slowkow.com/reference/geom_text_repel.html)
on the same data. A slopegraph, below, solves the problem properly by
spreading colliding labels apart itself.

## Slopegraphs

A slopegraph shows before-and-after for many units at once. Each unit is
a line; the slope is the change, the height is the level, and the
crossings show which units changed rank. Every number is printed on the
graphic, which makes the y axis redundant, so it goes. The table and the
figure become the same object.

``` r
set.seed(7)
units <- c("Victoria", "New South Wales", "Queensland", "South Australia",
           "Western Australia", "Tasmania")
before <- round(runif(6, 22, 41), 1)
change <- round(rnorm(6, 3.5, 5), 1)

wave <- data.frame(
  state = rep(units, each = 2),
  wave = rep(c("2015", "2025"), 6),
  value = as.vector(rbind(before, before + change))
)

slopegraph(wave, wave, value, state) +
  labs(
    title = "Share reporting contact with a migrant neighbour",
    subtitle = "Simulated two-wave panel, percentage points"
  )
```

![](simulated-examples_files/figure-html/slopegraph-1.png)

`direction_colour = TRUE` colours the lines by whether the unit rose or
fell, which is worth it only when the direction is the finding.

``` r
slopegraph(wave, wave, value, state, direction_colour = TRUE)
```

![](simulated-examples_files/figure-html/slopegraph-colour-1.png)

## Sparklines

A sparkline is word-sized: small enough to sit inside a sentence, with
the normal range as a grey band, dots at the extremes, and the final
value printed at the end. Each series keeps its own vertical scale,
because a sparkline reports the shape of one series rather than inviting
comparison of levels.

``` r
set.seed(21)
indicators <- do.call(rbind, lapply(
  c("Turnout", "Trust in parliament", "Union density", "Newspaper readership"),
  function(nm) {
    data.frame(
      quarter = 1:80,
      series = nm,
      value = cumsum(rnorm(80, 0, 1)) + 50
    )
  }
))

sparklines(indicators, quarter, value, series)
```

![](simulated-examples_files/figure-html/sparklines-1.png)

A single sparkline, at the size it is meant to be printed, is
[`sparkline()`](https://lobsterbush.github.io/tufter/reference/sparkline.md).
[`sparkline_grob()`](https://lobsterbush.github.io/tufter/reference/sparkline_grob.md)
returns a grob, so one can be dropped into a table cell or an inline
chunk.

``` r
set.seed(3)
sparkline(cumsum(rnorm(60)) + 20)
```

![](simulated-examples_files/figure-html/sparkline-one-1.png)

## Colour as a code

Four palettes, each answering a different question. `"grey"` encodes an
ordered variable without introducing a second, unwanted, categorical
signal. `"accent"` is greys plus one signal red, for when exactly one
series matters and the rest are context. `"muted"` is desaturated earth
tones that sit behind annotation without fighting it. `"divergent"`
handles signed quantities with a neutral rather than a white midpoint.

``` r
pals <- c("grey", "accent", "muted", "divergent")
swatches <- do.call(rbind, lapply(pals, function(p) {
  cols <- tufte_pal(p)(5)
  data.frame(palette = p, i = seq_along(cols), colour = cols)
}))

ggplot(swatches, aes(i, palette, fill = colour)) +
  geom_tile(colour = "white", linewidth = 2) +
  scale_fill_identity() +
  labs(x = NULL, y = NULL) +
  theme_tufte(ticks = FALSE) +
  theme(axis.text.x = element_blank())
```

![](simulated-examples_files/figure-html/palettes-1.png)

Used in anger, with grey for context and one accent for the series that
carries the argument:

``` r
focus <- panel
focus$highlight <- ifelse(focus$country == "Korea", "Korea", "Other")

ggplot(focus, aes(year, trust, group = country, colour = highlight)) +
  geom_line(linewidth = 0.4) +
  geom_rangeframe(sides = "l") +
  scale_colour_manual(values = c(Korea = "#c8102e", Other = "#bfbfbf")) +
  geom_text_last(
    data = subset(focus, country == "Korea"),
    aes(label = country), size = 3, colour = "#c8102e"
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.1))) +
  labs(x = NULL, y = "Institutional trust index") +
  theme_tufte() +
  theme(legend.position = "none")
```

![](simulated-examples_files/figure-html/accent-1.png)

## Auditing the result

Every figure above can be scored.
[`tufte_audit()`](https://lobsterbush.github.io/tufter/reference/tufte_audit.md)
runs fifteen checks, structural and measured, and reports which
principles the figure satisfies.

``` r
final <- ggplot(experiment, aes(condition, support)) +
  geom_tufteboxplot() +
  geom_rangeframe(sides = "l") +
  labs(x = NULL, y = "Support (1-7)") +
  theme_tufte() +
  label_source("Simulated data, n = 900")

tufte_audit(final, width = 6.5, height = 4)
#> 
#> ── Tufte audit ──
#> 
#> 14/15 checks passed (93%), at 6.5in x 4in.
#> 
#> ── Failing
#> ✖ Data-ink ratio is 0.46: 46% of the ink in this figure varies with the data.
#> Maximise the data-ink ratio (VDQI ch. 4)
#> 
#> ── Passing
#> • Panel background carries no data
#> • Grid is no heavier than the data
#> • Frame reports the data range
#> • No pie chart
#> • Lie factor near one
#> • No legend to decode
#> • Colour stays a code
#> • No variable encoded twice
#> • Comparison by repetition
#> • The figure says where its numbers came from
#> • The figure tends toward the horizontal
#> • Ink is dark enough to see
#> • The figure earns its space
#> • Nothing is clipped at the printed size
```

The [measuring
article](https://lobsterbush.github.io/tufter/articles/measuring.md)
goes through what each of those checks is actually computing, and where
the numbers can mislead you.
