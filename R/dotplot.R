#' The Cleveland dot plot
#'
#' When the audit tells you that a bar chart's baseline isn't zero, it's
#' offering you two ways out: start at zero, or stop using bars. This is the
#' second. A dot encodes its value by position rather than by length, so it can
#' be read on a scale that doesn't include zero without lying about
#' proportions, and it uses a fraction of the ink a bar does.
#'
#' Cleveland's version adds a light leader line running from the axis to the
#' dot, which lets the eye track a long way along a row without drifting into
#' the neighbouring one. That line isn't data-ink, and it earns its place only
#' because the alternative is a misread row.
#'
#' Sort the categories before plotting. An alphabetical dot plot wastes the main
#' advantage of the form, which is that rank is visible at a glance; use
#' \code{stats::reorder()} or \code{forcats::fct_reorder()}.
#'
#' @param mapping,data,stat,position,na.rm,show.legend,inherit.aes,... Standard
#'   \code{ggplot2} layer arguments. See \code{\link[ggplot2]{layer}()}.
#' @param orientation Which axis holds the categories. \code{"y"}, the default,
#'   puts categories down the left and values across, which is what you want
#'   whenever the category names are words. \code{"x"} is the transpose.
#' @param leader One of \code{"axis"} (the default), which draws the leader from
#'   the axis to the dot, \code{"full"}, which runs it the whole width of the
#'   panel, or \code{"none"}.
#' @param leader_colour,leader_linetype,leader_linewidth Appearance of the
#'   leader line. It should be quiet enough to read past.
#' @return A \code{ggplot2} layer.
#' @export
#' @examples
#' library(ggplot2)
#' d <- data.frame(
#'   country = c("Japan", "Korea", "Australia", "New Zealand", "Singapore"),
#'   value = c(41.2, 32.9, 38.4, 29.7, 22.5)
#' )
#'
#' ggplot(d, aes(value, stats::reorder(country, value))) +
#'   geom_cleveland_dot() +
#'   labs(x = "Share (%)", y = NULL) +
#'   theme_tufte()
geom_cleveland_dot <- function(mapping = NULL, data = NULL, stat = "identity",
                               position = "identity", ...,
                               orientation = c("y", "x"),
                               leader = c("axis", "full", "none"),
                               leader_colour = "grey80",
                               leader_linetype = "dotted",
                               leader_linewidth = 0.3,
                               na.rm = FALSE, show.legend = NA,
                               inherit.aes = TRUE) {
  orientation <- match.arg(orientation)
  leader <- match.arg(leader)
  ggplot2::layer(
    geom = GeomClevelandDot, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(
      orientation = orientation, leader = leader,
      leader_colour = leader_colour, leader_linetype = leader_linetype,
      leader_linewidth = leader_linewidth, na.rm = na.rm, ...
    )
  )
}

#' @rdname geom_cleveland_dot
#' @format NULL
#' @usage NULL
#' @export
GeomClevelandDot <- ggplot2::ggproto(
  "GeomClevelandDot", ggplot2::Geom,
  required_aes = c("x", "y"),
  draw_key = ggplot2::draw_key_point,
  default_aes = ggplot2::aes(
    colour = "black", fill = "black", shape = 19, size = 2, alpha = NA,
    stroke = 0.5
  ),

  draw_panel = function(data, panel_params, coord, orientation = "y",
                        leader = "axis", leader_colour = "grey80",
                        leader_linetype = "dotted", leader_linewidth = 0.3,
                        na.rm = FALSE) {
    grobs <- list()

    if (!identical(leader, "none")) {
      d <- coord$transform(data, panel_params)
      gp <- grid::gpar(
        col = leader_colour, lty = leader_linetype,
        lwd = leader_linewidth * .pt, lineend = "butt"
      )
      # The leader is drawn in panel coordinates so that "axis" means the panel
      # edge, wherever the scale happens to start.
      #
      # coord_flip() swaps the sides after the layer was set up, so the points,
      # which delegate to GeomPoint, moved while the leaders kept their old
      # direction and ran off at right angles to their own dots.
      drawn <- if (inherits(coord, "CoordFlip")) {
        if (identical(orientation, "y")) "x" else "y"
      } else {
        orientation
      }
      grobs$leader <- if (identical(drawn, "y")) {
        grid::segmentsGrob(
          x0 = grid::unit(0, "npc"),
          x1 = if (identical(leader, "full")) grid::unit(1, "npc")
               else grid::unit(d$x, "npc"),
          y0 = grid::unit(d$y, "npc"), y1 = grid::unit(d$y, "npc"),
          gp = gp
        )
      } else {
        grid::segmentsGrob(
          y0 = grid::unit(0, "npc"),
          y1 = if (identical(leader, "full")) grid::unit(1, "npc")
               else grid::unit(d$y, "npc"),
          x0 = grid::unit(d$x, "npc"), x1 = grid::unit(d$x, "npc"),
          gp = gp
        )
      }
    }

    grobs$points <- ggplot2::GeomPoint$draw_panel(data, panel_params, coord)
    .ggname("geom_cleveland_dot", do.call(grid::grobTree, grobs))
  }
)
