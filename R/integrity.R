#' Data-ink ratio
#'
#' Tufte defines the data-ink ratio as the share of a graphic's ink devoted to
#' the non-redundant display of data. This function estimates it by rendering
#' the plot twice, with and without its data layers, and comparing the pixels.
#'
#' Pixels are weighted by their distance from the background colour.
#' Overlapping marks count once. Redundant marks still count as data ink because
#' the function can't determine whether they repeat information. These choices
#' matter, particularly for dense scatterplots and large filled shapes.
#'
#' A pie chart can have a higher ratio than a dot plot of the same numbers
#' because its filled wedges occupy more of the canvas. That doesn't tell us
#' which chart is easier to read. I use the estimate to compare drafts at the
#' same size and resolution, alongside \code{\link{tufte_audit}()} and a look at
#' the figure itself.
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
  .check_size(width, height)
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
#
# This used to drop children whose name began with "geom", on the assumption
# that every layer is named that way. ggplot2 only names some of them:
# GeomPath, GeomLine, GeomStep, GeomText and GeomSegment return bare grid
# grobs called GRID.polyline, GRID.text and GRID.segments. Those were never
# stripped, so they stayed in the furniture rendering and were subtracted from
# the data ink. A plain line chart measured a data-ink ratio of zero.
#
# The furniture is the short, stable list instead: the grill, which holds the
# background and the gridlines, the panel border, and the zeroGrob placeholders
# ggplot2 pads the panel with. Anything else in the panel is a layer. Naming a
# new furniture element would over-count data, which is a far safer way to be
# wrong than erasing the data.
#' @noRd
.strip_data_grobs <- function(gt) {
  panels <- which(grepl("^panel", gt$layout$name))
  for (i in panels) {
    g <- gt$grobs[[i]]
    if (!inherits(g, "gTree") || is.null(g$children)) next
    nms <- names(g$children)
    nms[is.na(nms)] <- ""
    keep <- grepl("^grill", nms) |
      grepl("^panel\\.border", nms) |
      vapply(g$children, inherits, logical(1), "zeroGrob")
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
#' The lie factor divides the proportional change shown in a graphic by the
#' proportional change in the data. A value of one means those changes agree.
#' Tufte treats values outside roughly 0.95 to 1.05 as distortion.
#'
#' Supply two numeric vectors to compare data values with the sizes drawn.
#' Or supply a \code{ggplot} with bars to measure the effect of a non-zero
#' baseline. The plot method is limited to supported bar comparisons; a result
#' of one isn't a general assessment of the figure's accuracy.
#'
#' @param x Either a numeric vector of underlying data values, or a
#'   \code{ggplot} object.
#' @param graphic For the numeric method, a numeric vector of the same length
#'   giving the sizes drawn in the graphic.
#' @param ... Unused.
#' @return A numeric lie factor, or \code{NA} when there's nothing to compare.
#'   The \code{ggplot} method returns \code{1} for a plot with no bars or with
#'   a zero baseline. For supported Cartesian bars it checks each panel and
#'   returns the largest distortion, including negative and reversed axes.
#'   Nonlinear coordinates and truncated stacked or floating bars return
#'   \code{NA} when no supported comparison is available.
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
  # GeomRect is not a bar. A background band or an interval rectangle has its
  # own ymin, and treating the panel floor as its baseline manufactured a
  # distortion figure for a figure containing no bars at all. Bars and columns
  # are the geoms whose length is meant to be read from a zero baseline.
  bar_layers <- which(geoms %in% c("Bar", "Col", "ColTufte"))
  if (length(bar_layers) == 0) return(1)

  if (!inherits(built$layout$coord, "CoordCartesian")) return(NA_real_)
  out <- unlist(lapply(bar_layers, function(i) {
    d <- built$data[[i]]
    ax <- .bar_axes(d, built$layout$coord)
    if (!all(c(ax$lo, ax$hi) %in% names(d))) return(NA_real_)
    if (.nonlinear_position_scale(built, ax$data)) return(NA_real_)
    vapply(split(d, d$PANEL, drop = TRUE), function(part) {
      pp <- built$layout$panel_params[[as.integer(part$PANEL[1])]]
      limits <- sort(.panel_range_of(pp)[[ax$panel]])
      if (length(limits) != 2L || any(!is.finite(limits))) return(NA_real_)
      if (limits[1] <= 0 && limits[2] >= 0) return(1)
      # Floating/stacked intervals do not encode their values as lengths from
      # zero. Decline an unsupported numeric claim instead of using endpoints.
      if (any(part[[ax$lo]] != 0 & part[[ax$hi]] != 0)) return(NA_real_)
      values <- pmax(abs(part[[ax$lo]]), abs(part[[ax$hi]]))
      values <- values[is.finite(values)]
      if (length(values) < 2) return(NA_real_)
      baseline <- min(abs(limits))
      lo <- min(values); hi <- max(values)
      if (lo <= baseline) return(NA_real_)
      data_effect <- .proportional_change(c(lo, hi))
      graphic_effect <- .proportional_change(c(lo - baseline, hi - baseline))
      if (!is.finite(data_effect) || data_effect == 0) return(NA_real_)
      graphic_effect / data_effect
    }, numeric(1))
  }))
  out <- out[is.finite(out)]
  if (length(out) == 0) return(NA_real_)
  # Report the worst offender.
  unname(out[which.max(abs(log(out)))])
}

# Which axis carries a bar's length, in three different senses.
#
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
#' Estimate the number of data entries per square inch of a figure. This
#' implements Tufte's data-density measure. It can help you compare how much
#' information different versions of a figure occupy on the page.
#'
#' Entries are counted as pooled rows times the number of distinct variables
#' mapped to aesthetics. Constants outside \code{aes()} don't count.
#' Statistical layers and plots that combine data sources need care: the
#' function doesn't reconstruct a separate data matrix for each layer.
#'
#' Panel area is estimated from the rendered plot. If that estimate isn't
#' available, the function uses the whole canvas. I'd read the result alongside
#' the entry count and the figure, since a high density doesn't establish that
#' the information is useful.
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
  .check_size(width, height)
  built <- ggplot2::ggplot_build(plot)

  rows <- .distinct_rows(plot, built)
  vars <- .drawn_vars(plot)
  # No mapped variable means nothing varies with the data, so there are no
  # entries to count. Rounding that up to one invented a data matrix for a
  # graphic that carries none.
  entries <- rows * length(vars)

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
      variables = length(vars),
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
# The variables a figure actually draws. A layer aesthetic overrides the
# plot-level one of the same name rather than adding to it, and a layer with
# inherit.aes = FALSE takes none of them, so pooling every mapping counted
# columns that are never shown.
#' @noRd
.drawn_vars <- function(plot) {
  base <- plot$mapping %||% ggplot2::aes()
  per_layer <- lapply(plot$layers, function(l) {
    own <- l$mapping %||% ggplot2::aes()
    m <- if (isFALSE(l$inherit.aes)) own else utils::modifyList(as.list(base), as.list(own))
    unique(unlist(lapply(m, .mapped_base_vars)))
  })
  vars <- if (length(per_layer)) unique(unlist(per_layer)) else
    unique(unlist(lapply(base, .mapped_base_vars)))
  vars <- vars[!is.na(vars) & nzchar(vars)]
  vars
}

# data, such as an annotation, counts separately, as it should.
#' @noRd
.distinct_rows <- function(plot, built) {
  n <- length(plot$layers)
  # ggplot()$data is a waiver rather than NULL, so %||% never fired and
  # nrow(waiver()) returned NULL, giving back a malformed result object.
  if (n == 0) {
    d <- plot$data
    if (is.null(d) || inherits(d, "waiver")) return(0L)
    return(nrow(d))
  }

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
