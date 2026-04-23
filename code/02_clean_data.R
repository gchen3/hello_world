source(here::here("code", "00_setup.R"))

grunfeld_raw <- readr::read_csv(here::here("data", "raw", "grunfeld_raw.csv"), show_col_types = FALSE)
card_krueger_raw <- readr::read_csv(here::here("data", "raw", "card_krueger_raw.csv"), show_col_types = FALSE)

grunfeld_clean <- grunfeld_raw |>
  janitor::clean_names() |>
  dplyr::mutate(
    firm = as.factor(firm),
    year = as.integer(year),
    inv = as.numeric(inv),
    value = as.numeric(value),
    capital = as.numeric(capital)
  ) |>
  dplyr::distinct()

card_krueger_clean <- card_krueger_raw |>
  janitor::clean_names() |>
  dplyr::distinct()

saveRDS(grunfeld_clean, here::here("data", "interim", "grunfeld_clean.rds"))
saveRDS(card_krueger_clean, here::here("data", "interim", "card_krueger_clean.rds"))

cleaning_report <- dplyr::bind_rows(
  data.frame(
    dataset = "grunfeld",
    rows = nrow(grunfeld_clean),
    columns = ncol(grunfeld_clean),
    duplicates_removed = nrow(grunfeld_raw) - nrow(grunfeld_clean),
    missing_values = sum(is.na(grunfeld_clean)),
    stringsAsFactors = FALSE
  ),
  data.frame(
    dataset = "card_krueger",
    rows = nrow(card_krueger_clean),
    columns = ncol(card_krueger_clean),
    duplicates_removed = nrow(card_krueger_raw) - nrow(card_krueger_clean),
    missing_values = sum(is.na(card_krueger_clean)),
    stringsAsFactors = FALSE
  )
)

readr::write_csv(cleaning_report, here::here("output", "logs", "cleaning_report.csv"))
log_message("Saved cleaned datasets and cleaning report.")
