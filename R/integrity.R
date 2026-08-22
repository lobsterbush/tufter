#' Data-ink ratio
#'
#' Tufte defines the data-ink ratio as the share of a graphic's ink that's
#' devoted to the non-redundant display of data, and asks that it be pushed
#' towards one. \code{data_ink_ratio()} estimates it empirically: the plot is
#' rendered twice, once whole and once with every data layer removed, and the
#' ink in each rendering is measured from the pixels.
#'
#' The measurement is an estimate, for three reasons worth knowing before you
#' quote the number. Anti-aliased edges are counted in proportion to how far
#' they sit from the background colour, which is the right treatment but not an
#' exact one. Ink that overlaps is counted once, so a dense scatterplot
#' understates its own data-ink. And redundant data-ink, which Tufte would
#' subtract, still counts here as data-ink, because no measurement can tell
#' whether a mark repeats information the reader already has. Treat the result
#' as a comparative instrument: it's reliable for judging whether one version
#' of a figure is leaner than another, and unreliable as an absolute score.
#'
#' The redundancy point is worth a concrete case, because the number can run
#' the wrong way. Every pixel a data layer draws counts, the interiors of
#' filled shapes included, so a design built from large filled areas scores
#' high. Continental population as a pie chart measures 0.75; the same numbers
#' as a Cleveland dot plot measure 0.16, because dots are small and the axis
#' labels that make them readable are furniture. The pie is the worse graphic
#' and the ratio prefers it. Tufte would subtract the wedge interiors as
#' redundant, since the angle already carries the number, but no measurement
#' can decide which ink repeats what. The graded criteria in
#' \code{\link{tufte_audit}()} do separate the two, six unmet against one, and
#' this is why the audit reports the ratio rather than scoring it.
#'
#' @param plot A \code{ggplot} object.
#' @param width,height Rendering size in inches. Defaults to 6.5 by 4, the
#'   single-column figure size.
#' @param res Rendering resolution in pixels per inch. Defaults to 150. Higher
#'   values are slower and slightly more accurate at the edges.
#' @param background Background colour to measure ink against. Defaults to
#'   \code{"white"}.
#' @return An object of class \code{tufte_data_ink}: a list with the estimated
#'   \code{ratio}, and the \code{data_ink}, \code{non_data_ink} and
#'   \code{total_ink} it was computed from, in pixel-equivalents.
#' @export
#' @examples
#' library(ggplot2)
#' base <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' data_ink_ratio(base + theme_grey())
#' data_ink_ratio(base + geom_rangeframe() + theme_tufte())
data_ink_ratio <- function(plot, width = 6.5, height = 4, res = 150,
                           background = "white") {
  .check_gg(plot)
  gt <- .grob_of(plot)

  total <- .measure_ink(gt, width, height, res, background)
  non_data <- .measure_ink(.strip_data_grobs(gt), width, height, res, background)

  # Removing the data layers can only remove ink; clamp against rounding noise.
  non_data <- min(non_data, total)
  ratio <- if (total > 0) (total - non_data) / total else NA_real_

  structure(
    list(
      ratio = ratio,
      data_ink = total - non_data,
      non_data_ink = non_data,
      total_ink = total,
      width = width, height = height, res = res
    ),
    class = "tufte_data_ink"
  )
}

#' @export
print.tufte_data_ink <- function(x, ...) {
  cli::cli_h3("Data-ink ratio")
  cli::cli_text(
    "{.strong {round(100 * x$ratio)}%} of the ink in this figure varies with the data."
  )
  cli::cli_ul(c(
    "data ink: {.val {round(x$data_ink)}} pixel-equivalents",
    "non-data ink: {.val {round(x$non_data_ink)}}",
    "measured at {x$width}in x {x$height}in, {x$res} dpi"
  ))
  invisible(x)
}

# Render a gtable to a temporary PNG and return a weighted count of
# non-background pixels. Anti-aliased pixels contribute in proportion to how
# far they sit from the background colour, which is how a fractional pixel of
# ink should count.
#' @noRd
.measure_ink <- function(gt, width, height, res, background) {
  f <- .render_png(gt, width, height, res, background)
  on.exit(unlink(f), add = TRUE)

  arr <- png::readPNG(f)
  bg <- as.vector(grDevices::col2rgb(background)) / 255

  if (length(dim(arr)) == 2L) {
    # Greyscale: compare against the background's luminance.
    bg_grey <- sum(bg * c(0.2126, 0.7152, 0.0722))
    return(sum(abs(arr - bg_grey)))
  }

  chans <- dim(arr)[3]
  rgb <- arr[, , seq_len(min(3, chans)), drop = FALSE]
  if (dim(rgb)[3] < 3) rgb <- array(rgb[, , 1], dim = c(dim(arr)[1:2], 3))

  sq <- (rgb[, , 1] - bg[1])^2 + (rgb[, , 2] - bg[2])^2 + (rgb[, , 3] - bg[3])^2
  dist <- sqrt(sq / 3)

  if (chans == 4L) {
    # A transparent pixel shows the background through it, so weight by alpha.
    dist <- dist * arr[, , 4]
  }
  sum(dist)
}

