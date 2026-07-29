# Save a figure, and check it before you do

A wrapper on
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) with
the defaults set for print: 6.5 inches wide, which is a single text
column; `cairo_pdf` for PDF output, so that fonts embed properly; and
300 dpi for raster formats.

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

Before writing the file it runs
[`check_labels_fit()`](https://lobsterbush.github.io/tufter/reference/check_labels_fit.md)
at the size you asked for, because a subtitle that fits on screen at the
default device size is not a subtitle that fits in the saved file.
Clipping is reported as a warning; set `strict = TRUE` to make it an
error instead.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
f <- file.path(tempdir(), "figure.pdf")
save_tufte(f, p)
unlink(f)
```
