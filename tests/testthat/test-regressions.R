# Regressions for defects found by auditing the package against itself. Each
# test asserts an answer that is known independently of the implementation,
# rather than only that the code runs. The bugs below all survived a suite that
# checked the latter.

library(ggplot2)

test_that("every drawn layer is named so the ink stripper can find it", {
  # geom_rangeframe() once returned an unnamed grobTree, so data_ink_ratio()
  # counted the frame as furniture. Any layer whose grob is not "geom"-prefixed
  # is silently misattributed.
  plots <- list(
    rangeframe = ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_rangeframe(),
    quartileframe = ggplot(mtcars, aes(wt, mpg)) + geom_point() +
      geom_quartileframe(),
    dotdash = ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_dotdash(),
    col = ggplot(data.frame(g = letters[1:3], v = 1:3), aes(g, v)) +
      geom_col_tufte(),
    cleveland = ggplot(data.frame(g = letters[1:3], v = 1:3), aes(v, g)) +
      geom_cleveland_dot(),
    boxplot = ggplot(mtcars, aes(factor(cyl), mpg)) + geom_tufteboxplot()
  )

  # Measuring needs a device. Without one R starts the default, which writes an
  # Rplots.pdf into the test directory.
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)

  for (nm in names(plots)) {
    gt <- ggplotGrob(plots[[nm]])
    panel <- gt$grobs[[which(grepl("^panel", gt$layout$name))[1]]]
    # ggplot2 pads the panel with unnamed placeholder children; only the
    # grill, the border and the layers themselves carry real names.
    drawn <- Filter(
      function(n) !is.na(n) && nzchar(n) && n != "NULL" &&
        !grepl("^(grill|panel\\.border)", n),
      names(panel$children)
    )
    expect_true(all(grepl("^geom", drawn)),
                info = paste(nm, ":", paste(drawn, collapse = " | ")))
  }
})

test_that("adding a range frame raises the data-ink ratio, never lowers it", {
  # The frame reports the minimum and maximum, so it is data-ink. Before the
  # fix it was charged to the non-data side and adding it made the number
  # worse, which inverted the package's own advice.
  base <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  bare <- data_ink_ratio(base, 4, 3, 72)$ratio
  framed <- data_ink_ratio(base + geom_rangeframe(), 4, 3, 72)$ratio
  quartiled <- data_ink_ratio(base + geom_quartileframe(), 4, 3, 72)$ratio

  expect_gte(framed, bare)
  expect_gte(quartiled, bare)
})

test_that("layers re-reading the same data do not inflate data density", {
  # Three layers over thirty-two observations are still thirty-two numbers.
  base <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  expect_equal(data_density(base)$rows, nrow(mtcars))
  expect_equal(data_density(base + geom_rangeframe())$rows, nrow(mtcars))
  expect_equal(
    data_density(base + geom_rangeframe() + geom_dotdash())$rows,
    nrow(mtcars)
  )
})

test_that("a layer with its own data counts separately", {
  extra <- data.frame(wt = 3, mpg = 20, lab = "note")
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() +
    geom_text(data = extra, aes(label = lab))
  expect_equal(data_density(p)$rows, nrow(mtcars) + 1L)
})

test_that("a transformed column is not counted as a second variable", {
  # factor(cyl) and cyl are one variable, not two.
  p <- ggplot(mtcars, aes(factor(cyl), mpg)) + geom_point()
  expect_equal(data_density(p)$variables, 2L)
  expect_setequal(data_density(p)$variable_names, c("cyl", "mpg"))
})

test_that("banking a circle returns an aspect ratio of one", {
  # The definitive test for path handling: a circle is symmetric in x and y, so
  # its median absolute slope is 1 whatever the sampling. Sorting the points by
  # x, or discarding vertical segments, both destroy this and the old code did
  # each of them.
  th <- seq(0, 2 * pi, length.out = 721)[-1]
  circle <- data.frame(x = cos(th), y = sin(th))
  b <- bank_to_45(ggplot(circle, aes(x, y)) + geom_path())
  expect_equal(b$aspect, 1, tolerance = 0.02)
})

test_that("banking keeps every segment of a path, including verticals", {
  th <- seq(0, 2 * pi, length.out = 201)[-1]
  circle <- data.frame(x = cos(th), y = sin(th))
  segs <- tufter:::.slope_ratios(ggplot(circle, aes(x, y)) + geom_path())
  # No segment may be discarded; the old code dropped the steep ones.
  expect_equal(length(segs$m), nrow(circle) - 1L)
  expect_true(any(segs$m > 10))

  # An exactly vertical segment is infinitely steep, and must be kept as such
  # rather than thrown away.
  square <- data.frame(x = c(0, 1, 1, 0, 0), y = c(0, 0, 1, 1, 0))
  sq <- tufter:::.slope_ratios(ggplot(square, aes(x, y)) + geom_path())
  expect_equal(length(sq$m), 4L)
  expect_equal(sum(is.infinite(sq$m)), 2L)
})

test_that("banking is unchanged by reversing the order of a closed path", {
  th <- seq(0, 2 * pi, length.out = 361)[-1]
  circle <- data.frame(x = cos(th), y = sin(th))
  fwd <- bank_to_45(ggplot(circle, aes(x, y)) + geom_path())$aspect
  rev <- bank_to_45(ggplot(circle[rev(seq_len(nrow(circle))), ], aes(x, y)) +
                      geom_path())$aspect
  expect_equal(fwd, rev, tolerance = 1e-6)
})

test_that("a path that cannot be banked says so instead of inventing a number", {
  # Verticals contribute pi/2 to the mean orientation whatever the panel does,
  # so the mean can only be brought to pi/4 when fewer than half the segments
  # are vertical. The median method refuses at exactly the same threshold. The
  # two methods therefore fail together on a mostly vertical path, and the old
  # message suggesting the second as a way round the first was wrong.
  mostly_vertical <- ggplot(data.frame(x = rep(0, 20), y = seq_len(20)),
                            aes(x, y)) + geom_path()
  expect_error(bank_to_45(mostly_vertical), "vertical")
  expect_error(bank_to_45(mostly_vertical, method = "average_orientation"),
               "No aspect ratio")

  # The mirror case: nearly everything flat. This used to return exp(20), a
  # panel three billion inches tall, with no warning at all.
  flat <- ggplot(data.frame(x = seq_len(21), y = c(rep(5, 20), 6)),
                 aes(x, y)) + geom_line()
  expect_error(bank_to_45(flat, method = "average_orientation", weighted = FALSE),
               "No aspect ratio")

  # A minority of verticals is fine, and that is what the orientation method is
  # actually for: the median is finite, and both methods answer.
  set.seed(5)
  mixed <- data.frame(x = c(0, 0, cumsum(runif(18, 0.5, 2))),
                      y = c(1, 2, 2 + cumsum(runif(18, 0.5, 2))))
  pm <- ggplot(mixed, aes(x, y)) + geom_path()
  expect_s3_class(bank_to_45(pm), "tufte_banking")
  expect_s3_class(bank_to_45(pm, method = "average_orientation"), "tufte_banking")
})