# Draw a grob to a PNG file, preferring ragg when it is available because its
# anti-aliasing is more even, which makes the ink estimate steadier.
#' @noRd
.render_png <- function(gt, width, height, res, background) {
  f <- tempfile(fileext = ".png")
  old <- grDevices::dev.cur()

  use_ragg <- requireNamespace("ragg", quietly = TRUE)
  if (use_ragg) {
    ragg::agg_png(f, width = width, height = height, units = "in",
                  res = res, background = background)
  } else {
    args <- list(filename = f, width = width, height = height, units = "in",
                 res = res, bg = background)
    if (isTRUE(capabilities("cairo"))) args$type <- "cairo"
    do.call(grDevices::png, args)
  }

  drawn <- tryCatch({
    grid::grid.newpage()
    grid::grid.draw(gt)
    TRUE
  }, error = function(e) e)

  grDevices::dev.off()
  if (old > 1) try(grDevices::dev.set(old), silent = TRUE)

  if (inherits(drawn, "error")) {
    unlink(f)
    .abort(c("Could not render the plot for measurement.",
             x = conditionMessage(drawn)))
  }
  f
}

# Remove the data layers from a built gtable, leaving the frame, grid,
# background, axes, labels and legend behind.
#' @noRd
.strip_data_grobs <- function(gt) {
  panels <- which(grepl("^panel", gt$layout$name))
  for (i in panels) {
    g <- gt$grobs[[i]]
    if (!inherits(g, "gTree") || is.null(g$children)) next
    nms <- names(g$children)
    keep <- !grepl("^geom", nms)
    g$children <- g$children[keep]
    if (!is.null(g$childrenOrder)) {
      g$childrenOrder <- g$childrenOrder[g$childrenOrder %in% names(g$children)]
    }
    gt$grobs[[i]] <- g
  }
  gt
}

#' Lie factor
#'
#' Tufte's measure of graphical integrity: the size of the effect shown in the
#' graphic divided by the size of the effect in the data. A truthful graphic
#' has a lie factor of one. Tufte treats anything outside roughly 0.95 to 1.05
#' as distortion.
#'
#' Two ways in. Given two numeric vectors, the first the underlying values and
#' the second the sizes actually drawn, \code{lie_factor()} compares the
#' proportional change in each. Given a \code{ggplot} containing bars or
#' columns, it computes the distortion introduced by a baseline that doesn't
#' start at zero, which is by far the most common way a real figure lies: a bar
#' whose length no longer is the quantity it stands for.
#'
#' @param x Either a numeric vector of underlying data values, or a
#'   \code{ggplot} object.
#' @param graphic For the numeric method, a numeric vector of the same length
#'   giving the sizes drawn in the graphic.
#' @param ... Unused.
#' @return A numeric lie factor, or \code{NA} when there's nothing to compare.
#'   The \code{ggplot} method returns \code{1} for a plot with no bars or with
#'   a zero baseline.
#' @export
#' @examples
#' # Tufte's fuel-economy example: an 18 percent change drawn as 783 percent.
#' lie_factor(c(18.0, 27.5), c(0.6, 5.3))
#'
#' library(ggplot2)
#' d <- data.frame(g = c("a", "b"), v = c(100, 110))
#' lie_factor(ggplot(d, aes(g, v)) + geom_col() +
#'              coord_cartesian(ylim = c(95, 115)))
lie_factor <- function(x, ...) UseMethod("lie_factor")

#' @rdname lie_factor
#' @export
lie_factor.numeric <- function(x, graphic, ...) {
  if (missing(graphic)) .abort("Supply {.arg graphic}, the sizes actually drawn.")
  if (length(x) != length(graphic)) {
    .abort("{.arg x} and {.arg graphic} must be the same length.")
  }
  ok <- is.finite(x) & is.finite(graphic)
  x <- x[ok]; graphic <- graphic[ok]
  if (length(x) < 2) return(NA_real_)

  data_effect <- .proportional_change(x)
  graphic_effect <- .proportional_change(graphic)
  if (!is.finite(data_effect) || data_effect == 0) return(NA_real_)
  graphic_effect / data_effect
}

