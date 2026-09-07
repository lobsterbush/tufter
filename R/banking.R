#' Bank the aspect ratio to 45 degrees
#'
#' Changing a panel's height changes how steep a line looks. Banking chooses a
#' height, for a given width, that brings the slopes closer to 45 degrees.
#' This implements Cleveland's approach to comparing slopes and relates to
#' Tufte's advice that graphics should tend toward the horizontal.
#'
#' The default, \code{"median_slope"}, makes the median absolute slope 45 degrees.
#' It's less sensitive to unusually steep segments. \code{"average_orientation"}
#' makes the mean absolute orientation 45 degrees and can weight segments by
#' length.
#'
#' The function reads lines, paths and smooths. It rejects step charts and
#' plots without line-like layers. I treat the height as a starting point:
#' check whether it helps readers see the change you're interested in.
#'
#' @param plot A \code{ggplot} object.
#' @param width Panel width in inches to solve the height for. Defaults to 6.5.
#' @param method Either \code{"median_slope"} or \code{"average_orientation"}.
#' @param weighted For \code{"average_orientation"}, weight each segment by its
#'   length? Defaults to \code{TRUE}. Ignored by the other method.
#' @return An object of class \code{tufte_banking}: a list with the recommended
#'   \code{aspect} (height divided by width), the \code{height} that implies at
#'   the given \code{width}, the \code{method} used, and \code{n_segments}, the
#'   number of line segments the answer was computed from.
#'
#'   The aspect ratio describes the \emph{panel}, since that's where the slopes
#'   are drawn. A saved figure needs room for axis labels and titles on top of
#'   it, so pass something larger than \code{height} to
#'   \code{\link{save_tufte}()} and check the result with
#'   \code{\link{check_labels_fit}()}.
#' @seealso \code{\link{save_tufte}()}. Banking isn't applied automatically:
#'   pass the \code{height} it returns yourself, so that the choice stays
#'   visible in your code.
#' @export
#' @examples
#' library(ggplot2)
#' d <- data.frame(year = 1:100, value = sin(seq(0, 6 * pi, length.out = 100)))
#' p <- ggplot(d, aes(year, value)) + geom_line() + theme_tufte()
#'
#' b <- bank_to_45(p, width = 6.5)
#' b
#'
#' # Save at the banked height rather than a height chosen by habit.
#' \dontrun{
#' save_tufte("figure.pdf", p, width = 6.5, height = b$height)
#' }
bank_to_45 <- function(plot, width = 6.5,
                       method = c("median_slope", "average_orientation"),
                       weighted = TRUE) {
  .check_gg(plot)
  .check_size(width)
  method <- match.arg(method)

  segs <- .slope_ratios(plot)
  if (length(segs$m) == 0) {
    .abort(c(
      "This plot has no line segments, so there are no slopes to bank.",
      i = "Banking applies to lines, paths, steps and smooths."
    ))
  }

  m <- segs$m
  aspect <- if (method == "median_slope") {
    med <- stats::median(m)
    if (is.na(med) || med <= 0) {
      .abort("Every segment in this plot is flat, so no aspect ratio banks it.")
    }
    if (is.infinite(med)) {
      .abort(c(
        "More than half the segments in this plot are vertical, so no aspect ratio banks them.",
        i = "{.code method = \"average_orientation\"} tolerates verticals only while they are a minority, so it will refuse this too."
      ))
    }
    1 / med
  } else {
    w <- if (weighted) segs$len else rep(1, length(m))
    .solve_orientation(m, w)
  }

  structure(
    list(
      aspect = aspect,
      width = width,
      height = width * aspect,
      method = method,
      weighted = if (method == "average_orientation") weighted else NA,
      n_segments = length(m)
    ),
    class = "tufte_banking"
  )
}

#' @export
print.tufte_banking <- function(x, ...) {
  cli::cli_h3("Banking to 45 degrees")
  cli::cli_text(
    "Aspect ratio {.strong {round(x$aspect, 3)}} (height / width), ",
    "from {x$n_segments} segment{?s} by {.val {x$method}}."
  )
  cli::cli_text(
    "At {x$width}in wide, that's a panel {.strong {round(x$height, 2)}in} tall. ",
    "Allow more for axis labels and titles."
  )
  invisible(x)
}

