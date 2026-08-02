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

test_that("a mostly vertical path is refused rather than silently mangled", {
  d <- data.frame(x = rep(0, 20), y = seq_len(20))
  p <- ggplot(d, aes(x, y)) + geom_path()
  expect_error(bank_to_45(p), "vertical")
  # The orientation method tolerates verticals and should still answer.
  expect_s3_class(bank_to_45(p, method = "average_orientation"),
                  "tufte_banking")
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