#' @noRd
.proportional_change <- function(v) {
  first <- v[1]
  last <- v[length(v)]
  if (!is.finite(first) || first == 0) return(NA_real_)
  abs(last - first) / abs(first)
}

#' @rdname lie_factor
#' @export
lie_factor.ggplot <- function(x, ...) {
  built <- tryCatch(ggplot2::ggplot_build(x), error = function(e) NULL)
  if (is.null(built)) return(NA_real_)

  geoms <- .layer_geoms(x)
  bar_layers <- which(geoms %in% c("Bar", "Col", "ColTufte", "Rect"))
  if (length(bar_layers) == 0) return(1)

  ranges <- built$layout$panel_params
  out <- vapply(bar_layers, function(i) {
    d <- built$data[[i]]
    ax <- .bar_axes(d, built$plot$coordinates)
    if (!all(c(ax$lo, ax$hi) %in% names(d))) return(NA_real_)

    # On a transformed scale a bar's length is no longer proportional to
    # anything the reader can recover, and there is no single number that
    # describes the distortion. Returning 1 would read as a clean bill of
    # health for one of the more misleading things you can do to a bar chart.
    if (.nonlinear_position_scale(built, ax$data)) return(NA_real_)

    values <- d[[ax$hi]]
    if (length(values) < 2 || !is.finite(diff(range(values)))) return(NA_real_)

    baseline <- suppressWarnings(min(unlist(lapply(ranges, function(pp) {
      r <- .panel_range_of(pp)[[ax$panel]]
      if (is.null(r)) NA_real_ else r[1]
    })), na.rm = TRUE))
    if (!is.finite(baseline) || baseline <= 0) return(1)

    lo <- min(values); hi <- max(values)
    data_effect <- .proportional_change(c(lo, hi))
    graphic_effect <- .proportional_change(c(lo - baseline, hi - baseline))
    if (!is.finite(data_effect) || data_effect == 0) return(NA_real_)
    graphic_effect / data_effect
  }, numeric(1))

  out <- out[is.finite(out)]
  if (length(out) == 0) return(NA_real_)
  # Report the worst offender.
  out[which.max(abs(log(out)))]
}

# Which axis carries a bar's length, in three different senses.
#
# The built data follows the layer's own orientation: a horizontal bar keeps
# its length in xmin/xmax. So does the scale, since a scale is attached to a
# variable rather than to a side of the panel. The drawn panel follows both the
# layer orientation and coord_flip(), which swaps the sides at render time
# without touching either of the other two.
#' @noRd
.bar_axes <- function(d, coordinates = NULL) {
  flipped <- isTRUE(d$flipped_aes[1])
  coord_flipped <- inherits(coordinates, "CoordFlip")
  data_axis <- if (flipped) "x" else "y"
  list(
    data = data_axis,
    panel = if (xor(flipped, coord_flipped)) "x" else "y",
    hi = paste0(data_axis, "max"),
    lo = paste0(data_axis, "min")
  )
}

# Name of a position scale's transformation, or NA if it cannot be determined.
#' @noRd
.y_transform_name <- function(built, axis = "y") {
  slot <- if (identical(axis, "x")) "panel_scales_x" else "panel_scales_y"
  s <- tryCatch(built$layout[[slot]][[1]], error = function(e) NULL)
  if (is.null(s)) return(NA_character_)
  nm <- tryCatch(s$get_transformation()$name, error = function(e) NULL)
  if (is.null(nm)) nm <- tryCatch(s$trans$name, error = function(e) NULL)
  if (is.null(nm)) NA_character_ else as.character(nm)
}

#' @noRd
.nonlinear_position_scale <- function(built, axis = "y") {
  nm <- .y_transform_name(built, axis)
  !is.na(nm) && !nm %in% c("identity", "reverse")
}

#' @rdname lie_factor
#' @export
lie_factor.default <- function(x, ...) {
  .abort("{.fun lie_factor} needs a numeric vector or a ggplot object.")
}

