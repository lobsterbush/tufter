# Add a source note to a figure

Name the data source on the figure so readers can check where the
numbers came from. This follows Tufte's documentation principle and
wraps `labs(caption = ...)` with consistent formatting.

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
