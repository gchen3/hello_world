# Runnable Research Example Repo

This repository is a compact example of a reproducible empirical research workflow in R for Positron. It follows the structure described in [example_workflow.md](example_workflow.md) and builds a working pipeline around the built-in `plm::Grunfeld` panel dataset plus a DID example from `AER::CardKrueger`.

## Project Layout

```text
data/
  raw/
  interim/
  processed/
code/
  00_setup.R
  01_download_data.R
  02_clean_data.R
  03_construct_variables.R
  04_descriptive_stats.R
  05_regressions.R
  06_robustness.R
  07_make_outputs.R
  utils/
docs/
output/
  tables/
  figures/
  logs/
paper/
```

## Required Packages

Install the packages used in the pipeline:

```r
install.packages(c(
  "here",
  "janitor",
  "dplyr",
  "readr",
  "ggplot2",
  "fixest",
  "modelsummary",
  "broom",
  "plm",
  "AER"
))
```

## Run Order

Run the full pipeline from the project root with:

```r
source("run_pipeline.R")
```

You can also run the scripts one at a time:

```r
source(here::here("code", "00_setup.R"))
source(here::here("code", "01_download_data.R"))
source(here::here("code", "02_clean_data.R"))
source(here::here("code", "03_construct_variables.R"))
source(here::here("code", "04_descriptive_stats.R"))
source(here::here("code", "05_regressions.R"))
source(here::here("code", "06_robustness.R"))
source(here::here("code", "07_make_outputs.R"))
```

## Notes

- The pipeline assumes the project files, directories, and packages already exist.
- Paths are built with `here::here()` throughout the project.

test push