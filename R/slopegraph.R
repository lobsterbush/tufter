#' Slopegraphs
#'
#' A slopegraph shows a before-and-after comparison for many units at once.
#' Each unit is one line; the slope of the line is the change, the vertical
#' position is the level, and the crossings show which units changed rank.
#' Tufte's version prints every number on the graphic, which makes the y axis
#' redundant, so it's removed. The table and the graphic become the same
#' object.
#'
#' The design fails quietly when many units share a value, because the labels
#' collide. \code{slopegraph()} nudges colliding labels apart by default; if
#' your data are dense, reduce \code{label_size} or plot fewer units.
#'
#' @param data A data frame in long form: one row per unit per period.
#' @param x Bare column name for the period. Coerced to a factor; its levels
#'   set the left-to-right order.
#' @param y Bare column name for the value.
#' @param group Bare column name identifying the unit.
#' @param label_size Size of the printed labels. Defaults to \code{2.8}.
#' @param line_colour Colour of the connecting lines. Defaults to
#'   \code{"grey45"}.
#' @param linewidth Width of the connecting lines. Defaults to \code{0.35}.
#' @param point_size Size of the dots at each period. Set to \code{0} to omit
#'   them, as Tufte usually does.
#' @param accuracy Rounding for the printed values, passed to
#'   \code{\link[scales]{label_number}()}.
#' @param direction_colour Logical. Colour lines by whether the unit rose or
#'   fell between the first and last period? Defaults to \code{FALSE}; Tufte's
#'   own slopegraphs use a single grey.
#' @param min_gap Minimum vertical separation between labels, as a fraction of
#'   the y range. Labels closer than this are nudged apart. Set to \code{0} to
#'   disable. This is a typesetting allowance rather than a quantity from
#'   Tufte. It's here only so two units with near-identical values don't print
#'   on top of each other, and the right value depends on your font size.
#' @return A \code{ggplot} object.
#' @export
#' @examples
#' d <- data.frame(
#'   country = rep(c("Sweden", "Japan", "Chile", "Canada"), each = 2),
#'   year = rep(c("1970", "2020"), 4),
#'   value = c(30.1, 41.2, 20.7, 32.9, 22.5, 21.0, 31.0, 38.4)
#' )
#' slopegraph(d, year, value, country)
slopegraph <- function(data, x, y, group, label_size = 2.8,
                       line_colour = "grey45", linewidth = 0.35,
                       point_size = 0, accuracy = 0.1,
                       direction_colour = FALSE, min_gap = 0.03) {
  if (!is.data.frame(data)) .abort("{.arg data} must be a data frame.")

  xv <- rlang::eval_tidy(rlang::enquo(x), data)
  yv <- rlang::eval_tidy(rlang::enquo(y), data)
  gv <- rlang::eval_tidy(rlang::enquo(group), data)

  d <- data.frame(
    x = if (is.factor(xv)) xv else factor(xv, levels = unique(xv)),
    y = as.numeric(yv),
    g = as.character(gv),
    stringsAsFactors = FALSE
  )
  d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) == 0) .abort("No complete rows to plot.")
  if (nlevels(droplevels(d$x)) < 2) {
    .abort("{.arg x} needs at least two periods for a slopegraph.")
  }
  d$x <- droplevels(d$x)
  d$xn <- as.integer(d$x)

  fmt <- scales::label_number(accuracy = accuracy)
  levs <- levels(d$x)
  first <- d[d$xn == 1, , drop = FALSE]
  last <- d[d$xn == max(d$xn), , drop = FALSE]

  yrange <- diff(range(d$y))
  first$ylab <- .spread_labels(first$y, min_gap * yrange)
  last$ylab <- .spread_labels(last$y, min_gap * yrange)

  first$text <- paste0(first$g, "  ", fmt(first$y))
  last$text <- paste0(fmt(last$y), "  ", last$g)

  if (direction_colour) {
    change <- stats::setNames(last$y, last$g)[d$g] - stats::setNames(first$y, first$g)[d$g]
    d$direction <- ifelse(change >= 0, "up", "down")
  }

  p <- ggplot2::ggplot(d, ggplot2::aes(.data$xn, .data$y, group = .data$g))

  if (direction_colour) {
    p <- p +
      ggplot2::geom_line(
        ggplot2::aes(colour = .data$direction), linewidth = linewidth
      ) +
      ggplot2::scale_colour_manual(
        values = c(up = "#a1483c", down = "#4a6b82"), guide = "none"
      )
  } else {
    p <- p + ggplot2::geom_line(colour = line_colour, linewidth = linewidth)
  }

  if (point_size > 0) {
    p <- p + ggplot2::geom_point(colour = line_colour, size = point_size)
  }

  p <- p +
    ggplot2::geom_text(
      data = first, inherit.aes = FALSE,
      ggplot2::aes(x = .data$xn, y = .data$ylab, label = .data$text),
      hjust = 1, size = label_size, nudge_x = -0.03, colour = "grey15"
    ) +
    ggplot2::geom_text(
      data = last, inherit.aes = FALSE,
      ggplot2::aes(x = .data$xn, y = .data$ylab, label = .data$text),
      hjust = 0, size = label_size, nudge_x = 0.03, colour = "grey15"
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq_along(levs), labels = levs,
      position = "top",
      expand = ggplot2::expansion(mult = 0.28)
    ) +
    theme_slopegraph()

  p
}

# Nudge labels apart so that near-identical values remain readable. Works from
# the bottom up, pushing each label to at least `gap` above the previous one,
# then recentres so the set is not systematically shifted.
#' @noRd
.spread_labels <- function(y, gap) {
  if (gap <= 0 || length(y) < 2) return(y)
  ord <- order(y)
  v <- y[ord]
  for (i in 2:length(v)) {
    if (v[i] - v[i - 1] < gap) v[i] <- v[i - 1] + gap
  }
  v <- v - (mean(v) - mean(y))
  out <- numeric(length(y))
  out[ord] <- v
  out
}
