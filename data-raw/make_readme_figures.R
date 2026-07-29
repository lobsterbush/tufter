# Builds the figures shown in README.md. Run from the package root.
# Uses grid directly for layout so the package picks up no extra dependency.

devtools::load_all(".")
library(ggplot2)
library(grid)
set.seed(1)

lay <- function(file, plots, ncol, width, height, res = 200) {
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

base <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point(size = 1.4) +
  labs(x = "Weight (1000 lbs)", y = "Miles per gallon")

before <- base +
  labs(title = "Default ggplot2",
       subtitle = sprintf("data-ink ratio %.2f",
                          data_ink_ratio(base)$ratio))

after_p <- base + geom_quartileframe() +
  scale_x_continuous(breaks = quartile_breaks(mtcars$wt)) +
  scale_y_continuous(breaks = quartile_breaks(mtcars$mpg)) +
  theme_tufte()
after <- after_p +
  labs(title = "tufter",
       subtitle = sprintf("data-ink ratio %.2f",
                          data_ink_ratio(after_p)$ratio))

lay("man/figures/README-before-after.png", list(before, after),
    ncol = 2, width = 9, height = 3.4)

# --- gallery -----------------------------------------------------------------

boxes <- ggplot(mtcars, aes(factor(cyl), mpg)) +
  geom_tufteboxplot() +
  geom_rangeframe(sides = "l") +
  labs(x = "Cylinders", y = "MPG", title = "geom_tufteboxplot()") +
  theme_tufte()

crops <- data.frame(
  crop = c("Wheat", "Maize", "Rice", "Barley", "Oats"),
  yield = c(3.5, 5.8, 4.6, 3.1, 2.5)
)
bars <- ggplot(crops, aes(crop, yield)) +
  geom_col_tufte(fill = "grey72") +
  labs(x = NULL, y = "t/ha", title = "geom_col_tufte()") +
  theme_tufte()

spend <- data.frame(
  country = rep(c("Sweden", "Japan", "Chile", "Canada", "Greece"), each = 2),
  year = rep(c("1970", "2020"), 5),
  value = c(30.1, 41.2, 20.7, 32.9, 22.5, 21.0, 31.0, 38.4, 25.2, 29.7)
)
slopes <- slopegraph(spend, year, value, country, label_size = 2.4) +
  labs(title = "slopegraph()")

series <- data.frame(
  month = rep(1:60, 3),
  value = c(cumsum(rnorm(60)), cumsum(rnorm(60)), cumsum(rnorm(60))),
  series = rep(c("Wheat", "Maize", "Rice"), each = 60)
)
sparks <- sparklines(series, month, value, series) +
  labs(title = "sparklines()") +
  theme(plot.title = element_text(size = 11, hjust = 0))

lay("man/figures/README-gallery.png", list(boxes, bars, slopes, sparks),
    ncol = 2, width = 9, height = 6)
