# A maximum data-ink theme

Strips every element of the plot that doesn't itself carry data: the
panel background, the grid, the panel border, and the legend frame. This
is the theme half of Tufte's instruction to maximise the share of ink
that varies with the data, and to erase the rest.

## Usage

``` r
theme_tufte(
  base_size = 12,
  base_family = "",
  ticks = TRUE,
  axis_lines = FALSE,
  grid = c("none", "x", "y", "both")
)
```

## Arguments

- base_size:

  Base font size in points. Defaults to 12.

- base_family:

  Base font family. Defaults to `""` (the device default). `"serif"` is
  closer to Tufte's own books.

- ticks:

  Logical. Draw axis tick marks? Defaults to `TRUE`; ticks are data-ink
  in the weak sense that they locate values.

- axis_lines:

  Logical. Draw conventional axis lines? Defaults to `FALSE`, since
  [`geom_rangeframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
  is the better choice.

- grid:

  One of `"none"` (the default), `"x"`, `"y"` or `"both"`. Draws a
  hairline grid where you ask for one.

## Value

A `ggplot2` theme object.

## Details

The default has no axis lines at all, on the assumption that you'll add
a
[`geom_rangeframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md)
or
[`geom_quartileframe()`](https://lobsterbush.github.io/tufter/reference/geom_rangeframe.md),
which carries information the panel border doesn't. Set
`axis_lines = TRUE` if you want conventional full-length axes instead.

A faint grid is sometimes the honest choice: when readers must recover
values from the plot rather than compare shapes. Tufte's own bar charts
keep gridlines but erase them where they cross the bars, which is what
[`geom_col_tufte()`](https://lobsterbush.github.io/tufter/reference/geom_col_tufte.md)
does. `grid = "y"` or `"x"` gives you a hairline grid on one axis only.

## See also

[`theme_sparkline()`](https://lobsterbush.github.io/tufter/reference/theme_sparkline.md),
[`theme_slopegraph()`](https://lobsterbush.github.io/tufter/reference/theme_slopegraph.md)

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_rangeframe() +
  theme_tufte()
```
