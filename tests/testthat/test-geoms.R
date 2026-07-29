library(ggplot2)

# Building a plot is the real test for a geom: it exercises setup_data,
# draw_panel and the coord transform without needing a reference image.
render <- function(p) {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f))
  suppressWarnings(ggsave(f, p, width = 5, height = 3, dpi = 72))
  file.exists(f) && file.size(f) > 0
}

test_that("geom_rangeframe builds and draws", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_rangeframe()
  expect_s3_class(ggplot_build(p), "ggplot_built")
  expect_true(render(p))
})

test_that("geom_rangeframe honours sides", {
  for (s in c("b", "l", "bl", "tr", "bltr")) {
    p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_rangeframe(sides = s)
    expect_true(render(p), info = s)
  }
})

test_that("geom_quartileframe builds and draws", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_quartileframe()
  expect_true(render(p))
})

test_that("frame spans break at the quartiles", {
  v <- seq(0, 1, length.out = 101)
  rng <- tufter:::.frame_spans(v, "range")
  expect_equal(nrow(rng), 1L)
  expect_equal(rng$start, 0)
  expect_equal(rng$end, 1)

  q <- tufter:::.frame_spans(v, "quartile", gap = 0.02)
  expect_equal(nrow(q), 4L)
  # Every segment runs forwards, and gaps sit between them.
  expect_true(all(q$end > q$start))
  expect_true(all(q$start[-1] > q$end[-nrow(q)]))
})

test_that("frame spans collapse to a range when there is too little data", {
  expect_equal(nrow(tufter:::.frame_spans(c(1, 2), "quartile")), 1L)
  expect_null(tufter:::.frame_spans(numeric(0), "range"))
})

test_that("geom_dotdash builds and draws on every side", {
  for (s in c("bl", "tr", "b")) {
    p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + geom_dotdash(sides = s)
    expect_true(render(p), info = s)
  }
})

test_that("all three tufteboxplot variants draw", {
  for (ty in c("point", "line", "offset")) {
    p <- ggplot(mtcars, aes(factor(cyl), mpg)) + geom_tufteboxplot(type = ty)
    expect_true(render(p), info = ty)
  }
})

test_that("tufteboxplot rejects an unknown variant", {
  expect_error(geom_tufteboxplot(type = "banana"))
})

test_that("geom_col_tufte draws rules at the breaks", {
  d <- data.frame(g = letters[1:4], v = c(1, 3, 2, 4))
  p <- ggplot(d, aes(g, v)) + geom_col_tufte()
  expect_true(render(p))
  expect_true(render(ggplot(d, aes(v, g)) + geom_col_tufte(sides = "x")))
})

test_that("geom_bar_tufte counts", {
  p <- ggplot(mtcars, aes(factor(cyl))) + geom_bar_tufte()
  built <- ggplot_build(p)
  expect_equal(sum(built$data[[1]]$count), nrow(mtcars))
  expect_true(render(p))
})

test_that("geom_text_last keeps one row per group, at the largest x", {
  d <- data.frame(
    x = rep(1:5, 2), y = rnorm(10),
    g = rep(c("a", "b"), each = 5)
  )
  p <- ggplot(d, aes(x, y, colour = g)) + geom_line() +
    geom_text_last(aes(label = g))
  built <- ggplot_build(p)
  lab <- built$data[[2]]
  expect_equal(nrow(lab), 2L)
  expect_true(all(lab$x == 5))
})

test_that("geom_text_first labels the smallest x", {
  d <- data.frame(x = rep(1:5, 2), y = rnorm(10), g = rep(c("a", "b"), each = 5))
  p <- ggplot(d, aes(x, y, colour = g)) + geom_line() +
    geom_text_first(aes(label = g))
  expect_true(all(ggplot_build(p)$data[[2]]$x == 1))
})

test_that("direct labels reject a doubled position specification", {
  expect_error(
    geom_text_last(nudge_x = 1, position = "stack"),
    "not both"
  )
})
