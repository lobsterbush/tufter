#' tufter: Implement Edward Tufte's principles of graphical design
#'
#' Use Tufte-inspired \pkg{ggplot2} layers and themes to draw figures, then
#' estimate their data-ink ratio, lie factor and data density.
#'
#' I built the package to try these ideas in my own figures. The
#' measurements can help you compare drafts, but they can't tell you whether
#' a figure supports your argument.
#'
#' \code{\link{tufte_principles}()} maps principles to functions and records
#' which ones can be checked. \code{\link{tufte_audit}()} runs the available
#' checks on an existing plot.
#'
#' @keywords internal
#' @import ggplot2
#' @importFrom rlang %||% .data
#' @importFrom stats quantile median na.omit
"_PACKAGE"
