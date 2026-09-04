#' Audit every figure in a paper at once
#'
#' Running \code{\link{tufte_audit}()} on one plot is useful while you're
#' drawing it. Running it on all of them, the evening before you submit, is when
#' it earns its keep: the figure with the truncated subtitle is never the one
#' you were looking at.
#'
#' Give it the plots you built, or a directory of saved ones. It returns a row
#' per figure with the count of unmet criteria and the checks that failed, and
#' keeps the full per-check detail attached so you can drill into any of them.
#'
#' Figures are ordered by the number of stated criteria they fail, most first.
#' That's a count and not a score: it's comparable across figures because
#' every figure is being counted against the same criteria, whereas a
#' proportion would divide by a denominator that changes with the plot type.
#'
#' @param plots One of: a named list of \code{ggplot} objects; a single
#'   \code{ggplot}; or a path to a directory, in which case every \code{.rds}
#'   file in it's read and any that contains a \code{ggplot} is audited.
#' @param width,height Intended printed size in inches, applied to every figure.
#'   Pass a vector as long as \code{plots} to give each its own size.
#' @param measure Logical. Report the data-ink ratio and the data density?
#'   Defaults to \code{TRUE}. Setting it to \code{FALSE} skips only those two,
#'   which are ungraded, so the ordering by unmet criteria is the same either
#'   way and roughly twice as fast to get.
#' @return An object of class \code{tufte_audit_batch}: a tibble with one row
#'   per figure, giving \code{figure}, \code{violations}, \code{met} and
#'   \code{failing}, a comma-separated list of the criteria not met. The full
#'   audits are attached as the \code{"audits"} attribute, named by figure.
#' @seealso \code{\link{tufte_audit}()} for a single plot.
#' @export
#' @examples
#' library(ggplot2)
#' figures <- list(
#'   scatter = ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte(),
#'   boxes = ggplot(mtcars, aes(factor(cyl), mpg)) + geom_tufteboxplot()
#' )
#' audit_figures(figures, measure = FALSE)
audit_figures <- function(plots, width = 6.5, height = 4, measure = TRUE) {
  plots <- .as_plot_list(plots)
  n <- length(plots)
  if (n == 0) .abort("No plots to audit.")

  width <- rep_len(width, n)
  height <- rep_len(height, n)

  audits <- vector("list", n)
  names(audits) <- names(plots)
  rows <- vector("list", n)

  for (i in seq_len(n)) {
    a <- tryCatch(
      suppressWarnings(
        tufte_audit(plots[[i]], width = width[i], height = height[i],
                    measure = measure)
      ),
      error = function(e) e
    )
    if (inherits(a, "error")) {
      # `audits[[i]] <- NULL` deletes the element from the list rather than
      # storing NULL in it, which shifted every later name by one and left the
      # documented drill-in returning NULL for every figure after a failure.
      audits[i] <- list(NULL)
      rows[[i]] <- data.frame(
        figure = names(plots)[i], violations = NA_integer_, met = NA_integer_,
        failing = paste("couldn't be audited:", conditionMessage(a)),
        stringsAsFactors = FALSE
      )
      next
    }
    audits[[i]] <- a
    fails <- a$check[a$status == "fail"]
    rows[[i]] <- data.frame(
      figure = names(plots)[i],
      violations = length(fails),
      met = sum(a$status == "pass"),
      failing = if (length(fails)) paste(fails, collapse = ", ") else "",
      stringsAsFactors = FALSE
    )
  }

  out <- tibble::as_tibble(do.call(rbind, rows))
  out <- out[order(-out$violations, na.last = FALSE), , drop = FALSE]

  structure(
    out,
    audits = audits,
    class = c("tufte_audit_batch", class(out))
  )
}

#' @export
print.tufte_audit_batch <- function(x, ...) {
  worst <- x[!is.na(x$violations) & x$violations > 0, , drop = FALSE]
  clean <- x[!is.na(x$violations) & x$violations == 0, , drop = FALSE]
  broken <- x[is.na(x$violations), , drop = FALSE]

  cli::cli_h2("Tufte audit: {nrow(x)} figure{?s}")

  if (nrow(worst) > 0) {
    cli::cli_h3("Stated criteria not met, most first")
    for (i in seq_len(nrow(worst))) {
      cli::cli_text(
        "{.strong {worst$figure[i]}} ",
        "({worst$violations[i]} not met)"
      )
      cli::cli_text("  {.emph {worst$failing[i]}}")
    }
  }
  if (nrow(clean) > 0) {
    cli::cli_h3("Meeting every stated criterion")
    cli::cli_ul(clean$figure)
  }
  if (nrow(broken) > 0) {
    cli::cli_h3("Could not be audited")
    cli::cli_ul(paste0(broken$figure, ": ", broken$failing))
  }

  cli::cli_text("")
  cli::cli_alert_info(
    'Full detail for any one figure: {.code attr(x, "audits")[["<name>"]]}'
  )
  invisible(x)
}

#' @noRd
.as_plot_list <- function(plots) {
  if (.is_gg(plots)) {
    return(stats::setNames(list(plots), "plot"))
  }
  if (is.character(plots) && length(plots) == 1 && dir.exists(plots)) {
    files <- list.files(plots, pattern = "\\.rds$", ignore.case = TRUE,
                        full.names = TRUE)
    if (length(files) == 0) {
      .abort("No {.file .rds} files found in {.path {plots}}.")
    }
    loaded <- lapply(files, function(f) tryCatch(readRDS(f), error = function(e) NULL))
    names(loaded) <- tools::file_path_sans_ext(basename(files))
    keep <- vapply(loaded, .is_gg, logical(1))
    if (!any(keep)) {
      .abort("None of the {length(files)} {.file .rds} file{?s} in {.path {plots}} contain a ggplot.")
    }
    if (any(!keep)) {
      cli::cli_alert_info(
        "Skipped {sum(!keep)} file{?s} that didn't contain a ggplot."
      )
    }
    return(loaded[keep])
  }
  if (!is.list(plots)) {
    .abort("{.arg plots} must be a ggplot, a list of ggplots, or a directory path.")
  }
  # An empty list is caught by the caller; naming it here would error first.
  if (length(plots) == 0) return(plots)

  bad <- !vapply(plots, .is_gg, logical(1))
  if (any(bad)) {
    .abort("Element{?s} {which(bad)} of {.arg plots} {?is/are} not {?a/} ggplot{?s}.")
  }
  if (is.null(names(plots)) || any(!nzchar(names(plots)))) {
    names(plots) <- paste0("figure ", seq_along(plots))
  }
  plots
}
