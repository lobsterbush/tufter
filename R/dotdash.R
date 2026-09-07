#' Dot-dash-plot marginal distributions
#'
#' Add a short tick for each observation along the plot's margins. Tufte's
#' dot-dash plot uses these ticks to show the marginal distributions beside a
#' scatterplot.
#'
#' The default ticks are short and thin. Use \code{theme_tufte(ticks = FALSE)}
#' if you'd like them to replace the ordinary axis ticks.
#'
#' @param mapping,data,stat,position,na.rm,show.legend,inherit.aes,... Standard
#'   \code{ggplot2} layer arguments. See \code{\link[ggplot2]{layer}()}.
#' @param sides Which margins to draw on, as a string containing any of
#'   \code{"b"}, \code{"l"}, \code{"t"}, \code{"r"}. Defaults to \code{"bl"}.
#' @param tick_length Tick length, as a \code{\link[grid]{unit}}. Defaults to 2
#'   percent of the panel.
#' @return A \code{ggplot2} layer.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   geom_dotdash() +
#'   theme_tufte(ticks = FALSE)
geom_dotdash <- function(mapping = NULL, data = NULL, stat = "identity",
                         position = "identity", ..., sides = "bl",
                         tick_length = grid::unit(0.02, "npc"),
                         na.rm = FALSE, show.legend = NA, inherit.aes = TRUE) {
  sides <- .check_frame_sides(sides)
  ggplot2::layer(
    geom = GeomDotDash, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(sides = sides, tick_length = tick_length, na.rm = na.rm, ...)
  )
}

#' @rdname geom_dotdash
#' @format NULL
#' @usage NULL
#' @export
GeomDotDash <- ggplot2::ggproto(
  "GeomDotDash", ggplot2::Geom,
  optional_aes = c("x", "y"),
  draw_key = ggplot2::draw_key_path,
  default_aes = ggplot2::aes(
    colour = "black", linewidth = 0.25, linetype = 1, alpha = NA
  ),

  draw_panel = function(data, panel_params, coord, sides = "bl",
                        tick_length = grid::unit(0.02, "npc"), na.rm = FALSE) {
    d <- coord$transform(data, panel_params)
    gp <- .frame_gpar(data)
    grobs <- list()

    if (!is.null(d$x)) {
      xs <- d$x[is.finite(d$x)]
      if (length(xs) && grepl("b", sides, fixed = TRUE)) {
        grobs[[length(grobs) + 1]] <- grid::segmentsGrob(
          x0 = grid::unit(xs, "npc"), x1 = grid::unit(xs, "npc"),
          y0 = grid::unit(0, "npc"), y1 = tick_length, gp = gp
        )
      }
      if (length(xs) && grepl("t", sides, fixed = TRUE)) {
        grobs[[length(grobs) + 1]] <- grid::segmentsGrob(
          x0 = grid::unit(xs, "npc"), x1 = grid::unit(xs, "npc"),
          y0 = grid::unit(1, "npc"), y1 = grid::unit(1, "npc") - tick_length, gp = gp
        )
      }
    }
    if (!is.null(d$y)) {
      ys <- d$y[is.finite(d$y)]
      if (length(ys) && grepl("l", sides, fixed = TRUE)) {
        grobs[[length(grobs) + 1]] <- grid::segmentsGrob(
          y0 = grid::unit(ys, "npc"), y1 = grid::unit(ys, "npc"),
          x0 = grid::unit(0, "npc"), x1 = tick_length, gp = gp
        )
      }
      if (length(ys) && grepl("r", sides, fixed = TRUE)) {
        grobs[[length(grobs) + 1]] <- grid::segmentsGrob(
          y0 = grid::unit(ys, "npc"), y1 = grid::unit(ys, "npc"),
          x0 = grid::unit(1, "npc"), x1 = grid::unit(1, "npc") - tick_length, gp = gp
        )
      }
    }

    if (length(grobs) == 0) return(ggplot2::zeroGrob())
    .ggname("geom_dotdash", do.call(grid::grobTree, grobs))
  }
)
