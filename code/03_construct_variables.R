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

grunfeld_clean <- readRDS(path_dir("data", "interim", "grunfeld_clean.rds"))

grunfeld_analysis <- grunfeld_clean |>
  dplyr::arrange(firm, year) |>
  dplyr::group_by(firm) |>
  dplyr::mutate(
    investment = inv,
    market_value = value,
    capital_stock = capital,
    log_invest = log(pmax(investment, 1e-6)),
    log_value = log(pmax(market_value, 1e-6)),
    log_capital = log(pmax(capital_stock, 1e-6)),
    lag_log_invest = dplyr::lag(log_invest),
    lag_log_value = dplyr::lag(log_value),
    lag_log_capital = dplyr::lag(log_capital),
    delta_log_invest = log_invest - lag_log_invest,
    delta_log_value = log_value - lag_log_value,
    delta_log_capital = log_capital - lag_log_capital,
    panel_id = as.integer(firm)
  ) |>
  dplyr::ungroup()

save_rds(grunfeld_analysis, path_dir("data", "processed", "grunfeld_analysis.rds"))
log_message("Saved Grunfeld analysis dataset.")

build_card_krueger_panel <- function(card_data) {
  required_columns <- c("state", "emptot", "emptot2")

  if (!all(required_columns %in% names(card_data))) {
    return(NULL)
  }

  unit_id <- if ("store" %in% names(card_data)) {
    as.character(card_data$store)
  } else {
    sprintf("unit_%03d", seq_len(nrow(card_data)))
  }

  before_period <- card_data |>
    dplyr::mutate(
      unit = unit_id,
      period = 0L,
      post = 0L,
      employment = as.numeric(emptot)
    )

  after_period <- card_data |>
    dplyr::mutate(
      unit = unit_id,
      period = 1L,
      post = 1L,
      employment = as.numeric(emptot2)
    )

  dplyr::bind_rows(before_period, after_period) |>
    dplyr::mutate(
      state = as.character(state),
      treated = as.integer(tolower(state) %in% c("nj", "new jersey")),
      treated_post = treated * post
    ) |>
    dplyr::filter(!is.na(employment))
}

card_krueger_clean_path <- path_dir("data", "interim", "card_krueger_clean.rds")

if (file.exists(card_krueger_clean_path)) {
  card_krueger_clean <- readRDS(card_krueger_clean_path)
  card_krueger_analysis <- build_card_krueger_panel(card_krueger_clean)

  if (is.null(card_krueger_analysis)) {
    log_message(
      "CardKrueger data is present but does not have the expected columns for the DID example. Skipping DID construction.",
      level = "WARN"
    )
  } else {
    save_rds(card_krueger_analysis, path_dir("data", "processed", "card_krueger_analysis.rds"))
    log_message("Saved CardKrueger analysis dataset.")
  }
} else {
  log_message("Clean CardKrueger data not found. Skipping DID construction.", level = "WARN")
}
