#' Slopegraphs
#'
#' Compare values across two periods, with a line for each unit and a label at
#' each end. Line crossings show changes in rank. Tufte's version prints the
#' values directly, so the y axis is removed.
#'
#' The function accepts more than two periods, but labels only the first and
#' last and warns about that limit.
#'
#' Nearby labels are moved apart by default. If you have many similar values,
#' you may still need a smaller label size or fewer units. Check the figure at
#' its final size.
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
#'   fell between the first and last period? Defaults to \code{FALSE}.
#' @param min_gap Minimum vertical separation between labels, as a fraction of
#'   the y range. Labels closer than this are nudged apart. Set to \code{0} to
#'   disable. Adjust this for the font size and spacing in your figure.
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
  # droplevels() first. A factor carrying an unused level counted it as a
  # period and warned about labelling that was in fact complete.
  d$x <- droplevels(d$x)
  if (nlevels(d$x) > 2) {
    # The labels sit outside the panel, to the left of the first period and to
    # the right of the last, so a middle period has no side to be labelled on.
    # The lines are still drawn through every period.
    .warn(c(
      "{nlevels(d$x)} periods given, and only the first and last are labelled.",
      i = "The lines pass through every period. Tufte's form prints every number, which this layout can only do for two."
    ))
  }
  d$xn <- as.integer(d$x)

  # One unit can only have one value per period. More than one is ambiguous
  # data, and quietly drawing both would print two labels on top of each other.
  dupes <- duplicated(d[c("g", "x")])
  if (any(dupes)) {
    offenders <- unique(d$g[dupes])
    .warn(c(
      "{length(offenders)} unit{?s} {?has/have} more than one value in a period, so only the first is drawn.",
      x = "Affected: {paste(utils::head(offenders, 5), collapse = ', ')}{if (length(offenders) > 5) ', ...' else ''}",
      i = "Aggregate to one value per unit per period before plotting."
    ))
    d <- d[!dupes, , drop = FALSE]
  }

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