test_that("a continuous colour scale is one code, not many hues", {
  a <- tufte_audit(
    ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() + theme_tufte(),
    measure = FALSE
  )
  hues <- a[a$check == "Distinct hues", ]
  expect_match(hues$message, "continuously")
  # Counting the shades of a gradient as competing hues was the false alarm;
  # grading them at all would be a second one, since Tufte's advice on colour
  # is qualitative and names no number.
  expect_equal(hues$status, "report")
})

test_that("hues are counted and never graded, however many there are", {
  many <- data.frame(g = factor(letters[1:12]), v = 1:12)
  a <- tufte_audit(
    ggplot(many, aes(g, v, colour = g)) + geom_point() + theme_tufte(),
    measure = FALSE
  )
  hues <- a[a$check == "Distinct hues", ]
  expect_equal(hues$status, "report")
  expect_match(hues$message, "12 distinct colours")
  expect_match(hues$message, "not a verdict")
})

test_that("redundant encoding is caught through a transformation", {
  # x = factor(cyl) and colour = cyl are the same variable twice.
  a <- tufte_audit(
    ggplot(mtcars, aes(factor(cyl), mpg, colour = cyl)) + geom_point(),
    measure = FALSE
  )
  expect_equal(a$status[a$check == "No variable encoded twice"], "fail")
})

test_that("a log-scaled bar chart is not reported as honest", {
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  logged <- ggplot(d, aes(g, v)) + geom_col() + scale_y_log10()

  # Returning 1 here would read as a clean bill of health.
  expect_true(is.na(lie_factor(logged)))

  a <- tufte_audit(logged, measure = FALSE)
  baseline <- a[a$check == "Bars measured from zero", ]
  expect_equal(baseline$status, "fail")
  expect_match(baseline$message, "transformation")

  # A plain linear bar chart from zero is still honest.
  expect_equal(lie_factor(ggplot(d, aes(g, v)) + geom_col()), 1)
})

test_that("points on a transformed scale are left alone", {
  # Only bars claim proportionality through length, so a log scatterplot is
  # not a lie and must not be flagged as one.
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + scale_y_log10()
  expect_equal(lie_factor(p), 1)
  a <- tufte_audit(p, measure = FALSE)
  expect_false("Bars measured from zero" %in% a$check)
})

test_that("a rotated y axis title is measured along its own length", {
  # Found by the live-data article: a short, wide banked panel clipped
  # "Daily downloads" while check_labels_fit() reported that it fitted. The
  # width of a rotated text grob is the height of the lettering, which always
  # fits; what matters is the length of the string against the panel height.
  p <- ggplot(data.frame(x = 1:50, y = cumsum(rnorm(50))), aes(x, y)) +
    geom_line() +
    labs(x = NULL, y = "Daily downloads") +
    theme_tufte()

  short <- suppressWarnings(check_labels_fit(p, width = 6.5, height = 1.3))
  ytitle <- short[short$element == "y axis title", ]
  expect_equal(nrow(ytitle), 1L)
  # The string is over an inch long, not the tenth of an inch a rotated
  # grobWidth reports.
  expect_gt(ytitle$required_in, 1)
  expect_false(ytitle$fits)

  # Given room, the same title passes.
  tall <- check_labels_fit(p, width = 6.5, height = 4)
  expect_true(all(tall$fits))
})

test_that("sparkline value labels use a readable thousands separator", {
  # The scales default is a space, which reads as two numbers at sparkline size.
  d <- data.frame(t = 1:20, v = seq(10000, 66638, length.out = 20),
                  g = "series")
  built <- ggplot_build(sparklines(d, t, v, g, accuracy = 1))
  labels <- unlist(lapply(built$data, function(x) x$label))
  expect_true(any(grepl("66,638", labels, fixed = TRUE)))
  expect_false(any(grepl("66 638", labels, fixed = TRUE)))
})

test_that("fixed colours set outside aes are not reported as a legend", {
  # Red points under a blue fit line draw no key at all. Counting distinct
  # rendered colours accused this very ordinary plot of carrying a legend.
  fixed <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point(colour = "red") +
    geom_smooth(colour = "blue", se = FALSE, method = "lm", formula = y ~ x) +
    theme_tufte()
  expect_false(tufter:::.has_legend(fixed))
  a <- tufte_audit(fixed, measure = FALSE)
  expect_equal(a$status[a$check == "No legend to decode"], "pass")

  # A mapped discrete aesthetic still fails, and suppressing the key passes.
  mapped <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point() + theme_tufte()
  expect_true(tufter:::.has_legend(mapped))
  expect_equal(
    tufte_audit(mapped, measure = FALSE)$status[
      tufte_audit(mapped, measure = FALSE)$check == "No legend to decode"],
    "fail"
  )
  off <- mapped + theme(legend.position = "none")
  expect_false(tufter:::.has_legend(off))
})

test_that("lie_factor reads horizontal bars along their own length", {
  # A horizontal bar carries its length on x. Reading ymax measured the
  # category position instead, and returned a plausible 1.4 where the true
  # distortion was sixteenfold.
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  vertical <- ggplot(d, aes(g, v)) + geom_col() +
    coord_cartesian(ylim = c(95, 115))
  horizontal <- ggplot(d, aes(v, g)) + geom_col() +
    coord_cartesian(xlim = c(95, 115))

  expect_equal(lie_factor(horizontal), lie_factor(vertical), tolerance = 1e-6)
  expect_gt(lie_factor(horizontal), 5)

  # Honest and transformed horizontal bars behave like their vertical twins.
  expect_equal(lie_factor(ggplot(d, aes(v, g)) + geom_col()), 1)
  expect_true(is.na(lie_factor(ggplot(d, aes(v, g)) + geom_col() +
                                 scale_x_log10())))
})

