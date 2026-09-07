#' Save a figure after checking its labels
#'
#' Save with \code{\link[ggplot2]{ggsave}()} using defaults for print:
#' 6.5 inches wide, \code{cairo_pdf} for PDF output, and 300 dpi for raster
#' formats. Set the height to suit your figure.
#'
#' Before saving, the function runs \code{\link{check_labels_fit}()} at the
#' requested size. Labels that don't fit produce a warning. With
#' \code{strict = TRUE}, they stop the save. A check that can't run also warns,
#' or stops a strict save.
#'
#' Dimensions are in inches. You can't override \code{units} or \code{scale}
#' through \code{...}, because the size checked needs to match the size saved.
#' The label check has limits; inspect the exported figure too.
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
  .check_size(width, height)
  dots <- list(...)
  if (any(c("units", "scale") %in% names(dots))) {
    .abort("Set {.arg width} and {.arg height} in inches; {.arg units} and {.arg scale} cannot be overridden.")
  }
  if (check) {
    fits <- tryCatch(
      suppressWarnings(check_labels_fit(plot, width, height)),
      error = function(e) {
        msg <- c("Could not check labels before saving.", x = conditionMessage(e))
        if (strict) .abort(msg) else .warn(msg)
        NULL
      }
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
