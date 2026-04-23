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

build_cleaning_report <- function(dataset_name, data, duplicates_removed) {
  data.frame(
    dataset = dataset_name,
    rows = nrow(data),
    columns = ncol(data),
    duplicates_removed = duplicates_removed,
    missing_values = sum(is.na(data)),
    stringsAsFactors = FALSE
  )
}

grunfeld_raw <- readr::read_csv(
  path_dir("data", "raw", "grunfeld_raw.csv"),
  show_col_types = FALSE
)

grunfeld_clean <- grunfeld_raw |>
  janitor::clean_names() |>
  dplyr::mutate(
    firm = as.factor(firm),
    year = as.integer(year),
    inv = as.numeric(inv),
    value = as.numeric(value),
    capital = as.numeric(capital)
  )

grunfeld_duplicates <- nrow(grunfeld_clean) - nrow(dplyr::distinct(grunfeld_clean))
grunfeld_clean <- dplyr::distinct(grunfeld_clean)

save_rds(grunfeld_clean, path_dir("data", "interim", "grunfeld_clean.rds"))
log_message("Saved cleaned Grunfeld data.")

cleaning_reports <- list(
  build_cleaning_report("grunfeld", grunfeld_clean, grunfeld_duplicates)
)

if (file.exists(path_dir("data", "raw", "card_krueger_raw.csv"))) {
  card_krueger_raw <- readr::read_csv(
    path_dir("data", "raw", "card_krueger_raw.csv"),
    show_col_types = FALSE
  )

  card_krueger_clean <- card_krueger_raw |>
    janitor::clean_names() |>
    dplyr::distinct()

  card_krueger_duplicates <- nrow(card_krueger_raw) - nrow(card_krueger_clean)

  save_rds(card_krueger_clean, path_dir("data", "interim", "card_krueger_clean.rds"))
  log_message("Saved cleaned CardKrueger data.")

  cleaning_reports[[length(cleaning_reports) + 1]] <-
    build_cleaning_report("card_krueger", card_krueger_clean, card_krueger_duplicates)
} else {
  log_message("Raw CardKrueger file not found. Skipping DID cleaning.", level = "WARN")
}

readr::write_csv(
  dplyr::bind_rows(cleaning_reports),
  path_dir("output", "logs", "cleaning_report.csv")
)

log_message("Cleaning report written.")
