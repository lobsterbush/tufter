#' WCAG contrast ratio between two colours
#'
#' Compare the relative luminance of two colours using the Web Content
#' Accessibility Guidelines. The ratio ranges from 1 for identical colours to
#' 21 for black against white. The guidelines specify at least 4.5 for body
#' text and 3 for large text and graphical objects.
#'
#' @param colour,background Colours, in any form \code{\link[grDevices]{col2rgb}}
#'   accepts. Vectors are recycled against each other.
#' @return A numeric vector of contrast ratios.
#' @details Embedded transparency is composited against the background.
#'   A transparent background is first composited over white.
#' @seealso \code{\link{check_contrast}()}, which applies this to a whole plot.
#' @export
#' @examples
#' contrast_ratio("black", "white")
#' contrast_ratio(c("grey20", "grey50", "grey80"), "white")
contrast_ratio <- function(colour, background = "white") {
  if (!length(colour) || !length(background)) return(numeric(0))
  background <- .composite(background, NULL, "white")
  colour <- .composite(colour, NULL, background)
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

#' Check contrast in a plot
#'
#' Pale colours can make a figure hard to read. This function checks data-mark
#' colours and rendered theme text against the plot's background. That includes
#' axis labels and legend text with their own style settings.
#'
#' The default thresholds follow WCAG 2.1: 4.5 to 1 for text and 3 to 1 for
#' marks. Transparent colours are composited onto the background before checking.
#'
#' There are limits. The check doesn't resolve overlapping marks, text on filled
#' labels, or separate legend and strip backgrounds. I'd also inspect the figure
#' where it'll be used, particularly if it's going on a projector.
#'
#' @param plot A \code{ggplot} object.
#' @param background The colour to measure against. By default this is taken
#'   from the plot's own panel or plot background, falling back to white.
#' @param text_min,mark_min Minimum acceptable ratios for text and for data
#'   marks. Default to 4.5 and 3.
#' @return A tibble with one row per distinct colour: what it's used for, the
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
  override_background <- background
  background <- background %||% .plot_background(theme)

  rows <- list()
  add <- function(role, colour, threshold, bg = background) {
    colour <- unique(colour[!is.na(colour) & nzchar(colour)])
    colour <- colour[!colour %in% c("NA", "transparent")]
    if (length(colour) == 0) return(invisible(NULL))
    rows[[length(rows) + 1]] <<- data.frame(
      role = role, colour = colour,
      ratio = contrast_ratio(colour, bg),
      threshold = threshold,
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }

  # A layer that draws words is text, and text carries the higher minimum. Every
  # layer used to be a "data mark" at 3:1, so grey text at 4.48:1 passed a check
  # whose own documentation promises 4.5:1 for anything read as words.
  geoms <- .layer_geoms(plot)
  is_text <- geoms %in% c("Text", "Label", "TextLast", "TextFirst", "TextRepel",
                          "LabelRepel")
  pick <- function(which) {
    idx <- which(if (identical(which, "text")) is_text else !is_text)
    idx <- idx[idx <= length(built$data)]
    unlist(lapply(idx, function(i) {
      d <- built$data[[i]]
      c(.composite(d$colour, d$alpha, background),
        .composite(d$fill, d$alpha, background))
    }))
  }
  add("data mark", pick("mark"), mark_min)
  add("data label", pick("text"), text_min)

  # Read rendered text grobs so axis-specific overrides, legend labels and
  # inherited colours are checked only when the text is actually present.
  gt <- .grob_of(plot)
  outer <- override_background %||%
    .composite(.el_get(theme$plot.background, "fill") %||% "white", NULL, "white")
  for (i in seq_along(gt$grobs)) {
    name <- gt$layout$name[i]
    role <- if (name %in% c("title", "subtitle", "caption")) name else
      if (grepl("^axis-", name)) "axis text" else
      if (grepl("^[xy]lab-", name)) "axis title" else
      if (grepl("^guide-box", name)) "legend text" else
      if (grepl("^strip-", name)) "strip text" else NULL
    if (is.null(role)) next
    colours <- unlist(lapply(.collect_text_grobs(gt$grobs[[i]]), function(g) g$gp$col))
    add(role, colours, text_min, bg = outer)
  }
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

  out <- unique(do.call(rbind, rows))
  out$passes <- out$ratio >= out$threshold
  out$ratio <- round(out$ratio, 2)
  # A gridline is meant to be ignorable, so failing the mark threshold is
  # normal and not worth reporting as a problem.
  out$passes[out$role == "gridline"] <- TRUE
  tibble::as_tibble(out[order(out$ratio), , drop = FALSE])
}

#' @noRd
.plot_background <- function(theme) {
  outer <- .el_get(theme$plot.background, "fill") %||% "white"
  outer <- .composite(outer, NULL, "white")
  panel <- .el_get(theme$panel.background, "fill") %||% "transparent"
  .composite(panel, NULL, outer)
}

# What a semi-transparent colour actually looks like on the page.
#' @noRd
.composite <- function(colour, alpha, background) {
  if (!length(colour)) return(character(0))
  colour <- as.character(colour)
  n <- max(length(colour), length(background))
  colour <- rep_len(colour, n)
  rgba <- grDevices::col2rgb(colour, alpha = TRUE)
  embedded <- rgba[4, ] / 255
  alpha <- if (is.null(alpha)) embedded else rep_len(alpha, n)
  alpha[is.na(alpha)] <- embedded[is.na(alpha)]
  # An explicit layer alpha replaces the encoded alpha, including alpha = 1.
  opaque <- alpha == 1 & embedded < 1 & !is.na(colour)
  if (any(opaque)) {
    colour[opaque] <- grDevices::rgb(rgba[1, opaque], rgba[2, opaque],
                                    rgba[3, opaque], maxColorValue = 255)
  }
  needs <- alpha < 1 & !is.na(colour)
  if (!any(needs)) return(colour)
  bg <- grDevices::col2rgb(rep_len(background, n))[ , needs, drop = FALSE]
  fg <- rgba[1:3, needs, drop = FALSE]
  a <- matrix(alpha[needs], nrow = 3, ncol = sum(needs), byrow = TRUE)
  mixed <- fg * a + bg * (1 - a)
  colour[needs] <- grDevices::rgb(
    mixed[1, ], mixed[2, ], mixed[3, ], maxColorValue = 255
  )
  colour
}
