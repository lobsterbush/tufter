#' Range frames and quartile frames
#'
#' A conventional panel border is pure non-data ink: the box is the same box
#' whatever the numbers are. Tufte's replacement is an axis line drawn only
#' across the range the data actually occupy, so that the frame reports the
#' minimum and maximum for free. \code{geom_quartileframe()} goes further and
#' breaks that line at the quartiles, so the axis carries the whole five-number
#' summary.
#'
#' Use these with \code{\link{theme_tufte}()}, which draws no axis line of its
#' own, and remember to turn the panel border off in any other theme.
#'
#' @param mapping,data,stat,position,na.rm,show.legend,inherit.aes,... Standard
#'   \code{ggplot2} layer arguments. See \code{\link[ggplot2]{layer}()}.
#' @param sides Which axes to draw, as a string containing any of \code{"b"}
#'   (bottom), \code{"l"} (left), \code{"t"} (top) and \code{"r"} (right).
#'   Defaults to \code{"bl"}.
#' @param gap For \code{geom_quartileframe()}, the width of the break at each
#'   quartile, in npc units of the panel. Defaults to \code{0.01}.
#' @return A \code{ggplot2} layer.
#' @seealso \code{\link{quartile_breaks}()}, which puts the axis labels in the
#'   same places the quartile frame breaks.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   geom_rangeframe() +
#'   theme_tufte()
#'
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   geom_quartileframe() +
#'   scale_x_continuous(breaks = quartile_breaks(mtcars$wt)) +
#'   scale_y_continuous(breaks = quartile_breaks(mtcars$mpg)) +
#'   theme_tufte()
geom_rangeframe <- function(mapping = NULL, data = NULL, stat = "identity",
                            position = "identity", ..., sides = "bl",
                            na.rm = FALSE, show.legend = NA,
                            inherit.aes = TRUE) {
  ggplot2::layer(
    geom = GeomRangeFrame, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(sides = sides, na.rm = na.rm, ...)
  )
}

#' @rdname geom_rangeframe
#' @format NULL
#' @usage NULL
#' @export
GeomRangeFrame <- ggplot2::ggproto(
  "GeomRangeFrame", ggplot2::Geom,
  optional_aes = c("x", "y"),
  draw_key = ggplot2::draw_key_blank,
  default_aes = ggplot2::aes(
    colour = "black", linewidth = 0.3, linetype = 1, alpha = NA
  ),

  draw_panel = function(data, panel_params, coord, sides = "bl", na.rm = FALSE) {
    d <- coord$transform(data, panel_params)
    gp <- .frame_gpar(data)
    # The name matters beyond tidiness: data_ink_ratio() identifies data layers
    # by a "geom" prefix on the grob, and an unnamed frame would be charged to
    # the furniture instead of to the data it reports.
    .ggname("geom_rangeframe", .frame_grobs(d, sides, gp, breaks = "range"))
  }
)

#' @rdname geom_rangeframe
#' @export
geom_quartileframe <- function(mapping = NULL, data = NULL, stat = "identity",
                               position = "identity", ..., sides = "bl",
                               gap = 0.01, na.rm = FALSE, show.legend = NA,
                               inherit.aes = TRUE) {
  ggplot2::layer(
    geom = GeomQuartileFrame, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(sides = sides, gap = gap, na.rm = na.rm, ...)
  )
}

#' @rdname geom_rangeframe
#' @format NULL
#' @usage NULL
#' @export
GeomQuartileFrame <- ggplot2::ggproto(
  "GeomQuartileFrame", ggplot2::Geom,
  optional_aes = c("x", "y"),
  draw_key = ggplot2::draw_key_blank,
  default_aes = ggplot2::aes(
    colour = "black", linewidth = 0.3, linetype = 1, alpha = NA
  ),

  draw_panel = function(data, panel_params, coord, sides = "bl", gap = 0.01,
                        na.rm = FALSE) {
    d <- coord$transform(data, panel_params)
    gp <- .frame_gpar(data)
    .ggname(
      "geom_quartileframe",
      .frame_grobs(d, sides, gp, breaks = "quartile", gap = gap)
    )
  }
)

# Build the graphical parameters shared by both frames.
#' @noRd
.frame_gpar <- function(data) {
  grid::gpar(
    col = scales::alpha(data$colour[1], data$alpha[1] %||% NA),
    lty = data$linetype[1],
    lwd = data$linewidth[1] * .pt,
    lineend = "butt"
  )
}

