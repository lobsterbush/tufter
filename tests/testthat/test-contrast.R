library(ggplot2)

test_that("contrast_ratio reproduces the WCAG reference values", {
  expect_equal(contrast_ratio("black", "white"), 21, tolerance = 1e-6)
  expect_equal(contrast_ratio("white", "white"), 1, tolerance = 1e-6)
  expect_equal(contrast_ratio("white", "black"), 21, tolerance = 1e-6)
  # Mid grey #767676 is the standard example of the lowest grey that clears
  # 4.5 to 1 against white.
  expect_gt(contrast_ratio("#767676", "white"), 4.5)
  expect_lt(contrast_ratio("#777777", "white"), 4.6)
})

test_that("contrast_ratio is symmetric and vectorised", {
  expect_equal(contrast_ratio("grey30", "white"),
               contrast_ratio("white", "grey30"))
  r <- contrast_ratio(c("grey20", "grey50", "grey80"), "white")
  expect_length(r, 3)
  expect_true(all(diff(r) < 0))
})

test_that("check_contrast passes a normal plot and fails a faint one", {
  ok <- check_contrast(
    ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  )
  expect_true(all(ok$passes))
  expect_true("data mark" %in% ok$role)

  faint <- check_contrast(
    ggplot(mtcars, aes(wt, mpg)) + geom_point(colour = "grey85") + theme_tufte()
  )
  expect_false(all(faint$passes))
  expect_equal(faint$role[!faint$passes], "data mark")
})

test_that("check_contrast accounts for transparency", {
  # A black point at 10 percent opacity on white reads as light grey, and
  # should be measured as what the reader sees rather than as black.
  solid <- check_contrast(
    ggplot(mtcars, aes(wt, mpg)) + geom_point(colour = "black") + theme_tufte()
  )
  faded <- check_contrast(
    ggplot(mtcars, aes(wt, mpg)) +
      geom_point(colour = "black", alpha = 0.1) + theme_tufte()
  )
  solid_mark <- solid$ratio[solid$role == "data mark"]
  faded_mark <- faded$ratio[faded$role == "data mark"]
  expect_equal(solid_mark, 21, tolerance = 1e-6)
  expect_lt(faded_mark, solid_mark)
})

test_that("check_contrast measures against the plot's own background", {
  dark <- ggplot(mtcars, aes(wt, mpg)) +
    geom_point(colour = "white") +
    theme(panel.background = element_rect(fill = "black"))
  out <- check_contrast(dark)
  expect_equal(out$ratio[out$role == "data mark"], 21, tolerance = 1e-6)

  # An explicit background overrides the detected one.
  out2 <- check_contrast(dark, background = "white")
  expect_equal(out2$ratio[out2$role == "data mark"], 1, tolerance = 1e-6)
})

test_that("gridlines are exempt from the mark threshold", {
  out <- check_contrast(
    ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte(grid = "y")
  )
  grid_row <- out[out$role == "gridline", ]
  expect_equal(nrow(grid_row), 1L)
  expect_lt(grid_row$ratio, 3)
  expect_true(grid_row$passes)
})

test_that("check_contrast validates its input", {
  expect_error(check_contrast(mtcars), "must be a ggplot")
})

test_that("the audit fails a plot drawn too faintly to read", {
  a <- tufte_audit(
    ggplot(mtcars, aes(wt, mpg)) + geom_point(colour = "grey85") +
      geom_rangeframe() + theme_tufte() + label_source("x"),
    measure = FALSE
  )
  legible <- a[a$check == "Ink clears the WCAG contrast minimum", ]
  expect_equal(legible$status, "fail")
  expect_match(legible$message, "below the published minimum")
  # The threshold is WCAG's, and the audit must say so rather than imply
  # Tufte set it.
  expect_match(legible$source, "not Tufte")
})
