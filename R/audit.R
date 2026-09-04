#' Audit a plot against Tufte's principles
#'
#' Reports what a plot does against what Tufte actually wrote, and is careful
#' about the difference between the two kinds of thing he wrote.
#'
#' For some principles Tufte states a criterion a graphic either meets or does
#' not: bars are measured from zero, the lie factor lies between 0.95 and 1.05,
#' graphics tend toward the horizontal, non-data ink comes off the page. Those
#' are reported as met or not met.
#'
#' For others he states only a direction. He asks that the data-ink ratio be
#' maximised "within reason" and that data density be increased, and nowhere
#' says how much is enough, because the answer depends on the content. Those are
#' measured and reported without a verdict, since any threshold would be the
#' package author's rather than his.
#'
#' There's no score. Counting satisfied principles would mean weighting them
#' against each other, and Tufte offers no exchange rate between a pie chart and
#' a missing source note. The audit gives you a list of stated criteria that
#' aren't met, and a set of measurements to compare against another draft of the
#' same figure.
#'
#' @param plot A \code{ggplot} object.
#' @param width,height Intended printed size in inches, used by the checks and
#'   measurements that depend on it. Defaults to 6.5 by 4.
#' @param measure Logical. Report the data-ink ratio and the data density,
#'   which are the slow part? Defaults to \code{TRUE}. This governs only those
#'   two, which Tufte states no threshold for and the audit therefore doesn't
#'   grade. Every stated criterion is checked either way, so the count of
#'   violations means the same thing whichever you pass.
#' @return An object of class \code{tufte_audit}: a tibble with one row per
#'   check, whose \code{status} is \code{"fail"} for a stated criterion that's
#'   not met, \code{"pass"} for one that's met, \code{"report"} for a
#'   measurement Tufte gives no threshold for, and \code{"skip"} for a check
#'   that couldn't run. The count of unmet criteria, a single integer, is
#'   attached as the \code{"violations"} attribute.
#' @seealso \code{\link{tufte_principles}()}, which marks which principles carry
#'   a stated criterion and which don't.
#' @export
#' @examples
#' library(ggplot2)
#' tufte_audit(ggplot(mtcars, aes(wt, mpg)) + geom_point())
tufte_audit <- function(plot, width = 6.5, height = 4, measure = TRUE) {
  .check_gg(plot)
  # Every individual measure rejects a size that is not a size. The audit wraps
  # them in tryCatch, so without this an impossible canvas silently dropped the
  # four rendering checks, one of them a graded criterion, and the violation
  # count came back lower than the truth.
  .check_size(width, height)

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
    `redundant encoding` = .check_redundant_encoding,
    `documentation` = .check_documentation,
    `aspect ratio` = .check_aspect,
    `contrast` = .check_contrast,
    `label fit` = .check_fit,
    `data-ink ratio` = .check_data_ink,
    `data density` = .check_density,
    `banking` = .check_banking,
    `hues` = .check_hues,
    `overlaid series` = .check_series
  )

  rows <- lapply(names(checks), function(nm) {
    out <- tryCatch(checks[[nm]](ctx), error = function(e) {
      .row("(check unavailable)", nm, "skip",
           paste0("The ", nm, " check could not run: ", conditionMessage(e)))
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

  structure(
    tab,
    violations = sum(tab$status == "fail"),
    plot_size = c(width = width, height = height),
    class = c("tufte_audit", class(tab))
  )
}

#' @export
print.tufte_audit <- function(x, ...) {
  sz <- attr(x, "plot_size")
  violations <- attr(x, "violations")

  fails <- x[x$status == "fail", , drop = FALSE]
  reports <- x[x$status == "report", , drop = FALSE]
  passes <- x[x$status == "pass", , drop = FALSE]
  skipped <- x[x$status == "skip", , drop = FALSE]

  cli::cli_h2("Tufte audit")
  cli::cli_text(
    "At {sz[['width']]}in x {sz[['height']]}in: ",
    "{.strong {violations}} stated criteri{?on/a} not met."
  )

  if (nrow(fails) > 0) {
    cli::cli_h3("Not met")
    for (i in seq_len(nrow(fails))) {
      cli::cli_bullets(c("x" = "{fails$message[i]}"))
      cli::cli_text("  {.emph {fails$principle[i]} - {fails$source[i]}}")
    }
  }
  if (nrow(reports) > 0) {
    cli::cli_h3("Measured, not graded")
    cli::cli_text(
      "{.emph Tufte states a direction for these rather than a threshold. Read them ",
      "against another draft of the same figure.}"
    )
    for (i in seq_len(nrow(reports))) {
      cli::cli_bullets(c("*" = "{reports$message[i]}"))
    }
  }
  if (nrow(passes) > 0) {
    cli::cli_h3("Met")
    cli::cli_ul(passes$check)
  }
  if (nrow(skipped) > 0) {
    cli::cli_h3("Could not be checked")
    cli::cli_ul(skipped$message)
  }
  invisible(x)
}

# ---- shared helpers ---------------------------------------------------------

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

# The source is looked up from tufte_principles() rather than repeated here.
# Holding the same citation in two places let three of them drift apart, and
# the table is the package's own account of what it does.
#' @noRd
.row <- function(principle, check, status, message) {
  list(principle = principle, source = .principle_source(principle),
       check = check, status = status, message = message)
}

#' @noRd
.principle_source <- function(principle) {
  p <- tufte_principles()
  hit <- match(principle, p$principle)
  if (is.na(hit)) NA_character_ else p$source[hit]
}

# Is a fill invisible against the page? Comparing the strings themselves
# counted "grey100", "gray100", "#fff" and "#FFFFFFFF" as coloured panels,
# though every one of them is pure white. ggplot2 4.0's complete_theme() hands
# back eight-digit hex, so the eight-digit form is the common case, and a false
# fail here inflates the one count the audit says is meaningful.
#' @noRd
.is_blank_fill <- function(fill) {
  if (length(fill) != 1 || is.na(fill)) return(TRUE)
  if (identical(fill, "transparent")) return(TRUE)
  rgba <- tryCatch(grDevices::col2rgb(fill, alpha = TRUE)[, 1],
                   error = function(e) NULL)
  if (is.null(rgba)) return(FALSE)
  if (rgba[["alpha"]] == 0) return(TRUE)
  all(rgba[c("red", "green", "blue")] == 255)
}

# ---- criteria Tufte states -------------------------------------------------

#' @noRd
.check_panel_background <- function(ctx) {
  bg <- ctx$theme$panel.background
  fill <- .el_get(bg, "fill")
  opaque <- !is.null(fill) && !identical(fill, NA) && !.is_blank_fill(fill)
  .row(
    "Erase non-data ink",
    "Panel carries no background fill",
    if (opaque) "fail" else "pass",
    if (opaque) {
      sprintf("The panel is filled with %s. The fill is identical whatever the numbers are, so it's non-data ink and Tufte's instruction is to erase it.", fill)
    } else {
      "The panel has no background fill."
    }
  )
}

#' @noRd
.check_gridlines <- function(ctx) {
  # A grid asked for on one axis only lives in the .x or .y element, exactly as
  # check_contrast() already noted for the major grid. Reading only the parent
  # let panel.grid.minor.x through.
  minors <- list(ctx$theme$panel.grid.minor,
                 ctx$theme$panel.grid.minor.x,
                 ctx$theme$panel.grid.minor.y)
  if (any(!vapply(minors, .is_blank, logical(1)))) {
    return(.row(
      "Erase non-data ink",
      "No minor gridlines", "fail",
      "Minor gridlines are drawn. They subdivide the scale past the precision anyone reads off a graphic, so they're non-data ink."
    ))
  }
  .row(
    "Erase non-data ink",
    "No minor gridlines", "pass",
    "No minor gridlines."
  )
}

#' @noRd
.check_frame <- function(ctx) {
  border <- ctx$theme$panel.border
  has_border <- !.is_blank(border) &&
    !identical(.el_get(border, "colour"), NA)
  if (has_border) {
    return(.row(
      "The range-frame",
      "No full panel border", "fail",
      "A full panel border is drawn. The box is the same box whatever the data are. geom_rangeframe() replaces it with a line spanning only the range the data occupy, which reports the extremes for free."
    ))
  }
  .row(
    "The range-frame",
    "No full panel border", "pass",
    "No full panel border."
  )
}

#' @noRd
.check_pie <- function(ctx) {
  # coord_radial() is ggplot2's current spelling and does not inherit from
  # CoordPolar, so testing only the old class let the pies most people now
  # draw pass the check.
  polar <- inherits(ctx$plot$coordinates, c("CoordPolar", "CoordRadial"))
  bars <- any(ctx$geoms %in% c("Bar", "Col", "ColTufte"))
  if (polar && bars) {
    return(.row(
      "Graphical integrity",
      "No pie chart", "fail",
      "This is a pie chart. Tufte's judgement is that the only design worse than one pie chart is several of them. Readers compare angles and areas far less accurately than positions along a common scale."
    ))
  }
  .row("Graphical integrity", "No pie chart", "pass",
       "No pie chart.")
}

#' @noRd
.check_baseline <- function(ctx) {
  bars <- which(ctx$geoms %in% c("Bar", "Col", "ColTufte"))
  if (length(bars) == 0) return(NULL)

  # A horizontal bar chart, whether written that way or flipped by the coord,
  # carries its length on the other axis. Naming the wrong one would give the
  # right verdict with an explanation the reader cannot act on.
  ax <- .bar_axes(ctx$built$data[[bars[1]]], ctx$plot$coordinates)
  seen <- toupper(ax$panel)

  trans <- .y_transform_name(ctx$built, ax$data)
  if (!is.na(trans) && !trans %in% c("identity", "reverse")) {
    return(.row(
      "Graphical integrity",
      "Bars measured from zero", "fail",
      sprintf("The %s axis uses a %s transformation, so a bar's length is no longer proportional to the quantity it represents. Use points on a transformed scale instead of bars.", seen, trans)
    ))
  }

  lo <- suppressWarnings(min(vapply(ctx$built$layout$panel_params, function(pp) {
    r <- .panel_range_of(pp)[[ax$panel]]
    if (is.null(r)) NA_real_ else r[1]
  }, numeric(1)), na.rm = TRUE))

  if (is.finite(lo) && lo > 0) {
    return(.row(
      "Graphical integrity",
      "Bars measured from zero", "fail",
      sprintf("The %s axis starts at %.3g, so bar length isn't proportional to the quantity. Tufte's rule is that the representation of numbers, as physically measured on the graphic, should be directly proportional to the quantities represented.", seen, lo)
    ))
  }
  .row("Graphical integrity", "Bars measured from zero", "pass",
       "Bars are measured from zero.")
}

#' @noRd
.check_lie_factor <- function(ctx) {
  lf <- tryCatch(lie_factor(ctx$plot), error = function(e) NA_real_)
  if (!is.finite(lf)) return(NULL)
  # The 0.95 to 1.05 band is Tufte's own, stated in VDQI: outside it he treats
  # the graphic as substantially distorted.
  if (lf < 0.95 || lf > 1.05) {
    return(.row(
      "The lie factor",
      "Lie factor within Tufte's band", "fail",
      sprintf("Lie factor is %.2f. Tufte treats anything outside 0.95 to 1.05 as substantial distortion. The effect shown here is %.0f%% of the effect in the data.", lf, 100 * lf)
    ))
  }
  .row("The lie factor", "Lie factor within Tufte's band", "pass",
       sprintf("Lie factor is %.2f, inside Tufte's 0.95 to 1.05 band.", lf))
}

#' @noRd
.check_legend <- function(ctx) {
  # Ask the built figure whether a key is actually drawn. Counting distinct
  # rendered colours would accuse any plot that sets two fixed colours outside
  # aes(), such as red points under a blue fit line, of carrying a legend it
  # never had.
  if (!.has_legend(ctx$plot)) {
    return(.row(
      "Integrate word, number and image",
      "No legend to decode", "pass",
      "No legend, so the plot either labels itself or needs no key."
    ))
  }
  # A continuous scale has no series to name, so direct labelling is not on
  # offer and Tufte's instruction does not reach it. Tufte keys continuous
  # shading himself, in the maps of Envisioning Information.
  if (.has_continuous_colour(ctx$built)) {
    return(.row(
      "Integrate word, number and image",
      "No legend to decode", "report",
      "A key is drawn for a continuous scale. There are no named series to label on the data, so this isn't the legend Tufte objects to."
    ))
  }
  .row(
    "Integrate word, number and image",
    "No legend to decode", "fail",
    "A legend is drawn for named series. Tufte's instruction is that words belong on the data rather than in a key the reader has to hold in memory and look back to. geom_text_last() labels each series in place, and where there are too many to label, facet_tufte() shows them as small multiples instead."
  )
}

# Does the assembled figure carry a guide box with anything in it?
#' @noRd
.has_legend <- function(plot) {
  tryCatch(
    .with_null_device(.guide_box_drawn(ggplot2::ggplotGrob(plot))),
    error = function(e) FALSE
  )
}

# A guide box is in the layout whether or not a legend was drawn, so the test
# is whether one of them has any width. Called only from inside a device guard.
#' @noRd
.guide_box_drawn <- function(gt) {
  i <- which(grepl("^guide-box", gt$layout$name))
  if (length(i) == 0) return(FALSE)
  any(vapply(i, function(k) {
    g <- gt$grobs[[k]]
    if (inherits(g, "zeroGrob")) return(FALSE)
    w <- tryCatch(
      sum(grid::convertWidth(grid::grobWidth(g), "in", valueOnly = TRUE)),
      error = function(e) 0
    )
    is.finite(w) && w > 0
  }, logical(1)))
}

#' @noRd
.legend_hues <- function(built) {
  cols <- unique(unlist(lapply(built$data, function(d) {
    c(if (!is.null(d$colour)) d$colour, if (!is.null(d$fill)) d$fill)
  })))
  cols <- cols[!is.na(cols) & cols != "NA"]
  n <- length(unique(cols))
  if (n <= 1) 0L else as.integer(n)
}

#' @noRd
# Is every key in this figure a ramp rather than a list of names? The advice
# attached to a failure here is to label the series in place, which only makes
# sense when there are series. It used to look at colour and fill alone, so a
# continuous size, alpha or linewidth legend was told to use geom_text_last()
# on series it does not have.
.has_continuous_colour <- function(built) {
  scales <- tryCatch(built$plot$scales$scales, error = function(e) NULL)
  if (is.null(scales)) return(FALSE)
  keyed <- c("colour", "color", "fill", "size", "alpha", "linewidth", "shape",
             "linetype")
  relevant <- Filter(function(s) {
    aes <- tryCatch(s$aesthetics, error = function(e) character(0))
    any(keyed %in% aes)
  }, scales)
  if (!length(relevant)) return(FALSE)
  all(vapply(relevant, function(s) {
    isFALSE(tryCatch(s$is_discrete(), error = function(e) NA))
  }, logical(1)))
}

#' @noRd
.check_redundant_encoding <- function(ctx) {
  maps <- .all_mappings(ctx$plot)
  by_aes <- function(which) {
    unique(unlist(lapply(maps[names(maps) %in% which], .mapped_base_vars)))
  }
  # Position is x or y. Looking only at x let a horizontal bar chart map one
  # variable to both the category axis and the fill and still pass, which is
  # the same flipped-orientation blind spot .bar_axes() was written to close.
  shared <- intersect(by_aes(c("x", "y")), by_aes(c("fill", "colour", "color")))
  if (length(shared)) {
    return(.row(
      "Erase redundant data-ink",
      "No variable encoded twice", "fail",
      sprintf("'%s' is mapped to both position and colour. The second encoding is redundant data-ink, adding ink and a legend without adding information.", shared[1])
    ))
  }
  .row(
    "Erase redundant data-ink",
    "No variable encoded twice", "pass",
    "No variable is encoded twice."
  )
}

#' @noRd
.check_documentation <- function(ctx) {
  cap <- ctx$plot$labels$caption
  has_cap <- !is.null(cap) && nzchar(as.character(cap)[1])
  .row(
    "Documentation",
    "The figure names its source",
    if (has_cap) "pass" else "fail",
    if (has_cap) {
      "A caption documents the figure."
    } else {
      "No caption. Tufte asks that evidence be thoroughly described and its sources named on the graphic itself, so a reader can check the claim without hunting through the surrounding text. See label_source()."
    }
  )
}

#' @noRd
.check_aspect <- function(ctx) {
  ratio <- ctx$width / ctx$height
  # Tufte states the direction and the comparison: graphics should tend toward
  # the horizontal, greater in length than height. That gives a criterion at
  # 1, and no criterion anywhere else, so nothing else is graded here.
  if (ratio < 1) {
    return(.row(
      "Proportion and scale",
      "Wider than it is tall", "fail",
      sprintf("The figure is %.2f times as wide as it is tall, so it's taller than it's wide. Tufte's rule is that graphics should tend toward the horizontal, greater in length than height.", ratio)
    ))
  }
  .row("Proportion and scale",
       "Wider than it is tall", "pass",
       sprintf("The figure is %.2f times as wide as it is tall.", ratio))
}

#' @noRd
.check_contrast <- function(ctx) {
  cc <- tryCatch(check_contrast(ctx$plot), error = function(e) NULL)
  if (is.null(cc) || nrow(cc) == 0) return(NULL)

  bad <- cc[!cc$passes, , drop = FALSE]
  if (nrow(bad) > 0) {
    return(.row(
      "Legibility",
      "Ink clears the WCAG contrast minimum", "fail",
      sprintf("%s sits at contrast %.1f against the background, below the published minimum of %.1f. This isn't one of Tufte's criteria. It's the limit past which erasing ink stops being economy and starts being an unreadable figure.",
              paste0(bad$role[1], " ", bad$colour[1]), bad$ratio[1],
              bad$threshold[1])
    ))
  }
  .row(
    "Legibility",
    "Ink clears the WCAG contrast minimum", "pass",
    sprintf("Every colour clears its published minimum; the faintest is %.1f to 1.",
            min(cc$ratio))
  )
}

#' @noRd
.check_fit <- function(ctx) {
  # Not gated on ctx$measure. This is a stated criterion the figure passes or
  # fails, and dropping it turned a figure with a clipped subtitle into one
  # with no violations at all. Only the ungraded measurements are optional.
  fits <- tryCatch(
    suppressWarnings(check_labels_fit(ctx$plot, ctx$width, ctx$height)),
    error = function(e) NULL
  )
  if (is.null(fits) || nrow(fits) == 0) return(NULL)

  bad <- fits[!fits$fits, , drop = FALSE]
  if (nrow(bad) > 0) {
    return(.row(
      "Revise and edit",
      "Nothing is clipped at the printed size", "fail",
      sprintf("%s will be clipped at %gin x %gin.",
              paste(bad$element, collapse = ", "), ctx$width, ctx$height)
    ))
  }
  .row(
    "Revise and edit",
    "Nothing is clipped at the printed size", "pass",
    "Every text element fits inside the canvas."
  )
}

# ---- measurements Tufte gives no threshold for ------------------------------

#' @noRd
.check_data_ink <- function(ctx) {
  if (!isTRUE(ctx$measure)) return(NULL)
  di <- tryCatch(
    data_ink_ratio(ctx$plot, width = ctx$width, height = ctx$height),
    error = function(e) NULL
  )
  if (is.null(di) || !is.finite(di$ratio)) return(NULL)

  .row(
    "Maximise the data-ink ratio",
    "Data-ink ratio", "report",
    sprintf("Data-ink ratio %.2f: %.0f%% of the ink varies with the data. Tufte asks that this be maximised within reason and names no threshold, so read it against another draft of this figure rather than against a target.",
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

  .row(
    "Maximise data density",
    "Data density", "report",
    sprintf("Data density %.1f numbers per square inch: %d entries over %.1f square inches. Tufte ranks published graphics by this and sets no minimum.",
            dd$density, dd$entries, dd$area)
  )
}

#' @noRd
.check_banking <- function(ctx) {
  b <- tryCatch(bank_to_45(ctx$plot, width = ctx$width),
                error = function(e) NULL)
  if (is.null(b) || !is.finite(b$aspect)) return(NULL)

  .row(
    "Bank to 45 degrees",
    "Banked height", "report",
    sprintf("Slopes bank to 45 degrees at %.2fin tall for a %gin width; you have specified %gin. Cleveland gives 45 degrees as the target and states no tolerance around it, so there's nothing here to pass or fail.",
            b$height, ctx$width, ctx$height)
  )
}

#' @noRd
.check_hues <- function(ctx) {
  if (.has_continuous_colour(ctx$built)) {
    return(.row(
      "Colour as a code, not decoration",
      "Distinct hues", "report",
      "Colour varies continuously, which is one code rather than a set of competing hues."
    ))
  }
  n <- .legend_hues(ctx$built)
  .row(
    "Colour as a code, not decoration",
    "Distinct hues", "report",
    sprintf("%d distinct colour%s in use. Tufte's advice on colour is qualitative, so this is a count and not a verdict.",
            max(n, 1L), if (max(n, 1L) == 1) "" else "s")
  )
}

#' @noRd
.check_series <- function(ctx) {
  faceted <- !inherits(ctx$plot$facet, "FacetNull")
  # An ungrouped layer carries group -1, which is one series and not none.
  groups <- max(vapply(ctx$built$data, function(d) {
    if (is.null(d$group)) 0L else length(unique(d$group[d$group > 0]))
  }, integer(1)), 1L)

  # ggplot2 groups by the interaction of every discrete aesthetic, positional
  # ones included, so a dot plot of five countries arrives here as five groups.
  # Five points along a discrete axis are one series, not five overlaid ones,
  # and telling someone to facet them would put one point in each panel. Only
  # a non-positional aesthetic separates series that genuinely share a panel.
  if (!.has_series_aesthetic(ctx$plot)) groups <- 1L

  if (faceted) {
    return(.row(
      "Small multiples",
      "Overlaid series", "report",
      "The plot uses small multiples."
    ))
  }
  if (groups == 1L) {
    return(.row(
      "Small multiples",
      "Overlaid series", "report",
      "One series in one panel, so there is nothing to separate into small multiples."
    ))
  }
  .row(
    "Small multiples",
    "Overlaid series", "report",
    sprintf("%d series overlaid in one panel. facet_tufte() would show the same data as small multiples. Tufte gives no number at which to switch.",
            groups)
  )
}

# Is anything other than position telling the series apart? Position alone
# gives categories along an axis; colour, fill, linetype, shape or an explicit
# group give series that sit on top of one another.
#' @noRd
.has_series_aesthetic <- function(plot) {
  maps <- .all_mappings(plot)
  keys <- c("group", "colour", "color", "fill", "linetype", "shape")
  any(vapply(maps[names(maps) %in% keys],
             function(q) length(.mapped_base_vars(q)) > 0, logical(1)))
}
