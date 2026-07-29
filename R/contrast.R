#' WCAG contrast ratio between two colours
#'
#' The ratio of the relative luminances of two colours, as defined by the Web
#' Content Accessibility Guidelines. It runs from 1, for two identical colours,
#' to 21, for black on white. The guidelines ask for at least 4.5 for body text
#' and at least 3 for large text and for graphical objects such as the marks and
#' rules on a chart.
#'
#' @param colour,background Colours, in any form \code{\link[grDevices]{col2rgb}}
#'   accepts. Vectors are recycled against each other.
#' @return A numeric vector of contrast ratios.
#' @seealso \code{\link{check_contrast}()}, which applies this to a whole plot.
#' @export
#' @examples
#' contrast_ratio("black", "white")
#' contrast_ratio(c("grey20", "grey50", "grey80"), "white")
contrast_ratio <- function(colour, background = "white") {
  l1 <- .relative_luminance(colour)
  l2 <- .relative_luminance(background)
  n <- max(length(l1), length(l2))
  l1 <- rep_len(l1, n)
  l2 <- rep_len(l2, n)
  lighter <- pmax(l1, l2)
  darker <- pmin(l1, l2)
  (lighter + 0.05) / (darker + 0.05)
}

# WCAG 2.1 relative luminance: sRGB channels linearised, then weighted by the
# eye's sensitivity to each.
#' @noRd
.relative_luminance <- function(colour) {
  rgb <- grDevices::col2rgb(colour) / 255
  lin <- ifelse(rgb <= 0.03928, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  as.numeric(0.2126 * lin[1, ] + 0.7152 * lin[2, ] + 0.0722 * lin[3, ])
}

#' Check that a plot's ink is dark enough to see
#'
#' The strongest objection to maximising the data-ink ratio is that it is a
#' licence to draw in hairlines and pale greys, and that the result is elegant
#' and unreadable. This is the check that keeps the rest of the package honest:
#' it takes every colour the plot actually draws with, along with the text
#' colours the theme sets, and measures each against the background.
#'
#' The thresholds are the WCAG 2.1 ones: 4.5 to 1 for text, and 3 to 1 for
#' graphical objects, which is what data marks and rules are. These are minima
#' for people with moderately low vision, not targets, and a figure that clears
#' them can still be hard work in a badly lit lecture theatre.
#'
#' Colours drawn with transparency are measured as if composited onto the
#' background, since that is what the reader sees.
#'
#' @param plot A \code{ggplot} object.
#' @param background The colour to measure against. By default this is taken
#'   from the plot's own panel or plot background, falling back to white.
#' @param text_min,mark_min Minimum acceptable ratios for text and for data
#'   marks. Default to 4.5 and 3.
#' @return A tibble with one row per distinct colour: what it is used for, the
#'   colour, its contrast ratio against the background, the threshold applied,
#'   and whether it passes.
#' @export
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
#' check_contrast(p)
#'
#' # A figure drawn too faintly to read.
#' check_contrast(
#'   ggplot(mtcars, aes(wt, mpg)) + geom_point(colour = "grey85") + theme_tufte()
#' )
check_contrast <- function(plot, background = NULL, text_min = 4.5,
                           mark_min = 3) {
  .check_gg(plot)
  built <- ggplot2::ggplot_build(plot)
  theme <- .resolved_theme(plot)
  background <- background %||% .plot_background(theme)

  rows <- list()
  add <- function(role, colour, threshold) {
    colour <- unique(colour[!is.na(colour) & nzchar(colour)])
    colour <- colour[!colour %in% c("NA", "transparent")]
    if (length(colour) == 0) return(invisible(NULL))
    rows[[length(rows) + 1]] <<- data.frame(
      role = role, colour = colour,
      ratio = round(contrast_ratio(colour, background), 2),
      threshold = threshold,
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }

  marks <- unlist(lapply(built$data, function(d) {
    c(.composite(d$colour, d$alpha, background),
      .composite(d$fill, d$alpha, background))
  }))
  add("data mark", marks, mark_min)

  add("axis text", .el_get(theme$axis.text, "colour"), text_min)
  add("axis title", .el_get(theme$axis.title, "colour"), text_min)
  add("title", .el_get(theme$plot.title, "colour"), text_min)
  add("subtitle", .el_get(theme$plot.subtitle, "colour"), text_min)
  add("caption", .el_get(theme$plot.caption, "colour"), text_min)
  add("strip text", .el_get(theme$strip.text, "colour"), text_min)
  # A grid asked for on one axis only lives in the .x or .y element, so all
  # three have to be looked at.
  add("gridline", c(
    .el_get(theme$panel.grid.major, "colour"),
    .el_get(theme$panel.grid.major.x, "colour"),
    .el_get(theme$panel.grid.major.y, "colour")
  ), mark_min)

  if (length(rows) == 0) {
    return(tibble::tibble(
      role = character(0), colour = character(0), ratio = numeric(0),
      threshold = numeric(0), passes = logical(0)
    ))
  }

  out <- do.call(rbind, rows)
  out$passes <- out$ratio >= out$threshold
  # A gridline is meant to be ignorable, so failing the mark threshold is
  # normal and not worth reporting as a problem.
  out$passes[out$role == "gridline"] <- TRUE
  tibble::as_tibble(out[order(out$ratio), , drop = FALSE])
}

#' @noRd
.plot_background <- function(theme) {
  fill <- .el_get(theme$panel.background, "fill") %||%
    .el_get(theme$plot.background, "fill")
  if (is.null(fill) || is.na(fill) || identical(fill, "transparent")) {
    return("white")
  }
  fill
}

# What a semi-transparent colour actually looks like on the page.
#' @noRd
.composite <- function(colour, alpha, background) {
  if (is.null(colour)) return(character(0))
  colour <- as.character(colour)
  if (is.null(alpha)) return(colour)
  alpha <- rep_len(alpha, length(colour))
  needs <- !is.na(alpha) & alpha < 1 & !is.na(colour)
  if (!any(needs)) return(colour)

  bg <- as.vector(grDevices::col2rgb(background))
  fg <- grDevices::col2rgb(colour[needs])
  a <- matrix(alpha[needs], nrow = 3, ncol = sum(needs), byrow = TRUE)
  mixed <- fg * a + bg * (1 - a)
  colour[needs] <- grDevices::rgb(
    mixed[1, ], mixed[2, ], mixed[3, ], maxColorValue = 255
  )
  colour
}
