library(ggplot2)

test_that("a Tufte-styled plot scores higher than a default one", {
  base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  plain <- tufte_audit(base, width = 5, height = 3)
  lean <- tufte_audit(
    base + geom_rangeframe() + theme_tufte() + label_source("Motor Trend, 1974"),
    width = 5, height = 3
  )
  expect_gt(attr(lean, "score"), attr(plain, "score"))
  expect_equal(attr(lean, "score"), 1)
})

test_that("the audit returns one row per check with a usable status", {
  a <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                   width = 5, height = 3)
  expect_s3_class(a, "tufte_audit")
  expect_true(all(c("principle", "source", "check", "status", "message") %in%
                    names(a)))
  expect_true(all(a$status %in% c("pass", "fail", "note", "skip")))
  expect_gt(nrow(a), 8)
})

test_that("measure = FALSE skips the rendering checks", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  fast <- tufte_audit(p, measure = FALSE)
  slow <- tufte_audit(p, width = 5, height = 3)
  expect_lt(nrow(fast), nrow(slow))
  expect_false(any(grepl("data-ink", fast$check, ignore.case = TRUE)))
})

test_that("the audit names a pie chart as one", {
  d <- data.frame(g = letters[1:4], v = 1:4)
  a <- tufte_audit(
    ggplot(d, aes("", v, fill = g)) + geom_col() + coord_polar("y"),
    width = 5, height = 4
  )
  pie <- a[a$check == "No pie chart", ]
  expect_equal(pie$status, "fail")
  expect_match(pie$message, "pie chart")
})

test_that("the audit catches a truncated bar baseline", {
  d <- data.frame(g = c("a", "b"), v = c(100, 110))
  a <- tufte_audit(
    ggplot(d, aes(g, v)) + geom_col() + coord_cartesian(ylim = c(95, 115)),
    width = 5, height = 3
  )
  expect_equal(a$status[a$check == "Bars start at zero"], "fail")
  expect_equal(a$status[a$check == "Lie factor near one"], "fail")
})

test_that("the audit catches a variable encoded twice", {
  a <- tufte_audit(
    ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) + geom_boxplot(),
    measure = FALSE
  )
  redundant <- a[a$check == "No variable encoded twice", ]
  expect_equal(redundant$status, "fail")
})

test_that("the audit suggests direct labels for a small legend", {
  a <- tufte_audit(
    ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point(),
    measure = FALSE
  )
  expect_equal(a$status[a$check == "No legend to decode"], "fail")
})

test_that("the audit flags a portrait aspect ratio", {
  a <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                   width = 3, height = 6, measure = FALSE)
  ar <- a[a$check == "The figure tends toward the horizontal", ]
  expect_equal(ar$status, "fail")
})

test_that("the audit rejects things that are not plots", {
  expect_error(tufte_audit(mtcars), "must be a ggplot")
})

test_that("printing an audit reports the score", {
  a <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(), measure = FALSE)
  # cli signals its output as conditions rather than writing to stdout.
  expect_message(print(a), "Tufte audit")
  expect_identical(suppressMessages(print(a)), a)
})

test_that("no check silently disappears", {
  plots <- list(
    ggplot(mtcars, aes(wt, mpg)) + geom_point(),
    ggplot(data.frame(g = letters[1:4], v = 1:4), aes("", v, fill = g)) +
      geom_col() + coord_polar("y"),
    ggplot(mtcars, aes(factor(cyl), mpg)) + geom_tufteboxplot()
  )
  for (p in plots) {
    a <- tufte_audit(p, measure = FALSE)
    expect_false(any(is.na(a$check)))
    expect_false(any(a$status == "skip"))
  }
})

test_that("tufte_principles is complete and honest about what it cannot check", {
  p <- tufte_principles()
  expect_gt(nrow(p), 20)
  expect_true(all(c("principle", "source", "statement", "implemented_by",
                    "audited") %in% names(p)))
  expect_true(any(!p$audited))
  expect_equal(nrow(tufte_principles(audited_only = TRUE)), sum(p$audited))
  expect_false(any(duplicated(p$principle)))
})