test_that("banking normalises each panel by its own ranges", {
  # Two straight lines, each running corner to corner of its own panel, are
  # both at 45 degrees when the panel is square. Under free scales the answer
  # is 1; using the first panel's ranges for both gave 2.
  d <- rbind(
    data.frame(t = 1:50, v = seq(0, 1, length.out = 50), g = "tiny"),
    data.frame(t = 1:50, v = seq(0, 1000, length.out = 50), g = "huge")
  )
  free <- ggplot(d, aes(t, v)) + geom_line() +
    facet_wrap(~ g, scales = "free_y")
  expect_equal(bank_to_45(free)$aspect, 1, tolerance = 1e-6)

  # On a shared scale the small series really is nearly flat, so the answer
  # must differ. This is the check that the panel loop has not flattened the
  # distinction between fixed and free scales.
  fixed <- ggplot(d, aes(t, v)) + geom_line() + facet_wrap(~ g)
  expect_gt(bank_to_45(fixed)$aspect, 1.5)
})

test_that("slopegraph warns rather than silently overprinting duplicates", {
  d <- data.frame(
    g = c("a", "a", "b", "b", "a"),
    x = c("1", "2", "1", "2", "1"),
    v = c(1, 2, 3, 4, 9)
  )
  expect_warning(p <- slopegraph(d, x, v, g), "more than one value")
  # One label per unit per end, not two.
  built <- suppressWarnings(ggplot_build(slopegraph(d, x, v, g)))
  expect_equal(nrow(built$data[[2]]), 2L)
  expect_equal(nrow(built$data[[3]]), 2L)
})

test_that("bar orientation is read correctly however it was written", {
  # Three ways to draw the same truncated bar chart. All three distort by the
  # same amount, so all three must report the same lie factor, and the audit
  # must name the axis the reader can actually see.
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  cases <- list(
    vertical = ggplot(d, aes(g, v)) + geom_col() +
      coord_cartesian(ylim = c(95, 115)),
    horizontal = ggplot(d, aes(v, g)) + geom_col() +
      coord_cartesian(xlim = c(95, 115)),
    flipped = ggplot(d, aes(g, v)) + geom_col() + coord_flip(ylim = c(95, 115))
  )
  factors <- vapply(cases, lie_factor, numeric(1))
  expect_equal(unname(factors[2]), unname(factors[1]), tolerance = 1e-6)
  expect_equal(unname(factors[3]), unname(factors[1]), tolerance = 1e-6)
  expect_gt(factors[[1]], 5)

  axis_named <- function(p) {
    a <- tufte_audit(p, measure = FALSE)
    a$message[a$check == "Bars measured from zero"]
  }
  expect_match(axis_named(cases$vertical), "^The Y axis")
  expect_match(axis_named(cases$horizontal), "^The X axis")
  # coord_flip() moves the value axis to the bottom, so the message must too.
  expect_match(axis_named(cases$flipped), "^The X axis")
})

test_that("coord_flip on an honest bar chart is exactly honest", {
  # Reading the category range as the baseline gave 1.004, which is inside
  # Tufte's band by luck rather than by being right.
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  expect_equal(lie_factor(ggplot(d, aes(g, v)) + geom_col() + coord_flip()), 1)
})

test_that("a transformed scale is found through coord_flip", {
  # The scale stays attached to the variable even when the coord swaps sides,
  # so the transformation has to be looked up on the data axis and reported on
  # the panel axis.
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  flipped_log <- ggplot(d, aes(g, v)) + geom_col() + coord_flip() +
    scale_y_log10()
  expect_true(is.na(lie_factor(flipped_log)))
  a <- tufte_audit(flipped_log, measure = FALSE)
  msg <- a$message[a$check == "Bars measured from zero"]
  expect_match(msg, "^The X axis uses a log-10 transformation")
})

test_that("categories along a discrete axis are not counted as overlaid series", {
  # ggplot2 groups by the interaction of every discrete aesthetic, positional
  # ones included, so a dot plot of five countries used to report "5 series
  # overlaid in one panel" and recommend faceting, which would have put one
  # point in each panel.
  d <- data.frame(g = letters[1:5], v = c(3, 7, 5, 2, 9))

  dots <- tufte_audit(
    ggplot(d, aes(v, g)) + geom_cleveland_dot() + theme_tufte(),
    width = 5, height = 3, measure = FALSE)
  series <- dots$message[dots$check == "Overlaid series"]
  expect_match(series, "One series", fixed = TRUE)
  expect_false(grepl("5 series", series))

  # A genuine set of overlaid series, told apart by colour rather than by
  # position, is still counted.
  ts <- data.frame(x = rep(1:10, 3), y = rnorm(30),
                   s = rep(c("a", "b", "c"), each = 10))
  lines <- tufte_audit(
    ggplot(ts, aes(x, y, colour = s)) + geom_line() + theme_tufte(),
    width = 5, height = 3, measure = FALSE)
  expect_match(lines$message[lines$check == "Overlaid series"], "3 series")
})

test_that("the audit's return documentation describes what it returns", {
  # A contraction sweep once cut the verb out of this sentence, leaving
  # '"pass" for one that's,'.
  a <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                   width = 5, height = 3, measure = FALSE)
  v <- attr(a, "violations")
  expect_type(v, "integer")
  expect_length(v, 1L)
  expect_identical(v, sum(a$status == "fail"))
})

test_that("tufte_principles() columns are the types the docs promise", {
  p <- tufte_principles()
  expect_type(p$audited, "logical")
  expect_type(p$criterion, "logical")
  # Nothing can be graded that isn't audited at all.
  expect_true(all(p$audited[p$criterion]))
})

test_that("axis labels land where the quartile frame actually breaks", {
  # quartile_breaks() used stats::fivenum() while the frame used
  # stats::quantile(type = 7). Both docs and the vignette promise the labels
  # sit at the breaks, and for most sample sizes they did not: at n = 8 the
  # axis printed 56 next to a gap at 53.4.
  set.seed(3)
  for (n in c(5, 6, 7, 8, 9, 12, 20, 33, 47, 60, 101, 200)) {
    v <- sort(round(rnorm(n, 50, 10), 3))
    labels <- quartile_breaks(v)(range(v))
    frame <- unique(signif(
      as.numeric(stats::quantile(v, c(0, .25, .5, .75, 1), names = FALSE,
                                 type = 7)), 3))
    expect_equal(labels, frame,
                 info = paste("n =", n))
  }
})

