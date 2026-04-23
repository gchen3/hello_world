source(here::here("code", "utils", "paths.R"))

if (!isTRUE(get0(".hello_world_setup_complete", envir = .GlobalEnv, inherits = FALSE))) {
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

  assign(".hello_world_setup_complete", TRUE, envir = .GlobalEnv)

  log_message(sprintf("Project root resolved to %s", here::here()))
  log_message("Setup complete.")
}
