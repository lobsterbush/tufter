# Builds the figures shown in README.md. Run from the package root.
# Uses grid directly for layout so the package picks up no extra dependency.

devtools::load_all(here::here())
library(ggplot2)
library(grid)
library(palmerpenguins)
library(gapminder)
set.seed(1)

peng <- as.data.frame(penguins[complete.cases(penguins), ])
gap <- as.data.frame(gapminder)

lay <- function(file, plots, ncol, width, height, res = 300) {
  png(file, width = width, height = height, units = "in", res = res,
      bg = "white", type = if (capabilities("cairo")) "cairo" else NULL)
  grid.newpage()
  nrow <- ceiling(length(plots) / ncol)
  pushViewport(viewport(layout = grid.layout(nrow, ncol)))
  for (i in seq_along(plots)) {
    r <- ceiling(i / ncol); cc <- i - (r - 1) * ncol
    pushViewport(viewport(layout.pos.row = r, layout.pos.col = cc))
    print(plots[[i]], vp = viewport())
    popViewport()
  }
  dev.off()
  message("wrote ", file)
}

# --- before and after --------------------------------------------------------

base <- ggplot(peng, aes(flipper_length_mm, body_mass_g)) +
  geom_point(size = 1.2, alpha = 0.65) +
  labs(x = "Flipper length (mm)", y = "Body mass (g)")

before <- base +
  labs(title = "Default ggplot2",
       subtitle = sprintf("data-ink ratio %.2f",
                          data_ink_ratio(base)$ratio))

after_p <- base + geom_quartileframe() +
  scale_x_continuous(breaks = quartile_breaks(peng$flipper_length_mm)) +
  scale_y_continuous(breaks = quartile_breaks(peng$body_mass_g)) +
  theme_tufte()
after <- after_p +
  labs(title = "tufter",
       subtitle = sprintf("data-ink ratio %.2f",
                          data_ink_ratio(after_p)$ratio))

lay(here::here("man/figures/README-before-after.png"), list(before, after),
    ncol = 2, width = 9, height = 3.4)

# The two ratios are printed inside the figure, so the alt text has to quote
# them or a screen reader gets less than a sighted reader. Quoting them by hand
# meant they went stale the moment the measurement changed, so write the image
# line from the same numbers the subtitles use.
# pkgdown renders the alt text as a visible caption, so it has to work as
# both: what a reader takes from the figure, and what a screen reader is told.
alt <- sprintf(
  paste0("![The same penguins, drawn twice. Erasing the panel, the grid and ",
         "the border, then putting a quartile frame where the border was, ",
         "moves the data-ink ratio from %.2f to %.2f.]",
         "(man/figures/README-before-after.png)"),
  data_ink_ratio(base)$ratio, data_ink_ratio(after_p)$ratio
)
readme <- readLines(here::here("README.md"))
i <- grep("(man/figures/README-before-after.png)", readme, fixed = TRUE)
if (length(i) != 1) {
  stop("expected exactly one before-after image line in README.md", call. = FALSE)
}
readme[i] <- alt
writeLines(readme, here::here("README.md"))
message("rewrote the before-and-after alt text")

# --- gallery -----------------------------------------------------------------

boxes <- ggplot(peng, aes(species, body_mass_g)) +
  geom_tufteboxplot() +
  geom_rangeframe(sides = "l") +
  labs(x = NULL, y = "Body mass (g)", title = "geom_tufteboxplot()") +
  theme_tufte()

# Bars need a quantity that actually varies, or the erased gridlines have
# nothing to measure against and the form is the wrong choice anyway.
gdp <- subset(gap, year == 2007 & country %in%
                c("Japan", "Korea, Rep.", "Malaysia", "China", "Indonesia",
                  "India"))
bars <- ggplot(gdp, aes(stats::reorder(country, -gdpPercap), gdpPercap)) +
  geom_col_tufte(fill = "grey72") +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(x = NULL, y = "GDP per capita, 2007", title = "geom_col_tufte()") +
  theme_tufte() +
  theme(axis.text.x = element_text(size = rel(0.72)))

sea <- subset(gap, country %in% c("Cambodia", "Indonesia", "Malaysia",
                                  "Thailand", "Vietnam") &
                year %in% c(1952, 2007))
sea$year <- factor(sea$year)
slopes <- slopegraph(sea, year, lifeExp, country, label_size = 2.4,
                     min_gap = 0.05) +
  labs(title = "slopegraph()")

four <- subset(gap, country %in% c("China", "India", "Japan"))
sparks <- sparklines(four, year, gdpPercap, country, accuracy = 1) +
  labs(title = "sparklines()") +
  theme(plot.title = element_text(size = 11, hjust = 0))

lay(here::here("man/figures/README-gallery.png"), list(boxes, bars, slopes, sparks),
    ncol = 2, width = 9, height = 6)