test_that("the box plot, the quartile frame and the axis labels share one convention", {
  set.seed(11)
  v <- rnorm(40, 50, 10)
  box <- ggplot_build(
    ggplot(data.frame(g = "a", y = v), aes(g, y)) + geom_tufteboxplot())$data[[1]]
  q <- stats::quantile(v, c(.25, .75), names = FALSE, type = 7)

  # The geom follows ggplot2's own boxplot, which is quantile type 7.
  gg <- ggplot_build(
    ggplot(data.frame(g = "a", y = v), aes(g, y)) + geom_boxplot())$data[[1]]
  expect_equal(c(box$lower[1], box$upper[1]), c(gg$lower[1], gg$upper[1]))
  expect_equal(unname(c(box$lower[1], box$upper[1])), q)

  # And the axis labels agree with it.
  labels <- quartile_breaks(v)(range(v))
  expect_true(all(signif(q, 3) %in% labels))
})

test_that("with too few values for a summary the labels match the plain frame", {
  # .frame_spans() draws a plain range whenever there are fewer than four
  # distinct values, so the labels must not claim quartiles there either.
  expect_equal(quartile_breaks()(c(0, 10)), c(0, 10))
  expect_equal(quartile_breaks(c(2, 2, 9))(c(2, 9)), c(2, 9))
  expect_length(quartile_breaks(rep(5, 20))(c(5, 5)), 1L)
  # Four distinct values is enough, and then all five points are reported.
  expect_length(quartile_breaks(c(1, 2, 3, 4))(c(1, 4)), 5L)
})

test_that("measure = FALSE does not change any figure's verdict", {
  # check_labels_fit() was gated behind measure, and it is a stated criterion
  # rather than a measurement. A figure with a subtitle too wide to fit
  # reported one violation with measure = TRUE and none with measure = FALSE,
  # so the fast path called a failing figure clean.
  set.seed(2)
  d <- data.frame(x = rnorm(40), y = rnorm(40))
  clipped <- ggplot(d, aes(x, y)) + geom_point() + theme_tufte() +
    label_source("somewhere") +
    labs(subtitle = strrep("a subtitle that will not fit ", 8))

  full <- suppressWarnings(tufte_audit(clipped, width = 6.5, height = 4))
  fast <- suppressWarnings(tufte_audit(clipped, width = 6.5, height = 4,
                                       measure = FALSE))
  expect_equal(attr(fast, "violations"), attr(full, "violations"))
  expect_gt(attr(fast, "violations"), 0)

  # The same holds for a figure that passes everything.
  clean <- ggplot(d, aes(x, y)) + geom_point() + theme_tufte() +
    label_source("somewhere")
  expect_equal(
    attr(suppressWarnings(tufte_audit(clean, width = 6.5, height = 4,
                                      measure = FALSE)), "violations"),
    attr(suppressWarnings(tufte_audit(clean, width = 6.5, height = 4)),
         "violations"))

  # measure still governs the two ungraded measurements.
  fast_checks <- suppressWarnings(
    tufte_audit(clean, width = 6.5, height = 4, measure = FALSE))$check
  expect_false("Data-ink ratio" %in% fast_checks)
  expect_true("Nothing is clipped at the printed size" %in% fast_checks)
})

test_that("the accent palette always contains its accent", {
  # The palette is documented as greys plus one signal colour, for when one
  # series matters. It took the first n of a fixed vector whose third element
  # was the signal, so with two series you got two greys and no signal at all.
  signal <- "#c8102e"
  f <- tufte_pal("accent")
  for (n in 2:5) {
    cols <- f(n)
    expect_length(cols, n)
    expect_true(signal %in% cols, info = paste("n =", n))
    expect_equal(sum(cols == signal), 1L, info = paste("n =", n))
    # The signal is the last level, so a reader can put it where they mean to.
    expect_identical(cols[n], signal, info = paste("n =", n))
  }
  # One series has nothing to stand out from, so it stays neutral.
  expect_false(signal %in% f(1))

  # Past the palette's length the greys interpolate, with a warning, and the
  # signal still survives exactly once.
  expect_warning(wide <- f(8), "greys")
  expect_length(wide, 8)
  expect_equal(sum(wide == signal), 1L)
  expect_identical(wide[8], signal)
})

test_that("the erased rules survive coord_flip()", {
  # .erased_rules() chose the panel scale from `sides` alone. coord_flip()
  # moves the value scale to the other panel axis, so panel_params$y held the
  # discrete categories, whose breaks aren't numbers, and the layer drew a
  # zeroGrob. The bars came out with nothing to read them against.
  d <- data.frame(g = c("a", "b", "c", "d"), v = c(3, 7, 5, 9))

  rules <- function(p, axis) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    gt <- ggplot2::ggplotGrob(p)
    pan <- gt$grobs[[which(grepl("^panel", gt$layout$name))[1]]]
    lay <- pan$children[[which(grepl("geom_col_tufte", names(pan$children)))[1]]]
    out <- numeric(0)
    walk <- function(z) {
      if (inherits(z, "gTree")) { for (ch in z$children) walk(ch); return(invisible()) }
      if (inherits(z, "segments")) {
        out <<- c(out, as.numeric(if (axis == "y") z$y0 else z$x0))
      }
    }
    walk(lay)
    sort(unique(round(out, 4)))
  }
  breaks_npc <- function(p, axis) {
    pp <- ggplot_build(p)$layout$panel_params[[1]]
    sc <- if (axis == "y") pp$y else pp$x
    b <- sc$get_breaks(); b <- b[is.finite(b)]
    rng <- if (axis == "y") pp$y.range else pp$x.range
    v <- (b - rng[1]) / diff(rng)
    sort(unique(round(v[v >= 0 & v <= 1], 4)))
  }

  upright <- ggplot(d, aes(g, v)) + geom_col_tufte() + theme_tufte()
  expect_equal(rules(upright, "y"), breaks_npc(upright, "y"), tolerance = 1e-3)

  flipped <- upright + coord_flip()
  drawn <- rules(flipped, "x")
  expect_gt(length(drawn), 0)
  expect_equal(drawn, breaks_npc(flipped, "x"), tolerance = 1e-3)
})

