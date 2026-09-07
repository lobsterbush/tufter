# Small multiples

Show the same kind of plot for each group. Keeping the scales fixed lets
readers compare levels across panels without adjusting for different
axes.

## Usage

``` r
facet_tufte(facets, ncol = NULL, nrow = NULL, scales = "fixed", ...)
```

## Arguments

- facets:

  Variables to facet by, as with
  [`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html),
  for example `vars(cyl)` or `~ cyl`.

- ncol, nrow:

  Panel layout. `ncol` defaults to `NULL`, letting `ggplot2` choose.

- scales:

  Passed to
  [`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html).
  Defaults to `"fixed"`, and warns if you change it, because free scales
  make panels incomparable.

- ...:

  Further arguments passed to
  [`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html).

## Value

A `ggplot2` facet specification.

## Details

This wraps
[`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)
with fixed scales and left-aligned, unboxed strip labels. `ggplot2`
chooses the layout unless you specify it. Free scales can help with
other questions, but they make comparisons of levels harder, so the
function warns when you request them.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_rangeframe() +
  facet_tufte(~ cyl) +
  theme_tufte()
```
