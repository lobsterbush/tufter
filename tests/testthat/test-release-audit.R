library(ggplot2)

release_plot <- function() ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()

test_that("tidy evaluation pronouns are not counted as data variables", {
  p <- ggplot(mtcars, aes(.data$wt, .data[["mpg"]])) + geom_point()
  out <- data_density(p, panel_only = FALSE)
  expect_setequal(out$variable_names, c("wt", "mpg"))
  expect_equal(out$entries, 2 * nrow(mtcars))
  expect_equal(tufter:::.mapped_base_vars(rlang::quo(.env$offset)), character())
  expect_equal(tufter:::.mapped_base_vars(rlang::quo(log(.data$wt))), "wt")
})

test_that("strict saves stop when their safety check cannot run", {
  local_mocked_bindings(check_labels_fit = function(...) stop("device unavailable"))
  f <- withr::local_tempfile(fileext = ".pdf")
  expect_error(save_tufte(f, release_plot(), strict = TRUE), "Could not check labels")
  expect_false(file.exists(f))
  expect_warning(save_tufte(f, release_plot()), "Could not check labels")
  expect_true(file.exists(f))
})

test_that("saved dimensions cannot differ from checked dimensions", {
  f <- withr::local_tempfile(fileext = ".pdf")
  expect_error(save_tufte(f, release_plot(), units = "cm"), "cannot be overridden")
  expect_error(save_tufte(f, release_plot(), scale = 2), "cannot be overridden")
  expect_error(save_tufte(f, release_plot(), width = -1), "positive")
  expect_false(file.exists(f))
})

test_that("colour alpha is composited and rounding cannot grant a pass", {
  expect_equal(contrast_ratio("#00000000", "white"), 1)
  expect_lt(contrast_ratio("#0000001A", "white"), 1.5)
  expect_equal(tufter:::.composite("#0000001A", 1, "white"), "#000000")
  expect_equal(contrast_ratio(character()), numeric())
  expect_equal(contrast_ratio(c("#00000000", "#FFFFFF00"), c("white", "black")), c(1, 1))
  p <- release_plot() + geom_point(colour = "#0000001A")
  marks <- check_contrast(p)
  expect_true(any(!marks$passes[marks$role == "data mark"]))
  p <- release_plot() + theme(panel.background = element_rect(fill = "transparent"),
                              plot.background = element_rect(fill = "black"))
  expect_equal(tufter:::.plot_background(tufter:::.resolved_theme(p)), "#000000")
  ratio <- contrast_ratio("grey50", "white")
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point(colour = "grey50") + theme_tufte()
  out <- check_contrast(p, mark_min = ratio + 0.001)
  expect_false(out$passes[out$role == "data mark"][1])
})

test_that("unavailable checks are visible in individual and batch audits", {
  local_mocked_bindings(check_labels_fit = function(...) stop("device unavailable"),
                        check_contrast = function(...) stop("colour unavailable"))
  out <- tufte_audit(release_plot(), measure = FALSE)
  expect_equal(sum(out$status == "skip"), 2)
  expect_true(any(grepl("device unavailable", out$message)))
  batch <- audit_figures(release_plot(), measure = FALSE)
  expect_equal(batch$skipped, 2L)
})

test_that("drawn axis and legend text overrides are measured", {
  p <- release_plot() + theme(axis.text.x = element_text(colour = "grey95"))
  out <- check_contrast(p)
  expect_true(any(!out$passes[out$role == "axis text"]))
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() +
    theme_tufte() + theme(legend.text = element_text(colour = "grey95"))
  out <- check_contrast(p)
  expect_true(any(!out$passes[out$role == "legend text"]))
  p <- release_plot() + labs(title = "Black title on white paper") +
    theme(panel.background = element_rect(fill = "black"))
  out <- check_contrast(p)
  expect_equal(out$ratio[out$role == "title"], 21)
})

test_that("batch dimensions cannot silently recycle partial vectors", {
  p <- release_plot()
  expect_error(audit_figures(list(p, p, p), width = c(3, 4)), "one per plot")
  expect_error(audit_figures(p, height = numeric()), "positive")
})

test_that("negative and reversed truncated bars are detected", {
  d <- data.frame(g = c("a", "b"), v = c(-100, -110))
  p <- ggplot(d, aes(g, v)) + geom_col() + coord_cartesian(ylim = c(-115, -95), expand = FALSE)
  expect_equal(lie_factor(p), 20)
  out <- tufte_audit(p, measure = FALSE)
  expect_equal(out$status[out$check == "Bars measured from zero"], "fail")
  d$v <- -d$v
  p <- ggplot(d, aes(g, v)) + geom_col() + scale_y_reverse() +
    coord_cartesian(ylim = c(95, 115), expand = FALSE)
  expect_equal(lie_factor(p), 20)
})

test_that("a zero baseline in one facet cannot hide truncation in another", {
  d <- data.frame(g = rep(c("a", "b"), 2), v = c(0, 10, 100, 110), panel = rep(c("A", "B"), each = 2))
  p <- ggplot(d, aes(g, v)) + geom_col() + facet_wrap(~panel, scales = "free_y")
  built <- ggplot_build(p)
  # Exercise the panel-specific measurement with a plot coordinate that
  # chooses a separate viewport range for each facet.
  coord <- ggproto(NULL, CoordCartesian, setup_panel_params = function(self, scale_x, scale_y, params = list()) {
    out <- CoordCartesian$setup_panel_params(scale_x, scale_y, params)
    if (max(scale_y$get_limits()) > 50) out$y.range <- c(95, 115)
    out
  })
  p <- p + coord
  expect_equal(lie_factor(p), 20)
  out <- tufte_audit(p, measure = FALSE)
  expect_equal(out$status[out$check == "Bars measured from zero"], "fail")
})

test_that("title margins reduce the available width", {
  p <- release_plot() + labs(title = "A title") +
    theme(plot.margin = margin(5, 72, 5, 72, "pt"), plot.title.position = "plot")
  out <- suppressWarnings(check_labels_fit(p, width = 6.5, height = 4))
  expect_lt(out$available_in[out$element == "title"], 5)
})

test_that("reversed axes retain every quartile-frame segment", {
  q <- c(0.1, 0.3, 0.5, 0.7, 0.9)
  expect_equal(tufter:::.frame_spans(q, "quartile", q = rev(q)),
               tufter:::.frame_spans(q, "quartile", q = q))
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_quartileframe() + scale_x_reverse()
  gt <- tufter:::.grob_of(p)
  panel <- gt$grobs[[which(gt$layout$name == "panel")]]
  frame <- panel$children[[which(grepl("geom_quartileframe", names(panel$children)))]]
  expect_length(frame$children[[1]]$x0, 4)
})
