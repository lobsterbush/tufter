library(ggplot2)

render <- function(p) {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f))
  suppressWarnings(ggsave(f, p, width = 5, height = 3, dpi = 72))
  file.exists(f) && file.size(f) > 0
}

test_that("themes return theme objects and strip what they claim to", {
  th <- theme_tufte()
  expect_s3_class(th, "theme")
  expect_true(inherits(th$panel.grid.major, "element_blank"))
  expect_true(inherits(th$panel.border, "element_blank"))
  expect_false(inherits(th$axis.ticks, "element_blank"))

  expect_true(inherits(theme_tufte(ticks = FALSE)$axis.ticks, "element_blank"))
  expect_false(inherits(theme_tufte(axis_lines = TRUE)$axis.line,
                        "element_blank"))
  expect_false(inherits(theme_tufte(grid = "y")$panel.grid.major.y,
                        "element_blank"))
  expect_s3_class(theme_sparkline(), "theme")
  expect_s3_class(theme_slopegraph(), "theme")
})

test_that("palettes return the requested number of colours", {
  for (pal in c("grey", "accent", "muted", "divergent")) {
    cols <- tufte_pal(pal)(4)
    expect_length(cols, 4)
    expect_true(all(grepl("^#", cols)))
  }
  expect_length(tufte_pal("grey")(0), 0)
  expect_identical(tufte_colors("muted"), tufte_colours("muted"))
})

test_that("asking a discrete palette for more colours than it has warns", {
  # The warning says what actually happens, that the extra colours are
  # interpolated. It must not assert a number at which hues stop working:
  # Tufte's advice on colour is qualitative and names none.
  expect_warning(tufte_pal("muted")(20), "interpolated")
})

test_that("tufte scales attach to a plot", {
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
  expect_true(render(p + scale_colour_tufte("accent")))
  expect_true(render(p + scale_color_tufte("grey", reverse = TRUE)))
  expect_true(render(
    ggplot(mtcars, aes(factor(cyl), fill = factor(gear))) + geom_bar() +
      scale_fill_tufte("muted")
  ))
  expect_true(render(
    ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point() +
      scale_colour_tufte_c()
  ))
  expect_true(render(
    ggplot(mtcars, aes(wt, mpg, fill = hp)) +
      geom_point(shape = 21) + scale_fill_tufte_c(reverse = TRUE)
  ))
})

test_that("quartile_breaks returns the five-number summary", {
  b <- quartile_breaks(mtcars$mpg)(range(mtcars$mpg))
  expect_equal(length(b), 5)
  expect_equal(min(b), signif(min(mtcars$mpg), 3))
  expect_equal(max(b), signif(max(mtcars$mpg), 3))

  # With no vector supplied it works from the scale limits. Two numbers are not
  # a five-number summary, and the frame draws a plain range for them, so the
  # axis gets the two ends. It used to print a label at 5, standing for a
  # quartile nothing had computed and sitting where the frame has no break.
  expect_equal(quartile_breaks()(c(0, 10)), c(0, 10))
  expect_length(quartile_breaks()(numeric(0)), 0)
})

test_that("quartile_breaks keeps all five unless thinning is asked for", {
  # The default must be the whole five-number summary: the spacing at which
  # labels collide depends on font and figure size, which a breaks function
  # cannot see, so no default may assume it.
  all_five <- quartile_breaks(mtcars$wt)(range(mtcars$wt))
  expect_length(all_five, 5)

  # mtcars$wt has a median and Q3 close enough to overprint at most sizes, so
  # an explicit min_gap drops one.
  thinned <- quartile_breaks(mtcars$wt, min_gap = 0.12)(range(mtcars$wt))
  expect_lt(length(thinned), length(all_five))
  # The extremes always survive, because they are what the frame reports.
  expect_equal(range(thinned), range(all_five))
  span <- diff(range(all_five))
  expect_true(all(diff(thinned) >= 0.12 * span - 1e-9))
})

test_that("facet_tufte facets, and objects to free scales", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_tufte(~ cyl)
  expect_true(render(p))
  expect_warning(facet_tufte(~ cyl, scales = "free_y"), "comparison")
})

test_that("sparkline builds from a bare vector", {
  set.seed(1)
  p <- sparkline(cumsum(rnorm(50)))
  expect_s3_class(p, "ggplot")
  expect_true(render(p))
  expect_true(render(sparkline(cumsum(rnorm(50)), band = NULL, label = FALSE)))
})

test_that("sparkline validates its input", {
  expect_error(sparkline(1), "at least two")
  expect_error(sparkline(1:5, index = 1:3), "same length")
  expect_error(sparkline(1:5, band = 0.5), "length-2")
})

test_that("sparklines keeps the order the series arrive in", {
  set.seed(2)
  d <- data.frame(
    t = rep(1:20, 3),
    v = c(cumsum(rnorm(20)), cumsum(rnorm(20)), cumsum(rnorm(20))),
    series = rep(c("Wheat", "Maize", "Barley"), each = 20)
  )
  p <- sparklines(d, t, v, series)
  expect_s3_class(p, "ggplot")
  expect_equal(levels(ggplot_build(p)$data[[2]]$PANEL), c("1", "2", "3"))
  expect_true(render(p))
})

test_that("sparkline_grob returns a grob", {
  set.seed(3)
  expect_s3_class(sparkline_grob(cumsum(rnorm(20))), "gtable")
})

test_that("slopegraph draws and labels both ends", {
  d <- data.frame(
    country = rep(c("Sweden", "Japan", "Chile", "Canada"), each = 2),
    year = rep(c("1970", "2020"), 4),
    value = c(30.1, 41.2, 20.7, 32.9, 22.5, 21.0, 31.0, 38.4)
  )
  p <- slopegraph(d, year, value, country)
  expect_s3_class(p, "ggplot")
  built <- ggplot_build(p)
  # One line layer plus two label layers, four labels each.
  expect_equal(nrow(built$data[[2]]), 4L)
  expect_equal(nrow(built$data[[3]]), 4L)
  expect_true(any(grepl("Sweden", built$data[[2]]$label)))
  expect_true(render(p))
  expect_true(render(slopegraph(d, year, value, country,
                                direction_colour = TRUE, point_size = 1)))
})

test_that("slopegraph needs at least two periods", {
  d <- data.frame(g = c("a", "b"), x = c("1970", "1970"), v = c(1, 2))
  expect_error(slopegraph(d, x, v, g), "at least two periods")
  expect_error(slopegraph(mtcars$wt, x, v, g), "data frame")
})

test_that("colliding slopegraph labels are pushed apart", {
  spread <- tufter:::.spread_labels(c(1, 1, 1), gap = 0.5)
  expect_true(all(diff(sort(spread)) >= 0.5 - 1e-9))
  # The set stays centred on the values it came from.
  expect_equal(mean(spread), 1)
  expect_equal(tufter:::.spread_labels(c(1, 5), gap = 0), c(1, 5))
})

test_that("label_source builds a caption", {
  l <- label_source("Motor Trend, 1974", note = "n = 32.")
  expect_equal(l$caption, "Source: Motor Trend, 1974. n = 32.")
})
