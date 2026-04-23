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

write_model_tidy_csv <- function(models, path) {
  tidy_table <- dplyr::bind_rows(
    lapply(names(models), function(model_name) {
      broom::tidy(models[[model_name]], conf.int = TRUE) |>
        dplyr::mutate(model = model_name, .before = 1)
    })
  )

  readr::write_csv(tidy_table, path)
}

summary_artifacts <- readRDS(path_dir("data", "processed", "summary_statistics.rds"))
main_results <- readRDS(path_dir("data", "processed", "main_models.rds"))
robustness_results <- readRDS(path_dir("data", "processed", "robustness_models.rds"))
grunfeld_analysis <- readRDS(path_dir("data", "processed", "grunfeld_analysis.rds"))
distribution_data <- grunfeld_analysis |>
  dplyr::filter(is.finite(log_invest))
relationship_data <- grunfeld_analysis |>
  dplyr::filter(is.finite(log_invest), is.finite(log_value))

coef_map <- c(
  "log_value" = "Log market value",
  "log_capital" = "Log capital stock",
  "lag_log_value" = "Lagged log market value",
  "lag_log_capital" = "Lagged log capital stock",
  "log_value_winsor" = "Winsorized log market value",
  "log_capital_winsor" = "Winsorized log capital stock",
  "delta_log_value" = "Delta log market value",
  "delta_log_capital" = "Delta log capital stock",
  "treated" = "Treated",
  "post" = "Post",
  "treated_post" = "Treated x post"
)

gof_map <- data.frame(
  raw = c("nobs", "r.squared", "adj.r.squared"),
  clean = c("Observations", "R2", "Adjusted R2"),
  fmt = c(0, 3, 3),
  stringsAsFactors = FALSE
)

journal_add_rows <- data.frame(
  term = c("Capital control", "Firm fixed effects", "Year fixed effects", "Lagged covariates"),
  "OLS: bivariate" = c("No", "No", "No", "No"),
  "OLS: + capital control" = c("Yes", "No", "No", "No"),
  "Firm FE" = c("Yes", "Yes", "No", "No"),
  "Firm + Year FE" = c("Yes", "Yes", "Yes", "No"),
  "Lagged covariates FE" = c("Yes", "Yes", "Yes", "Yes"),
  check.names = FALSE
)

robustness_add_rows <- data.frame(
  term = c("Capital control", "Firm fixed effects", "Year fixed effects", "Specification"),
  "Winsorized FE" = c("Yes", "Yes", "Yes", "Winsorized covariates"),
  "First differences" = c("Yes", "No", "No", "Within-firm changes"),
  check.names = FALSE
)

modelsummary::datasummary_df(
  summary_artifacts$summary_table,
  title = "Table 1. Summary statistics",
  output = path_dir("output", "tables", "table_1_summary_statistics.html")
)

modelsummary::modelsummary(
  main_results$grunfeld_models,
  coef_map = coef_map,
  gof_map = gof_map,
  add_rows = journal_add_rows,
  estimate = "{estimate}{stars}",
  statistic = "({std.error})",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Table 2. Main Grunfeld results",
  notes = main_results$notes$grunfeld,
  output = path_dir("output", "tables", "table_2_main_results.html")
)

modelsummary::modelsummary(
  main_results$grunfeld_models,
  coef_map = coef_map,
  gof_map = gof_map,
  add_rows = journal_add_rows,
  estimate = "{estimate}{stars}",
  statistic = "({std.error})",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Table 2. Main Grunfeld results",
  notes = main_results$notes$grunfeld,
  output = path_dir("output", "tables", "table_2_main_results_journal.html")
)

write_model_tidy_csv(
  main_results$grunfeld_models,
  path_dir("output", "tables", "table_2_main_results.csv")
)

readr::write_csv(
  main_results$correlation_table,
  path_dir("output", "tables", "table_0_correlation_matrix.csv")
)

modelsummary::datasummary_df(
  main_results$correlation_table,
  title = "Table 0. Correlation matrix for logged analysis variables",
  output = path_dir("output", "tables", "table_0_correlation_matrix.html")
)

readr::write_csv(
  main_results$diagnostics,
  path_dir("output", "tables", "table_4_model_diagnostics.csv")
)

modelsummary::datasummary_df(
  main_results$diagnostics,
  title = "Table 4. Model diagnostics and specification tests",
  output = path_dir("output", "tables", "table_4_model_diagnostics.html")
)

modelsummary::modelsummary(
  robustness_results$models,
  coef_map = coef_map,
  gof_map = gof_map,
  add_rows = robustness_add_rows,
  estimate = "{estimate}{stars}",
  statistic = "({std.error})",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Table A1. Robustness results",
  notes = robustness_results$notes,
  output = path_dir("output", "tables", "table_a1_robustness.html")
)

write_model_tidy_csv(
  robustness_results$models,
  path_dir("output", "tables", "table_a1_robustness.csv")
)

if (!is.null(main_results$did_models)) {
  modelsummary::modelsummary(
    main_results$did_models,
    coef_map = coef_map,
    gof_map = gof_map,
    title = "Table 3. DID example results",
    notes = main_results$notes$did,
    output = path_dir("output", "tables", "table_3_did_results.html")
  )

  write_model_tidy_csv(
    main_results$did_models,
    path_dir("output", "tables", "table_3_did_results.csv")
  )
}

distribution_plot <- ggplot2::ggplot(
  distribution_data,
  ggplot2::aes(x = log_invest)
) +
  ggplot2::geom_histogram(bins = 20, fill = "#2F6B7C", color = "white") +
  ggplot2::labs(
    title = "Figure 1. Distribution of log investment",
    x = "Log investment",
    y = "Count"
  )

relationship_plot <- ggplot2::ggplot(
  relationship_data,
  ggplot2::aes(x = log_value, y = log_invest)
) +
  ggplot2::geom_point(alpha = 0.65, color = "#1F3B4D") +
  ggplot2::geom_smooth(method = "lm", se = FALSE, color = "#B24C63") +
  ggplot2::labs(
    title = "Figure 2. Investment and market value",
    x = "Log market value",
    y = "Log investment"
  )

ggplot2::ggsave(
  filename = path_dir("output", "figures", "figure_1_distribution.png"),
  plot = distribution_plot,
  width = 8,
  height = 5,
  dpi = 300
)

ggplot2::ggsave(
  filename = path_dir("output", "figures", "figure_2_main_relationship.png"),
  plot = relationship_plot,
  width = 8,
  height = 5,
  dpi = 300
)

log_message("Final tables and figures written.")
