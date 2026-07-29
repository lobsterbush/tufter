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
  strip_hidden_comments()

  leaked <- list.files("docs", pattern = "^WARP", recursive = TRUE)
  if (length(leaked)) {
    warning("internal files reached docs/: ", paste(leaked, collapse = ", "))
  } else {
    message("site built into docs/; no internal files present")
  }
  invisible(TRUE)
}

# Markdown passes HTML comments straight through to the built page, so a
# section commented out in README.md is invisible to a reader but still sitting
# in the page source for anyone who looks. Sections marked HIDDEN FOR NOW are
# removed from the built HTML entirely; they stay in the repository source, so
# uncommenting them there brings them back on the next build.
strip_hidden_comments <- function() {
  pattern <- "<!--\\s*HIDDEN FOR NOW.*?END OF HIDDEN SECTION\\s*-->"
  files <- list.files("docs", pattern = "\\.(html|md)$", recursive = TRUE,
                      full.names = TRUE)
  n <- 0L
  for (f in files) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    if (!grepl("HIDDEN FOR NOW", txt, fixed = TRUE)) next
    out <- gsub(pattern, "", txt)
    if (grepl("HIDDEN FOR NOW", out, fixed = TRUE)) {
      warning("unmatched HIDDEN FOR NOW marker left in ", f)
    }
    writeLines(out, f)
    n <- n + 1L
  }
  if (n) message("stripped hidden sections from ", n, " built file(s)")
  invisible(n)
}

build_private_site()

stopifnot("WARP.md was not restored" = file.exists("WARP.md"))
