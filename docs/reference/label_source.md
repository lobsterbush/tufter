# Add a source note to a figure

Tufte's documentation principle: a graphic should say where its numbers
came from, on the graphic, so that the claim can be checked without
hunting for the surrounding text. This is a thin wrapper on
`labs(caption = ...)` that formats the note consistently.

## Usage

``` r
label_source(source, note = NULL, prefix = "Source:")
```

## Arguments

- source:

  Where the data came from.

- note:

  Optional extra note, appended after the source.

- prefix:

  Label placed before the source. Defaults to `"Source:"`.

## Value

A `ggplot2` labs object, to be added to a plot.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  theme_tufte() +
  label_source("Motor Trend, 1974", note = "n = 32 cars.")
```
