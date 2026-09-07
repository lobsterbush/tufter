#' A minimal theme for statistical graphics
#'
#' Remove the panel background, grid, panel border and legend frame. The theme
#' follows Tufte's advice to reduce ink that doesn't represent data.
#'
#' There are no axis lines by default. Add \code{\link{geom_rangeframe}()} or
#' \code{\link{geom_quartileframe}()}, or set \code{axis_lines = TRUE} for
#' ordinary axes.
#'
#' I'd keep a grid when it helps readers estimate values. Use \code{grid = "y"}
#' or \code{"x"} for a light grid on one axis. For Tufte's bar design, with
#' rules erased through the bars, use \code{\link{geom_col_tufte}()}.
#'
#' @param base_size Base font size in points. Defaults to 12.
#' @param base_family Base font family. Defaults to \code{""} (the device
#'   default). \code{"serif"} is closer to Tufte's own books.
#' @param ticks Logical. Draw axis tick marks? Defaults to \code{TRUE}; ticks
#'   are data-ink in the weak sense that they locate values.
#' @param axis_lines Logical. Draw conventional axis lines? Defaults to
#'   \code{FALSE}. Add a range frame if you'd like axes tied to the data.
#' @param grid One of \code{"none"} (the default), \code{"x"}, \code{"y"} or
#'   \code{"both"}. Draws a hairline grid where you ask for one.
#' @return A \code{ggplot2} theme object.
#' @seealso \code{\link{theme_sparkline}()}, \code{\link{theme_slopegraph}()}
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   geom_rangeframe() +
#'   theme_tufte()
theme_tufte <- function(base_size = 12,
                        base_family = "",
                        ticks = TRUE,
                        axis_lines = FALSE,
                        grid = c("none", "x", "y", "both")) {
  grid <- match.arg(grid)

  grid_line <- ggplot2::element_line(
    colour = "grey92", linewidth = .hairline, lineend = "butt"
  )

  th <- ggplot2::theme_bw(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      line = ggplot2::element_line(colour = "black", linewidth = .hairline),
      rect = ggplot2::element_blank(),
      text = ggplot2::element_text(colour = "black", family = base_family),

      panel.background = ggplot2::element_blank(),
      panel.border     = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.background  = ggplot2::element_blank(),

      axis.line  = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_line(colour = "black", linewidth = .hairline),
      axis.text  = ggplot2::element_text(size = ggplot2::rel(0.9), colour = "grey20"),
      axis.title = ggplot2::element_text(size = ggplot2::rel(1)),

      legend.background = ggplot2::element_blank(),
      legend.key        = ggplot2::element_blank(),
      legend.title      = ggplot2::element_text(size = ggplot2::rel(0.9)),
      legend.position   = "bottom",

      strip.background = ggplot2::element_blank(),
      strip.text       = ggplot2::element_text(size = ggplot2::rel(0.9), hjust = 0),

      plot.title    = ggplot2::element_text(size = ggplot2::rel(1.1), hjust = 0,
                                            face = "plain"),
      plot.subtitle = ggplot2::element_text(size = ggplot2::rel(0.95), hjust = 0,
                                            colour = "grey30"),
      plot.caption  = ggplot2::element_text(size = ggplot2::rel(0.8), hjust = 0,
                                            colour = "grey40"),
      plot.title.position   = "plot",
      plot.caption.position = "plot"
    )

  if (!ticks) {
    th <- th + ggplot2::theme(axis.ticks = ggplot2::element_blank())
  }
  if (axis_lines) {
    th <- th + ggplot2::theme(
      axis.line = ggplot2::element_line(colour = "black", linewidth = .hairline)
    )
  }
  if (grid %in% c("x", "both")) {
    th <- th + ggplot2::theme(panel.grid.major.x = grid_line)
  }
  if (grid %in% c("y", "both")) {
    th <- th + ggplot2::theme(panel.grid.major.y = grid_line)
  }

  th
}

#' A theme for sparklines
#'
#' Remove axes, labels and the frame, and leave a small margin. This gives a
#' sparkline room to sit beside the text that explains it.
#'
#' @param base_size Base font size in points. Defaults to 9.
#' @param base_family Base font family. Defaults to the device default.
#' @return A \code{ggplot2} theme object.
#' @export
#' @examples
#' library(ggplot2)
#' d <- data.frame(t = 1:50, v = cumsum(rnorm(50)))
#' ggplot(d, aes(t, v)) + geom_line() + theme_sparkline()
theme_sparkline <- function(base_size = 9, base_family = "") {
  ggplot2::theme_void(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      legend.position = "none",
      plot.margin = ggplot2::margin(1, 1, 1, 1, "pt"),
      strip.text.y.left = ggplot2::element_text(
        angle = 0, hjust = 1, size = ggplot2::rel(0.9)
      ),
      panel.spacing.y = grid::unit(2, "pt")
    )
}

#' A theme for slopegraphs
#'
#' Keep category labels at the top and remove the y axis. Slopegraphs print
#' values at the ends of their lines, so readers can read the values directly.
#'
#' @param base_size Base font size in points. Defaults to 11.
#' @param base_family Base font family. Defaults to the device default.
#' @return A \code{ggplot2} theme object.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot() + theme_slopegraph()
theme_slopegraph <- function(base_size = 11, base_family = "") {
  ggplot2::theme_void(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      legend.position = "none",
      axis.text.x = ggplot2::element_text(
        size = ggplot2::rel(1), colour = "black", face = "bold",
        margin = ggplot2::margin(b = 6)
      ),
      axis.ticks = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(hjust = 0, size = ggplot2::rel(1.15),
                                         margin = ggplot2::margin(b = 4)),
      plot.subtitle = ggplot2::element_text(hjust = 0, colour = "grey30",
                                            margin = ggplot2::margin(b = 10)),
      plot.caption = ggplot2::element_text(hjust = 0, colour = "grey40",
                                           size = ggplot2::rel(0.85)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )
}
