# Tufte's colour palettes

These four palettes are intended for different uses. Choose one for the
comparison you want readers to make, then check the contrast in your
figure.

## Usage

``` r
tufte_pal(palette = c("grey", "accent", "muted", "divergent"))

tufte_colours(palette = c("grey", "accent", "muted", "divergent"))

tufte_colors(palette = c("grey", "accent", "muted", "divergent"))
```

## Arguments

- palette:

  One of `"grey"`, `"accent"`, `"muted"`, `"divergent"`.

## Value

For `tufte_pal()`, a function of `n` returning `n` colours. For
`tufte_colours()`, a character vector of hex colours.

## Details

- `"grey"`:

  A sequence of greys for ordered values.

- `"accent"`:

  Greys with one red accent, assigned to the last level. Put the series
  you want to highlight last in the factor order. This draws on the use
  of value for layering in *Envisioning Information*.

- `"muted"`:

  Desaturated earth tones, drawing on the maps and timetables Tufte
  reproduces. Check that they remain readable at the size you'll use.

- `"divergent"`:

  A muted blue-to-red sequence for signed values, with a neutral
  midpoint.

## Examples

``` r
tufte_pal("muted")(4)
#> [1] "#7c6a55" "#8a9a5b" "#9c6b6b" "#5b7c8a"
tufte_colours("accent")
#> [1] "#8c8c8c" "#b3b3b3" "#d9d9d9" "#595959" "#c8102e"
```
