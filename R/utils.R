#' Internal helpers
#'
#' @keywords internal
#' @noRd
NULL

# Abort and warn, evaluating any cli {} expressions in the caller's frame
# rather than in this helper's.
#' @noRd
.abort <- function(..., .envir = rlang::caller_env()) {
  cli::cli_abort(c(...), call = .envir, .envir = .envir)
}

#' @noRd
.warn <- function(..., .envir = rlang::caller_env()) {
  cli::cli_warn(c(...), call = .envir, .envir = .envir)
}

# Is this a ggplot object?
#' @noRd
.is_gg <- function(p) inherits(p, "ggplot")

#' @noRd
.check_gg <- function(p, arg = "plot") {
  if (!.is_gg(p)) {
    cli::cli_abort("{.arg {arg}} must be a ggplot object, not {.cls {class(p)[1]}}.",
                   call = rlang::caller_env())
  }
  invisible(TRUE)
}

# Names of the geoms used in a plot, e.g. c("point", "line").
#' @noRd
.layer_geoms <- function(p) {
  vapply(
    p$layers,
    function(l) {
      cls <- class(l$geom)[1]
      sub("^Geom", "", cls)
    },
    character(1)
  )
}

# Names of the stats used in a plot.
#' @noRd
.layer_stats <- function(p) {
  vapply(p$layers, function(l) sub("^Stat", "", class(l$stat)[1]), character(1))
}

# All aesthetic mappings in force, plot-level plus layer-level, as a named list
# of quosures.
#' @noRd
.all_mappings <- function(p) {
  maps <- c(list(p$mapping), lapply(p$layers, function(l) l$mapping))
  maps <- maps[lengths(maps) > 0]
  do.call(c, maps)
}

# Name the variable behind a mapping. A bare symbol gives its own name; an
# expression like factor(cyl) gives the whole expression, so that the same
# transformation of the same column is recognised wherever it appears. A
# literal returns NA, because a constant carries no data.
# The columns an aesthetic actually reads. factor(cyl) and cyl both come back
# as "cyl", which is what you want when counting how many variables a graphic
# carries, and when asking whether one variable has been encoded twice.
#' @noRd
.mapped_base_vars <- function(quo) {
  if (is.null(quo)) return(character(0))
  expr <- if (rlang::is_quosure(quo)) rlang::quo_get_expr(quo) else quo
  if (is.symbol(expr)) {
    name <- as.character(expr)
    return(setdiff(name, c(".data", ".env")))
  }
  if (is.call(expr)) {
    operator <- as.character(expr[[1]])[1]
    if (operator %in% c("$", "[[") && length(expr) >= 3 &&
        identical(expr[[2]], as.name(".env"))) return(character(0))
    if (operator %in% c("$", "[[") && length(expr) >= 3 &&
        identical(expr[[2]], as.name(".data"))) {
      key <- expr[[3]]
      if (is.character(key) || (operator == "$" && is.symbol(key))) {
        return(as.character(key))
      }
      return(character(0))
    }
    return(unique(unlist(lapply(as.list(expr)[-1], .mapped_base_vars),
                         use.names = FALSE)))
  }
  character(0)
}

#' @noRd
.mapped_var <- function(quo) {
  if (is.null(quo)) return(NA_character_)
  expr <- if (rlang::is_quosure(quo)) rlang::quo_get_expr(quo) else quo
  if (is.symbol(expr)) return(as.character(expr))
  if (is.call(expr)) return(paste(deparse(expr), collapse = ""))
  NA_character_
}

# Round while keeping a fixed number of decimals for printing.
#' @noRd
.fmt <- function(x, digits = 2) formatC(x, format = "f", digits = digits)

#' @noRd
# Which axis carries a bar's length, in each of the three frames that disagree
# about it. This is the one place that answers the question; three separate
# answers to it were three separate bugs.
#
#   data   the aesthetic the values are mapped to. ggplot2 records this as
#          flipped_aes, set when the user writes aes(value, category) or passes
#          orientation = "y".
#   panel  the side of the drawn panel the values end up on. coord_flip()
#          swaps the sides at render time without touching the data or the
#          scales, so it composes with flipped_aes rather than replacing it.
#   hi/lo  the built-data columns holding the bar's ends.
#
# `data` may be a built-data frame or a bare logical saying whether the layer
# is flipped, so callers that have only one of the two can still ask.
.bar_axes <- function(d, coordinates = NULL) {
  flipped <- if (is.logical(d)) isTRUE(d[1]) else isTRUE(d$flipped_aes[1])
  coord_flipped <- inherits(coordinates, "CoordFlip")
  data_axis <- if (flipped) "x" else "y"
  list(
    data = data_axis,
    panel = if (xor(flipped, coord_flipped)) "x" else "y",
    hi = paste0(data_axis, "max"),
    lo = paste0(data_axis, "min")
  )
}



