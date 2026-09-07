#' Sparklines
#'
#' Draw a time series small enough to place in a sentence, table cell, or
#' margin. Tufte describes these word-sized graphics in
#' \emph{Beautiful Evidence}.
#'
#' The default grey band marks the interquartile range. Dots identify the
#' minimum and maximum, and a label gives the final value. There are no axes,
#' so make sure the surrounding text supplies the context readers need.
#'
#' @param values Numeric vector of values, in order.
#' @param index Optional numeric vector of positions. Defaults to
#'   \code{seq_along(values)}.
#' @param band Either \code{NULL} for no band, or a length-2 numeric vector of
#'   quantiles defining the normal range. Defaults to \code{c(0.25, 0.75)}.
#' @param band_fill Fill colour of the normal-range band.
#' @param extremes Logical. Mark the minimum and maximum with dots?
#' @param last_point Logical. Mark the final value with a dot?
#' @param label Logical. Print the final value at the right-hand end?
#' @param accuracy Rounding for the printed value, passed to
#'   \code{\link[scales]{label_number}()}. Defaults to \code{0.1}; use
#'   \code{1} for counts.
#' @param big.mark Thousands separator for the printed value. Defaults to a
#'   comma, since the \pkg{scales} default is a space and reads oddly at
#'   sparkline size.
#' @param colour Line colour. Defaults to a near-black grey.
#' @param linewidth Line width. Defaults to \code{0.3}, a hairline.
#' @param extreme_colours Length-2 vector of colours for the minimum and
#'   maximum dots.
#' @return A \code{ggplot} object with no axes, sized to be printed small.
#' @seealso \code{\link{sparklines}()} for many series at once,
#'   \code{\link{sparkline_grob}()} to embed one in other graphics.
#' @export
#' @examples
#' set.seed(1)
#' sparkline(cumsum(rnorm(80)))
sparkline <- function(values, index = seq_along(values),
                      band = c(0.25, 0.75), band_fill = "grey90",
                      extremes = TRUE, last_point = TRUE, label = TRUE,
                      accuracy = 0.1, big.mark = ",", colour = "grey15",
                      linewidth = 0.3,
                      extreme_colours = c("#4a6b82", "#a1483c")) {
  values <- as.numeric(values)
  if (length(values) < 2) .abort("{.arg values} needs at least two points.")
  if (length(index) != length(values)) {
    .abort("{.arg index} and {.arg values} must be the same length.")
  }
  d <- data.frame(x = as.numeric(index), y = values)

  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y))

  if (!is.null(band)) {
    if (length(band) != 2) .abort("{.arg band} must be a length-2 vector of quantiles.")
    qs <- stats::quantile(values, probs = band, na.rm = TRUE, names = FALSE)
    p <- p + ggplot2::annotate(
      "rect", xmin = -Inf, xmax = Inf, ymin = qs[1], ymax = qs[2],
      fill = band_fill, colour = NA
    )
  }

  p <- p + ggplot2::geom_line(colour = colour, linewidth = linewidth)

  if (extremes) {
    ext <- d[c(which.min(d$y), which.max(d$y)), , drop = FALSE]
    ext$kind <- c("min", "max")
    p <- p + ggplot2::geom_point(
      data = ext, ggplot2::aes(colour = .data$kind), size = 0.8,
      show.legend = FALSE
    ) + ggplot2::scale_colour_manual(
      values = c(min = extreme_colours[1], max = extreme_colours[2])
    )
  }

  # The rightmost point, not the last row. geom_line() draws sorted by x, so on
  # unsorted input the line's right-hand end and the labelled "final value"
  # were different observations. sparklines() already sorts and got this right,
  # so the two functions disagreed on identical data.
  lastd <- d[which.max(d$x), , drop = FALSE]
  if (last_point) {
    p <- p + ggplot2::geom_point(data = lastd, colour = colour, size = 0.8)
  }
  if (label) {
    fmt <- scales::label_number(accuracy = accuracy, big.mark = big.mark)
    p <- p + ggplot2::geom_text(
      data = lastd, ggplot2::aes(label = fmt(.data$y)),
      hjust = -0.25, size = 2.4, colour = colour
    ) + ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.01, 0.16))
    )
  }

  p + theme_sparkline()
}

