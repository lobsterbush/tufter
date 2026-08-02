#' Bank the aspect ratio to 45 degrees
#'
#' Tufte's advice on shape, that graphics should tend toward the horizontal, is
#' the informal version of a result Cleveland made precise: the slope of a line
#' is judged most accurately when it sits near 45 degrees, and the aspect ratio
#' of the panel is what puts it there. Banking chooses the height, for a given
#' width, that brings the slopes in the data closest to 45 degrees.
#'
#' The same series can look like a gentle drift or a cliff depending only on how
#' tall the panel is, and neither reading is the data's fault. Banking replaces
#' that choice with a rule.
#'
#' Two methods are offered. \code{"median_slope"} is Cleveland's original: pick
#' the aspect ratio that makes the median absolute slope exactly 45 degrees. It
#' resists outliers and is the default. \code{"average_orientation"} instead
#' makes the mean absolute orientation 45 degrees, optionally weighting by
#' its length so that long segments count for more, which is closer to what the
#' eye does with a line that varies in density.
#'
#' Only line-like layers are read: lines, paths, steps and smooths. A plot with
#' no such layer has no slopes to bank, and the function says so rather than
#' guessing.
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
#'   The aspect ratio describes the \emph{panel}, since that is where the slopes
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
        i = "Try {.code method = \"average_orientation\"}, which tolerates verticals."
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
    "At {x$width}in wide, that is a panel {.strong {round(x$height, 2)}in} tall. ",
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
  idx <- which(geoms %in% c("Line", "Path", "Step", "Smooth"))
  if (length(idx) == 0) return(list(m = numeric(0), len = numeric(0)))

  rng <- .panel_ranges(built)
  rx <- diff(rng$x)
  ry <- diff(rng$y)
  if (!is.finite(rx) || !is.finite(ry) || rx <= 0 || ry <= 0) {
    return(list(m = numeric(0), len = numeric(0)))
  }

  m <- numeric(0)
  len <- numeric(0)
  for (i in idx) {
    d <- built$data[[i]]
    if (is.null(d$x) || is.null(d$y)) next
    key <- interaction(
      d$group %||% 1L, d$PANEL %||% 1L, drop = TRUE
    )
    for (part in split(d, key)) {
      # Take the rows in the order they are drawn. Sorting by x would be
      # harmless for a time series and destructive for any path that doubles
      # back, such as a closed loop, where consecutive points are neighbours
      # along the path rather than along the axis.
      dx <- diff(part$x)
      dy <- diff(part$y)
      ok <- is.finite(dx) & is.finite(dy) & !(dx == 0 & dy == 0)
      if (!any(ok)) next
      # Normalise both deltas by the panel range, so the ratio is the slope of
      # a unit square panel and the aspect ratio scales it directly.
      ndx <- dx[ok] / rx
      ndy <- dy[ok] / ry
      # A vertical segment has infinite slope, which is a real value here and
      # must not be dropped: discarding verticals would bias the median of any
      # shape that has them.
      m <- c(m, abs(ndy) / abs(ndx))
      len <- c(len, sqrt(ndx^2 + ndy^2))
    }
  }
  keep <- !is.na(m) & is.finite(len)
  list(m = m[keep], len = len[keep])
}

#' @noRd
.panel_ranges <- function(built) {
  pp <- built$layout$panel_params[[1]]
  x <- pp$x.range %||% (if (!is.null(pp$x)) pp$x$continuous_range else NULL)
  y <- pp$y.range %||% (if (!is.null(pp$y)) pp$y$continuous_range else NULL)
  list(x = x %||% c(NA_real_, NA_real_), y = y %||% c(NA_real_, NA_real_))
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
  if (gap(lo) > 0) return(exp(lo))
  if (gap(hi) < 0) return(exp(hi))
  exp(stats::uniroot(gap, lower = lo, upper = hi, tol = 1e-9)$root)
}
