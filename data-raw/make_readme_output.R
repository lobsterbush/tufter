# Rewrites the example output blocks in README.md from what the package
# actually prints.
#
# Those blocks were hand-transcribed and drifted twice: once when the
# range-frame fix changed the data-ink ratio, and once when the audit messages
# were rewritten. Generating them removes the whole class of problem.
#
#   Rscript data-raw/make_readme_output.R
#
# Each block sits between a pair of HTML comment markers in README.md.

devtools::load_all(here::here(), quiet = TRUE)
library(ggplot2)

# Capture what cli prints, which it signals as conditions rather than writing
# to stdout, and prefix each line the way an R console transcript would.
transcript <- function(expr) {
  out <- character(0)
  withCallingHandlers(
    force(expr),
    message = function(m) {
      out <<- c(out, sub("\n$", "", conditionMessage(m)))
      invokeRestart("muffleMessage")
    }
  )
  out <- unlist(strsplit(out, "\n", fixed = TRUE))
  out <- sub("\\s+$", "", out)
  paste0("#> ", out)
}

replace_block <- function(text, marker, lines) {
  open <- sprintf("<!-- %s:start -->", marker)
  close <- sprintf("<!-- %s:end -->", marker)
  i <- grep(open, text, fixed = TRUE)
  j <- grep(close, text, fixed = TRUE)
  if (length(i) != 1 || length(j) != 1 || j <= i) {
    stop("markers for '", marker, "' not found in README.md", call. = FALSE)
  }
  c(text[seq_len(i)], lines, text[j:length(text)])
}

library(palmerpenguins)
peng <- as.data.frame(penguins[complete.cases(penguins), ])

base <- ggplot(peng, aes(flipper_length_mm, body_mass_g)) + geom_point()
lean <- base + geom_rangeframe() + theme_tufte()

short <- c(
  "```r",
  "library(ggplot2)",
  "library(tufter)",
  "library(palmerpenguins)",
  "",
  "peng <- penguins[complete.cases(penguins), ]",
  "base <- ggplot(peng, aes(flipper_length_mm, body_mass_g)) + geom_point()",
  "",
  "data_ink_ratio(base)",
  transcript(print(data_ink_ratio(base))),
  "",
  "lean <- base + geom_rangeframe() + theme_tufte()",
  "",
  "data_ink_ratio(lean)",
  transcript(print(data_ink_ratio(lean))),
  "```"
)

# Verbatim, with nothing cut. An earlier version trimmed the explanation off
# each measured bullet with a regex, but cli decides where to wrap, so the
# pattern matched the first line of a bullet and left its continuation lines
# stranded in the README. A transcript that doesn't match the console is worse
# than a long one.
audit <- c("```r", "tufte_audit(base)",
           transcript(print(tufte_audit(base))), "```")

readme <- readLines(here::here("README.md"))
readme <- replace_block(readme, "readme-short", short)
readme <- replace_block(readme, "readme-audit", audit)
writeLines(readme, "README.md")

message("rewrote the README output blocks")