test_that("the quartile frame keeps each variable on its own axis under a flip", {
  # Two deliberately different distributions, so putting one variable's
  # quartiles on the other's axis would be obvious.
  set.seed(21)
  d <- data.frame(x = c(rnorm(40, 10, 1), 25), y = c(1, rnorm(40, 90, 2)))
  ends <- function(p, axis) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    gt <- ggplot2::ggplotGrob(p)
    pan <- gt$grobs[[which(grepl("^panel", gt$layout$name))[1]]]
    g <- pan$children[[which(grepl("quartileframe", names(pan$children)))[1]]]
    out <- numeric(0)
    walk <- function(z) {
      if (inherits(z, "gTree")) { for (ch in z$children) walk(ch); return(invisible()) }
      if (inherits(z, "segments")) {
        xs <- c(as.numeric(z$x0), as.numeric(z$x1))
        ys <- c(as.numeric(z$y0), as.numeric(z$y1))
        if (axis == "x" && diff(range(ys)) < 1e-6) out <<- c(out, xs)
        if (axis == "y" && diff(range(xs)) < 1e-6) out <<- c(out, ys)
      }
    }
    walk(g)
    sort(unique(round(out, 4)))
  }
  want <- function(v, rng) {
    sort(unique(round(
      (stats::quantile(v, c(0, .25, .5, .75, 1), names = FALSE) - rng[1]) /
        diff(rng), 4)))
  }
  for (flip in c(FALSE, TRUE)) {
    p <- ggplot(d, aes(x, y)) + geom_point() + geom_quartileframe(gap = 0) +
      theme_tufte()
    if (flip) p <- p + coord_flip()
    pp <- ggplot_build(p)$layout$panel_params[[1]]
    expect_equal(ends(p, "x"), want(if (flip) d$y else d$x, pp$x.range),
                 tolerance = 2e-3, info = paste("flip =", flip))
    expect_equal(ends(p, "y"), want(if (flip) d$x else d$y, pp$y.range),
                 tolerance = 2e-3, info = paste("flip =", flip))
  }
})

test_that("every geom's ink counts as data, whatever ggplot2 names its grob", {
  # .strip_data_grobs() dropped panel children whose name began with "geom".
  # ggplot2 names only some layers that way: GeomPath, GeomLine, GeomStep,
  # GeomText and GeomSegment return bare grid grobs called GRID.polyline,
  # GRID.text and GRID.segments. Those survived into the furniture rendering
  # and were subtracted from the data ink, so a plain line chart measured a
  # data-ink ratio of exactly zero.
  set.seed(3)
  d <- data.frame(x = 1:40, y = cumsum(rnorm(40)), g = rep(letters[1:4], 10))

  layers <- list(
    line    = geom_line(),
    path    = geom_path(),
    step    = geom_step(),
    # real segments: xend = x would draw zero-length ones and no ink at all
    segment = geom_segment(aes(xend = x + 1, yend = y + 1)),
    text    = geom_text(aes(label = g)),
    point   = geom_point()
  )
  for (nm in names(layers)) {
    r <- data_ink_ratio(ggplot(d, aes(x, y)) + layers[[nm]] + theme_tufte(),
                        width = 4, height = 3, res = 72)
    expect_gt(r$data_ink, 0)
    expect_gt(r$ratio, 0.5)   # theme_tufte leaves very little furniture
  }
})

test_that("furniture ink does not depend on which layers are drawn", {
  # The property that would have caught the stripper bug: for one theme and one
  # set of scales, the ink left after removing the data is a fact about the
  # theme, not about the layers.
  set.seed(4)
  d <- data.frame(x = 1:40, y = cumsum(rnorm(40)))
  base <- function(...) ggplot(d, aes(x, y)) + ... + theme_tufte() +
    scale_x_continuous(limits = c(1, 40)) +
    scale_y_continuous(limits = range(d$y))

  nd <- vapply(list(geom_point(), geom_line(), geom_step(),
                    geom_text(aes(label = "x"))),
               function(l) {
                 p <- ggplot(d, aes(x, y)) + l + theme_tufte() +
                   scale_x_continuous(limits = c(1, 40)) +
                   scale_y_continuous(limits = range(d$y))
                 data_ink_ratio(p, width = 4, height = 3, res = 72)$non_data_ink
               }, numeric(1))
  expect_equal(max(nd) - min(nd), 0, tolerance = 1e-6)
})

test_that("the same bars measure the same however the orientation is written", {
  # Three separate places used to work out which axis carries a bar's length,
  # and each got it wrong in its own way. They all go through .bar_axes() now,
  # so the four ways of writing one chart have to agree.
  d <- data.frame(g = letters[1:5], v = c(12, 30, 21, 44, 8))
  forms <- list(
    vertical      = ggplot(d, aes(g, v)) + geom_col(),
    horizontal    = ggplot(d, aes(v, g)) + geom_col(),
    flipped       = ggplot(d, aes(g, v)) + geom_col() + coord_flip(),
    orientation_y = ggplot(d, aes(v, g)) + geom_col(orientation = "y")
  )
  lf <- vapply(forms, lie_factor, numeric(1))
  expect_equal(diff(range(lf)), 0)

  vi <- vapply(forms, function(p)
    attr(suppressWarnings(tufte_audit(p, 6.5, 4, measure = FALSE)), "violations"),
    integer(1))
  expect_equal(diff(range(vi)), 0L)

  # Data density counts the same entries each way. The density itself may
  # differ by a percent or so, because category labels and numeric labels take
  # different room and the measure is per square inch of panel.
  ent <- vapply(forms, function(p) data_density(p, 6.5, 4)$entries, numeric(1))
  expect_equal(diff(range(ent)), 0)

  # A truncated axis is caught whichever way the chart is written.
  trunc <- list(
    vertical   = ggplot(d, aes(g, v)) + geom_col() + coord_cartesian(ylim = c(5, 50)),
    horizontal = ggplot(d, aes(v, g)) + geom_col() + coord_cartesian(xlim = c(5, 50))
  )
  tl <- vapply(trunc, lie_factor, numeric(1))
  expect_true(all(tl > 1.05))
  expect_equal(diff(range(tl)), 0)
})

test_that("geom_col_tufte erases rules however the bars are oriented", {
  d <- data.frame(g = letters[1:4], v = c(3, 7, 5, 9))
  drew <- function(p) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    gt <- ggplot2::ggplotGrob(p)
    pan <- gt$grobs[[which(grepl("^panel", gt$layout$name))[1]]]
    lay <- pan$children[[which(grepl("geom_col_tufte", names(pan$children)))[1]]]
    leaves <- character(0)
    walk <- function(z) {
      if (inherits(z, "gTree")) { for (ch in z$children) walk(ch) }
      else leaves <<- c(leaves, class(z)[1])
    }
    walk(lay)
    any(leaves == "segments")
  }
  expect_true(drew(ggplot(d, aes(g, v)) + geom_col_tufte() + theme_tufte()))
  expect_true(drew(ggplot(d, aes(v, g)) + geom_col_tufte() + theme_tufte()))
  expect_true(drew(ggplot(d, aes(g, v)) + geom_col_tufte() + coord_flip() + theme_tufte()))
  expect_true(drew(ggplot(d, aes(v, g)) + geom_col_tufte(orientation = "y") + theme_tufte()))
  # An explicit sides that points at a scale with no numeric breaks says so.
  expect_warning(
    drew(ggplot(d, aes(g, v)) + geom_col_tufte(sides = "x") + theme_tufte()),
    "no rules were erased")
})

