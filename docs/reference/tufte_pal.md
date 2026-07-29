# Tufte's colour palettes

Four palettes, each answering a different question about colour.

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

  Tufte's default. Grey encodes an ordered variable without introducing
  a second, unwanted, categorical signal.

- `"accent"`:

  Greys plus one signal red. Use when exactly one series matters and the
  rest are context. This is the palette that does the most work in
  *Envisioning Information*: layering by value, not by hue.

- `"muted"`:

  Desaturated earth tones, after the maps and timetables Tufte
  reproduces. Colours this weak sit behind text and annotation without
  fighting them.

- `"divergent"`:

  A muted blue-to-red ramp for signed quantities, with a neutral rather
  than a white midpoint.

## Examples

``` r
tufte_pal("muted")(4)
#> [1] "#7c6a55" "#8a9a5b" "#9c6b6b" "#5b7c8a"
tufte_colours("accent")
#> [1] "#8c8c8c" "#b3b3b3" "#c8102e" "#d9d9d9" "#595959"
```
