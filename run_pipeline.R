pipeline_source_files <- vapply(
  sys.frames(),
  function(frame) {
    if (is.null(frame$ofile)) {
      return(NA_character_)
    }

    frame$ofile
  },
  character(1)
)
pipeline_source_files <- pipeline_source_files[!is.na(pipeline_source_files)]

pipeline_root <- if (length(pipeline_source_files) > 0) {
  dirname(normalizePath(tail(pipeline_source_files, 1), winslash = "/", mustWork = FALSE))
} else {
  normalizePath(".", winslash = "/", mustWork = FALSE)
}

pipeline_scripts <- file.path(
  pipeline_root,
  "code",
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
  message(sprintf("Running %s", normalizePath(script, winslash = "/", mustWork = FALSE)))
  source(script, chdir = FALSE)
}

message("Pipeline complete.")