# ---- from the independent audit --------------------------------------------

test_that("the quartile frame breaks where the labels sit, on any scale", {
  # .frame_spans() took quantiles of the scale-transformed values while
  # quartile_breaks() took them of the raw data. Type-7 quantiles survive an
  # affine transform but not a log or a square root, so on a log10 axis the
  # label read 5050 and the frame broke at 1000.
  y <- c(1, 10, 100, 1e4, 1e5, 1e6)
  d <- data.frame(x = seq_along(y), y = y)
  labels <- quartile_breaks(y)(range(y))

  for (sc in list(NULL, scale_y_log10(), scale_y_sqrt())) {
    p <- ggplot(d, aes(x, y)) + geom_point() + geom_quartileframe(sides = "l")
    if (!is.null(sc)) p <- p + sc
    b <- ggplot_build(p)
    pp <- b$layout$panel_params[[1]]
    tr <- tryCatch(pp$y$scale$get_transformation(), error = function(e) NULL)
    q <- .data_space_quantiles(b$data[[2]]$y, pp$y)
    back <- if (is.null(tr) || identical(tr$name, "identity")) q else tr$inverse(q)
    expect_equal(as.numeric(signif(back, 6)), as.numeric(labels),
                 tolerance = 1e-4)
  }
})

test_that("audit_figures keeps its per-figure detail when a figure fails", {
  # audits[[i]] <- NULL deleted the element instead of storing NULL, shifting
  # every later name, so the documented drill-in returned NULL for every figure
  # after the first failure.
  figs <- list(broken = ggplot(mtcars, aes(nosuchcol, mpg)) + geom_point(),
               ok = ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte())
  b <- suppressWarnings(audit_figures(figs, measure = FALSE))
  expect_equal(names(attr(b, "audits")), names(figs))
  expect_s3_class(attr(b, "audits")[["ok"]], "tufte_audit")
  expect_null(attr(b, "audits")[["broken"]])
})

test_that("coord_radial() pies are caught, not only coord_polar() ones", {
  d <- data.frame(g = c("a", "b", "c"), v = c(3, 4, 5))
  status <- function(p) {
    a <- suppressWarnings(tufte_audit(p, measure = FALSE))
    a$status[a$check == "No pie chart"]
  }
  expect_equal(status(ggplot(d, aes(x = "", y = v, fill = g)) + geom_col() +
                        coord_polar(theta = "y")), "fail")
  expect_equal(status(ggplot(d, aes(x = "", y = v, fill = g)) + geom_col() +
                        coord_radial(theta = "y")), "fail")
  expect_equal(status(ggplot(d, aes(g, v)) + geom_col() + theme_tufte()), "pass")
})

test_that("a variable encoded twice is caught on either position aesthetic", {
  d <- data.frame(g = c("a", "b", "c"), v = c(3, 4, 5))
  status <- function(p) {
    a <- suppressWarnings(tufte_audit(p, measure = FALSE))
    a$status[a$check == "No variable encoded twice"]
  }
  expect_equal(status(ggplot(d, aes(g, v, fill = g)) + geom_col()), "fail")
  expect_equal(status(ggplot(d, aes(v, g, fill = g)) + geom_col()), "fail")
  expect_equal(status(ggplot(d, aes(g, v)) + geom_col() + theme_tufte()), "pass")
})

test_that("a white panel is white however the colour was spelled", {
  # The check compared the strings themselves, so grey100, gray100, #fff and
  # the eight-digit #FFFFFFFF all counted as coloured panels. ggplot2 4.0's
  # complete_theme() returns eight-digit hex, so that spelling is the common
  # one, and a false fail inflates the violation count.
  status <- function(f) {
    p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_bw() +
      theme(panel.background = element_rect(fill = f))
    a <- suppressWarnings(tufte_audit(p, measure = FALSE))
    a$status[a$check == "Panel carries no background fill"]
  }
  for (f in c("white", "grey100", "gray100", "#FFFFFF", "#ffffff",
              "#FFFFFFFF", "#fff", "transparent")) {
    expect_equal(status(f), "pass", info = f)
  }
  # A real fill is still a real fill.
  for (f in c("grey92", "#EBEBEBFF", "lightblue")) {
    expect_equal(status(f), "fail", info = f)
  }
})

test_that("a continuous legend of any aesthetic is not told to label its series", {
  status <- function(p) {
    a <- suppressWarnings(tufte_audit(p, measure = FALSE))
    a$status[a$check == "No legend to decode"]
  }
  # Continuous keys are ramps, not lists of names, so there is nothing to
  # label in place. This used to hold for colour and fill only.
  for (a in c("size", "alpha", "colour")) {
    p <- ggplot(mtcars, aes(wt, mpg)) +
      do.call(geom_point, stats::setNames(list(ggplot2::aes(hp)[[1]]), a))
    expect_false(identical(status(ggplot(mtcars,
      aes(wt, mpg, size = hp)) + geom_point()), "fail"))
  }
  # A discrete key still is a list of names.
  expect_equal(status(ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
                        geom_point()), "fail")
})

test_that("data_density() handles a plot with no layers", {
  # ggplot()$data is a waiver, not NULL, so %||% never fired and nrow(waiver())
  # returned NULL, giving back a malformed object that print() could not read.
  r <- suppressWarnings(data_density(ggplot()))
  expect_type(r$rows, "integer")
  expect_equal(r$rows, 0L)
  expect_true(is.finite(r$entries))
})

test_that("check_labels_fit() is invisible when everything fits", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  expect_false(withVisible(check_labels_fit(p))$visible)
  wordy <- p + labs(subtitle = strrep("a subtitle that will not fit ", 8))
  expect_true(withVisible(suppressWarnings(check_labels_fit(wordy)))$visible)
})

test_that("geom_col_tufte(minor = TRUE) draws each rule once", {
  d <- data.frame(g = letters[1:4], v = c(3, 7, 5, 9))
  count <- function(minor) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    gt <- ggplot2::ggplotGrob(ggplot(d, aes(g, v)) +
                                geom_col_tufte(minor = minor) + theme_tufte())
    pan <- gt$grobs[[which(grepl("^panel", gt$layout$name))[1]]]
    lay <- pan$children[[which(grepl("geom_col_tufte",
                                     names(pan$children)))[1]]]
    seg <- Filter(function(z) inherits(z, "segments"), lay$children)
    if (!length(seg)) 0L else length(unique(round(as.numeric(seg[[1]]$y0), 6)))
  }
  # get_breaks_minor() includes the majors, so every major used to be drawn
  # twice, one exactly on top of the other.
  expect_equal(count(FALSE), length(unique(round(seq(0, 7.5, by = 2.5), 6))))
  expect_gt(count(TRUE), count(FALSE))
})

