#' Save a figure, and check it before you do
#'
#' A wrapper on \code{\link[ggplot2]{ggsave}()} with the defaults set for print:
#' 6.5 inches wide, which is a single text column; \code{cairo_pdf} for PDF
#' output, so that fonts embed properly; and 300 dpi for raster formats.
#'
#' Before writing the file it runs \code{\link{check_labels_fit}()} at the size
#' you asked for, because a subtitle that fits on screen at the default device
#' size isn't a subtitle that fits in the saved file. Clipping is reported as a
#' warning; set \code{strict = TRUE} to make it an error instead.
#'
#' @param filename Path to write to. The extension sets the device.
#' @param plot The plot to save. Defaults to the last plot drawn.
#' @param width,height Size in inches. Defaults to 6.5 by 4.
#' @param dpi Resolution for raster formats. Defaults to 300.
#' @param check Logical. Check that the labels fit before saving?
#' @param strict Logical. Turn a clipping warning into an error?
#' @param ... Passed to \code{\link[ggplot2]{ggsave}()}.
#' @return The filename, invisibly.
#' @export
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
#' f <- file.path(tempdir(), "figure.pdf")
#' save_tufte(f, p)
#' unlink(f)
save_tufte <- function(filename, plot = ggplot2::last_plot(), width = 6.5,
                       height = 4, dpi = 300, check = TRUE, strict = FALSE,
                       ...) {
  if (check) {
    fits <- tryCatch(
      suppressWarnings(check_labels_fit(plot, width, height)),
      error = function(e) NULL
    )
    if (!is.null(fits) && nrow(fits) > 0) {
      bad <- fits[!fits$fits, , drop = FALSE]
      if (nrow(bad) > 0) {
        msg <- c(
          "{nrow(bad)} element{?s} will be clipped at {width}in x {height}in.",
          stats::setNames(
            sprintf("%s needs %.2fin but has %.2fin.", bad$element,
                    bad$required_in, bad$available_in),
            rep("x", nrow(bad))
          ),
          i = "Hard-wrap the text, widen the canvas, or reduce the font size."
        )
        if (strict) .abort(msg) else .warn(msg)
      }
    }
  }

  ext <- tolower(tools::file_ext(filename))
  args <- list(filename = filename, plot = plot, width = width,
               height = height, dpi = dpi, ...)
  if (ext == "pdf" && is.null(args$device) && capabilities("cairo")) {
    args$device <- grDevices::cairo_pdf
  }
  do.call(ggplot2::ggsave, args)
  invisible(filename)
}
