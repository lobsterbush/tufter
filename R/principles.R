#' Tufte's principles, and what implements them
#'
#' Returns the table this package is built around: each principle, the book it
#' comes from, the function or functions that put it into practice, and whether
#' \code{\link{tufte_audit}()} can check it automatically. Principles that no
#' function can check are listed too, with \code{audited} set to \code{FALSE},
#' because the honest version of "implements all of Tufte's principles" says
#' which ones a package cannot reach.
#'
#' @param audited_only Logical. Return only the principles the audit can check?
#'   Defaults to \code{FALSE}.
#' @return A tibble with columns \code{principle}, \code{source},
#'   \code{statement}, \code{implemented_by} and \code{audited}.
#' @export
#' @examples
#' tufte_principles()
#' subset(tufte_principles(), !audited)$principle
tufte_principles <- function(audited_only = FALSE) {
  out <- tibble::tribble(
    ~principle, ~source, ~statement, ~implemented_by, ~audited,

    "Above all else show the data", "VDQI ch. 4",
    "The graphic exists to show numbers; everything else is subordinate to that.",
    "theme_tufte()", TRUE,

    "Maximise the data-ink ratio", "VDQI ch. 4",
    "A large share of the ink should be devoted to the non-redundant display of data.",
    "data_ink_ratio(), theme_tufte()", TRUE,

    "Erase non-data ink", "VDQI ch. 4",
    "Ink that does not change when the data change should come off the page.",
    "theme_tufte()", TRUE,

    "Erase redundant data-ink", "VDQI ch. 4",
    "Ink that repeats information the reader already has should come off too.",
    "geom_col_tufte(), geom_tufteboxplot()", TRUE,

    "Revise and edit", "VDQI ch. 4",
    "Graphics are drafted, not drawn; the last pass removes what the first pass needed.",
    "check_labels_fit(), save_tufte()", TRUE,

    "The range-frame", "VDQI ch. 6",
    "The frame should report the range of the data rather than boxing the panel.",
    "geom_rangeframe(), geom_quartileframe(), quartile_breaks()", TRUE,

    "The dot-dash plot", "VDQI ch. 6",
    "The axis can carry the marginal distribution instead of a line.",
    "geom_dotdash()", FALSE,

    "The lie factor", "VDQI ch. 2",
    "The effect shown should be the size of the effect in the data.",
    "lie_factor()", TRUE,

    "Graphical integrity", "VDQI ch. 2",
    "Bars measure from zero; areas do not stand in for lengths; no pie charts.",
    "tufte_audit()", TRUE,

    "Maximise data density", "VDQI ch. 8",
    "A graphic should carry enough numbers to justify the space it takes.",
    "data_density(), sparkline()", TRUE,

    "Shrink the graphic", "VDQI ch. 8",
    "Most statistical graphics can be reduced far below their published size without loss.",
    "sparkline(), sparklines()", FALSE,

    "Aspect ratio", "VDQI ch. 9",
    "Graphics tend toward the horizontal, a little wider than they are tall.",
    "save_tufte(), tufte_audit()", TRUE,

    "Small multiples", "Envisioning Information ch. 4",
    "Show the same graphic once per condition, at one scale, and let the reader compare.",
    "facet_tufte()", TRUE,

    "Layering and separation", "Envisioning Information ch. 3",
    "Distinguish elements by weight and value before reaching for hue.",
    "tufte_pal(), scale_colour_tufte()", TRUE,

    "Micro and macro readings", "Envisioning Information ch. 2",
    "Detail should reward close reading without disturbing the overall shape.",
    "sparklines(), facet_tufte()", FALSE,

    "Colour as a code, not decoration", "Envisioning Information ch. 5",
    "Colour should mean something; muted palettes let annotation sit on top of it.",
    "tufte_pal(\"muted\"), scale_colour_tufte()", TRUE,

    "Show comparisons", "Beautiful Evidence ch. 6",
    "Every quantity begs the question: compared with what?",
    "slopegraph(), facet_tufte()", FALSE,

    "Show causality", "Beautiful Evidence ch. 6",
    "The graphic should carry the mechanism, not just the correlation.",
    "annotation, not code", FALSE,

    "Show multivariate data", "Beautiful Evidence ch. 6",
    "The world has more than two variables; the page can hold more than two.",
    "facet_tufte(), sparklines()", FALSE,

    "Integrate word, number and image", "Beautiful Evidence ch. 5",
    "Labels belong on the data, not in a legend the reader must decode.",
    "geom_text_last(), geom_text_first(), slopegraph()", TRUE,

    "Documentation", "Beautiful Evidence ch. 6",
    "The graphic should say where its numbers came from.",
    "label_source()", TRUE,

    "Sparklines", "Beautiful Evidence ch. 2",
    "Word-sized graphics that sit inside the text they belong to.",
    "sparkline(), sparklines(), sparkline_grob()", FALSE,

    "Content counts most of all", "Beautiful Evidence ch. 6",
    "No amount of design rescues a graphic with nothing to say.",
    "you", FALSE
  )

  if (audited_only) out <- out[out$audited, , drop = FALSE]
  out
}
