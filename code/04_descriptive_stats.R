source(here::here("code", "00_setup.R"))

grunfeld_analysis <- readRDS(here::here("data", "processed", "grunfeld_analysis.rds"))
card_krueger_analysis <- readRDS(here::here("data", "processed", "card_krueger_analysis.rds"))

summary_variables <- c(
  investment = "Investment",
  market_value = "Market value",
  capital_stock = "Capital stock",
  log_invest = "Log investment",
  log_value = "Log market value",
  log_capital = "Log capital stock"
)

summary_table <- dplyr::bind_rows(lapply(names(summary_variables), function(column) {
  values <- grunfeld_analysis[[column]]

  data.frame(
    variable = summary_variables[[column]],
    n = sum(!is.na(values)),
    mean = mean(values, na.rm = TRUE),
    sd = stats::sd(values, na.rm = TRUE),
    min = min(values, na.rm = TRUE),
    max = max(values, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}))

sample_counts <- data.frame(
  dataset = c("grunfeld", "card_krueger"),
  rows = c(nrow(grunfeld_analysis), nrow(card_krueger_analysis)),
  stringsAsFactors = FALSE
)

summary_artifacts <- list(
  summary_table = summary_table,
  sample_counts = sample_counts
)

saveRDS(summary_artifacts, here::here("data", "processed", "summary_statistics.rds"))
readr::write_csv(summary_table, here::here("output", "tables", "table_1_summary_statistics.csv"))
readr::write_csv(sample_counts, here::here("output", "logs", "sample_counts.csv"))

log_message("Saved summary statistics.")