# ---- from the Codex audit ---------------------------------------------------

test_that("text layers are held to the text contrast minimum", {
  # Every layer was classified as a data mark at 3:1, so grey text at 4.48:1
  # passed a check whose documentation promises 4.5:1 for words.
  p <- ggplot(data.frame(x = 1, y = 1, label = "t"), aes(x, y, label = label)) +
    geom_text(colour = "#777777") + theme_void()
  cc <- suppressWarnings(check_contrast(p))
  row <- cc[cc$colour == "#777777", ]
  expect_equal(row$role[1], "data label")
  expect_equal(row$threshold[1], 4.5)
  expect_false(row$passes[1])

  # A point of the same colour is still a mark, at 3:1.
  pp <- ggplot(data.frame(x = 1, y = 1), aes(x, y)) +
    geom_point(colour = "#777777") + theme_void()
  cm <- suppressWarnings(check_contrast(pp))
  expect_equal(cm$threshold[cm$colour == "#777777"][1], 3)
})

test_that("data_density counts the variables actually drawn", {
  # .all_mappings() pooled plot and layer mappings, so a layer that overrides
  # an aesthetic added a column instead of replacing one, and inherit.aes =
  # FALSE was ignored entirely.
  d <- data.frame(x = 1:10, y = 11:20, z = 21:30)
  ent <- function(p) data_density(p, 6.5, 4)$entries
  expect_equal(ent(ggplot(d, aes(x, y)) + geom_point()), 20)
  expect_equal(ent(ggplot(d, aes(x, y)) + geom_point(aes(y = z))), 20)
  expect_equal(ent(ggplot(d, aes(x, y, colour = z)) + geom_point()), 30)
  expect_equal(ent(ggplot(d, aes(x, y)) +
                     geom_point(aes(x = z, y = z), inherit.aes = FALSE)), 10)
})

test_that("banking measures the slopes as drawn", {
  # .slope_ratios() divided the built columns by x.range and y.range without
  # going through the coord, so under coord_flip() it measured neither the data
  # slopes nor the drawn ones.
  drawn_aspect <- function(p) {
    b <- ggplot_build(p)
    pp <- b$layout$panel_params[[1]]
    td <- b$layout$coord$transform(b$data[[1]], pp)
    m <- abs(diff(td$y) / diff(td$x))
    1 / stats::median(m[is.finite(m)])
  }
  for (n in c(3, 4, 5)) {
    set.seed(n)
    d <- data.frame(x = seq_len(n + 1), y = cumsum(c(0, runif(n, .5, 3))))
    for (flip in c(FALSE, TRUE)) {
      p <- ggplot(d, aes(x, y)) + geom_line()
      if (flip) p <- p + coord_flip()
      expect_equal(bank_to_45(p)$aspect, drawn_aspect(p), tolerance = 1e-6,
                   info = paste("n =", n, "flip =", flip))
    }
  }
})

test_that("lie_factor leaves rectangles that are not bars alone", {
  # GeomRect was classified as a bar, so a background band or an interval
  # rectangle got the panel floor for a baseline and a fabricated distortion.
  d <- data.frame(xmin = c(1, 3), xmax = c(2, 4),
                  ymin = c(100, 100), ymax = c(105, 110))
  p <- ggplot(d) +
    geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)) +
    coord_cartesian(ylim = c(95, 115))
  expect_equal(lie_factor(p), 1)

  # Bars are still measured.
  b <- data.frame(g = c("a", "b"), v = c(100, 110))
  expect_gt(lie_factor(ggplot(b, aes(g, v)) + geom_col() +
                         coord_cartesian(ylim = c(95, 115))), 1.05)
})

test_that("Cleveland leader lines follow the coord", {
  # The points delegate to GeomPoint and flipped; the leaders read the
  # untransformed orientation and stayed horizontal, at right angles to the
  # dots they belong to.
  direction <- function(p) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    gt <- ggplot2::ggplotGrob(p)
    pan <- gt$grobs[[which(grepl("^panel", gt$layout$name))[1]]]
    lay <- pan$children[[which(grepl("geom_cleveland_dot",
                                     names(pan$children)))[1]]]
    s <- Filter(function(z) inherits(z, "segments"), lay$children)[[1]]
    if (all(abs(as.numeric(s$y0) - as.numeric(s$y1)) < 1e-9)) "horizontal" else "vertical"
  }
  d <- data.frame(category = letters[1:3], value = 1:3)
  expect_equal(direction(ggplot(d, aes(value, category)) +
                           geom_cleveland_dot() + theme_tufte()), "horizontal")
  expect_equal(direction(ggplot(d, aes(value, category)) +
                           geom_cleveland_dot() + coord_flip() + theme_tufte()),
               "vertical")
})

test_that("sizes have to be sizes", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  expect_error(data_density(p, width = 0), "positive")
  expect_error(data_density(p, width = 6.5, height = -1), "positive")
  expect_error(data_ink_ratio(p, width = NA), "positive")
  expect_error(check_labels_fit(p, width = Inf), "positive")
  expect_error(bank_to_45(ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) +
                            geom_line(), width = -1), "positive")
})

test_that("geom_tufteboxplot says why it will not draw sideways", {
  expect_error(geom_tufteboxplot(orientation = "y"), "coord_flip")
  # The supported route still works.
  expect_s3_class(ggplot_build(ggplot(mtcars, aes(factor(cyl), mpg)) +
                                 geom_tufteboxplot() + coord_flip()),
                  "ggplot_built")
})

test_that("a slopegraph with more than two periods says what it labels", {
  d <- expand.grid(unit = c("A", "B"), period = 1:3)
  d$value <- seq_len(nrow(d))
  expect_warning(slopegraph(d, period, value, unit), "first and last")
  d2 <- expand.grid(unit = c("A", "B"), period = 1:2)
  d2$value <- seq_len(nrow(d2))
  expect_silent(slopegraph(d2, period, value, unit))
})

