#' Small multiples
#'
#' Tufte's answer to multivariate data is repetition rather than complication:
#' the same graphic, at the same scale, once per condition, so that comparison
#' is a matter of looking rather than of decoding. Once the reader has learned
#' to read one panel, they have learned to read all of them.
#'
#' This is \code{\link[ggplot2]{facet_wrap}()} with the defaults changed to
#' match that argument. Scales are fixed, because free scales destroy the
#' comparison the design exists to make. Strips are left-aligned and unboxed.
#' The panel count is left to \code{ggplot2} unless you set \code{ncol}.
#'
#' @param facets Variables to facet by, as with
#'   \code{\link[ggplot2]{facet_wrap}()}, for example \code{vars(cyl)} or
#'   \code{~ cyl}.
#' @param ncol,nrow Panel layout. \code{ncol} defaults to \code{NULL}, letting
#'   \code{ggplot2} choose.
#' @param scales Passed to \code{facet_wrap()}. Defaults to \code{"fixed"}, and
#'   warns if you change it, because free scales make panels incomparable.
#' @param ... Further arguments passed to \code{\link[ggplot2]{facet_wrap}()}.
#' @return A \code{ggplot2} facet specification.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   geom_rangeframe() +
#'   facet_tufte(~ cyl) +
#'   theme_tufte()
facet_tufte <- function(facets, ncol = NULL, nrow = NULL, scales = "fixed",
                        ...) {
  if (!identical(scales, "fixed")) {
    .warn(c(
      "{.arg scales = \"{scales}\"} breaks the comparison small multiples exist to make.",
      i = "Panels drawn at different scales cannot be compared by eye."
    ))
  }
  ggplot2::facet_wrap(
    facets, ncol = ncol, nrow = nrow, scales = scales,
    strip.position = "top", ...
  )
}
