current_source_dir <- function() {
  source_files <- vapply(
    sys.frames(),
    function(frame) {
      if (is.null(frame$ofile)) {
        return(NA_character_)
      }

      frame$ofile
    },
    character(1)
  )

  source_files <- source_files[!is.na(source_files)]

  if (length(source_files) > 0) {
    return(dirname(normalizePath(tail(source_files, 1), winslash = "/", mustWork = FALSE)))
  }

  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

find_project_root <- function(start_dir = current_source_dir()) {
  current_dir <- normalizePath(start_dir, winslash = "/", mustWork = FALSE)

  repeat {
    has_git <- dir.exists(file.path(current_dir, ".git"))
    has_project_layout <- file.exists(file.path(current_dir, "README.md")) &&
      dir.exists(file.path(current_dir, "code"))

    if (has_git || has_project_layout) {
      return(current_dir)
    }

    parent_dir <- dirname(current_dir)

    if (identical(parent_dir, current_dir)) {
      return(normalizePath(getwd(), winslash = "/", mustWork = FALSE))
    }

    current_dir <- parent_dir
  }
}

project_root <- local({
  root <- find_project_root()

  function() {
    root
  }
})

path_dir <- function(...) {
  file.path(project_root(), ...)
}

ensure_project_dirs <- function() {
  dirs <- c(
    path_dir("data", "raw"),
    path_dir("data", "interim"),
    path_dir("data", "processed"),
    path_dir("output", "tables"),
    path_dir("output", "figures"),
    path_dir("output", "logs"),
    path_dir("paper"),
    path_dir("docs")
  )

  fs::dir_create(dirs)
  invisible(dirs)
}

log_file_path <- function() {
  path_dir("output", "logs", "pipeline.log")
}

log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- sprintf("[%s] [%s] %s", timestamp, level, message)

  cat(line, "\n")
  write(line, file = log_file_path(), append = TRUE)
  invisible(line)
}

write_if_changed <- function(path, contents) {
  if (file.exists(path)) {
    existing <- paste(readLines(path, warn = FALSE), collapse = "\n")
    if (identical(existing, contents)) {
      return(invisible(FALSE))
    }
  }

  writeLines(contents, con = path, useBytes = TRUE)
  invisible(TRUE)
}

save_rds <- function(object, path) {
  saveRDS(object, file = path)
  invisible(path)
}

read_rds_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }

  readRDS(path)
}
