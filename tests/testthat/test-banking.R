library(ggplot2)

test_that("a diagonal line across the panel is already banked", {
  # A line running corner to corner sits at 45 degrees when the panel is
  # square, so the recommended aspect ratio is 1.
  d <- data.frame(t = 1:100, v = seq(0, 1, length.out = 100))
  b <- bank_to_45(ggplot(d, aes(t, v)) + geom_line())
  expect_s3_class(b, "tufte_banking")
  expect_equal(b$aspect, 1, tolerance = 1e-6)
  expect_equal(b$height, b$width * b$aspect)
})

test_that("banking matches the analytic answer for a sine wave", {
  # Slopes are proportional to |cos|, whose median over a whole number of
  # periods is cos(pi/4). The banked aspect is the reciprocal of the median
  # scaled slope, so it can be predicted exactly.
  n <- 2001
  periods <- 3
  d <- data.frame(t = seq_len(n),
                  v = sin(seq(0, periods * 2 * pi, length.out = n)))
  p <- ggplot(d, aes(t, v)) + geom_line()

  built <- ggplot_build(p)
  rng <- tufter:::.panel_ranges(built)
  amplitude_slope <- periods * 2 * pi / (n - 1)
  scaled <- (amplitude_slope / diff(rng$y)) / (1 / diff(rng$x))
  expected <- 1 / (scaled * cos(pi / 4))

  expect_equal(bank_to_45(p)$aspect, expected, tolerance = 0.02)
})

test_that("a steeper series is banked to a shorter panel", {
  gentle <- data.frame(t = 1:100, v = sin(seq(0, 2 * pi, length.out = 100)))
  steep <- data.frame(t = 1:100, v = sin(seq(0, 20 * pi, length.out = 100)))
  a_gentle <- bank_to_45(ggplot(gentle, aes(t, v)) + geom_line())$aspect
  a_steep <- bank_to_45(ggplot(steep, aes(t, v)) + geom_line())$aspect
  expect_lt(a_steep, a_gentle)
})

test_that("both methods agree in order of magnitude", {
  d <- data.frame(t = 1:200, v = cumsum(rnorm(200)))
  p <- ggplot(d, aes(t, v)) + geom_line()
  m <- bank_to_45(p, method = "median_slope")$aspect
  o <- bank_to_45(p, method = "average_orientation")$aspect
  expect_gt(o / m, 0.25)
  expect_lt(o / m, 4)
})

test_that("average_orientation puts the mean orientation at 45 degrees", {
  d <- data.frame(t = 1:300, v = cumsum(rnorm(300)))
  p <- ggplot(d, aes(t, v)) + geom_line()
  b <- bank_to_45(p, method = "average_orientation", weighted = FALSE)

  segs <- tufter:::.slope_ratios(p)
  expect_equal(mean(atan(b$aspect * segs$m)), pi / 4, tolerance = 1e-4)
})

test_that("banking reads paths, steps and smooths as well as lines", {
  d <- data.frame(t = 1:60, v = cumsum(rnorm(60)))
  for (layer in list(geom_path(), geom_step(),
                     geom_smooth(se = FALSE, formula = y ~ x, method = "loess"))) {
    p <- ggplot(d, aes(t, v)) + layer
    expect_s3_class(suppressWarnings(bank_to_45(p)), "tufte_banking")
  }
})

test_that("banking refuses a plot with no slopes", {
  expect_error(
    bank_to_45(ggplot(mtcars, aes(wt, mpg)) + geom_point()),
    "no line segments"
  )
  flat <- data.frame(t = 1:10, v = rep(3, 10))
  expect_error(bank_to_45(ggplot(flat, aes(t, v)) + geom_line()), "flat")
})

test_that("banking validates its input and prints", {
  expect_error(bank_to_45(mtcars), "must be a ggplot")
  d <- data.frame(t = 1:50, v = cumsum(rnorm(50)))
  b <- bank_to_45(ggplot(d, aes(t, v)) + geom_line())
  expect_message(print(b), "Banking")
})

test_that("the audit banks when there are lines and stays quiet otherwise", {
  d <- data.frame(t = 1:200, v = sin(seq(0, 20 * pi, length.out = 200)))
  p <- ggplot(d, aes(t, v)) + geom_line() + theme_tufte()

  # A tall panel for a very steep series should be flagged.
  tall <- tufte_audit(p, width = 4, height = 8, measure = FALSE)
  expect_equal(tall$status[tall$check == "Slopes are readable at this shape"],
               "fail")

  # A scatterplot has no slopes, so the check does not appear at all.
  none <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                      measure = FALSE)
  expect_false("Slopes are readable at this shape" %in% none$check)
})
