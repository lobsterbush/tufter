# Small multiples

Tufte's answer to multivariate data is repetition rather than
complication: the same graphic, at the same scale, once per condition,
so that comparison is a matter of looking rather than of decoding. Once
the reader has learned to read one panel, they have learned to read all
of them.

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

This is
[`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)
with the defaults changed to match that argument. Scales are fixed,
because free scales destroy the comparison the design exists to make.
Strips are left-aligned and unboxed. The panel count is left to
`ggplot2` unless you set `ncol`.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  geom_rangeframe() +
  facet_tufte(~ cyl) +
  theme_tufte()
```
