## Test environments

* local macOS 26.4 (aarch64), R 4.5.2
* `R CMD check --as-cran` on the built tarball

## R CMD check results

0 errors | 0 warnings | 2 notes

```
* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Charles Crabtree <charles.crabtree@monash.edu>'
  New submission
  Found the following (possibly) invalid URLs: ...
```

This is a new submission.

**Before submitting**, make the GitHub repository public. The two URLs flagged
above return 404 only because `github.com/lobsterbush/tufter` is currently
private; the documentation site at `lobsterbush.github.io/tufter` already
resolves. Either publish the repository or drop the two URLs from DESCRIPTION.
Do not submit while the check reports them as 404.

```
* checking HTML version of manual ... NOTE
  Skipping checking HTML validation: 'tidy' doesn't look like recent enough HTML Tidy.
```

This is the local toolchain rather than the package. The macOS system `tidy`
predates the version R now wants.

## Notes for the reviewer

`data_ink_ratio()` and `check_labels_fit()` render the plot to a temporary PNG
in order to measure it, using `ragg` when that's installed and `grDevices::png()`
otherwise. Both write only to `tempfile()`, delete what they write, and restore
the previously active graphics device.

Nothing in the package accesses the internet. `data-raw/` holds a script that
fetches from four public APIs and is excluded from the build. The vignettes use
`gapminder` and `palmerpenguins`, both suggested and both guarded, so the
vignettes build when neither is installed.

The title and description name Edward Tufte, whose books the package
implements. The four books are cited by ISBN, and Cleveland, McGill and McGill
(1988) by DOI, which was checked against Crossref.
