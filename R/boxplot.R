#' Tufte's minimal box plot
#'
#' This implements Tufte's box plot without the enclosing box or whisker caps.
#' Choose the version that makes the distribution easiest to read at your
#' figure's final size.
#'
#' \describe{
#'   \item{\code{"point"}}{The default. Two whisker lines leave a gap for the
#'     interquartile range, with a dot at the median.}
#'   \item{\code{"line"}}{A thin whisker line spans the range, a thicker segment
#'     marks the interquartile range, and a white break marks the median.}
#'   \item{\code{"offset"}}{The interquartile segment sits beside the whisker
#'     line. This can help when the whiskers are short.}
#' }
#'
#' @param mapping,data,stat,position,na.rm,show.legend,inherit.aes,... Standard
#'   \code{ggplot2} layer arguments. See \code{\link[ggplot2]{layer}()}.
#' @param type One of \code{"point"}, \code{"line"} or \code{"offset"}.
#' @param offset For \code{type = "offset"}, how far to shift the
#'   interquartile line, as a fraction of the category width. Defaults to
#'   \code{0.12}.
#' @param median_size Size of the median dot for \code{type = "point"}.
#'   Defaults to \code{1.6}.
#' @param box_linewidth Line width of the interquartile segment for the
#'   \code{"line"} and \code{"offset"} variants. Defaults to \code{1.6}.
#' @param outliers Logical. Draw outlying points beyond the whiskers? Defaults
#'   to \code{TRUE}. Tufte would keep them: they're data.
#' @return A \code{ggplot2} layer.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   geom_tufteboxplot() +
#'   theme_tufte()
#'
#' ggplot(mtcars, aes(factor(cyl), mpg)) +
#'   geom_tufteboxplot(type = "offset") +
#'   theme_tufte()
geom_tufteboxplot <- function(mapping = NULL, data = NULL, stat = "boxplot",
                              position = "dodge2", ...,
                              type = c("point", "line", "offset"),
                              offset = 0.12, median_size = 1.6,
                              box_linewidth = 1.6, outliers = TRUE,
                              na.rm = FALSE, show.legend = NA,
                              inherit.aes = TRUE) {
  # ggplot2 checks required_aes before it touches the geom, and a horizontal
  # box carries no x column at all, so no ggproto method is reached in time to
  # explain the refusal. The constructor is the only place that can.
  if (identical(list(...)$orientation, "y")) {
    .abort(c(
      "{.fn geom_tufteboxplot} draws vertical boxes only.",
      i = "Map the category to {.arg x} and the value to {.arg y}, then add {.code coord_flip()} to turn the finished plot on its side."
    ))
  }
  type <- match.arg(type)
  ggplot2::layer(
    geom = GeomTufteBoxplot, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(
      type = type, offset = offset, median_size = median_size,
      box_linewidth = box_linewidth, outliers = outliers, na.rm = na.rm, ...
    )
  )
}

#' @rdname geom_tufteboxplot
#' @format NULL
#' @usage NULL
#' @export
GeomTufteBoxplot <- ggplot2::ggproto(
  "GeomTufteBoxplot", ggplot2::Geom,
  required_aes = c("x", "lower", "upper", "middle", "ymin", "ymax"),
  draw_key = ggplot2::draw_key_pointrange,
  default_aes = ggplot2::aes(
    colour = "black", linewidth = 0.4, linetype = 1, alpha = NA,
    shape = 19, size = 1.6, fill = NA, weight = 1
  ),

  # StatBoxplot hands back xlower/xmiddle/xupper for a horizontal box, and this
  # geom is written around the vertical fields. setup_params runs before
  # ggplot2's required-aes check, which is the only place early enough to say
  # something useful; from setup_data the failure was already the unhelpful
  # "requires the following missing aesthetics: x".
  setup_data = function(data, params) {
    if (!is.null(data$xmiddle) || isTRUE(data$flipped_aes[1])) {
      .abort(c(
        "{.fn geom_tufteboxplot} draws vertical boxes only.",
        i = "Map the category to {.arg x} and the value to {.arg y}, then add {.code coord_flip()} to turn the finished plot on its side."
      ))
    }
    data$width <- data$width %||%
      params$width %||% (ggplot2::resolution(data$x, FALSE) * 0.9)
    data$xmin <- data$x - data$width / 2
    data$xmax <- data$x + data$width / 2
    data
  },

  draw_group = function(data, panel_params, coord,
                        type = "point", offset = 0.12, median_size = 1.6,
                        box_linewidth = 1.6, outliers = TRUE, na.rm = FALSE) {
    common <- data[rep(1, 1), setdiff(names(data), c("x", "y")), drop = FALSE]

    seg <- function(x, xend, y, yend, lwd = data$linewidth[1]) {
      d <- common
      d$x <- x; d$xend <- xend; d$y <- y; d$yend <- yend
      d$linewidth <- lwd
      d
    }

    grobs <- list()

    if (type == "point") {
      segs <- rbind(
        seg(data$x, data$x, data$ymin, data$lower),
        seg(data$x, data$x, data$upper, data$ymax)
      )
      grobs$whisker <- ggplot2::GeomSegment$draw_panel(segs, panel_params, coord)
      pt <- common
      pt$x <- data$x; pt$y <- data$middle; pt$size <- median_size
      pt$fill <- data$colour[1]
      grobs$median <- ggplot2::GeomPoint$draw_panel(pt, panel_params, coord)
    } else if (type == "line") {
      segs <- rbind(
        seg(data$x, data$x, data$ymin, data$ymax),
        seg(data$x, data$x, data$lower, data$upper, lwd = box_linewidth)
      )
      grobs$body <- ggplot2::GeomSegment$draw_panel(segs, panel_params, coord)
      pt <- common
      pt$x <- data$x; pt$y <- data$middle
      pt$size <- box_linewidth * 0.55
      pt$colour <- "white"; pt$fill <- "white"; pt$shape <- 19
      grobs$median <- ggplot2::GeomPoint$draw_panel(pt, panel_params, coord)
    } else {
      shift <- offset * (data$xmax[1] - data$xmin[1])
      segs <- rbind(
        seg(data$x, data$x, data$ymin, data$ymax),
        seg(data$x + shift, data$x + shift, data$lower, data$upper,
            lwd = box_linewidth)
      )
      grobs$body <- ggplot2::GeomSegment$draw_panel(segs, panel_params, coord)
      pt <- common
      pt$x <- data$x; pt$y <- data$middle; pt$size <- median_size
      pt$fill <- data$colour[1]
      grobs$median <- ggplot2::GeomPoint$draw_panel(pt, panel_params, coord)
    }

    if (outliers && !is.null(data$outliers) && length(data$outliers[[1]]) > 0) {
      out <- data$outliers[[1]]
      od <- common[rep(1, length(out)), , drop = FALSE]
      od$x <- data$x[1]
      od$y <- out
      od$size <- median_size * 0.7
      od$shape <- 1
      grobs$outliers <- ggplot2::GeomPoint$draw_panel(od, panel_params, coord)
    }

    .ggname("geom_tufteboxplot", do.call(grid::grobTree, grobs))
  }
)
