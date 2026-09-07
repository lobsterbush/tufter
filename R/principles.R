#' Tufte's principles, and what implements them
#'
#' Look up each principle, its source, and the functions that implement it.
#' The table also records whether \code{\link{tufte_audit}()} can check it.
#'
#' The \code{criterion} column identifies principles with a stated rule, such
#' as a zero baseline for bars or a lie factor between 0.95 and 1.05. Tufte asks
#' that data-ink be maximised "within reason" and that data density increase,
#' but doesn't give them numerical targets. The audit reports those measurements
#' without grading them.
#'
#' Principles the package can't check are included with \code{audited = FALSE}.
#' I've kept them in the table so the limits of the audit are visible.
#'
#' @param audited_only Logical. Return only the principles the audit can check?
#'   Defaults to \code{FALSE}.
#' @return A tibble with columns \code{principle}, \code{source},
#'   \code{statement}, \code{implemented_by}, \code{audited} and
#'   \code{criterion}. \code{implemented_by} is a comma-separated list of
#'   functions in this package, or \code{NA} for the principles no function
#'   reaches. \code{audited} and \code{criterion} are both logical:
#'   \code{audited} says whether any function reports on the principle, and
#'   \code{criterion} whether Tufte states a threshold, so that
#'   \code{criterion} is the column that separates what the audit grades from
#'   what it only measures.
#' @export
#' @examples
#' tufte_principles()
#' # Principles Tufte states a testable criterion for:
#' subset(tufte_principles(), criterion)$principle
tufte_principles <- function(audited_only = FALSE) {
  out <- tibble::tribble(
    ~principle, ~source, ~statement, ~implemented_by, ~audited, ~criterion,

    "Above all else show the data", "VDQI ch. 4",
    "The graphic exists to show numbers; everything else is subordinate to that.",
    "theme_tufte()", FALSE, FALSE,

    "Maximise the data-ink ratio", "VDQI ch. 4",
    "A large share of the ink should be devoted to the non-redundant display of data.",
    "data_ink_ratio(), theme_tufte()", TRUE, FALSE,

    "Erase non-data ink", "VDQI ch. 4",
    "Ink that does not change when the data change should come off the page.",
    "theme_tufte()", TRUE, TRUE,

    "Erase redundant data-ink", "VDQI ch. 4",
    "Ink that repeats information the reader already has should come off too.",
    "geom_col_tufte(), geom_tufteboxplot()", TRUE, TRUE,

    "Revise and edit", "VDQI ch. 4",
    "Graphics are drafted, not drawn; the last pass removes what the first pass needed.",
    "check_labels_fit(), save_tufte()", TRUE, TRUE,

    "The range-frame", "VDQI ch. 6",
    "The frame should report the range of the data rather than boxing the panel.",
    "geom_rangeframe(), geom_quartileframe(), quartile_breaks()", TRUE, TRUE,

    "The dot-dash plot", "VDQI ch. 6",
    "The axis can carry the marginal distribution instead of a line.",
    "geom_dotdash()", FALSE, FALSE,

    "The lie factor", "VDQI ch. 2",
    "The effect shown should be the size of the effect in the data.",
    "lie_factor()", TRUE, TRUE,

    "Graphical integrity", "VDQI ch. 2",
    "Bars measure from zero; areas do not stand in for lengths; no pie charts.",
    "tufte_audit()", TRUE, TRUE,

    "Maximise data density", "VDQI ch. 8",
    "A graphic should carry enough numbers to justify the space it takes.",
    "data_density(), sparkline()", TRUE, FALSE,

    "Shrink the graphic", "VDQI ch. 8",
    "Most statistical graphics can be reduced far below their published size without loss.",
    "sparkline(), sparklines()", FALSE, FALSE,

    "Proportion and scale", "VDQI ch. 9",
    "Graphics tend toward the horizontal, a little wider than they are tall.",
    "save_tufte(), tufte_audit()", TRUE, TRUE,

    "Bank to 45 degrees", "Cleveland, not Tufte",
    "Slopes are judged best near 45 degrees; the aspect ratio is what puts them there.",
    "bank_to_45()", TRUE, FALSE,

    "Position beats length", "VDQI ch. 5",
    "A dot read against a scale needs no zero baseline and a fraction of the ink.",
    "geom_cleveland_dot()", FALSE, FALSE,

    "Legibility", "WCAG 2.1, not Tufte",
    "Erasing ink stops when what is left can no longer be seen.",
    "check_contrast(), contrast_ratio()", TRUE, TRUE,

    "Small multiples", "Envisioning Information ch. 4",
    "Show the same graphic once per condition, at one scale, and let the reader compare.",
    "facet_tufte()", TRUE, FALSE,

    "Layering and separation", "Envisioning Information ch. 3",
    "Distinguish elements by weight and value before reaching for hue.",
    "tufte_pal(), scale_colour_tufte()", FALSE, FALSE,

    "Micro and macro readings", "Envisioning Information ch. 2",
    "Detail should reward close reading without disturbing the overall shape.",
    "sparklines(), facet_tufte()", FALSE, FALSE,

    "Colour as a code, not decoration", "Envisioning Information ch. 5",
    "Colour should mean something; muted palettes let annotation sit on top of it.",
    "tufte_pal(\"muted\"), scale_colour_tufte()", TRUE, FALSE,

    "Show comparisons", "Beautiful Evidence ch. 6",
    "Every quantity begs the question: compared with what?",
    "slopegraph(), facet_tufte()", FALSE, FALSE,

    "Show causality", "Beautiful Evidence ch. 6",
    "The graphic should carry the mechanism as well as the correlation. No function does this; annotation does.",
    NA_character_, FALSE, FALSE,

    "Show multivariate data", "Beautiful Evidence ch. 6",
    "The world has more than two variables; the page can hold more than two.",
    "facet_tufte(), sparklines()", FALSE, FALSE,

    "Integrate word, number and image", "Beautiful Evidence ch. 5",
    "Labels belong on the data, not in a legend the reader must decode.",
    "geom_text_last(), geom_text_first(), slopegraph()", TRUE, TRUE,

    "Documentation", "Beautiful Evidence ch. 6",
    "The graphic should say where its numbers came from.",
    "label_source()", TRUE, TRUE,

    "Sparklines", "Beautiful Evidence ch. 2",
    "Word-sized graphics that sit inside the text they belong to.",
    "sparkline(), sparklines(), sparkline_grob()", FALSE, FALSE,

    "Content counts most of all", "Beautiful Evidence ch. 6",
    "No amount of design rescues a graphic with nothing to say. This one is yours.",
    NA_character_, FALSE, FALSE
  )

  if (audited_only) out <- out[out$audited, , drop = FALSE]
  out
}
