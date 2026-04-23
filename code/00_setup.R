setup_source_files <- vapply(
  sys.frames(),
  function(frame) {
    if (is.null(frame$ofile)) {
      return(NA_character_)
    }

    frame$ofile
  },
  character(1)
)
setup_source_files <- setup_source_files[!is.na(setup_source_files)]

setup_dir <- if (length(setup_source_files) > 0) {
  dirname(normalizePath(tail(setup_source_files, 1), winslash = "/", mustWork = FALSE))
} else if (file.exists(file.path("utils", "paths.R"))) {
  normalizePath(".", winslash = "/", mustWork = FALSE)
} else {
  normalizePath("code", winslash = "/", mustWork = FALSE)
}

source(file.path(setup_dir, "utils", "paths.R"))

required_packages <- c(
  "here",
  "fs",
  "janitor",
  "dplyr",
  "readr",
  "ggplot2",
  "fixest",
  "modelsummary",
  "broom",
  "plm"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    sprintf(
      "Missing required packages: %s. Install them before running the pipeline.",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

ensure_project_dirs()

r_config_dir <- path_dir("output", "logs", "r-config")
fs::dir_create(r_config_dir)
Sys.setenv(
  R_USER_CONFIG_DIR = r_config_dir,
  XDG_CONFIG_HOME = r_config_dir
)

ggplot2::theme_set(
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title.position = "plot",
      panel.grid.minor = ggplot2::element_blank()
    )
)

options(
  dplyr.summarise.inform = FALSE,
  scipen = 999
)

log_message(sprintf("Project root resolved to %s", project_root()))
log_message("Setup complete.")

invisible(
  list(
    project_root = project_root(),
    required_packages = required_packages
  )
)
