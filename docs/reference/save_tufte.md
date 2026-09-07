# Save a figure after checking its labels

Save with
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) using
defaults for print: 6.5 inches wide, `cairo_pdf` for PDF output, and 300
dpi for raster formats. Set the height to suit your figure.

## Usage

``` r
save_tufte(
  filename,
  plot = ggplot2::last_plot(),
  width = 6.5,
  height = 4,
  dpi = 300,
  check = TRUE,
  strict = FALSE,
  ...
)
```

## Arguments

- filename:

  Path to write to. The extension sets the device.

- plot:

  The plot to save. Defaults to the last plot drawn.

- width, height:

  Size in inches. Defaults to 6.5 by 4.

- dpi:

  Resolution for raster formats. Defaults to 300.

- check:

  Logical. Check that the labels fit before saving?

- strict:

  Logical. Turn a clipping warning into an error?

- ...:

  Passed to
  [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The filename, invisibly.

## Details

Before saving, the function runs
[`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md)
at the requested size. Labels that don't fit produce a warning. With
`strict = TRUE`, they stop the save. A check that can't run also warns,
or stops a strict save.

Dimensions are in inches. You can't override `units` or `scale` through
`...`, because the size checked needs to match the size saved. The label
check has limits; inspect the exported figure too.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
f <- file.path(tempdir(), "figure.pdf")
save_tufte(f, p)
unlink(f)
```
