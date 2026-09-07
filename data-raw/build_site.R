# Build public documentation from an isolated copy; run from the package root.
# Existing docs are backed up before replacement. Internal project notes and
# release checks never enter the site, its search index, or its sitemap.

build_public_site <- function() {
  root <- here::here()
  stage <- tempfile("tufter-site-")
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  inputs <- c("DESCRIPTION", "NAMESPACE", "LICENSE", "README.md", "NEWS.md",
              "_pkgdown.yml", "R", "man", "inst", "vignettes", "pkgdown",
              "data-raw", ".Rbuildignore")
  stopifnot(all(file.copy(file.path(root, inputs), stage, recursive = TRUE)))
  pkgdown::build_site(pkg = stage, preview = FALSE, install = TRUE)
  output <- file.path(stage, "docs")
  stopifnot(file.exists(file.path(output, "index.html")))
  # pkgdown 2.2.0 awaits the Fuse object before its asynchronous fetch has
  # assigned it. A pasted query can therefore run against an empty index.
  # Await the actual loading promise; keep the fix in the reproducible build.
  search_file <- file.path(output, "pkgdown.js")
  js <- paste(readLines(search_file, warn = FALSE), collapse = "\n")
  if (grepl("await fuse;", js, fixed = TRUE)) {
    js <- sub("var fuse;", "var fuse;\n    var fusePromise;", js, fixed = TRUE)
    js <- sub('$("#search-input").focus(async function (e) {',
      '$("#search-input").focus(function (e) {\n      if (fusePromise) return;\n      fusePromise = (async function () {', js, fixed = TRUE)
    js <- sub('$(e.target).removeClass("loading");\n    });',
      '$(e.target).removeClass("loading");\n      })();\n    });', js, fixed = TRUE)
    js <- sub("await fuse;", "await fusePromise;", js, fixed = TRUE)
    writeLines(js, search_file)
  }
  forbidden <- list.files(output, pattern = "WARP|cran-comments|release_audit",
                          recursive = TRUE)
  if (length(forbidden)) stop("Internal files reached the site: ", paste(forbidden, collapse = ", "))
  destination <- here::here("docs")
  if (dir.exists(destination)) {
    backup_root <- here::here(".dev", "site-backups")
    dir.create(backup_root, recursive = TRUE, showWarnings = FALSE)
    backup <- tempfile("tufter-docs-", tmpdir = backup_root)
    if (!file.rename(destination, backup)) stop("Could not back up existing docs")
    message("Previous documentation backed up to ", backup)
  }
  if (!file.copy(output, root, recursive = TRUE)) {
    if (exists("backup")) file.rename(backup, destination)
    stop("Could not publish the built documentation")
  }
  message("Public documentation built into docs/")
}

build_public_site()
