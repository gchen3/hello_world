script_source_files <- vapply(
  sys.frames(),
  function(frame) {
    if (is.null(frame$ofile)) {
      return(NA_character_)
    }

    frame$ofile
  },
  character(1)
)
script_source_files <- script_source_files[!is.na(script_source_files)]

script_dir <- if (length(script_source_files) > 0) {
  dirname(normalizePath(tail(script_source_files, 1), winslash = "/", mustWork = FALSE))
} else if (file.exists("00_setup.R")) {
  normalizePath(".", winslash = "/", mustWork = FALSE)
} else {
  normalizePath("code", winslash = "/", mustWork = FALSE)
}

source(file.path(script_dir, "00_setup.R"))

winsorize <- function(x, probs = c(0.01, 0.99)) {
  bounds <- stats::quantile(x, probs = probs, na.rm = TRUE)
  pmin(pmax(x, bounds[[1]]), bounds[[2]])
}

grunfeld_analysis <- readRDS(path_dir("data", "processed", "grunfeld_analysis.rds"))

robustness_data <- grunfeld_analysis |>
  dplyr::mutate(
    log_value_winsor = winsorize(log_value),
    log_capital_winsor = winsorize(log_capital)
  )

robustness_models <- list(
  "Winsorized FE" = fixest::feols(
    log_invest ~ log_value_winsor + log_capital_winsor | firm + year,
    data = robustness_data,
    vcov = ~firm
  ),
  "First differences" = fixest::feols(
    delta_log_invest ~ delta_log_value + delta_log_capital,
    data = robustness_data,
    vcov = ~firm
  )
)

robustness_results <- list(
  models = robustness_models,
  notes = c(
    "Winsorized FE uses 1% and 99% winsorized log covariates.",
    "First differences use year-to-year changes within firms.",
    "Standard errors are clustered by firm."
  )
)

save_rds(robustness_results, path_dir("data", "processed", "robustness_models.rds"))
log_message("Robustness models saved.")