# Segment endpoints along one axis, in npc, given transformed values.
#' @noRd
.frame_spans <- function(v, breaks = c("range", "quartile"), gap = 0.01) {
  breaks <- match.arg(breaks)
  v <- v[is.finite(v)]
  if (length(v) == 0) return(NULL)
  if (breaks == "range" || length(unique(v)) < 4) {
    return(data.frame(start = min(v), end = max(v)))
  }
  q <- as.numeric(stats::quantile(v, probs = c(0, 0.25, 0.5, 0.75, 1),
                                  names = FALSE, type = 7))
  half <- gap / 2
  starts <- q[1:4]
  ends <- q[2:5]
  # Open a gap at each interior quartile, without letting a segment invert.
  starts[2:4] <- starts[2:4] + half
  ends[1:3] <- ends[1:3] - half
  keep <- ends > starts
  data.frame(start = starts[keep], end = ends[keep])
}

#' @noRd
.frame_grobs <- function(d, sides, gp, breaks = "range", gap = 0.01) {
  grobs <- list()

  add <- function(spans, horizontal, at) {
    if (is.null(spans)) return(invisible(NULL))
    g <- if (horizontal) {
      grid::segmentsGrob(
        x0 = grid::unit(spans$start, "npc"), x1 = grid::unit(spans$end, "npc"),
        y0 = grid::unit(at, "npc"), y1 = grid::unit(at, "npc"), gp = gp
      )
    } else {
      grid::segmentsGrob(
        y0 = grid::unit(spans$start, "npc"), y1 = grid::unit(spans$end, "npc"),
        x0 = grid::unit(at, "npc"), x1 = grid::unit(at, "npc"), gp = gp
      )
    }
    grobs[[length(grobs) + 1]] <<- g
    invisible(NULL)
  }

  if (!is.null(d$x)) {
    sx <- .frame_spans(d$x, breaks, gap)
    if (grepl("b", sides, fixed = TRUE)) add(sx, TRUE, 0)
    if (grepl("t", sides, fixed = TRUE)) add(sx, TRUE, 1)
  }
  if (!is.null(d$y)) {
    sy <- .frame_spans(d$y, breaks, gap)
    if (grepl("l", sides, fixed = TRUE)) add(sy, FALSE, 0)
    if (grepl("r", sides, fixed = TRUE)) add(sy, FALSE, 1)
  }

  if (length(grobs) == 0) return(ggplot2::zeroGrob())
  do.call(grid::grobTree, grobs)
}

#' Axis breaks at the five-number summary
#'
#' Returns a breaks function that labels the minimum, the quartiles, the median
#' and the maximum, so that the printed axis labels agree with what a
#' \code{\link{geom_quartileframe}()} shows. Tufte's point is that an axis
#' should report the distribution, not a set of round numbers chosen by the
#' plotting software.
#'
#' All five values are returned by default, because the five-number summary is
#' what a quartile frame reports. Where two of them fall close enough together
#' that their labels overprint, \code{min_gap} will drop the crowded ones, but
#' it is off unless you ask for it: the spacing at which labels collide depends
#' on the font, the figure size and the number of digits, none of which a breaks
#' function can see. \code{\link{check_labels_fit}()} measures the collision
#' properly, at the size you intend to print.
#'
#' @param x Optional numeric vector. If supplied, the breaks are computed from
#'   it once, which is what you want when the axis limits are wider than the
#'   data. If omitted, breaks are computed from the scale's own limits.
#' @param digits Number of significant digits to round the breaks to. Defaults
#'   to 3.
#' @param min_gap Minimum spacing between breaks, as a fraction of the data
#'   range; breaks closer than this to the one before them are dropped. Defaults
#'   to \code{0}, which keeps the whole five-number summary. Any value you set
#'   is a judgement about your own font and figure size, so it belongs in your
#'   code rather than in a default here.
#' @return A function suitable for the \code{breaks} argument of a continuous
#'   scale.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   geom_quartileframe() +
#'   scale_y_continuous(breaks = quartile_breaks(mtcars$mpg)) +
#'   theme_tufte()
quartile_breaks <- function(x = NULL, digits = 3, min_gap = 0) {
  force(x)
  function(limits) {
    v <- if (is.null(x)) limits else x
    v <- v[is.finite(v)]
    if (length(v) == 0) return(numeric(0))

    brk <- unique(signif(stats::fivenum(v), digits))
    if (min_gap <= 0 || length(brk) < 3) return(brk)

    span <- diff(range(brk))
    if (!is.finite(span) || span == 0) return(brk)
    gap <- min_gap * span

    # Walk up from the minimum keeping breaks that clear the gap, then make
    # sure the maximum survives even if it crowds the break below it.
    keep <- brk[1]
    for (b in brk[-1]) if (b - keep[length(keep)] >= gap) keep <- c(keep, b)
    top <- brk[length(brk)]
    if (keep[length(keep)] != top) {
      if (top - keep[length(keep)] < gap) keep <- keep[-length(keep)]
      keep <- c(keep, top)
    }
    keep
  }
}