# The five-number summary the quartile frame and its axis labels both use.
# stats::quantile(type = 7) is R's default and what ggplot2's geom_boxplot()
# uses, so the box plot, the frame and the labels agree. Tukey's hinges, from
# fivenum(), sit elsewhere for most sample sizes.
#
# Fewer than four distinct values is not a summary. The frame draws a plain
# range there, so this returns the two ends and the labels say nothing the
# frame does not draw.
#' @noRd
.five_number <- function(v) {
  v <- v[is.finite(v)]
  if (length(v) == 0) return(numeric(0))
  if (length(unique(v)) < 4) return(range(v))
  as.numeric(stats::quantile(v, probs = c(0, 0.25, 0.5, 0.75, 1),
                             names = FALSE, type = 7))
}

# A width or a height has to be a positive finite number of inches. Zero gave
# an infinite data density and a negative width gave a negative banked height,
# both without complaint.
#' @noRd
.check_size <- function(width, height = NULL) {
  ok <- function(v) is.numeric(v) && length(v) == 1 && is.finite(v) && v > 0
  if (!ok(width)) .abort("{.arg width} must be a single positive number of inches.")
  if (!is.null(height) && !ok(height)) {
    .abort("{.arg height} must be a single positive number of inches.")
  }
  invisible(TRUE)
}

# Which panel edges a frame or rug draws on. The drawing code matches with
# grepl(fixed = TRUE), so "BL" and "LB", the natural typos for "bl", matched
# nothing and the layer drew nothing without a word. geom_col_tufte() already
# refuses a bad `sides`; the frame and rug geoms did not.
#' @noRd
.check_frame_sides <- function(sides) {
  if (!is.character(sides) || length(sides) != 1 || is.na(sides)) {
    .abort('{.arg sides} must be a single string made of "t", "r", "b" and "l".')
  }
  chars <- strsplit(sides, "")[[1]]
  bad <- setdiff(chars, c("t", "r", "b", "l"))
  if (!nzchar(sides) || length(bad)) {
    .abort(c(
      '{.arg sides} must be a single string made of "t", "r", "b" and "l", such as {.val bl}.',
      i = if (length(bad)) 'Got {.val {sides}}; {.val {bad}} {?is/are} not {?a side/sides}. The letters are lower case.'
          else 'Got an empty string, so nothing would be drawn.'
    ))
  }
  sides
}

# A gap opened at each interior quartile, as a fraction of the axis. Wide enough
# and every segment inverts, leaving nothing to draw and a zero-length unit for
# grid, which is an error rather than an empty frame.
#' @noRd
.check_gap <- function(gap) {
  if (!is.numeric(gap) || length(gap) != 1 || !is.finite(gap) ||
      gap < 0 || gap >= 1) {
    .abort("{.arg gap} must be a single number from 0 up to but not including 1, as a fraction of the axis.")
  }
  gap
}

# Standard Tufte line weight: hairlines, not rules.
#' @noRd
.hairline <- 0.3

# Evaluate something that measures grobs, with a device guaranteed open.
#
# Measuring text needs a graphics device to measure against. With none open, R
# starts the default one, which in a non-interactive session is pdf() and leaves
# an unasked-for Rplots.pdf in the user's working directory. pdf(NULL) is a
# device that writes no file, so the measurement borrows one and gives it back.
#
# This wraps the whole measurement rather than the grob build alone. Building
# the gtable under a guard and then calling convertWidth() on the result once
# the guard has closed puts you right back where you started, because the unit
# conversion is what needs the device, not just the build.
#' @noRd
.with_null_device <- function(expr) {
  if (grDevices::dev.cur() == 1L) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  force(expr)
}

# Build a plot's gtable without side effects. Safe on its own; anything that
# goes on to convert units from the result belongs inside .with_null_device().
#' @noRd
.grob_of <- function(plot) {
  .with_null_device(ggplot2::ggplotGrob(plot))
}

# Give a grob a unique name, as ggplot2 does internally for its own layers.
# A zeroGrob is left alone: it draws nothing, so it needs no identity.
#' @noRd
.ggname <- function(prefix, grob) {
  if (inherits(grob, "zeroGrob")) return(grob)
  grob$name <- grid::grobName(grob, prefix)
  grob
}
