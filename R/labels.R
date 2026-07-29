#' Label series directly instead of with a legend
#'
#' A legend makes the reader look away from the data, hold a colour in memory,
#' look back, and match. Tufte's rule is to integrate word and image: put the
#' name on the line. \code{geom_text_last()} labels each group at its largest x
#' value, which is where the eye leaves a time series;
#' \code{geom_text_first()} labels at the smallest.
#'
#' Both add horizontal space to the right or left of the panel by clipping off,
#' so pair them with \code{coord_cartesian(clip = "off")} and a plot margin, or
#' widen the x scale with \code{\link[ggplot2]{expansion}()}.
#'
#' @param mapping,data,position,na.rm,show.legend,inherit.aes,... Standard
#'   \code{ggplot2} layer arguments. See \code{\link[ggplot2]{layer}()}. The
#'   \code{label} aesthetic defaults to the grouping variable.
#' @param nudge_x,nudge_y Offsets applied to the label position, in data units.
#' @param hjust,vjust Text justification. Sensible defaults are chosen per side.
#' @param geom Either \code{"text"} (the default) or \code{"label"}.
#' @return A \code{ggplot2} layer.
#' @export
#' @examples
#' library(ggplot2)
#' d <- data.frame(
#'   year = rep(2000:2010, 3),
#'   value = c(cumsum(rnorm(11)), cumsum(rnorm(11)) + 3, cumsum(rnorm(11)) - 3),
#'   series = rep(c("A", "B", "C"), each = 11)
#' )
#' ggplot(d, aes(year, value, colour = series)) +
#'   geom_line() +
#'   geom_text_last(aes(label = series)) +
#'   scale_x_continuous(expand = expansion(mult = c(0.02, 0.1))) +
#'   theme_tufte() +
#'   theme(legend.position = "none")
geom_text_last <- function(mapping = NULL, data = NULL, position = "identity",
                           ..., nudge_x = 0, nudge_y = 0, hjust = 0,
                           vjust = 0.5, geom = c("text", "label"),
                           na.rm = FALSE, show.legend = FALSE,
                           inherit.aes = TRUE) {
  .layer_extreme(
    which = "last", mapping = mapping, data = data, position = position,
    nudge_x = nudge_x, nudge_y = nudge_y, hjust = hjust, vjust = vjust,
    geom = match.arg(geom), na.rm = na.rm, show.legend = show.legend,
    inherit.aes = inherit.aes, ...
  )
}

#' @rdname geom_text_last
#' @export
geom_text_first <- function(mapping = NULL, data = NULL, position = "identity",
                            ..., nudge_x = 0, nudge_y = 0, hjust = 1,
                            vjust = 0.5, geom = c("text", "label"),
                            na.rm = FALSE, show.legend = FALSE,
                            inherit.aes = TRUE) {
  .layer_extreme(
    which = "first", mapping = mapping, data = data, position = position,
    nudge_x = nudge_x, nudge_y = nudge_y, hjust = hjust, vjust = vjust,
    geom = match.arg(geom), na.rm = na.rm, show.legend = show.legend,
    inherit.aes = inherit.aes, ...
  )
}

#' @noRd
.layer_extreme <- function(which, mapping, data, position, nudge_x, nudge_y,
                           hjust, vjust, geom, na.rm, show.legend,
                           inherit.aes, ...) {
  if (nudge_x != 0 || nudge_y != 0) {
    if (!identical(position, "identity")) {
      .abort("Supply either {.arg position} or {.arg nudge_x}/{.arg nudge_y}, not both.")
    }
    position <- ggplot2::position_nudge(nudge_x, nudge_y)
  }
  ggplot2::layer(
    geom = geom, stat = StatExtreme, mapping = mapping, data = data,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(which = which, hjust = hjust, vjust = vjust, na.rm = na.rm, ...)
  )
}

#' @rdname geom_text_last
#' @format NULL
#' @usage NULL
#' @export
StatExtreme <- ggplot2::ggproto(
  "StatExtreme", ggplot2::Stat,
  required_aes = c("x", "y"),

  compute_group = function(data, scales, which = "last") {
    ok <- is.finite(data$x)
    if (!any(ok)) return(data[0, , drop = FALSE])
    data <- data[ok, , drop = FALSE]
    i <- if (identical(which, "last")) which.max(data$x) else which.min(data$x)
    data[i, , drop = FALSE]
  }
)

#' Add a source note to a figure
#'
#' Tufte's documentation principle: a graphic should say where its numbers came
#' from, on the graphic, so that the claim can be checked without hunting for
#' the surrounding text. This is a thin wrapper on \code{labs(caption = ...)}
#' that formats the note consistently.
#'
#' @param source Where the data came from.
#' @param note Optional extra note, appended after the source.
#' @param prefix Label placed before the source. Defaults to \code{"Source:"}.
#' @return A \code{ggplot2} labs object, to be added to a plot.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   theme_tufte() +
#'   label_source("Motor Trend, 1974", note = "n = 32 cars.")
label_source <- function(source, note = NULL, prefix = "Source:") {
  txt <- paste(prefix, source)
  if (!is.null(note)) txt <- paste0(txt, ". ", note)
  ggplot2::labs(caption = txt)
}
