# Builds the pkgdown site into docs/.
#
# The GitHub repository is private but GitHub Pages on this plan is not, so
# anything landing in docs/ is world-readable. pkgdown renders every markdown
# file it finds at the repository root, which would put WARP.md, internal
# project context, on a public site. Rather than scrub the built output, which
# leaves entries behind in the search index and the sitemap, the file is moved
# aside for the duration of the build and put back afterwards.
#
# The work happens inside a function so that on.exit actually fires; registered
# at the top level of a script it does not, and the file would stay moved.
#
# Run from the package root:  Rscript data-raw/build_site.R

build_private_site <- function(private_files = "WARP.md") {
  present <- private_files[file.exists(private_files)]

  if (length(present)) {
    stash <- file.path(tempdir(), paste0(basename(present), ".held"))
    if (!all(file.copy(present, stash, overwrite = TRUE))) {
      stop("could not stash ", paste(present, collapse = ", "), "; aborting")
    }
    unlink(present)
    on.exit({
      file.copy(stash, present, overwrite = TRUE)
      unlink(stash)
      message("restored: ", paste(present, collapse = ", "))
    }, add = TRUE)
    message("held back from the public site: ", paste(present, collapse = ", "))
  }

  pkgdown::build_site(preview = FALSE, install = TRUE)

  leaked <- list.files("docs", pattern = "^WARP", recursive = TRUE)
  if (length(leaked)) {
    warning("internal files reached docs/: ", paste(leaked, collapse = ", "))
  } else {
    message("site built into docs/; no internal files present")
  }
  invisible(TRUE)
}

build_private_site()

stopifnot("WARP.md was not restored" = file.exists("WARP.md"))
