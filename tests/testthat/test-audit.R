library(ggplot2)

test_that("a Tufte-styled plot breaks fewer stated criteria", {
  base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  plain <- tufte_audit(base, width = 5, height = 3)
  lean <- tufte_audit(
    base + geom_rangeframe() + theme_tufte() + label_source("Motor Trend, 1974"),
    width = 5, height = 3
  )
  expect_lt(attr(lean, "violations"), attr(plain, "violations"))
  expect_equal(attr(lean, "violations"), 0)
})

test_that("the audit reports no score, because Tufte gives no weighting", {
  a <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(), measure = FALSE)
  expect_null(attr(a, "score"))
  expect_type(attr(a, "violations"), "integer")
  expect_equal(attr(a, "violations"), sum(a$status == "fail"))
})

test_that("directions without a threshold are measured, never graded", {
  a <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                   width = 5, height = 3)
  ungraded <- c("Data-ink ratio", "Data density", "Distinct hues",
                "Overlaid series")
  for (nm in ungraded) {
    expect_equal(a$status[a$check == nm], "report", info = nm)
  }
  # No measurement may ever come back as a pass or a fail.
  expect_false(any(a$status[a$check %in% ungraded] %in% c("pass", "fail")))
})

test_that("the graded checks are exactly those with a stated criterion", {
  a <- tufte_audit(
    ggplot(data.frame(g = c("a", "b"), v = c(1, 2)), aes(g, v)) + geom_col(),
    width = 5, height = 3
  )
  graded <- a$principle[a$status %in% c("pass", "fail")]
  stated <- tufte_principles()
  stated <- stated$principle[stated$criterion]
  # Every graded principle must appear in the table as carrying a criterion.
  # Names are matched loosely because the audit abbreviates a few of them.
  for (p in unique(graded)) {
    hit <- any(vapply(stated, function(s) {
      grepl(substr(s, 1, 12), p, fixed = TRUE) ||
        grepl(substr(p, 1, 12), s, fixed = TRUE)
    }, logical(1)))
    expect_true(hit, info = p)
  }
})

test_that("the audit returns one row per check with a usable status", {
  a <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                   width = 5, height = 3)
  expect_s3_class(a, "tufte_audit")
  expect_true(all(c("principle", "source", "check", "status", "message") %in%
                    names(a)))
  expect_true(all(a$status %in% c("pass", "fail", "report", "skip")))
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
  expect_equal(a$status[a$check == "Bars measured from zero"], "fail")
  expect_equal(a$status[a$check == "Lie factor within Tufte's band"], "fail")
})

test_that("the audit catches a variable encoded twice", {
  a <- tufte_audit(
    ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) + geom_boxplot(),
    measure = FALSE
  )
  redundant <- a[a$check == "No variable encoded twice", ]
  expect_equal(redundant$status, "fail")
})

test_that("a legend for named series fails, a continuous key does not", {
  discrete <- tufte_audit(
    ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point(),
    measure = FALSE
  )
  expect_equal(discrete$status[discrete$check == "No legend to decode"], "fail")

  # A gradient has no named series to label on the data, so Tufte's
  # instruction does not reach it and it must not be graded.
  continuous <- tufte_audit(
    ggplot(mtcars, aes(wt, mpg, colour = hp)) + geom_point(),
    measure = FALSE
  )
  expect_equal(continuous$status[continuous$check == "No legend to decode"],
               "report")
})

test_that("the audit flags a portrait aspect ratio and nothing beyond it", {
  tall <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                      width = 3, height = 6, measure = FALSE)
  expect_equal(tall$status[tall$check == "Wider than it is tall"], "fail")

  # Tufte states the criterion at 1 and nothing above it, so a very wide
  # figure must pass rather than attract an invented upper limit.
  wide <- tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                      width = 12, height = 2, measure = FALSE)
  expect_equal(wide$status[wide$check == "Wider than it is tall"], "pass")
})

test_that("the audit rejects things that are not plots", {
  expect_error(tufte_audit(mtcars), "must be a ggplot")
})

test_that("printing an audit reports unmet criteria", {
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

test_that("tufte_principles separates stated criteria from directions", {
  p <- tufte_principles()
  expect_true("criterion" %in% names(p))
  expect_type(p$criterion, "logical")
  expect_false(any(is.na(p$criterion)))
  # Both kinds must be present, or the distinction is not being drawn.
  expect_gt(sum(p$criterion), 0)
  expect_gt(sum(!p$criterion), 0)
  # The two open-ended measurements must not be marked as carrying a criterion.
  expect_false(p$criterion[p$principle == "Maximise the data-ink ratio"])
  expect_false(p$criterion[p$principle == "Maximise data density"])
  # The ones Tufte states a line for must be.
  expect_true(p$criterion[p$principle == "The lie factor"])
  expect_true(p$criterion[p$principle == "Graphical integrity"])
})

test_that("tufte_principles is complete and honest about what it cannot check", {
  p <- tufte_principles()
  expect_gt(nrow(p), 20)
  expect_true(all(c("principle", "source", "statement", "implemented_by",
                    "audited", "criterion") %in% names(p)))
  expect_true(any(!p$audited))
  expect_equal(nrow(tufte_principles(audited_only = TRUE)), sum(p$audited))
  expect_false(any(duplicated(p$principle)))
})
