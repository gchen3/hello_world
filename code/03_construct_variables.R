source(here::here("code", "00_setup.R"))

grunfeld_clean <- readRDS(here::here("data", "interim", "grunfeld_clean.rds"))
card_krueger_clean <- readRDS(here::here("data", "interim", "card_krueger_clean.rds"))

grunfeld_analysis <- grunfeld_clean |>
  dplyr::arrange(firm, year) |>
  dplyr::group_by(firm) |>
  dplyr::mutate(
    investment = inv,
    market_value = value,
    capital_stock = capital,
    log_invest = log(investment),
    log_value = log(market_value),
    log_capital = log(capital_stock),
    lag_log_invest = dplyr::lag(log_invest),
    lag_log_value = dplyr::lag(log_value),
    lag_log_capital = dplyr::lag(log_capital),
    delta_log_invest = log_invest - lag_log_invest,
    delta_log_value = log_value - lag_log_value,
    delta_log_capital = log_capital - lag_log_capital
  ) |>
  dplyr::ungroup()

unit_id <- if ("store" %in% names(card_krueger_clean)) {
  as.character(card_krueger_clean$store)
} else {
  sprintf("unit_%03d", seq_len(nrow(card_krueger_clean)))
}

card_krueger_analysis <- dplyr::bind_rows(
  card_krueger_clean |>
    dplyr::mutate(
      unit = unit_id,
      period = 0L,
      post = 0L,
      employment = as.numeric(emptot)
    ),
  card_krueger_clean |>
    dplyr::mutate(
      unit = unit_id,
      period = 1L,
      post = 1L,
      employment = as.numeric(emptot2)
    )
) |>
  dplyr::mutate(
    state = as.character(state),
    treated = as.integer(tolower(state) %in% c("nj", "new jersey")),
    treated_post = treated * post
  ) |>
  dplyr::filter(!is.na(employment))

saveRDS(grunfeld_analysis, here::here("data", "processed", "grunfeld_analysis.rds"))
saveRDS(card_krueger_analysis, here::here("data", "processed", "card_krueger_analysis.rds"))

log_message("Saved analysis datasets.")
