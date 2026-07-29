#' Tufte's colour palettes
#'
#' Four palettes, each answering a different question about colour.
#'
#' \describe{
#'   \item{\code{"grey"}}{Tufte's default. Grey encodes an ordered variable
#'     without introducing a second, unwanted, categorical signal.}
#'   \item{\code{"accent"}}{Greys plus one signal red. Use when exactly one
#'     series matters and the rest are context. This is the palette that does
#'     the most work in \emph{Envisioning Information}: layering by value, not
#'     by hue.}
#'   \item{\code{"muted"}}{Desaturated earth tones, after the maps and
#'     timetables Tufte reproduces. Colours this weak sit behind text and
#'     annotation without fighting them.}
#'   \item{\code{"divergent"}}{A muted blue-to-red ramp for signed quantities,
#'     with a neutral rather than a white midpoint.}
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
    if (n > length(cols)) {
      .warn(c(
        "Palette {.val {palette}} has {length(cols)} colours but {n} were requested.",
        i = "More than about six hues stops being a code and starts being decoration."
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
    accent = c("#8c8c8c", "#b3b3b3", "#c8102e", "#d9d9d9", "#595959"),
    muted = c("#7c6a55", "#8a9a5b", "#9c6b6b", "#5b7c8a", "#b0a084", "#6b6b6b"),
    divergent = c("#4a6b82", "#93a9b8", "#d8d5cd", "#c49a8a", "#a1483c")
  )
}

#' @rdname tufte_pal
#' @export
tufte_colors <- tufte_colours

#' Tufte colour and fill scales
#'
#' Discrete and continuous scales built on \code{\link{tufte_pal}()}.
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
