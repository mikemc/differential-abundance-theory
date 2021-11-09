set.seed(42)

knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  cache = FALSE,
  echo = FALSE,
  # out.width = "70%",
  # fig.align = 'center',
  # fig.width = 6,
  # fig.asp = 0.618,
  fig.show = "hold"
)

options(dplyr.print_min = 6, dplyr.print_max = 6)
options(crayon.enabled = FALSE)

library(tidyverse)
library(here)
library(cowplot)
library(patchwork)
theme_set(theme_cowplot(12))

close_elts <- function(x) x / sum(x)

# Create a pdf from an svg with inkscape
# svg_path should be relative to project root
svg_to_pdf <- function(svg_path) {
  fig_path <- fs::path(
    'figures', 'export-pdf', 
    fs::path_ext_set(svg_path, 'pdf')
  )
  args <- c(
    "--export-area-page", 
    "--export-type=pdf", 
    str_c("--export-filename=", fig_path),
    svg_path
  )
  system2("inkscape", args = args)
  fig_path
}
