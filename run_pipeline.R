pipeline_scripts <- file.path(
  here::here("code"),
  c(
    "00_setup.R",
    "01_download_data.R",
    "02_clean_data.R",
    "03_construct_variables.R",
    "04_descriptive_stats.R",
    "05_regressions.R",
    "06_robustness.R",
    "07_make_outputs.R"
  )
)

for (script in pipeline_scripts) {
  message(sprintf("Running %s", script))
  source(script, chdir = FALSE)
}

message("Pipeline complete.")
