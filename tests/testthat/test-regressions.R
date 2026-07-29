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
  hues <- a[a$check == "Colour stays a code", ]
  expect_equal(hues$status, "pass")
  expect_match(hues$message, "continuously")

  # A genuinely over-coloured discrete plot must still fail.
  many <- data.frame(g = factor(letters[1:12]), v = 1:12)
  a2 <- tufte_audit(
    ggplot(many, aes(g, v, colour = g)) + geom_point() + theme_tufte(),
    measure = FALSE
  )
  expect_equal(a2$status[a2$check == "Colour stays a code"], "fail")
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
  baseline <- a[a$check == "Bars start at zero", ]
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
  expect_false("Bars start at zero" %in% a$check)
})