#' Many sparklines at once
#'
#' Stack one sparkline per series, with its name on the left and final value
#' on the right. Each series has its own vertical scale.
#'
#' This is useful for comparing patterns over time. To compare levels across
#' series on a shared scale, use \code{\link{facet_tufte}()}.
#'
#' @param data A data frame.
#' @param x,y,group Bare column names for position, value and series.
#' @param band,band_fill,colour,linewidth,accuracy,big.mark As in
#'   \code{\link{sparkline}()}.
#' @param extremes Logical. Mark each series' minimum and maximum?
#' @param label Logical. Print each series' final value at the right?
#' @return A \code{ggplot} object.
#' @export
#' @examples
#' set.seed(1)
#' d <- data.frame(
#'   t = rep(1:40, 4),
#'   v = c(cumsum(rnorm(40)), cumsum(rnorm(40)), cumsum(rnorm(40)),
#'         cumsum(rnorm(40))),
#'   series = rep(c("Wheat", "Maize", "Rice", "Barley"), each = 40)
#' )
#' sparklines(d, t, v, series)
sparklines <- function(data, x, y, group, band = c(0.25, 0.75),
                       band_fill = "grey90", extremes = TRUE, label = TRUE,
                       accuracy = 0.1, big.mark = ",", colour = "grey15",
                       linewidth = 0.3) {
  if (!is.data.frame(data)) .abort("{.arg data} must be a data frame.")
  d <- data.frame(
    x = as.numeric(rlang::eval_tidy(rlang::enquo(x), data)),
    y = as.numeric(rlang::eval_tidy(rlang::enquo(y), data)),
    g = as.character(rlang::eval_tidy(rlang::enquo(group), data))
  )
  d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) == 0) .abort("No complete rows to plot.")
  # Series stack in the order they first appear, not alphabetically: the order
  # of a table of indicators is usually meaningful.
  d$g <- factor(d$g, levels = unique(d$g))
  d <- d[order(d$g, d$x), , drop = FALSE]
  parts <- split(d, d$g, drop = TRUE)

  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y))

  if (!is.null(band)) {
    bands <- do.call(rbind, lapply(parts, function(s) {
      qs <- stats::quantile(s$y, probs = band, na.rm = TRUE, names = FALSE)
      data.frame(g = s$g[1], ymin = qs[1], ymax = qs[2])
    }))
    p <- p + ggplot2::geom_rect(
      data = bands, inherit.aes = FALSE,
      ggplot2::aes(xmin = -Inf, xmax = Inf, ymin = .data$ymin, ymax = .data$ymax),
      fill = band_fill, colour = NA
    )
  }

  p <- p + ggplot2::geom_line(colour = colour, linewidth = linewidth)

  if (extremes) {
    ext <- do.call(rbind, lapply(parts, function(s) {
      out <- s[c(which.min(s$y), which.max(s$y)), , drop = FALSE]
      out$kind <- c("min", "max")
      out
    }))
    p <- p + ggplot2::geom_point(
      data = ext, ggplot2::aes(colour = .data$kind), size = 0.8,
      show.legend = FALSE
    ) + ggplot2::scale_colour_manual(
      values = c(min = "#4a6b82", max = "#a1483c")
    )
  }

  lastd <- do.call(rbind, lapply(parts, function(s) s[nrow(s), , drop = FALSE]))
  p <- p + ggplot2::geom_point(data = lastd, colour = colour, size = 0.8)

  if (label) {
    fmt <- scales::label_number(accuracy = accuracy, big.mark = big.mark)
    p <- p + ggplot2::geom_text(
      data = lastd, ggplot2::aes(label = fmt(.data$y)),
      hjust = -0.25, size = 2.4, colour = colour
    ) + ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.01, 0.18))
    )
  }

  p +
    ggplot2::facet_wrap(
      ~ g, ncol = 1, scales = "free_y", strip.position = "left"
    ) +
    theme_sparkline()
}

#' A sparkline as a grob
#'
#' Return a \code{grid} grob that you can place in another graphic, a table
#' cell, or an \pkg{rmarkdown} inline chunk.
#'
#' @inheritParams sparkline
#' @param ... Passed to \code{\link{sparkline}()}.
#' @return A \code{grid} grob.
#' @export
#' @examples
#' set.seed(1)
#' g <- sparkline_grob(cumsum(rnorm(50)))
#' grid::grid.newpage()
#' grid::grid.draw(g)
sparkline_grob <- function(values, ...) {
  .grob_of(sparkline(values, ...))
}
