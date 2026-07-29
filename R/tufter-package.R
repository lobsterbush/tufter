#' tufter: Implement Edward Tufte's Principles of Graphical Design
#'
#' The package has two halves. The generative half provides the graphical
#' forms Tufte designed or advocated, as \pkg{ggplot2} layers, themes, scales
#' and plot constructors. The evaluative half provides the quantities Tufte
#' defined, so that a finished figure can be measured rather than merely
#' admired: the data-ink ratio, the lie factor, and data density.
#'
#' Call \code{\link{tufte_principles}()} for a table mapping each principle to
#' the function that implements it, and \code{\link{tufte_audit}()} to score an
#' existing plot against all of them at once.
#'
#' @keywords internal
#' @import ggplot2
#' @importFrom rlang %||% .data
#' @importFrom stats quantile median na.omit
"_PACKAGE"
