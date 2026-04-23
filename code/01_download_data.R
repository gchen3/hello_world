source(here::here("code", "00_setup.R"))

grunfeld_env <- new.env(parent = emptyenv())
card_krueger_env <- new.env(parent = emptyenv())

utils::data("Grunfeld", package = "plm", envir = grunfeld_env)
utils::data("CardKrueger", package = "AER", envir = card_krueger_env)

grunfeld_raw <- as.data.frame(grunfeld_env$Grunfeld)
card_krueger_raw <- as.data.frame(card_krueger_env$CardKrueger)

readr::write_csv(grunfeld_raw, here::here("data", "raw", "grunfeld_raw.csv"))
readr::write_csv(card_krueger_raw, here::here("data", "raw", "card_krueger_raw.csv"))

writeLines(
  c(
    "# Data sources",
    "",
    sprintf(
      "- `plm::Grunfeld`: built-in panel dataset saved to `%s` on %s.",
      here::here("data", "raw", "grunfeld_raw.csv"),
      Sys.Date()
    ),
    sprintf(
      "- `AER::CardKrueger`: built-in DID example saved to `%s` on %s.",
      here::here("data", "raw", "card_krueger_raw.csv"),
      Sys.Date()
    )
  ),
  con = here::here("docs", "data_sources.md"),
  useBytes = TRUE
)

log_message("Saved raw datasets and updated data source notes.")
