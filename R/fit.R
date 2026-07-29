#' Check that every text element fits inside the canvas
#'
#' A figure that has been designed carefully and then saved at the wrong size
#' is a figure with a truncated subtitle. This renders the plot at the size you
#' intend to print it and measures the text elements against the space
#' available, so that clipping is caught before the figure reaches a page.
#'
#' Subtitles and captions are the usual offenders, because \code{ggplot2} does
#' not wrap them: text longer than the device is silently cut at the edge. The
#' fix is a hard line break, a wider canvas, or a smaller font, and then a
#' second look at the rendered file.
#'
#' @param plot A \code{ggplot} object.
#' @param width,height Intended size in inches. Defaults to 6.5 by 4.
#' @return A tibble with one row per element checked: what it needs, what it
#'   has, and whether it fits. Invisibly returns the same tibble when all
#'   elements fit.
#' @export
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   labs(subtitle = paste(rep("A very long subtitle indeed", 6), collapse = " "))
#' check_labels_fit(p, width = 6.5, height = 4)
check_labels_fit <- function(plot, width = 6.5, height = 4) {
  .check_gg(plot)
  gt <- ggplot2::ggplotGrob(plot)

  f <- tempfile(fileext = ".png")
  args <- list(filename = f, width = width, height = height, units = "in",
               res = 72)
  if (isTRUE(capabilities("cairo"))) args$type <- "cairo"
  old <- grDevices::dev.cur()
  do.call(grDevices::png, args)
  on.exit({
    grDevices::dev.off()
    if (old > 1) try(grDevices::dev.set(old), silent = TRUE)
    unlink(f)
  }, add = TRUE)
  grid::grid.newpage()

  rows <- list()
  add <- function(element, required, available) {
    if (!is.finite(required) || !is.finite(available)) return(invisible(NULL))
    rows[[length(rows) + 1]] <<- data.frame(
      element = element,
      required_in = round(required, 3),
      available_in = round(available, 3),
      fits = required <= available + 1e-6,
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }

  fixed_w <- .safe_sum_widths(gt$widths)
  fixed_h <- .safe_sum_heights(gt$heights)
  add("layout (non-panel width)", fixed_w, width)
  add("layout (non-panel height)", fixed_h, height)

  panel_w <- width - fixed_w
  panel_h <- height - fixed_h

  # Faceting splits the panel area into a grid, so each panel gets a share.
  n_cols <- length(unique(gt$layout$l[grepl("^panel", gt$layout$name)]))
  n_rows <- length(unique(gt$layout$t[grepl("^panel", gt$layout$name)]))
  panel_w <- panel_w / max(n_cols, 1)
  panel_h <- panel_h / max(n_rows, 1)

  titles <- list(
    c("title", "^title$", "max"),
    c("subtitle", "^subtitle$", "max"),
    c("caption", "^caption$", "max"),
    c("x axis title", "^xlab-", "max"),
    c("y axis title", "^ylab-", "max")
  )
  for (spec in titles) {
    req <- .max_extent(gt, spec[2], spec[3], "width")
    add(spec[1], req, width)
  }

  add("x axis labels (side by side)",
      .max_extent(gt, "^axis-b", "sum", "width"), panel_w)
  add("y axis labels (stacked)",
      .max_extent(gt, "^axis-l", "sum", "height"), panel_h)
  add("legend", .max_extent(gt, "^guide-box", "max", "width"), width)
  add("strip label", .max_extent(gt, "^strip-t", "max", "width"), panel_w)

  if (length(rows) == 0) {
    return(tibble::tibble(
      element = character(0), required_in = numeric(0),
      available_in = numeric(0), fits = logical(0)
    ))
  }
  out <- tibble::as_tibble(do.call(rbind, rows))

  bad <- out[!out$fits, , drop = FALSE]
  if (nrow(bad) > 0) {
    .warn(c(
      "{nrow(bad)} element{?s} will be clipped at {width}in x {height}in.",
      stats::setNames(
        sprintf("%s needs %.2fin but has %.2fin.", bad$element,
                bad$required_in, bad$available_in),
        rep("x", nrow(bad))
      ),
      i = "Hard-wrap the text, widen the canvas, or reduce the font size."
    ))
  }
  out
}

#' @noRd
.grob_named <- function(gt, name) {
  i <- which(gt$layout$name == name)
  if (length(i) == 0) return(NULL)
  g <- gt$grobs[[i[1]]]
  if (inherits(g, "zeroGrob")) return(NULL)
  g
}

# Worst requirement across every grob in the gtable whose name matches.
#' @noRd
.max_extent <- function(gt, pattern, how, what) {
  i <- which(grepl(pattern, gt$layout$name))
  if (length(i) == 0) return(NA_real_)
  vals <- vapply(i, function(k) {
    g <- gt$grobs[[k]]
    if (inherits(g, "zeroGrob")) return(NA_real_)
    .text_extent(g, how, what)
  }, numeric(1))
  vals <- vals[is.finite(vals)]
  if (length(vals) == 0) return(NA_real_)
  max(vals)
}

# Sum only the absolute part of a unit vector; null units resolve to zero,
# which is what we want when asking how much fixed space the layout consumes.
#' @noRd
.safe_sum_widths <- function(u) {
  tryCatch(sum(grid::convertWidth(u, "in", valueOnly = TRUE)),
           error = function(e) NA_real_)
}

#' @noRd
.safe_sum_heights <- function(u) {
  tryCatch(sum(grid::convertHeight(u, "in", valueOnly = TRUE)),
           error = function(e) NA_real_)
}

# Extent of the text inside a grob tree. `how = "max"` gives the widest single
# string, which is what a title needs; `how = "sum"` gives the total, which is
# what a row of axis labels needs if they are not to overlap.
#
# ggplot2 wraps its text in titleGrobs whose own width resolves to zero,
# because the space is allocated by the enclosing gtable. So the measurement
# has to reach the text grobs themselves.
#' @noRd
.text_extent <- function(g, how = c("max", "sum"), what = c("width", "height")) {
  how <- match.arg(how)
  what <- match.arg(what)
  tryCatch({
    texts <- .collect_text_grobs(g)
    if (length(texts) == 0) return(NA_real_)
    w <- unlist(lapply(texts, .label_extents, what = what))
    w <- w[is.finite(w)]
    if (length(w) == 0) return(NA_real_)
    if (how == "max") max(w) else sum(w)
  }, error = function(e) NA_real_)
}

# A single text grob can hold many labels, and its own grobWidth reports only
# the widest. Measure each label separately so that a row of axis labels can be
# summed.
#' @noRd
.label_extents <- function(t, what = "width") {
  labs <- t$label
  if (is.null(labs) || length(labs) == 0) return(numeric(0))
  labs <- as.character(labs)
  rot <- t$rot %||% 0
  conv <- if (what == "width") grid::convertWidth else grid::convertHeight
  vapply(labs, function(s) {
    tryCatch({
      tg <- grid::textGrob(s, gp = t$gp, rot = rot)
      u <- if (what == "width") grid::grobWidth(tg) else grid::grobHeight(tg)
      conv(u, "in", valueOnly = TRUE)
    }, error = function(e) NA_real_)
  }, numeric(1), USE.NAMES = FALSE)
}

#' @noRd
.collect_text_grobs <- function(g, acc = list()) {
  if (inherits(g, "text")) return(c(acc, list(g)))
  if (inherits(g, "gtable") && !is.null(g$grobs)) {
    for (child in g$grobs) acc <- .collect_text_grobs(child, acc)
    return(acc)
  }
  if (inherits(g, "gTree") && !is.null(g$children)) {
    for (child in g$children) acc <- .collect_text_grobs(child, acc)
  }
  acc
}
