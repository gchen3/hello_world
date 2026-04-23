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

summarise_variable <- function(data, column, label) {
  values <- data[[column]]

  data.frame(
    variable = label,
    n = sum(!is.na(values)),
    mean = mean(values, na.rm = TRUE),
    sd = stats::sd(values, na.rm = TRUE),
    min = min(values, na.rm = TRUE),
    max = max(values, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

grunfeld_analysis <- readRDS(path_dir("data", "processed", "grunfeld_analysis.rds"))
did_analysis_path <- path_dir("data", "processed", "card_krueger_analysis.rds")
did_is_available <- file.exists(did_analysis_path)

summary_table <- dplyr::bind_rows(
  summarise_variable(grunfeld_analysis, "investment", "Investment"),
  summarise_variable(grunfeld_analysis, "market_value", "Market value"),
  summarise_variable(grunfeld_analysis, "capital_stock", "Capital stock"),
  summarise_variable(grunfeld_analysis, "log_invest", "Log investment"),
  summarise_variable(grunfeld_analysis, "log_value", "Log market value"),
  summarise_variable(grunfeld_analysis, "log_capital", "Log capital stock")
)

sample_counts <- data.frame(
  dataset = c("grunfeld", if (did_is_available) "card_krueger"),
  rows = c(
    nrow(grunfeld_analysis),
    if (did_is_available) {
      nrow(readRDS(did_analysis_path))
    }
  ),
  stringsAsFactors = FALSE
)

summary_artifacts <- list(
  summary_table = summary_table,
  sample_counts = sample_counts
)

save_rds(summary_artifacts, path_dir("data", "processed", "summary_statistics.rds"))

readr::write_csv(summary_table, path_dir("output", "tables", "table_1_summary_statistics.csv"))
readr::write_csv(sample_counts, path_dir("output", "logs", "sample_counts.csv"))

log_message("Summary statistics saved.")