#' Data density
#'
#' The number of entries in the data matrix divided by the area of the data
#' graphic, in square inches. Tufte's complaint about most published statistical
#' graphics is that they're enormous and say almost nothing: a chart carrying
#' four numbers over half a page has a data density near zero, and the numbers
#' would have been better set as a sentence.
#'
#' The data matrix here is counted as the number of rows drawn, times the number
#' of distinct variables mapped to aesthetics. Positional aesthetics count;
#' constants set outside \code{aes()} don't, because they carry no data.
#'
#' @param plot A \code{ggplot} object.
#' @param width,height Intended printed size in inches. Defaults to 6.5 by 4.
#' @param panel_only Logical. Measure against the panel area rather than the
#'   whole figure? Defaults to \code{TRUE}, which is what Tufte means by "the
#'   data graphic". The panel share is estimated by rendering the plot.
#' @return An object of class \code{tufte_density}: a list with
#'   \code{density} (entries per square inch), \code{entries}, \code{rows},
#'   \code{variables} and \code{area}.
#' @export
#' @examples
#' library(ggplot2)
#' data_density(ggplot(mtcars, aes(wt, mpg)) + geom_point())
data_density <- function(plot, width = 6.5, height = 4, panel_only = TRUE) {
  .check_gg(plot)
  built <- ggplot2::ggplot_build(plot)

  rows <- .distinct_rows(plot, built)
  vars <- unique(unlist(lapply(.all_mappings(plot), .mapped_base_vars)))
  vars <- vars[!is.na(vars) & nzchar(vars)]
  n_vars <- max(length(vars), 1L)
  entries <- rows * n_vars

  area <- width * height
  if (panel_only) {
    share <- .panel_area_share(plot, width, height)
    if (is.finite(share) && share > 0) area <- area * share
  }

  structure(
    list(
      density = entries / area,
      entries = entries,
      rows = rows,
      variables = n_vars,
      variable_names = vars,
      area = area
    ),
    class = "tufte_density"
  )
}

# How many rows of data the graphic actually carries.
#
# Summing rows across layers is wrong, because a range frame, a rug and a line
# drawn over the same points all re-read the same data: three layers over
# thirty-two observations are still thirty-two numbers, not ninety-six. Layers
# are therefore grouped by the data they read, and each group contributes the
# largest number of marks any one of its layers draws. A layer carrying its own
# data, such as an annotation, counts separately, as it should.
#' @noRd
.distinct_rows <- function(plot, built) {
  n <- length(plot$layers)
  if (n == 0) return(nrow(plot$data %||% data.frame()))

  sources <- lapply(plot$layers, function(l) {
    if (is.null(l$data) || inherits(l$data, "waiver")) plot$data else l$data
  })
  drawn <- vapply(seq_len(n), function(i) {
    d <- built$data[[i]]
    if (is.null(d)) 0 else nrow(d)
  }, numeric(1))

  total <- 0
  seen <- list()
  for (i in seq_len(n)) {
    match_at <- NA_integer_
    for (j in seq_along(seen)) {
      if (identical(seen[[j]]$source, sources[[i]])) {
        match_at <- j
        break
      }
    }
    if (is.na(match_at)) {
      seen[[length(seen) + 1]] <- list(source = sources[[i]], rows = drawn[i])
    } else {
      seen[[match_at]]$rows <- max(seen[[match_at]]$rows, drawn[i])
    }
  }
  for (s in seen) total <- total + s$rows
  total
}

#' @export
print.tufte_density <- function(x, ...) {
  cli::cli_h3("Data density")
  cli::cli_text(
    "{.strong {round(x$density, 1)}} numbers per square inch of data graphic."
  )
  cli::cli_ul(c(
    "{x$rows} row{?s} x {x$variables} mapped variable{?s} = {x$entries} entries",
    "over {round(x$area, 2)} square inches"
  ))
  invisible(x)
}

# Fraction of the figure area taken up by panels.
#' @noRd
.panel_area_share <- function(plot, width, height) {
  tryCatch({
    gt <- .grob_of(plot)
    f <- tempfile(fileext = ".png")
    args <- list(filename = f, width = width, height = height, units = "in",
                 res = 72)
    if (isTRUE(capabilities("cairo"))) args$type <- "cairo"
    old <- grDevices::dev.cur()
    do.call(grDevices::png, args)
    on.exit({
      grDevices::dev.off()
      if (old > 1) try(grDevices::dev.set(old), silent = TRUE)
      unlink(f)
    }, add = TRUE)

    panels <- gt$layout[grepl("^panel", gt$layout$name), , drop = FALSE]
    if (nrow(panels) == 0) return(NA_real_)
    # Panel dimensions are null units and resolve to zero under conversion, so
    # the panel area is what is left after every fixed element has taken its
    # share of the canvas.
    fixed_w <- sum(grid::convertWidth(gt$widths, "in", valueOnly = TRUE))
    fixed_h <- sum(grid::convertHeight(gt$heights, "in", valueOnly = TRUE))
    w <- width - fixed_w
    h <- height - fixed_h
    if (!is.finite(w) || !is.finite(h) || w <= 0 || h <= 0) return(NA_real_)
    (w * h) / (width * height)
  }, error = function(e) NA_real_)
}
