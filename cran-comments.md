## Test environment

* Local macOS 26.4 (aarch64), R 4.5.2, ggplot2 4.0.3
* Built source archive: `tufter_0.6.4.tar.gz`, rebuilt after the prose rewrite
* `R CMD check --as-cran` completed on 2026-09-07

## R CMD check results

0 errors | 0 warnings | 1 note

The only note is CRAN incoming feasibility: "New submission".
All 672 test expectations passed, with no failures, warnings, or skips.
Examples, both installed vignettes, and PDF and HTML manuals passed.
The repository is public and the package URLs pass URL checks.

## Checks still required before submission

This is a release candidate, not a record of completed cross-platform checks.
Run the archive on current R release and R-devel, including Windows, and
update this file with those actual results before uploading to CRAN.
I haven't uploaded the package to CRAN or requested external service checks.

## Notes for the reviewer

This is the first CRAN submission of tufter.

`data_ink_ratio()` and `check_labels_fit()` use temporary PNG files for
measurement. The ink renderer uses `ragg` when available and `grDevices::png()`
otherwise. Temporary measurement files are cleaned up and the previous
graphics device is restored. The base PNG fallback was also exercised locally.

Package functions do not access the internet. Network data collection scripts
and site-only articles are excluded from the source package. The two installed
vignettes guard their suggested data packages with `requireNamespace()`.

The source archive includes `inst/PROVENANCE`, declaring AI – Human (editor)
and identifying Charles Crabtree as human editor and maintainer. Development
notes, website files, build scripts, and local check artifacts are excluded.
