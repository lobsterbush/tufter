# Fetches the data behind vignettes/articles/live-data.Rmd from four public
# APIs, none of which need a key, and caches the result inside the package.
#
# The article reads that cache. Hitting four APIs on every documentation build
# would be slow, impolite to whoever runs them, and would break the build on the
# day one of them is down. Caching keeps the published page reproducible and
# still lets anyone re-run the same calls.
#
#   Rscript data-raw/fetch_live_examples.R
#
# Writes inst/extdata/live-examples.rds, a list with a `fetched_at` stamp and
# one data frame per source.

library(jsonlite)

TIMEOUT <- 60
get_json <- function(url) {
  jsonlite::fromJSON(url)
}

# ---- 1. CRAN daily downloads, from cranlogs -------------------------------
# https://cranlogs.r-pkg.org/  (RStudio mirror logs, no key)

fetch_cran <- function(packages, days = 180) {
  to <- Sys.Date() - 2
  from <- to - days
  out <- lapply(packages, function(pkg) {
    url <- sprintf("https://cranlogs.r-pkg.org/downloads/daily/%s:%s/%s",
                   from, to, pkg)
    d <- get_json(url)$downloads[[1]]
    if (is.null(d) || !nrow(d)) return(NULL)
    data.frame(package = pkg, day = as.Date(d$day),
               downloads = as.numeric(d$downloads))
  })
  do.call(rbind, out)
}

# ---- 2. Earthquakes, from the USGS FDSN event service ----------------------
# https://earthquake.usgs.gov/fdsnws/event/1/  (no key)

fetch_quakes <- function(days = 365, min_magnitude = 4.5) {
  to <- Sys.Date()
  from <- to - days
  url <- sprintf(paste0("https://earthquake.usgs.gov/fdsnws/event/1/query",
                        "?format=geojson&starttime=%s&endtime=%s",
                        "&minmagnitude=%s&orderby=time"),
                 from, to, min_magnitude)
  g <- get_json(url)
  p <- g$features$properties
  coords <- do.call(rbind, g$features$geometry$coordinates)
  data.frame(
    time = as.POSIXct(p$time / 1000, origin = "1970-01-01", tz = "UTC"),
    magnitude = as.numeric(p$mag),
    depth_km = as.numeric(coords[, 3]),
    place = as.character(p$place)
  )
}

# ---- 3. Daily temperature, from the Open-Meteo ERA5 archive ----------------
# https://open-meteo.com/en/docs/historical-weather-api  (no key)
#
# Two ten-year windows per city, so the comparison is a decadal mean rather
# than one year against another, which would be weather.

CITIES <- data.frame(
  city = c("Tokyo", "Seoul", "Taipei", "Singapore", "Melbourne", "Auckland"),
  lat  = c(35.68, 37.57, 25.03, 1.35, -37.81, -36.85),
  lon  = c(139.69, 126.98, 121.57, 103.82, 144.96, 174.76)
)

fetch_climate <- function(cities = CITIES,
                          early = c("1975-01-01", "1984-12-31"),
                          late  = c("2015-01-01", "2024-12-31")) {
  one <- function(lat, lon, from, to) {
    url <- sprintf(paste0("https://archive-api.open-meteo.com/v1/archive",
                          "?latitude=%s&longitude=%s&start_date=%s&end_date=%s",
                          "&daily=temperature_2m_mean&timezone=UTC"),
                   lat, lon, from, to)
    d <- get_json(url)
    mean(as.numeric(d$daily$temperature_2m_mean), na.rm = TRUE)
  }
  out <- lapply(seq_len(nrow(cities)), function(i) {
    row <- cities[i, ]
    message("  ", row$city)
    e <- one(row$lat, row$lon, early[1], early[2])
    Sys.sleep(1)
    l <- one(row$lat, row$lon, late[1], late[2])
    Sys.sleep(1)
    data.frame(
      city = rep(row$city, 2),
      period = c(paste0(substr(early[1], 1, 4), "-", substr(early[2], 1, 4)),
                 paste0(substr(late[1], 1, 4), "-", substr(late[2], 1, 4))),
      mean_temp = c(e, l)
    )
  })
  do.call(rbind, out)
}

# ---- 4. Wikipedia pageviews, from the Wikimedia REST API -------------------
# https://wikimedia.org/api/rest_v1/  (no key)

fetch_pageviews <- function(articles, days = 120) {
  to <- Sys.Date() - 2
  from <- to - days
  fmt <- function(d) format(d, "%Y%m%d")
  out <- lapply(articles, function(a) {
    url <- sprintf(paste0("https://wikimedia.org/api/rest_v1/metrics/pageviews",
                          "/per-article/en.wikipedia/all-access/all-agents",
                          "/%s/daily/%s/%s"),
                   utils::URLencode(a, reserved = TRUE), fmt(from), fmt(to))
    d <- tryCatch(get_json(url), error = function(e) NULL)
    if (is.null(d$items)) return(NULL)
    data.frame(
      article = gsub("_", " ", a),
      date = as.Date(substr(d$items$timestamp, 1, 8), "%Y%m%d"),
      views = as.numeric(d$items$views)
    )
  })
  do.call(rbind, out)
}

# ---- run -------------------------------------------------------------------

message("CRAN downloads")
cran <- fetch_cran(c("ggplot2", "dplyr", "data.table", "sf", "targets"))

message("USGS earthquakes")
quakes <- fetch_quakes()

message("Open-Meteo temperatures")
climate <- fetch_climate()

message("Wikipedia pageviews")
pageviews <- fetch_pageviews(c(
  "Edward_Tufte", "Data_visualization", "Statistical_graphics",
  "Histogram", "Scatter_plot"
))

live <- list(
  fetched_at = Sys.time(),
  cran = cran,
  quakes = quakes,
  climate = climate,
  pageviews = pageviews,
  sources = c(
    cran = "cranlogs.r-pkg.org (RStudio CRAN mirror logs)",
    quakes = "earthquake.usgs.gov FDSN event service",
    climate = "open-meteo.com ERA5 historical archive",
    pageviews = "wikimedia.org REST pageviews API"
  )
)

dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
saveRDS(live, "inst/extdata/live-examples.rds", compress = "xz")

message("\nwrote inst/extdata/live-examples.rds")
for (nm in c("cran", "quakes", "climate", "pageviews")) {
  message(sprintf("  %-10s %5d rows", nm, nrow(live[[nm]])))
}
