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

write_raw_csv <- function(data, path) {
  temp_path <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_path), add = TRUE)

  readr::write_csv(data, temp_path)

  if (file.exists(path)) {
    existing_hash <- unname(tools::md5sum(path))
    new_hash <- unname(tools::md5sum(temp_path))
    existing_lines <- readLines(path, warn = FALSE)
    new_lines <- readLines(temp_path, warn = FALSE)
    has_stale_tail <- length(existing_lines) > length(new_lines) &&
      identical(existing_lines[seq_along(new_lines)], new_lines)

    if (!identical(existing_hash, new_hash) && !has_stale_tail) {
      stop(
        sprintf(
          "Refusing to overwrite protected raw file because it differs from the bundled source: %s",
          path
        ),
        call. = FALSE
      )
    }
  }

  if (file.exists(path)) {
    file.remove(path)
  }

  file.copy(temp_path, path, overwrite = FALSE)
  invisible(path)
}

grunfeld_env <- new.env(parent = emptyenv())
utils::data("Grunfeld", package = "plm", envir = grunfeld_env)

if (!exists("Grunfeld", envir = grunfeld_env, inherits = FALSE)) {
  stop("The plm package is installed, but the Grunfeld dataset was not found.", call. = FALSE)
}

grunfeld_raw <- as.data.frame(get("Grunfeld", envir = grunfeld_env))
grunfeld_raw_path <- path_dir("data", "raw", "grunfeld_raw.csv")
write_raw_csv(grunfeld_raw, grunfeld_raw_path)
log_message("Saved raw Grunfeld data.")

card_krueger_raw <- NULL
card_krueger_raw_path <- path_dir("data", "raw", "card_krueger_raw.csv")

if (requireNamespace("AER", quietly = TRUE)) {
  did_env <- new.env(parent = emptyenv())
  suppressWarnings(utils::data("CardKrueger", package = "AER", envir = did_env))

  if (exists("CardKrueger", envir = did_env, inherits = FALSE)) {
    card_krueger_raw <- as.data.frame(get("CardKrueger", envir = did_env))
    write_raw_csv(card_krueger_raw, card_krueger_raw_path)
    log_message("Saved raw CardKrueger data.")
  } else {
    log_message("AER is installed, but CardKrueger was not found. DID path will be skipped.", level = "WARN")
  }
} else {
  log_message("AER is not installed. DID path will be skipped.", level = "WARN")
}

data_source_lines <- c(
  "# Data sources",
  "",
  sprintf(
    "- `plm::Grunfeld`: built-in panel dataset saved to `%s` on %s.",
    gsub("\\\\", "/", grunfeld_raw_path),
    Sys.Date()
  ),
  if (!is.null(card_krueger_raw)) {
    sprintf(
      "- `AER::CardKrueger`: built-in DID example saved to `%s` on %s.",
      gsub("\\\\", "/", card_krueger_raw_path),
      Sys.Date()
    )
  } else {
    sprintf("- `AER::CardKrueger`: not available in this environment on %s.", Sys.Date())
  }
)

write_if_changed(
  path_dir("docs", "data_sources.md"),
  paste(data_source_lines, collapse = "\n")
)

log_message("Data source notes updated.")
