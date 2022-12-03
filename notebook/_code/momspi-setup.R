
# Setup

## R setup

# ```{r libraries}
# Tools for microbiome data
library(speedyseq)
# Tools for general purpose data manipulation and plotting
library(tidyverse)
library(fs)

# library(metacal); packageVersion("metacal")

colors_brooks <- c(
  "Atopobium_vaginae" = "#009E73",
  "Gardnerella_vaginalis" = "#56B4E9",
  "Lactobacillus_crispatus" = "#D55E00",
  "Lactobacillus_iners" = "#505050",
  "Prevotella_bivia" = "#0072B2",
  "Sneathia_amnii" = "#CC79A7",
  "Streptococcus_agalactiae" = "#E69F00"
)

## Estimate bias from @brooks2015thet

# We can estimate the efficiencies for the control species used in the cellular mocks of @brooks2015thet by running the example code in the docs for `metacal::estimate_bias()`. 
# This code uses the observed and actual species-level abundance tables which were produced by @mclaren2019cons from the SI files of @brooks2015thet and are included in the metacal package.

dr <- system.file("extdata", package = "metacal")
list.files(dr)
actual <- file.path(dr, "brooks2015-actual.csv") |>
  read.csv(row.names = "Sample") |>
  as("matrix")
observed <- file.path(dr, "brooks2015-observed.csv") |>
  read.csv(row.names = "Sample") |>
  subset(select = - Other) |>
  as("matrix")

# Estimate bias with bootstrapping for error estimation
mc_fit <- metacal::estimate_bias(observed, actual, margin = 1, boot = TRUE)
summary(mc_fit)

rm(actual, observed, dr)

control_species <- mc_fit %>% coef %>% names
control_genera <- control_species %>% str_extract('^[^_]+')

## Load the MOMSPI data

# TODO: replace this code chunk with one that pulls data from the github repo into `_data/`

# Load the MOMSPI Stirrups profiles into phyloseq

# path_momspi <- '~/research/momspi'
path_momspi <- here::here('notebook/_data/momspi')

otu <- path(path_momspi, "stirrups-profiles", "abundance-matrix.csv.bz2") %>%
  read_csv(
    col_types = cols(.default = col_double(), sample_name = col_character())
  ) %>%
  otu_table(taxa_are_rows = FALSE)
sam <- path(path_momspi, "stirrups-profiles", "sample-data.csv.bz2") %>%
  read_csv(col_types = "ccccccic") %>%
  mutate(across(host_visit_number, factor, ordered = TRUE)) %>%
  sample_data
tax <- path(path_momspi, "stirrups-profiles", "taxonomy.csv.bz2") %>%
  read_csv(col_types = cols(.default = col_character())) %>%
  tax_table %>%
  mutate_tax_table(
    species = case_when(!is.na(genus) ~ .otu)
  )
momspi_raw <- phyloseq(otu, sam, tax) %>%
  mutate_tax_table(across(.otu, str_replace, 
      "(?<=Lactobacillus_crispatus)_cluster", "")) %>%
  mutate_sample_data(., sample_sum = sample_sums(.))
taxa_names(momspi_raw) %>% str_subset("crispatus")
stopifnot(all(control_species %in% taxa_names(momspi_raw)))

# Filter low-read samples and OTUs
momspi <- momspi_raw %>% 
  filter_sample_data(sample_sum >= 1e3) %>% 
  filter_taxa2(~sum(.) >= 2e2)

## Impute efficiencies

bias_species <- coef(mc_fit) %>% 
  enframe("species", "efficiency")
bias_genus <- bias_species %>%
  mutate(genus = str_extract(species, "^[^_]+"), .before = 1) %>%
  with_groups(genus, summarize, across(efficiency, metacal::gm_mean))
# Match on genus or species, depending on which is available; then set others
# to average genus efficiency
bias_all <- tax_table(momspi) %>% as_tibble %>%
  left_join(bias_species, by = "species") %>%
  left_join(bias_genus, by = "genus") %>%
  mutate(
    efficiency = case_when(
      !is.na(efficiency.x) ~ efficiency.x,
      !is.na(efficiency.y) ~ efficiency.y,
      TRUE ~ metacal::gm_mean(bias_genus$efficiency)
    )
  ) %>%
  select(-efficiency.x, -efficiency.y) %>%
  # standardize to L. iners, the most efficiently measured
  mutate(
    across(efficiency, ~ . / max(.))
  )
bias_all_vec <- bias_all %>% select(.otu, efficiency) %>% deframe 


## Function for replacing zeros
adjust_dirchlet <- function(ps) {
  taxa_mean_prop <- ps %>%
    otu_table %>%
    transform_sample_counts(close_elts) %>%
    orient_taxa(as = 'cols') %>%
    as('matrix') %>%
    colMeans
  stopifnot(sum(taxa_mean_prop) == 1)
  prior_vec <- taxa_mean_prop * ntaxa(ps)
  stopifnot(identical(length(prior_vec), ntaxa(ps)))
  # Note the need for the seq_along trick to get phyloseq to allow this
  # adjustment
  ps %>% 
    transform_sample_counts(~ prior_vec[seq_along(.x)] + .x)
}
