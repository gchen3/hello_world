source(here::here("code", "00_setup.R"))

grunfeld_analysis <- readRDS(here::here("data", "processed", "grunfeld_analysis.rds"))

log_value_bounds <- stats::quantile(grunfeld_analysis$log_value, probs = c(0.01, 0.99), na.rm = TRUE)
log_capital_bounds <- stats::quantile(grunfeld_analysis$log_capital, probs = c(0.01, 0.99), na.rm = TRUE)

robustness_data <- grunfeld_analysis |>
  dplyr::mutate(
    log_value_winsor = pmin(pmax(log_value, log_value_bounds[[1]]), log_value_bounds[[2]]),
    log_capital_winsor = pmin(pmax(log_capital, log_capital_bounds[[1]]), log_capital_bounds[[2]])
  )

robustness_results <- list(
  models = list(
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
  ),
  notes = c(
    "Winsorized FE uses 1% and 99% winsorized log covariates.",
    "First differences use year-to-year changes within firms.",
    "Standard errors are clustered by firm."
  )
)

saveRDS(robustness_results, here::here("data", "processed", "robustness_models.rds"))
log_message("Saved robustness models.")
