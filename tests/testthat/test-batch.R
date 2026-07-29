library(ggplot2)

lean <- function() {
  ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_rangeframe() +
    theme_tufte() + label_source("Motor Trend, 1974")
}
sloppy <- function() {
  ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(cyl))) + geom_boxplot()
}

test_that("audit_figures scores a named list, worst first", {
  out <- audit_figures(list(good = lean(), bad = sloppy()), measure = FALSE)

  expect_s3_class(out, "tufte_audit_batch")
  expect_equal(nrow(out), 2L)
  expect_setequal(out$figure, c("good", "bad"))
  # Sorted ascending by score, so the figure needing most work comes first.
  expect_equal(out$figure[1], "bad")
  expect_lt(out$score[1], out$score[2])
  expect_gt(out$failed[out$figure == "bad"], 0)
  expect_equal(out$failing[out$figure == "good"], "")
})

test_that("the full audits are kept for drilling into", {
  out <- audit_figures(list(good = lean(), bad = sloppy()), measure = FALSE)
  audits <- attr(out, "audits")
  expect_named(audits, c("good", "bad"))
  expect_s3_class(audits$bad, "tufte_audit")
  # The summary row and the underlying audit must agree.
  expect_equal(sum(audits$bad$status == "fail"), out$failed[out$figure == "bad"])
})

test_that("a single plot and an unnamed list both work", {
  one <- audit_figures(lean(), measure = FALSE)
  expect_equal(nrow(one), 1L)
  expect_equal(one$figure, "plot")

  two <- audit_figures(list(lean(), sloppy()), measure = FALSE)
  expect_setequal(two$figure, c("figure 1", "figure 2"))
})

test_that("per-figure sizes are honoured", {
  # A portrait figure fails the aspect check; a landscape one does not.
  out <- audit_figures(
    list(wide = lean(), tall = lean()),
    width = c(6.5, 3), height = c(4, 6), measure = FALSE
  )
  audits <- attr(out, "audits")
  aspect_status <- function(a) {
    a$status[a$check == "The figure tends toward the horizontal"]
  }
  expect_equal(aspect_status(audits$wide), "pass")
  expect_equal(aspect_status(audits$tall), "fail")
})

test_that("audit_figures reads a directory of saved plots", {
  dir <- withr::local_tempdir()
  saveRDS(lean(), file.path(dir, "fig01.rds"))
  saveRDS(sloppy(), file.path(dir, "fig02.rds"))
  saveRDS(mtcars, file.path(dir, "not-a-plot.rds"))

  out <- suppressMessages(audit_figures(dir, measure = FALSE))
  expect_equal(nrow(out), 2L)
  expect_setequal(out$figure, c("fig01", "fig02"))
})

test_that("audit_figures rejects input it cannot use", {
  expect_error(audit_figures(list()), "No plots")
  expect_error(audit_figures(list(a = lean(), b = mtcars)), "not")
  expect_error(audit_figures(42), "must be a ggplot")

  empty <- withr::local_tempdir()
  expect_error(audit_figures(empty), "No .*rds.* files found")

  only_data <- withr::local_tempdir()
  saveRDS(mtcars, file.path(only_data, "x.rds"))
  expect_error(audit_figures(only_data), "contain a ggplot")
})

test_that("one broken figure does not sink the batch", {
  broken <- ggplot(mtcars, aes(wt, nonexistent_column)) + geom_point()
  out <- audit_figures(list(fine = lean(), broken = broken), measure = FALSE)
  expect_equal(nrow(out), 2L)
  expect_true(is.na(out$score[out$figure == "broken"]))
  expect_false(is.na(out$score[out$figure == "fine"]))
})

test_that("printing a batch does not error", {
  out <- audit_figures(list(good = lean(), bad = sloppy()), measure = FALSE)
  expect_message(print(out), "Tufte audit")
})
