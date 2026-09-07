#' Small multiples
#'
#' Show the same kind of plot for each group. Keeping the scales fixed lets
#' readers compare levels across panels without adjusting for different axes.
#'
#' This wraps \code{\link[ggplot2]{facet_wrap}()} with fixed scales and
#' left-aligned, unboxed strip labels. \code{ggplot2} chooses the layout unless
#' you specify it. Free scales can help with other questions, but they make
#' comparisons of levels harder, so the function warns when you request them.
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