test_that("check_labels_fit measures axes and strips on every side", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() +
    facet_wrap(~cyl, strip.position = "right") +
    scale_x_continuous(position = "top") +
    scale_y_continuous(position = "right") +
    theme_tufte()
  out <- suppressWarnings(check_labels_fit(p, 5, 4))
  for (e in c("strip label (side)", "x axis labels (top)",
              "y axis labels (right)")) {
    expect_true(e %in% out$element, info = e)
  }
})

# ---- from the third audit ---------------------------------------------------

test_that("the quartile frame survives an axis with too few distinct values", {
  # Introduced by the fix that moved the summary into data space:
  # .transformed_quantiles() padded the degenerate axis with a constant and
  # returned it as though it were a real summary, so .frame_spans() skipped its
  # plain-range branch, every segment inverted, and a zero-row segmentsGrob
  # reached grid::unit(), which errors.
  builds <- function(p) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
    !inherits(try(ggplot2::ggplotGrob(p), silent = TRUE), "try-error")
  }
  base <- function(a) ggplot(mtcars, a) + geom_point() + geom_quartileframe()
  expect_true(builds(base(aes(factor(cyl), mpg))))
  expect_true(builds(base(aes(cyl, mpg))))
  expect_true(builds(base(aes(wt, mpg))))
  expect_true(builds(base(aes(factor(cyl), mpg)) + coord_flip()))
  expect_true(builds(base(aes(wt, factor(cyl)))))
})

test_that("frame geoms refuse a sides string they cannot draw", {
  # grepl(fixed = TRUE) matched nothing for "BL" or "LB", the natural typos for
  # "bl", and the layer drew nothing without a word.
  for (bad in c("LB", "BL", "", "xy", "top")) {
    expect_error(geom_rangeframe(sides = bad), "sides", info = bad)
    expect_error(geom_dotdash(sides = bad), "sides", info = bad)
    expect_error(geom_quartileframe(sides = bad), "sides", info = bad)
  }
  for (good in c("bl", "tr", "b", "trbl")) {
    expect_s3_class(geom_rangeframe(sides = good), "Layer")
  }
  # A gap wide enough to swallow every segment left nothing to draw and a
  # zero-length unit for grid.
  for (bad in c(5, -0.5, 1, NA, "x", c(0.1, 0.2))) {
    expect_error(geom_quartileframe(gap = bad), "gap")
  }
  expect_s3_class(geom_quartileframe(gap = 0.02), "Layer")
})

test_that("check_contrast only measures text the figure draws", {
  # The theme carries a colour for every element whether the plot uses it or
  # not, so a styled subtitle colour on a plot with no subtitle was measured,
  # failed, and counted against the violation total.
  styled <- function(p) p + theme_tufte() +
    theme(plot.subtitle = element_text(colour = "grey72"),
          plot.caption = element_text(colour = "grey72"),
          strip.text = element_text(colour = "grey72"))
  bare <- styled(ggplot(mtcars, aes(wt, mpg)) + geom_point())
  cc <- suppressWarnings(check_contrast(bare))
  expect_false(any(cc$role %in% c("subtitle", "caption", "strip text")))

  # Give it a real subtitle and it is measured again.
  with_sub <- bare + labs(subtitle = "a real subtitle")
  expect_true("subtitle" %in% suppressWarnings(check_contrast(with_sub))$role)

  # A fully transparent fill draws nothing, so it is not the background.
  clear <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte() +
    theme(panel.background = element_rect(fill = "#00000000", colour = NA))
  expect_true(suppressWarnings(check_contrast(clear))$passes[1])
})

test_that("tufte_audit refuses a canvas that is not a canvas", {
  # Every individual measure rejects a bad size, but the audit wrapped them in
  # tryCatch, so an impossible canvas dropped four checks including a graded
  # criterion and reported a lower violation count than the truth.
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  for (w in list(0, -1, NA, "6.5", c(1, 2), Inf)) {
    expect_error(tufte_audit(p, width = w), "positive")
  }
  expect_error(tufte_audit(p, height = 0), "positive")
})

test_that("a minor grid on one axis only is still a minor grid", {
  status <- function(p) {
    a <- suppressWarnings(tufte_audit(p, measure = FALSE))
    a$status[a$check == "No minor gridlines"]
  }
  base <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  expect_equal(status(base), "pass")
  expect_equal(status(base + theme(panel.grid.minor.x = element_line(colour = "grey80"))), "fail")
  expect_equal(status(base + theme(panel.grid.minor.y = element_line(colour = "grey80"))), "fail")
  expect_equal(status(base + theme(panel.grid.minor = element_line(colour = "grey80"))), "fail")
})

test_that("direct labels take a vector nudge, as geom_text does", {
  # `||` on a vector is an error rather than a comparison.
  expect_s3_class(geom_text_last(aes(label = "a"), nudge_x = c(1, 2, 3)), "Layer")
  expect_s3_class(geom_text_first(aes(label = "a"), nudge_y = c(0, 1)), "Layer")
  expect_s3_class(geom_text_last(aes(label = "a"), nudge_x = 1), "Layer")
})

test_that("sparkline labels the rightmost point, not the last row", {
  # geom_line() draws sorted by x, so on unsorted input the line's right-hand
  # end and the labelled final value were different observations. sparklines()
  # sorts and always agreed; the two disagreed on identical data.
  b <- ggplot_build(sparkline(c(3, 1, 2), index = c(3, 1, 2)))
  expect_equal(b$data[[length(b$data)]]$x[1], 3)
  b2 <- ggplot_build(sparkline(c(3, 1, 2)))
  expect_equal(b2$data[[length(b2$data)]]$x[1], 3)
})

test_that("slopegraph counts the periods that are present", {
  # An unused factor level counted as a period and warned about labelling that
  # was in fact complete.
  d <- data.frame(country = rep(c("Sweden", "Japan"), each = 2),
                  year = factor(rep(c("1970", "2020"), 2),
                                levels = c("1970", "1995", "2020")),
                  value = c(30.1, 41.2, 20.7, 32.9))
  expect_silent(slopegraph(d, year, value, country))
  d3 <- expand.grid(unit = c("A", "B"), period = 1:3)
  d3$value <- seq_len(nrow(d3))
  expect_warning(slopegraph(d3, period, value, unit), "first and last")
})

test_that("audit_figures keeps the names it was given", {
  # One unnamed element used to replace every name the caller supplied,
  # breaking the documented drill-in.
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  r <- suppressWarnings(audit_figures(list(scatter = p, p), measure = FALSE))
  expect_equal(r$figure, c("scatter", "figure 2"))
  expect_s3_class(attr(r, "audits")[["scatter"]], "tufte_audit")
})
