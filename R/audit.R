#' Audit a plot against Tufte's principles
#'
#' Runs every check the package knows how to make against an existing
#' \code{ggplot}, and reports which of Tufte's principles it satisfies. Some
#' checks are structural, and read the plot's specification. Others are
#' measurements, and render the plot to take them.
#'
#' The score is the share of applicable checks passed. It is a prompt, not a
#' verdict: a plot can pass every check and still be pointless, since Tufte's
#' first principle is that content counts most of all, and no function can
#' evaluate that. What the audit is good for is catching the failures that are
#' mechanical, and that authors stop seeing after the fifth draft.
#'
#' @param plot A \code{ggplot} object.
#' @param width,height Intended printed size in inches, used by the checks that
#'   depend on it. Defaults to 6.5 by 4.
#' @param measure Logical. Run the rendering-based measurements, which are the
#'   slow part? Defaults to \code{TRUE}.
#' @return An object of class \code{tufte_audit}: a tibble of checks with a
#'   \code{score} attribute and the underlying measurements attached.
#' @seealso \code{\link{tufte_principles}()} for the full list of principles
#'   and the functions that implement them.
#' @export
#' @examples
#' library(ggplot2)
#' tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point())
tufte_audit <- function(plot, width = 6.5, height = 4, measure = TRUE) {
  .check_gg(plot)

  built <- tryCatch(ggplot2::ggplot_build(plot), error = function(e) NULL)
  if (is.null(built)) .abort("This plot cannot be built, so it cannot be audited.")

  ctx <- list(
    plot = plot,
    built = built,
    width = width,
    height = height,
    geoms = .layer_geoms(plot),
    theme = .resolved_theme(plot),
    measure = measure
  )

  checks <- list(
    `panel background` = .check_panel_background,
    `gridlines` = .check_gridlines,
    `frame` = .check_frame,
    `pie chart` = .check_pie,
    `bar baseline` = .check_baseline,
    `lie factor` = .check_lie_factor,
    `legend` = .check_legend,
    `hues` = .check_hues,
    `redundant encoding` = .check_redundant_encoding,
    `small multiples` = .check_small_multiples,
    `documentation` = .check_documentation,
    `aspect ratio` = .check_aspect,
    `banking` = .check_banking,
    `contrast` = .check_contrast,
    `data-ink ratio` = .check_data_ink,
    `data density` = .check_density,
    `label fit` = .check_fit
  )

  rows <- lapply(names(checks), function(nm) {
    out <- tryCatch(checks[[nm]](ctx), error = function(e) {
      list(principle = "(check unavailable)", source = NA_character_,
           check = nm, status = "skip",
           message = paste0("The ", nm, " check could not run: ",
                            conditionMessage(e)))
    })
    if (is.null(out)) return(NULL)
    out
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]

  tab <- tibble::as_tibble(do.call(rbind, lapply(rows, function(r) {
    data.frame(
      principle = r$principle, source = r$source, check = r$check,
      status = r$status, message = r$message, stringsAsFactors = FALSE
    )
  })))

  applicable <- tab$status %in% c("pass", "fail")
  score <- if (any(applicable)) mean(tab$status[applicable] == "pass") else NA_real_

  structure(
    tab,
    score = score,
    plot_size = c(width = width, height = height),
    class = c("tufte_audit", class(tab))
  )
}

#' @export
print.tufte_audit <- function(x, ...) {
  score <- attr(x, "score")
  sz <- attr(x, "plot_size")

  cli::cli_h2("Tufte audit")
  if (is.finite(score)) {
    n_ok <- sum(x$status == "pass")
    n_app <- sum(x$status %in% c("pass", "fail"))
    cli::cli_text(
      "{.strong {n_ok}/{n_app}} checks passed ({round(100 * score)}%), ",
      "at {sz[['width']]}in x {sz[['height']]}in."
    )
  }

  fails <- x[x$status == "fail", , drop = FALSE]
  notes <- x[x$status == "note", , drop = FALSE]
  passes <- x[x$status == "pass", , drop = FALSE]

  if (nrow(fails) > 0) {
    cli::cli_h3("Failing")
    for (i in seq_len(nrow(fails))) {
      cli::cli_bullets(c("x" = "{fails$message[i]}"))
      cli::cli_text("  {.emph {fails$principle[i]} ({fails$source[i]})}")
    }
  }
  if (nrow(notes) > 0) {
    cli::cli_h3("Worth a look")
    for (i in seq_len(nrow(notes))) {
      cli::cli_bullets(c("i" = "{notes$message[i]}"))
    }
  }
  if (nrow(passes) > 0) {
    cli::cli_h3("Passing")
    cli::cli_ul(passes$check)
  }
  skipped <- x[x$status == "skip", , drop = FALSE]
  if (nrow(skipped) > 0) {
    cli::cli_h3("Could not be checked")
    cli::cli_ul(skipped$message)
  }
  invisible(x)
}

# ---- individual checks ------------------------------------------------------

#' @noRd
.resolved_theme <- function(plot) {
  tryCatch(
    ggplot2::complete_theme(plot$theme),
    error = function(e) tryCatch(ggplot2::theme_get() + plot$theme,
                                 error = function(e2) plot$theme)
  )
}

#' @noRd
.is_blank <- function(el) is.null(el) || inherits(el, "element_blank")

#' @noRd
.el_get <- function(el, field) {
  if (.is_blank(el)) return(NULL)
  out <- tryCatch(el[[field]], error = function(e) NULL)
  if (length(out) == 0) return(NULL)
  out
}

#' @noRd
.row <- function(principle, source, check, status, message) {
  list(principle = principle, source = source, check = check,
       status = status, message = message)
}

#' @noRd
.check_panel_background <- function(ctx) {
  bg <- ctx$theme$panel.background
  fill <- .el_get(bg, "fill")
  opaque <- !is.null(fill) && !identical(fill, NA) &&
    !fill %in% c("white", "transparent", "#FFFFFF", "#ffffff")
  .row(
    "Erase non-data ink", "VDQI ch. 4",
    "Panel background carries no data",
    if (opaque) "fail" else "pass",
    if (opaque) {
      sprintf("The panel is filled with %s. A tinted panel is ink that never varies with the data.", fill)
    } else {
      "The panel has no background fill."
    }
  )
}

#' @noRd
.check_gridlines <- function(ctx) {
  major <- ctx$theme$panel.grid.major
  minor <- ctx$theme$panel.grid.minor
  has_minor <- !.is_blank(minor)
  has_major <- !.is_blank(major)
  lwd <- .el_get(major, "linewidth") %||% 0.5

  if (has_minor) {
    return(.row(
      "Erase redundant data-ink", "VDQI ch. 4",
      "Grid is no heavier than the data",
      "fail",
      "Minor gridlines are drawn. They divide space the reader is not reading to that precision."
    ))
  }
  if (has_major && lwd > 0.4) {
    return(.row(
      "Erase redundant data-ink", "VDQI ch. 4",
      "Grid is no heavier than the data",
      "note",
      sprintf("Major gridlines are drawn at linewidth %.2f. A grid should be a hairline the eye can ignore, or erased through the bars with geom_col_tufte().", lwd)
    ))
  }
  .row(
    "Erase redundant data-ink", "VDQI ch. 4",
    "Grid is no heavier than the data", "pass",
    "The grid is absent or hairline-weight."
  )
}

#' @noRd
.check_frame <- function(ctx) {
  border <- ctx$theme$panel.border
  has_border <- !.is_blank(border) &&
    !identical(.el_get(border, "colour"), NA)
  has_rangeframe <- any(ctx$geoms %in% c("RangeFrame", "QuartileFrame"))

  if (has_border && !has_rangeframe) {
    return(.row(
      "The range-frame", "VDQI ch. 6",
      "Frame reports the data range",
      "fail",
      "A full panel border is drawn. Replace it with geom_rangeframe(), which spans only the range the data occupy and so reports the minimum and maximum for free."
    ))
  }
  if (has_rangeframe) {
    return(.row(
      "The range-frame", "VDQI ch. 6",
      "Frame reports the data range", "pass",
      "A range or quartile frame is in use."
    ))
  }
  .row(
    "The range-frame", "VDQI ch. 6",
    "Frame reports the data range", "note",
    "No frame at all. That is defensible, but geom_rangeframe() would give the axis something to say."
  )
}

#' @noRd
.check_pie <- function(ctx) {
  polar <- inherits(ctx$plot$coordinates, "CoordPolar")
  bars <- any(ctx$geoms %in% c("Bar", "Col", "ColTufte"))
  if (polar && bars) {
    return(.row(
      "Graphical integrity", "VDQI ch. 5",
      "No pie chart", "fail",
      "This is a pie chart. Readers judge angles and areas far worse than they judge positions along a common scale; a dot plot or a small table shows the same numbers better."
    ))
  }
  .row("Graphical integrity", "VDQI ch. 5", "No pie chart", "pass",
       "No pie chart.")
}

#' @noRd
.check_baseline <- function(ctx) {
  bars <- which(ctx$geoms %in% c("Bar", "Col", "ColTufte"))
  if (length(bars) == 0) return(NULL)

  lo <- suppressWarnings(min(vapply(ctx$built$layout$panel_params, function(pp) {
    r <- pp$y.range %||% (if (!is.null(pp$y)) pp$y$continuous_range else NULL)
    if (is.null(r)) NA_real_ else r[1]
  }, numeric(1)), na.rm = TRUE))

  if (is.finite(lo) && lo > 0) {
    return(.row(
      "Graphical integrity", "VDQI ch. 2",
      "Bars start at zero", "fail",
      sprintf("The y axis starts at %.3g, so bar length is no longer proportional to the quantity. Either start at zero or use points instead of bars.", lo)
    ))
  }
  .row("Graphical integrity", "VDQI ch. 2", "Bars start at zero", "pass",
       "Bars are measured from zero.")
}

#' @noRd
.check_lie_factor <- function(ctx) {
  lf <- tryCatch(lie_factor(ctx$plot), error = function(e) NA_real_)
  if (!is.finite(lf)) return(NULL)
  if (lf < 0.95 || lf > 1.05) {
    return(.row(
      "The lie factor", "VDQI ch. 2",
      "Lie factor near one", "fail",
      sprintf("Lie factor is %.2f: the effect shown is %.0f%% of the effect in the data.", lf, 100 * lf)
    ))
  }
  .row("The lie factor", "VDQI ch. 2", "Lie factor near one", "pass",
       sprintf("Lie factor is %.2f.", lf))
}

#' @noRd
.check_legend <- function(ctx) {
  pos <- ctx$theme$legend.position %||% "right"
  if (identical(pos, "none")) {
    return(.row(
      "Integrate word and image", "Beautiful Evidence ch. 5",
      "No legend to decode", "pass",
      "No legend: the plot labels itself or needs no key."
    ))
  }
  keys <- .legend_keys(ctx$built)
  if (keys == 0) {
    return(.row(
      "Integrate word and image", "Beautiful Evidence ch. 5",
      "No legend to decode", "pass", "No legend is drawn."
    ))
  }
  if (keys <= 6) {
    return(.row(
      "Integrate word and image", "Beautiful Evidence ch. 5",
      "No legend to decode", "fail",
      sprintf("A legend with %d entries makes the reader look away, hold a colour in memory, and look back. With this few series, label them on the plot with geom_text_last().", keys)
    ))
  }
  .row(
    "Integrate word and image", "Beautiful Evidence ch. 5",
    "No legend to decode", "note",
    sprintf("%d legend entries. Too many to label directly, which is usually a sign the plot should be small multiples instead.", keys)
  )
}

#' @noRd
.legend_keys <- function(built) {
  cols <- unique(unlist(lapply(built$data, function(d) {
    c(if (!is.null(d$colour)) d$colour, if (!is.null(d$fill)) d$fill)
  })))
  cols <- cols[!is.na(cols)]
  n <- length(unique(cols))
  if (n <= 1) 0L else as.integer(n)
}

#' @noRd
.check_hues <- function(ctx) {
  cols <- unique(unlist(lapply(ctx$built$data, function(d) {
    c(if (!is.null(d$colour)) d$colour, if (!is.null(d$fill)) d$fill)
  })))
  cols <- unique(cols[!is.na(cols) & cols != "NA"])
  n <- length(cols)
  if (n > 7) {
    return(.row(
      "Layering and separation", "Envisioning Information ch. 3",
      "Colour stays a code", "fail",
      sprintf("%d distinct colours. Past about six, hue stops being a code the reader can hold and becomes decoration; try grey with one accent, or small multiples.", n)
    ))
  }
  .row(
    "Layering and separation", "Envisioning Information ch. 3",
    "Colour stays a code", "pass",
    sprintf("%d colour%s in use.", n, if (n == 1) "" else "s")
  )
}

#' @noRd
.check_redundant_encoding <- function(ctx) {
  maps <- .all_mappings(ctx$plot)
  vars <- vapply(maps, .mapped_var, character(1))
  names(vars) <- names(maps)
  xv <- vars[names(vars) == "x"]
  dup <- vars[names(vars) %in% c("fill", "colour", "color")]
  dup <- dup[!is.na(dup)]
  if (length(xv) && length(dup) && any(dup %in% xv)) {
    return(.row(
      "Erase redundant data-ink", "VDQI ch. 4",
      "No variable encoded twice", "fail",
      sprintf("'%s' is mapped to both position and colour. The second encoding adds ink and a legend without adding information.", dup[dup %in% xv][1])
    ))
  }
  .row(
    "Erase redundant data-ink", "VDQI ch. 4",
    "No variable encoded twice", "pass",
    "No variable is encoded twice."
  )
}

#' @noRd
.check_small_multiples <- function(ctx) {
  faceted <- !inherits(ctx$plot$facet, "FacetNull")
  groups <- max(vapply(ctx$built$data, function(d) {
    if (is.null(d$group)) 0L else length(unique(d$group[d$group > 0]))
  }, integer(1)), 0L)

  if (faceted) {
    return(.row(
      "Small multiples", "Envisioning Information ch. 4",
      "Comparison by repetition", "pass",
      "The plot uses small multiples."
    ))
  }
  if (groups > 6) {
    return(.row(
      "Small multiples", "Envisioning Information ch. 4",
      "Comparison by repetition", "note",
      sprintf("%d series are overlaid in one panel. Past half a dozen, the lines start hiding each other; facet_tufte() shows the same data as a comparable series of panels.", groups)
    ))
  }
  .row(
    "Small multiples", "Envisioning Information ch. 4",
    "Comparison by repetition", "pass",
    "Few enough series to read in one panel."
  )
}

#' @noRd
.check_documentation <- function(ctx) {
  cap <- ctx$plot$labels$caption
  has_cap <- !is.null(cap) && nzchar(as.character(cap)[1])
  .row(
    "Documentation", "Beautiful Evidence ch. 6",
    "The figure says where its numbers came from",
    if (has_cap) "pass" else "fail",
    if (has_cap) {
      "A caption documents the figure."
    } else {
      "No caption. A graphic should name its source on the graphic, so the claim can be checked without hunting through the text. See label_source()."
    }
  )
}

#' @noRd
.check_aspect <- function(ctx) {
  ratio <- ctx$width / ctx$height
  if (ratio < 1) {
    return(.row(
      "Aspect ratio", "VDQI ch. 9",
      "The figure tends toward the horizontal", "fail",
      sprintf("The figure is taller than it is wide (%.2f:1). Causal and temporal comparisons read left to right; graphics should tend toward the horizontal, near 1.5:1.", ratio)
    ))
  }
  if (ratio > 3) {
    return(.row(
      "Aspect ratio", "VDQI ch. 9",
      "The figure tends toward the horizontal", "note",
      sprintf("The figure is %.2f:1, which flattens vertical detail. That is right for a sparkline and wrong for most else.", ratio)
    ))
  }
  .row("Aspect ratio", "VDQI ch. 9",
       "The figure tends toward the horizontal", "pass",
       sprintf("Aspect ratio %.2f:1.", ratio))
}

#' @noRd
.check_banking <- function(ctx) {
  b <- tryCatch(bank_to_45(ctx$plot, width = ctx$width),
                error = function(e) NULL)
  if (is.null(b) || !is.finite(b$aspect)) return(NULL)

  current <- ctx$height / ctx$width
  off <- b$aspect / current
  if (!is.finite(off) || off <= 0) return(NULL)

  if (off > 2 || off < 0.5) {
    return(.row(
      "Bank to 45 degrees", "Cleveland, after VDQI ch. 9",
      "Slopes are readable at this shape", "fail",
      sprintf("At %gin x %gin the slopes in this plot sit far from 45 degrees, where they are judged most accurately. Banking suggests %.2fin tall rather than %gin. See bank_to_45().",
              ctx$width, ctx$height, b$height, ctx$height)
    ))
  }
  .row(
    "Bank to 45 degrees", "Cleveland, after VDQI ch. 9",
    "Slopes are readable at this shape", "pass",
    sprintf("Slopes sit near 45 degrees; banking would suggest %.2fin tall against the %gin given.",
            b$height, ctx$height)
  )
}

#' @noRd
.check_contrast <- function(ctx) {
  cc <- tryCatch(check_contrast(ctx$plot), error = function(e) NULL)
  if (is.null(cc) || nrow(cc) == 0) return(NULL)

  bad <- cc[!cc$passes, , drop = FALSE]
  if (nrow(bad) > 0) {
    return(.row(
      "Legibility", "WCAG 2.1, against VDQI ch. 4",
      "Ink is dark enough to see", "fail",
      sprintf("%s at contrast %.1f against the background, below the %.1f minimum. Maximising data-ink is not a licence to draw in colours people cannot see.",
              paste0(bad$role[1], " ", bad$colour[1]), bad$ratio[1],
              bad$threshold[1])
    ))
  }
  .row(
    "Legibility", "WCAG 2.1, against VDQI ch. 4",
    "Ink is dark enough to see", "pass",
    sprintf("Every colour clears its contrast minimum; the faintest is %.1f to 1.",
            min(cc$ratio))
  )
}

#' @noRd
.check_data_ink <- function(ctx) {
  if (!isTRUE(ctx$measure)) return(NULL)
  di <- tryCatch(
    data_ink_ratio(ctx$plot, width = ctx$width, height = ctx$height),
    error = function(e) NULL
  )
  if (is.null(di) || !is.finite(di$ratio)) return(NULL)

  status <- if (di$ratio >= 0.5) "pass" else "fail"
  .row(
    "Maximise the data-ink ratio", "VDQI ch. 4",
    "Most ink varies with the data", status,
    sprintf("Data-ink ratio is %.2f: %.0f%% of the ink in this figure varies with the data.",
            di$ratio, 100 * di$ratio)
  )
}

#' @noRd
.check_density <- function(ctx) {
  if (!isTRUE(ctx$measure)) return(NULL)
  dd <- tryCatch(
    data_density(ctx$plot, width = ctx$width, height = ctx$height),
    error = function(e) NULL
  )
  if (is.null(dd) || !is.finite(dd$density)) return(NULL)

  if (dd$density < 2) {
    return(.row(
      "Maximise data density", "VDQI ch. 8",
      "The figure earns its space", "fail",
      sprintf("Data density is %.1f numbers per square inch: %d entries over %.1f square inches. A graphic this empty would be shorter as a sentence.",
              dd$density, dd$entries, dd$area)
    ))
  }
  .row(
    "Maximise data density", "VDQI ch. 8",
    "The figure earns its space", "pass",
    sprintf("Data density is %.1f numbers per square inch.", dd$density)
  )
}

#' @noRd
.check_fit <- function(ctx) {
  if (!isTRUE(ctx$measure)) return(NULL)
  fits <- tryCatch(
    suppressWarnings(check_labels_fit(ctx$plot, ctx$width, ctx$height)),
    error = function(e) NULL
  )
  if (is.null(fits) || nrow(fits) == 0) return(NULL)

  bad <- fits[!fits$fits, , drop = FALSE]
  if (nrow(bad) > 0) {
    return(.row(
      "Revise and edit", "VDQI ch. 9",
      "Nothing is clipped at the printed size", "fail",
      sprintf("%s will be clipped at %gin x %gin.",
              paste(bad$element, collapse = ", "), ctx$width, ctx$height)
    ))
  }
  .row(
    "Revise and edit", "VDQI ch. 9",
    "Nothing is clipped at the printed size", "pass",
    "Every text element fits inside the canvas."
  )
}