# Absolute data slopes, rescaled by the panel ranges, so that multiplying by
# the aspect ratio gives the slope as it appears on the page. Also returns each
# segment's length in normalised units, for weighting.
#' @noRd
.slope_ratios <- function(plot) {
  built <- ggplot2::ggplot_build(plot)
  geoms <- .layer_geoms(plot)
  # Step charts are excluded. GeomStep turns each pair of points into a
  # horizontal and a vertical segment inside draw_panel(), so differencing the
  # built points measures a diagonal that is never drawn, and every segment
  # that is drawn sits at 0 or 90 degrees, which no aspect ratio banks.
  idx <- which(geoms %in% c("Line", "Path", "Smooth"))
  if (length(idx) == 0) {
    if (any(geoms == "Step")) {
      .abort(c(
        "A step chart has no sloped segments to bank.",
        i = "Every segment it draws is horizontal or vertical, whatever the panel shape."
      ))
    }
    return(list(m = numeric(0), len = numeric(0)))
  }

  pps <- built$layout$panel_params
  coord <- built$layout$coord
  m <- numeric(0)
  len <- numeric(0)

  for (i in idx) {
    d <- built$data[[i]]
    if (is.null(d$x) || is.null(d$y)) next
    panels <- d$PANEL %||% factor(rep(1L, nrow(d)))

    # Each panel gets normalised by its own ranges. Under free scales the
    # panels have different ranges, and using the first panel's for all of
    # them would rescale every other panel's slopes by the wrong factor.
    for (pn in unique(panels)) {
      pp <- pps[[as.integer(pn)]]
      if (is.null(pp)) next
      rng <- .panel_range_of(pp)
      rx <- diff(rng$x)
      ry <- diff(rng$y)
      if (!is.finite(rx) || !is.finite(ry) || rx <= 0 || ry <= 0) next

      dp <- d[panels == pn, , drop = FALSE]
      # Slopes have to be measured as drawn. coord_flip() puts the data's y on
      # the panel's x, so dividing the built columns by x.range and y.range
      # measured neither the data slopes nor the drawn ones. The coord already
      # knows how to map a row to the panel, so let it.
      tp <- tryCatch(coord$transform(dp, pp), error = function(e) NULL)
      if (!is.null(tp) && !is.null(tp$x) && !is.null(tp$y)) {
        dp$x <- tp$x * rx + rng$x[1]
        dp$y <- tp$y * ry + rng$y[1]
      }
      key <- dp$group %||% rep(1L, nrow(dp))
      for (part in split(dp, key, drop = TRUE)) {
        # Take the rows in the order they are drawn. Sorting by x would be
        # harmless for a time series and destructive for any path that doubles
        # back, such as a closed loop, where consecutive points are neighbours
        # along the path rather than along the axis.
        dx <- diff(part$x)
        dy <- diff(part$y)
        ok <- is.finite(dx) & is.finite(dy) & !(dx == 0 & dy == 0)
        if (!any(ok)) next
        # Normalise both deltas by the panel range, so the ratio is the slope
        # of a unit square panel and the aspect ratio scales it directly.
        ndx <- dx[ok] / rx
        ndy <- dy[ok] / ry
        # A vertical segment has infinite slope, which is a real value here
        # and must not be dropped: discarding verticals would bias the median
        # of any shape that has them.
        m <- c(m, abs(ndy) / abs(ndx))
        len <- c(len, sqrt(ndx^2 + ndy^2))
      }
    }
  }
  keep <- !is.na(m) & is.finite(len)
  list(m = m[keep], len = len[keep])
}

# Ranges from a single panel's parameters.
#' @noRd
.panel_range_of <- function(pp) {
  x <- pp$x.range %||% (if (!is.null(pp$x)) pp$x$continuous_range else NULL)
  y <- pp$y.range %||% (if (!is.null(pp$y)) pp$y$continuous_range else NULL)
  list(x = x %||% c(NA_real_, NA_real_), y = y %||% c(NA_real_, NA_real_))
}

#' @noRd
.panel_ranges <- function(built) {
  .panel_range_of(built$layout$panel_params[[1]])
}

# Find the aspect ratio whose mean absolute orientation is 45 degrees. The mean
# orientation rises monotonically with the aspect ratio, so a bounded search on
# the log scale is safe and quick.
#' @noRd
.solve_orientation <- function(m, w) {
  target <- pi / 4
  w <- w / sum(w)
  gap <- function(log_a) {
    ang <- atan(exp(log_a) * m)
    sum(w * ang) - target
  }
  lo <- -20
  hi <- 20
  # Outside the bracket there is no aspect ratio that banks these segments, and
  # returning the bound handed back exp(20), a height of three billion inches,
  # as though it were an answer. The median method aborts on the same data.
  if (gap(lo) > 0 || gap(hi) < 0) {
    .abort(c(
      "No aspect ratio brings the mean orientation of these segments to 45 degrees.",
      i = "Most of them are flat or vertical, so the mean cannot reach the target however the panel is shaped."
    ))
  }
  exp(stats::uniroot(gap, lower = lo, upper = hi, tol = 1e-9)$root)
}
