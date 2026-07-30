#' Bar charts with the gridlines erased through the bars
#'
#' Tufte's bar chart redesign is the clearest case of erasing redundant
#' data-ink. The gridlines are needed, because readers have to recover values
#' from bar heights. But a gridline crossing a bar is drawn on top of ink that
#' already encodes the same information, so it's erased there instead of being
#' drawn over the bar. The result is a bar with white rules through it, which
#' reads as a ruler laid against the data.
#'
#' Use with \code{\link{theme_tufte}()} and \code{grid = "none"}: this layer
#' draws the white rules, and the theme should not add grey ones underneath.
#'
#' @param mapping,data,stat,position,na.rm,show.legend,inherit.aes,... Standard
#'   \code{ggplot2} layer arguments. See \code{\link[ggplot2]{layer}()}.
#' @param sides Which axis's breaks to erase through the bars. \code{"y"} (the
#'   default) suits vertical bars; \code{"x"} suits horizontal ones.
#' @param rule_colour Colour of the erased rules. Defaults to \code{"white"},
#'   which is correct on a white page; set it to your background colour
#'   otherwise.
#' @param rule_linewidth Width of the erased rules. Defaults to \code{0.6}.
#' @param minor Logical. Erase minor breaks as well as major ones? Defaults to
#'   \code{FALSE}.
#' @return A \code{ggplot2} layer.
#' @export
#' @examples
#' library(ggplot2)
#' d <- data.frame(
#'   who = c("Reagan", "Bush", "Clinton", "Bush", "Obama"),
#'   value = c(3.5, 2.3, 3.9, 2.1, 2.5)
#' )
#' ggplot(d, aes(who, value)) +
#'   geom_col_tufte(fill = "grey70") +
#'   theme_tufte()
geom_col_tufte <- function(mapping = NULL, data = NULL, stat = "identity",
                           position = "stack", ..., sides = c("y", "x"),
                           rule_colour = "white", rule_linewidth = 0.6,
                           minor = FALSE, na.rm = FALSE, show.legend = NA,
                           inherit.aes = TRUE) {
  sides <- match.arg(sides)
  ggplot2::layer(
    geom = GeomColTufte, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(
      sides = sides, rule_colour = rule_colour,
      rule_linewidth = rule_linewidth, minor = minor, na.rm = na.rm, ...
    )
  )
}

#' @rdname geom_col_tufte
#' @export
geom_bar_tufte <- function(mapping = NULL, data = NULL, stat = "count",
                           position = "stack", ..., sides = c("y", "x"),
                           rule_colour = "white", rule_linewidth = 0.6,
                           minor = FALSE, na.rm = FALSE, show.legend = NA,
                           inherit.aes = TRUE) {
  sides <- match.arg(sides)
  ggplot2::layer(
    geom = GeomColTufte, mapping = mapping, data = data, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(
      sides = sides, rule_colour = rule_colour,
      rule_linewidth = rule_linewidth, minor = minor, na.rm = na.rm, ...
    )
  )
}

#' @rdname geom_col_tufte
#' @format NULL
#' @usage NULL
#' @export
GeomColTufte <- ggplot2::ggproto(
  "GeomColTufte", ggplot2::GeomBar,

  draw_panel = function(self, data, panel_params, coord, lineend = "butt",
                        linejoin = "mitre", width = NULL,
                        sides = "y", rule_colour = "white",
                        rule_linewidth = 0.6, minor = FALSE, na.rm = FALSE) {
    bars <- ggplot2::GeomRect$draw_panel(
      data, panel_params, coord, lineend = lineend, linejoin = linejoin
    )
    rules <- .erased_rules(panel_params, coord, sides, rule_colour,
                           rule_linewidth, minor)
    .ggname("geom_col_tufte", grid::grobTree(bars, rules))
  }
)

# White rules at the axis breaks, drawn over the bars.
#' @noRd
.erased_rules <- function(panel_params, coord, sides, colour, linewidth,
                          minor) {
  scale <- if (identical(sides, "y")) panel_params$y else panel_params$x
  if (is.null(scale)) return(ggplot2::zeroGrob())

  brk <- tryCatch(scale$get_breaks(), error = function(e) NULL)
  if (minor) {
    brk <- c(brk, tryCatch(scale$get_breaks_minor(), error = function(e) NULL))
  }
  brk <- brk[is.finite(brk)]
  if (length(brk) == 0) return(ggplot2::zeroGrob())

  df <- if (identical(sides, "y")) {
    data.frame(x = rep(brk[1], length(brk)), y = brk)
  } else {
    data.frame(x = brk, y = rep(brk[1], length(brk)))
  }
  tdf <- tryCatch(coord$transform(df, panel_params), error = function(e) NULL)
  if (is.null(tdf)) return(ggplot2::zeroGrob())

  pos <- if (identical(sides, "y")) tdf$y else tdf$x
  keep <- is.finite(pos) & pos >= 0 & pos <= 1
  pos <- pos[keep]
  if (length(pos) == 0) return(ggplot2::zeroGrob())

  gp <- grid::gpar(col = colour, lwd = linewidth * .pt, lineend = "butt")
  if (identical(sides, "y")) {
    grid::segmentsGrob(
      x0 = grid::unit(0, "npc"), x1 = grid::unit(1, "npc"),
      y0 = grid::unit(pos, "npc"), y1 = grid::unit(pos, "npc"), gp = gp
    )
  } else {
    grid::segmentsGrob(
      y0 = grid::unit(0, "npc"), y1 = grid::unit(1, "npc"),
      x0 = grid::unit(pos, "npc"), x1 = grid::unit(pos, "npc"), gp = gp
    )
  }
}
