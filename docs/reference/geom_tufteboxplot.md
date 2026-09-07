# Tufte's minimal box plot

This implements Tufte's box plot without the enclosing box or whisker
caps. Choose the version that makes the distribution easiest to read at
your figure's final size.

## Usage

``` r
geom_tufteboxplot(
  mapping = NULL,
  data = NULL,
  stat = "boxplot",
  position = "dodge2",
  ...,
  type = c("point", "line", "offset"),
  offset = 0.12,
  median_size = 1.6,
  box_linewidth = 1.6,
  outliers = TRUE,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
)
```

## Arguments

- mapping, data, stat, position, na.rm, show.legend, inherit.aes, ...:

  Standard `ggplot2` layer arguments. See
  [`layer()`](https://ggplot2.tidyverse.org/reference/layer.html).

- type:

  One of `"point"`, `"line"` or `"offset"`.

- offset:

  For `type = "offset"`, how far to shift the interquartile line, as a
  fraction of the category width. Defaults to `0.12`.

- median_size:

  Size of the median dot for `type = "point"`. Defaults to `1.6`.

- box_linewidth:

  Line width of the interquartile segment for the `"line"` and
  `"offset"` variants. Defaults to `1.6`.

- outliers:

  Logical. Draw outlying points beyond the whiskers? Defaults to `TRUE`.
  Tufte would keep them: they're data.

## Value

A `ggplot2` layer.

## Details

- `"point"`:

  The default. Two whisker lines leave a gap for the interquartile
  range, with a dot at the median.

- `"line"`:

  A thin whisker line spans the range, a thicker segment marks the
  interquartile range, and a white break marks the median.

- `"offset"`:

  The interquartile segment sits beside the whisker line. This can help
  when the whiskers are short.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(factor(cyl), mpg)) +
  geom_tufteboxplot() +
  theme_tufte()


ggplot(mtcars, aes(factor(cyl), mpg)) +
  geom_tufteboxplot(type = "offset") +
  theme_tufte()
```
