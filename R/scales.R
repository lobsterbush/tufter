#' Tufte's colour palettes
#'
#' These four palettes are intended for different uses. Choose one for the
#' comparison you want readers to make, then check the contrast in your figure.
#'
#' \describe{
#'   \item{\code{"grey"}}{A sequence of greys for ordered values.}
#'   \item{\code{"accent"}}{Greys with one red accent, assigned to the last
#'     level. Put the series you want to highlight last in the factor order.
#'     This draws on the use of value for layering in
#'     \emph{Envisioning Information}.}
#'   \item{\code{"muted"}}{Desaturated earth tones, drawing on the maps and
#'     timetables Tufte reproduces. Check that they remain readable at the
#'     size you'll use.}
#'   \item{\code{"divergent"}}{A muted blue-to-red sequence for signed values,
#'     with a neutral midpoint.}
#' }
#'
#' @param palette One of \code{"grey"}, \code{"accent"}, \code{"muted"},
#'   \code{"divergent"}.
#' @return For \code{tufte_pal()}, a function of \code{n} returning \code{n}
#'   colours. For \code{tufte_colours()}, a character vector of hex colours.
#' @export
#' @examples
#' tufte_pal("muted")(4)
#' tufte_colours("accent")
tufte_pal <- function(palette = c("grey", "accent", "muted", "divergent")) {
  palette <- match.arg(palette)
  cols <- tufte_colours(palette)

  function(n) {
    if (n < 1) return(character(0))
    if (palette == "divergent") {
      return(grDevices::colorRampPalette(cols)(n))
    }
    if (palette == "grey") {
      # Evenly spaced greys, dark to light, never reaching white.
      return(grDevices::grey.colors(n, start = 0.15, end = 0.75, gamma = 1))
    }
    if (palette == "accent") {
      # The whole point of this palette is that one level is the signal, so it
      # has to survive every n. Taking the first n of a fixed vector did not:
      # with two series you got two greys and no accent at all, which is the
      # one thing the palette exists to provide. The signal is the last colour,
      # and the greys fill in ahead of it.
      signal <- cols[length(cols)]
      greys <- cols[-length(cols)]
      if (n == 1) return(greys[1])
      if (n - 1 > length(greys)) {
        .warn(c(
          "Palette {.val accent} has {length(greys)} greys but {n - 1} were requested.",
          i = "The extra greys are interpolated, so neighbouring levels will be harder to tell apart than the palette intends."
        ))
        greys <- grDevices::colorRampPalette(greys)(n - 1)
      }
      return(c(greys[seq_len(n - 1)], signal))
    }
    if (n > length(cols)) {
      .warn(c(
        "Palette {.val {palette}} has {length(cols)} colours but {n} were requested.",
        i = "The extra colours are interpolated, so neighbouring levels will be harder to tell apart than the palette intends."
      ))
      return(grDevices::colorRampPalette(cols)(n))
    }
    cols[seq_len(n)]
  }
}

#' @rdname tufte_pal
#' @export
tufte_colours <- function(palette = c("grey", "accent", "muted", "divergent")) {
  palette <- match.arg(palette)
  switch(palette,
    grey = c("#262626", "#4d4d4d", "#737373", "#999999", "#bfbfbf"),
    # Greys first, the signal colour last, so tufte_pal() can always keep it.
    accent = c("#8c8c8c", "#b3b3b3", "#d9d9d9", "#595959", "#c8102e"),
    muted = c("#7c6a55", "#8a9a5b", "#9c6b6b", "#5b7c8a", "#b0a084", "#6b6b6b"),
    divergent = c("#4a6b82", "#93a9b8", "#d8d5cd", "#c49a8a", "#a1483c")
  )
}

#' @rdname tufte_pal
#' @export
tufte_colors <- tufte_colours

#' Tufte colour and fill scales
#'
#' Apply the palettes from \code{\link{tufte_pal}()} to discrete or continuous
#' colour and fill mappings.
#'
#' @inheritParams tufte_pal
#' @param ... Passed to \code{\link[ggplot2]{discrete_scale}()} or
#'   \code{\link[ggplot2]{continuous_scale}()}.
#' @param reverse Logical. Reverse the palette order?
#' @return A \code{ggplot2} scale.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
#'   geom_point() +
#'   scale_colour_tufte("accent") +
#'   theme_tufte()
scale_colour_tufte <- function(palette = "grey", ..., reverse = FALSE) {
  pal <- tufte_pal(palette)
  ggplot2::discrete_scale(
    "colour", palette = function(n) {
      out <- pal(n)
      if (reverse) rev(out) else out
    }, ...
  )
}

#' @rdname scale_colour_tufte
#' @export
scale_color_tufte <- scale_colour_tufte

#' @rdname scale_colour_tufte
#' @export
scale_fill_tufte <- function(palette = "grey", ..., reverse = FALSE) {
  pal <- tufte_pal(palette)
  ggplot2::discrete_scale(
    "fill", palette = function(n) {
      out <- pal(n)
      if (reverse) rev(out) else out
    }, ...
  )
}

#' @rdname scale_colour_tufte
#' @export
scale_colour_tufte_c <- function(palette = "divergent", ..., reverse = FALSE) {
  cols <- tufte_colours(palette)
  if (reverse) cols <- rev(cols)
  ggplot2::scale_colour_gradientn(colours = cols, ...)
}

#' @rdname scale_colour_tufte
#' @export
scale_fill_tufte_c <- function(palette = "divergent", ..., reverse = FALSE) {
  cols <- tufte_colours(palette)
  if (reverse) cols <- rev(cols)
  ggplot2::scale_fill_gradientn(colours = cols, ...)
}
