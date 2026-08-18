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
  if (is.symbol(expr) || is.call(expr)) return(all.vars(expr))
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

# Standard Tufte line weight: hairlines, not rules.
#' @noRd
.hairline <- 0.3

# Build a plot's gtable without side effects.
#
# ggplotGrob() needs a graphics device to measure text against. With none open,
# R starts the default device, which in a non-interactive session is pdf() and
# leaves an unasked-for Rplots.pdf in the user's working directory. pdf(NULL)
# is a device that writes no file, so the measurement borrows one and gives it
# back.
#' @noRd
.grob_of <- function(plot) {
  if (grDevices::dev.cur() == 1L) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  ggplot2::ggplotGrob(plot)
}

# Give a grob a unique name, as ggplot2 does internally for its own layers.
# A zeroGrob is left alone: it draws nothing, so it needs no identity.
#' @noRd
.ggname <- function(prefix, grob) {
  if (inherits(grob, "zeroGrob")) return(grob)
  grob$name <- grid::grobName(grob, prefix)
  grob
}
