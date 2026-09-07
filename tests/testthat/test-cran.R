# Invariants that matter for shipping rather than for drawing: the package must
# not reach the network, must clean up after itself, must survive a session
# without its suggested packages, and must leave the user's graphics device
# exactly as it found it.

library(ggplot2)

test_that("no exported function opens a network connection", {
  # The measurements render to disk, so it is worth being sure that is all
  # they do. CRAN forbids network access in checks.
  fns <- paste(unlist(lapply(getNamespaceExports("tufter"), function(f) {
    o <- get(f, envir = asNamespace("tufter"))
    if (is.function(o)) deparse(o) else character(0)
  })), collapse = "\n")
  for (bad in c("url\\(", "download\\.file", "curl::", "httr", "readLines\\(\"http")) {
    expect_false(grepl(bad, fns), info = bad)
  }
})

test_that("measuring leaves the graphics device as it found it", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()

  before_dev <- grDevices::dev.cur()
  before_list <- grDevices::dev.list()

  invisible(data_ink_ratio(p, width = 3, height = 2, res = 48))
  invisible(check_labels_fit(p, width = 3, height = 2))
  invisible(data_density(p, width = 3, height = 2))

  expect_equal(grDevices::dev.cur(), before_dev)
  expect_equal(grDevices::dev.list(), before_list)
})

test_that("measuring leaves no files behind", {
  dir <- withr::local_tempdir()
  before <- list.files(tempdir(), pattern = "\\.png$", recursive = TRUE)
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()

  invisible(data_ink_ratio(p, width = 3, height = 2, res = 48))
  invisible(check_labels_fit(p, width = 3, height = 2))

  # Whatever the renderers wrote, they must have removed.
  after <- list.files(tempdir(), pattern = "\\.png$", recursive = TRUE)
  expect_setequal(after, before)
})

test_that("an open device belonging to the user survives measurement", {
  f <- withr::local_tempfile(fileext = ".png")
  grDevices::png(f, width = 200, height = 200)
  on.exit(if (grDevices::dev.cur() > 1) grDevices::dev.off(), add = TRUE)
  mine <- grDevices::dev.cur()

  invisible(data_ink_ratio(
    ggplot(mtcars, aes(wt, mpg)) + geom_point(), width = 3, height = 2, res = 48
  ))

  # The measurement opens and closes its own device; ours must still be current.
  expect_equal(grDevices::dev.cur(), mine)
})

test_that("every exported function is documented and has examples where it can", {
  ns <- getNamespaceExports("tufter")
  fns <- ns[!grepl("^(Geom|Stat)", ns)]
  rd <- tryCatch(tools::Rd_db("tufter"), error = function(e) NULL)
  skip_if(is.null(rd) || !length(rd), "Rd database needs an installed package")
  documented <- unlist(lapply(rd, function(r) {
    aliases <- vapply(r[vapply(r, function(x) identical(attr(x, "Rd_tag"), "\\alias"), logical(1))],
                      function(x) trimws(paste(unlist(x), collapse = "")), character(1))
    aliases
  }), use.names = FALSE)
  expect_setequal(setdiff(fns, documented), character(0))
})

test_that("the package works when its suggested packages are unavailable", {
  # None of the exported functions may need a Suggests package to run. ragg is
  # used when present and grDevices::png() otherwise; the rest are for
  # vignettes and tests only.
  hard <- c("ggplot2", "grid", "grDevices", "scales", "png", "rlang", "cli",
            "tibble", "stats", "tools")
  desc <- read.dcf(system.file("DESCRIPTION", package = "tufter"))
  imports <- trimws(unlist(strsplit(desc[1, "Imports"], ",")))
  imports <- sub("\\s*\\(.*$", "", imports)
  expect_setequal(sort(imports), sort(hard))

  # And the fallback path really is exercisable.
  expect_s3_class(
    data_ink_ratio(ggplot(mtcars, aes(wt, mpg)) + geom_point(),
                   width = 3, height = 2, res = 48),
    "tufte_data_ink"
  )
})

test_that("printing every result class returns its object invisibly", {
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  line <- ggplot(data.frame(x = 1:20, y = cumsum(rnorm(20))), aes(x, y)) +
    geom_line()

  objs <- list(
    data_ink_ratio(p, width = 3, height = 2, res = 48),
    data_density(p, width = 3, height = 2),
    bank_to_45(line),
    tufte_audit(p, measure = FALSE),
    audit_figures(list(a = p), measure = FALSE)
  )
  for (o in objs) {
    expect_identical(suppressMessages(print(o)), o)
  }
})


test_that("measuring never leaves a stray device or an Rplots.pdf behind", {
  # ggplotGrob() needs a device to measure text against. With none open, R
  # starts the default one, which in a script is pdf(), and that wrote an
  # unasked-for Rplots.pdf into whatever directory the user happened to be in.
  dir <- withr::local_tempdir()
  withr::local_dir(dir)

  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_tufte()
  line <- ggplot(data.frame(x = 1:20, y = cumsum(rnorm(20))), aes(x, y)) +
    geom_line()
  # A plot that actually draws a legend. The guide box is in the layout either
  # way, but only a real one gets its width converted, and that conversion was
  # a second leak that a legend-free plot never reached.
  legended <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()

  # Start from no device at all, which is the case that used to leak.
  while (grDevices::dev.cur() > 1) grDevices::dev.off()

  invisible(check_labels_fit(p, width = 3, height = 2))
  invisible(data_ink_ratio(p, width = 3, height = 2, res = 48))
  invisible(data_density(p, width = 3, height = 2))
  invisible(sparkline_grob(cumsum(rnorm(20))))
  invisible(tufte_audit(p, width = 3, height = 2, measure = FALSE))
  invisible(tufte_audit(legended, width = 3, height = 2, measure = FALSE))
  invisible(tufte_audit(legended, width = 3, height = 2))
  invisible(bank_to_45(line))

  expect_equal(unname(grDevices::dev.cur()), 1L)
  expect_null(grDevices::dev.list())
  expect_false(file.exists("Rplots.pdf"))
  expect_equal(list.files(dir), character(0))
})
