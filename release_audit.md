# tufter release audit

**Author and maintainer:** Charles Crabtree  
**Version:** 0.6.4  
**Date:** 7 September 2026  
**Status:** Release candidate; local checks pass, current R and Windows checks pending

The package and documentation have been audited and revised. The source archive
passes local CRAN-style checks with **0 errors, 0 warnings, and 1 expected new
submission note**. It has not been submitted to CRAN. Repository visibility and
public documentation were authorized by the maintainer.

## Issues fixed

| Area | Finding and resulting behavior |
| --- | --- |
| Strict export | A failed label check could still allow a strict save. Strict saves now stop when the check cannot run; ordinary saves warn. |
| Export dimensions | `units` or `scale` passed through to `ggsave()` could change the size after it was checked. These overrides are rejected, and dimensions are validated. |
| Contrast | Encoded transparency, transparent panel backgrounds, and rounded thresholds could produce incorrect passes. Colours are composited against the resolved background and thresholds use unrounded values. |
| Theme text | Axis and legend overrides could escape contrast checks. Checks now inspect rendered text grobs, including titles, captions, strips, axes, and legends. |
| Incomplete audits | Failed measurement checks could disappear. They now produce visible skipped results, and batch summaries distinguish incomplete audits from completed passes. |
| Batch dimensions | Partial dimension vectors could recycle silently. Dimensions must be positive scalars or supply exactly one value per plot. |
| Bar integrity | Negative bars, reversed axes, and different facet ranges could hide a truncated baseline. Measurements now inspect the relevant layer and panel; unsupported geometry returns unavailable results. |
| Label space | Title space ignored adjacent layout columns, and side-strip measurements used the wrong dimension. Available space now follows each grob's layout span and orientation. |
| Data density | `.data$x` and `.data[["x"]]` mappings could inflate or omit variable counts. The parser extracts the referenced columns and excludes `.env` constants. |
| Quartile frames | Reversed scales could make quartile frame segments disappear. Transformed quantiles are ordered before constructing the segments. |
| Documentation figures | Crowded GDP ticks, long facet names, clipped slopegraph labels, and missing direct series labels were corrected. README and vignette PNGs use 300 dpi. |
| Website access | The password gate and no-index instruction prevented public review. Public pages now expose documentation and installation links, with crawlable robots settings. |
| Site build | Builds now stage approved inputs, preserve previous documentation under `.dev/site-backups/`, and exclude internal release notes from generated pages. |
| Search | A pkgdown 2.2.0 loading race could lose pasted searches. The reproducible build patches search to await the index-loading promise. |
| Website design | Typography, navy accent, spacing, tables, navigation, and responsive layouts now match the current Charles Crabtree professional website. Inline console output has readable contrast. |

## Validation evidence

The checked archive is `.dev/release-0.6.4/tufter_0.6.4.tar.gz`. Its included R
sources, manuals, tests, and vignettes match the release working tree. It includes
the provenance declaration and excludes development artifacts, site output,
private project notes, and `.DS_Store` files. The archive's SHA-256 digest is
stored beside it.

| Check | Result |
| --- | --- |
| `R CMD check --as-cran` on built archive | 0 errors, 0 warnings, 1 note: new submission |
| Installed test suite | 672 passed; 0 failed, 0 warnings, 0 skipped |
| Examples and installed vignettes | Passed |
| PDF and HTML manuals | Passed |
| Base PNG fallback smoke check | Rendered at the requested dimensions and restored the prior device |
| Package URL check | All 15 checked URLs passed |
| Static documentation links and anchors | 65 HTML files checked; no broken local targets |
| Browser layouts | Home, reference index, label-fit reference, and real-data article checked at 1440, 768, 390, and 320 px; no horizontal overflow or failed images |
| Browser interactions | Mobile navigation and pasted search worked; no JavaScript page errors |
| Automated accessibility | The same four pages at 1440 and 390 px: no detected WCAG A/AA violations; colour-contrast checks on some code output remain marked incomplete by axe |
| Figure inspection | All 65 generated PNGs inspected against white backgrounds; corrected figures reinspected for text clipping and overlaps |

Accessibility coverage is sampled. Automated results do not certify every page
or replace keyboard and screen-reader review. Browser logs, screenshots,
accessibility results, URL results, and the package check directory are retained
locally under `.dev/release-0.6.4/`.

The four empirical references discussed in the package were checked read-only
against Crossref metadata. Matching records were found for Cleveland, McGill and
McGill (1988), Gillan and Richman (1994), Inbar, Tractinsky and Meyer (2007), and
Bateman and colleagues (2010). This verifies metadata, not every interpretation
of those papers. The Tufte books are identified by ISBN and were not counted as
DOI candidates. No citation or bibliography entry was changed.

## Remaining issues and limits

1. **Complete current R and Windows checks before submission.** Local R 4.5.2 is
   older than the current R release. Run the exact archive on current R release
   and R-devel, including Windows, then record the actual results in
   `cran-comments.md`. No results from those environments are implied here.
2. **Inspect final exports.** `check_labels_fit()` measures plot furniture; it
   does not certify text placed inside panels or detect every overlap. Font and
   graphics-device differences can change the saved result. Inspect each final
   exported figure at its intended dimensions.
3. **Treat contrast checks as a screen.** The checker does not resolve all
   overlapping marks or custom filled label, legend, and strip backgrounds.
   Passing it does not establish overall accessibility or colour-blind safety.
4. **Interpret measurements within their scope.** Data density estimates pooled
   rows and the union of mapped variables; it can fall back to canvas area when
   panel area cannot be estimated. Data-ink ratios depend on rendering and layer
   identification. Lie factor is limited to supported Cartesian comparisons;
   unsupported cases return unavailable results. A plot without bars does not
   acquire a general guarantee of graphical integrity from a baseline check.
5. **Review claims and sources editorially.** Audit checks cannot establish data
   accuracy, whether a caption names the correct source, or whether a graphic
   supports its substantive claim. The package supplies measurements and
   specific checks, not a universal quality score.
6. **Revisit the search patch when upgrading pkgdown.** It targets the generated
   JavaScript in pkgdown 2.2.0. Repeat the pasted-query browser check after an
   upgrade.

CRAN preparation follows the official
[submission policies](https://cran.r-project.org/web/packages/policies.html)
and [Writing R extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html).
The remaining environment checks are a release gate, not a package error found
by the completed local check.

## Reproduction

From the repository root, use the commands in `README.md` to regenerate README
outputs and the site. Build a fresh source archive with `R CMD build .`, then
run `R CMD check --as-cran tufter_0.6.4.tar.gz` from a dedicated check directory.
Keep the archive and full check logs together. Site checks used a local static
HTTP server and Chrome through Playwright; these tools are development-only.

## Provenance

| Provenance | Declaration |
| --- | --- |
| AI – Human (editor) | 🤖✏️👤 · [The Latent Review provenance standard](https://thelatentreview.com/provenance/) |

The original implementation was primarily generated with Claude. Codex assisted
with this audit, code fixes, release preparation, and website redesign. Charles
Crabtree is the human editor and maintainer with editorial responsibility. This
declaration appears in the README, website footer, and installed provenance file.
