library(ggplot2)

test_that("data_ink_ratio is higher for a Tufte theme than for the default", {
  base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  grey <- data_ink_ratio(base + theme_grey(), width = 4, height = 3, res = 72)
  lean <- data_ink_ratio(base + geom_rangeframe() + theme_tufte(),
                         width = 4, height = 3, res = 72)

  expect_s3_class(grey, "tufte_data_ink")
  expect_gt(lean$ratio, grey$ratio)
  expect_true(grey$ratio >= 0 && grey$ratio <= 1)
  expect_true(lean$ratio >= 0 && lean$ratio <= 1)
})

test_that("data_ink_ratio components add up", {
  di <- data_ink_ratio(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                       width = 4, height = 3, res = 72)
  expect_equal(di$data_ink + di$non_data_ink, di$total_ink)
  expect_equal(di$ratio, di$data_ink / di$total_ink)
})

test_that("a plot with no data layers has essentially no data ink", {
  p <- ggplot(mtcars, aes(wt, mpg)) + theme_tufte()
  di <- data_ink_ratio(p, width = 4, height = 3, res = 72)
  expect_lt(di$ratio, 0.05)
})

test_that("data_ink_ratio rejects things that are not plots", {
  expect_error(data_ink_ratio(mtcars), "must be a ggplot")
})

test_that("lie_factor reproduces Tufte's fuel-economy example", {
  # An 18 to 27.5 mpg change (53 percent) drawn as a line growing from
  # 0.6 to 5.3 inches (783 percent).
  lf <- lie_factor(c(18.0, 27.5), c(0.6, 5.3))
  expect_gt(lf, 14)
  expect_lt(lf, 15)
})

test_that("lie_factor is one when the graphic is honest", {
  expect_equal(lie_factor(c(10, 20), c(1, 2)), 1)
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  expect_equal(lie_factor(ggplot(d, aes(g, v)) + geom_col()), 1)
})

test_that("lie_factor detects a truncated bar baseline", {
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  lf <- lie_factor(
    ggplot(d, aes(g, v)) + geom_col() + coord_cartesian(ylim = c(95, 115))
  )
  expect_gt(lf, 5)
})

test_that("lie_factor returns one for a plot with no bars", {
  expect_equal(lie_factor(ggplot(mtcars, aes(wt, mpg)) + geom_point()), 1)
})

test_that("lie_factor validates its inputs", {
  expect_error(lie_factor(c(1, 2), c(1, 2, 3)), "same length")
  expect_error(lie_factor("a"), "numeric vector or a ggplot")
})

test_that("data_density counts rows times mapped variables", {
  dd <- data_density(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                     width = 4, height = 3)
  expect_s3_class(dd, "tufte_density")
  expect_equal(dd$rows, nrow(mtcars))
  expect_equal(dd$variables, 2L)
  expect_equal(dd$entries, nrow(mtcars) * 2)
  expect_gt(dd$density, 0)
})

test_that("data_density falls when the same plot is drawn larger", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  small <- data_density(p, width = 3, height = 2)
  large <- data_density(p, width = 9, height = 6)
  expect_gt(small$density, large$density)
})

test_that("check_labels_fit passes a plain plot and fails a long subtitle", {
  base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  ok <- check_labels_fit(base, width = 6.5, height = 4)
  expect_true(all(ok$fits))

  long <- base + labs(
    subtitle = paste(rep("A very long subtitle indeed", 8), collapse = " ")
  )
  expect_warning(bad <- check_labels_fit(long, width = 6.5, height = 4),
                 "clipped")
  expect_false(all(bad$fits))
  expect_true("subtitle" %in% bad$element[!bad$fits])
})

test_that("check_labels_fit catches x axis labels that cannot sit side by side", {
  d <- data.frame(
    g = c("Non-post-conflict baseline", "Post-conflict, high intensity",
          "Post-conflict, low intensity"),
    v = 1:3
  )
  expect_warning(
    out <- check_labels_fit(ggplot(d, aes(g, v)) + geom_col(),
                            width = 3, height = 2.5),
    "clipped"
  )
  expect_true(any(grepl("x axis labels", out$element[!out$fits])))
})

test_that("check_labels_fit handles facets and legends", {
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
    geom_point() + facet_wrap(~ gear)
  out <- check_labels_fit(p, width = 8, height = 5)
  expect_true("legend" %in% out$element)
  expect_true("strip label" %in% out$element)
})

test_that("save_tufte writes a file and warns about clipping", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  f <- tempfile(fileext = ".pdf")
  save_tufte(f, p, width = 5, height = 3)
  expect_true(file.exists(f))
  unlink(f)

  wide <- p + labs(
    subtitle = paste(rep("An extremely long subtitle", 10), collapse = " ")
  )
  f2 <- tempfile(fileext = ".png")
  expect_warning(save_tufte(f2, wide, width = 4, height = 3), "clipped")
  expect_error(save_tufte(f2, wide, width = 4, height = 3, strict = TRUE),
               "clipped")
  unlink(f2)
})
