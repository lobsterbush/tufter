## Test environments

* local macOS 26.4 (aarch64), R 4.5.2
* `R CMD check --as-cran` on the built tarball

## R CMD check results

0 errors | 0 warnings | 2 notes

This is a new submission.

The second note reports that `https://github.com/lobsterbush/tufter` returns
404. Make the repository public, or drop the two URLs from `DESCRIPTION`, before
submitting.

The third-party note is local: this machine's HTML Tidy predates the version R
now asks for, so the HTML manual check is skipped.

## Notes for the reviewer

`data_ink_ratio()` and `check_labels_fit()` render the plot to a temporary PNG
in order to measure it, using `ragg` when that's installed and `grDevices::png()`
otherwise. Both write only to `tempfile()`, delete what they write, and restore
the previously active graphics device.

Nothing in the package accesses the internet. `data-raw/` holds a script that
fetches from four public APIs and is excluded from the build. The vignettes use
`gapminder` and `palmerpenguins`, both suggested and both guarded, so they build
when neither is installed.

The title and description name Edward Tufte, whose books the package implements.
The four books are cited by ISBN and Cleveland, McGill and McGill (1988) by DOI.
