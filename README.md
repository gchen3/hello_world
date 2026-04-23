# Runnable Research Example Repo

This repository is a compact example of a reproducible empirical research workflow in R for Positron. It follows the structure described in [example_workflow.md](example_workflow.md) and builds a working pipeline around the built-in `plm::Grunfeld` panel dataset.

The main path always runs on `Grunfeld`. A simple DID example based on `AER::CardKrueger` is included when the `AER` package is available; otherwise the DID steps are skipped without breaking the rest of the project.

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

Install the core packages before running the pipeline:

```r
install.packages(c(
  "here",
  "fs",
  "janitor",
  "dplyr",
  "readr",
  "ggplot2",
  "fixest",
  "modelsummary",
  "broom",
  "plm"
))
```

Optional DID support:

```r
install.packages("AER")
```

## Run Order

Run the full pipeline from the project root with:

```r
source("run_pipeline.R")
```

You can also run the scripts one at a time in this order:

```r
source("code/00_setup.R")
source("code/01_download_data.R")
source("code/02_clean_data.R")
source("code/03_construct_variables.R")
source("code/04_descriptive_stats.R")
source("code/05_regressions.R")
source("code/06_robustness.R")
source("code/07_make_outputs.R")
```

The scripts resolve project paths from their own file locations, so they are safe to source from the project root or from inside the `code/` directory.

## Expected Outputs

After a successful run, the repo will contain starter research artifacts such as:

- `data/raw/grunfeld_raw.csv`
- `data/interim/grunfeld_clean.rds`
- `data/processed/grunfeld_analysis.rds`
- `output/tables/table_1_summary_statistics.csv`
- `output/tables/table_1_summary_statistics.html`
- `output/tables/table_0_correlation_matrix.html`
- `output/tables/table_2_main_results.html`
- `output/tables/table_2_main_results_journal.html`
- `output/tables/table_4_model_diagnostics.html`
- `output/tables/table_a1_robustness.html`
- `output/figures/figure_1_distribution.png`
- `output/figures/figure_2_main_relationship.png`
- `docs/data_sources.md`
- `output/logs/pipeline.log`
- `paper/results_memo.html`

If `AER` is installed and `CardKrueger` is available, the pipeline will also create optional DID artifacts.

## Notes

- The scripts are idempotent: rerunning them should refresh generated artifacts without manual cleanup.
- Raw files are treated as protected inputs. The download script refuses to overwrite an existing raw file if its contents do not match the bundled example data.
- The current shell environment used to scaffold this repo does not have `Rscript` on `PATH`, so runtime verification should be done in Positron or another R-enabled environment.
