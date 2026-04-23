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

grunfeld_analysis <- readRDS(path_dir("data", "processed", "grunfeld_analysis.rds"))

get_fitstat <- function(model, type) {
  value <- tryCatch(
    fixest::fitstat(model, type)[[type]],
    error = function(e) NA_real_
  )

  as.numeric(value)
}

get_wald_test <- function(model, keep_pattern) {
  test <- tryCatch(
    {
      captured_test <- NULL
      utils::capture.output(
        captured_test <- fixest::wald(model, keep = keep_pattern)
      )
      captured_test
    },
    error = function(e) NULL
  )

  if (is.null(test)) {
    return(c(statistic = NA_real_, p_value = NA_real_, df1 = NA_real_, df2 = NA_real_))
  }

  c(
    statistic = unname(test$stat),
    p_value = unname(test$p),
    df1 = unname(test$df1),
    df2 = unname(test$df2)
  )
}

get_bp_style_test <- function(model) {
  model_residuals <- stats::residuals(model)
  model_fitted <- stats::fitted(model)
  complete_rows <- stats::complete.cases(model_residuals, model_fitted)
  model_residuals <- model_residuals[complete_rows]
  model_fitted <- model_fitted[complete_rows]

  if (length(model_residuals) < 3) {
    return(c(statistic = NA_real_, p_value = NA_real_))
  }

  auxiliary_model <- stats::lm(I(model_residuals^2) ~ model_fitted)
  statistic <- length(model_residuals) * summary(auxiliary_model)$r.squared

  c(
    statistic = unname(statistic),
    p_value = stats::pchisq(statistic, df = 1, lower.tail = FALSE)
  )
}

build_model_diagnostics <- function(models) {
  dplyr::bind_rows(
    lapply(names(models), function(model_name) {
      model <- models[[model_name]]
      wald_test <- get_wald_test(model, "log_value|log_capital|lag_log_value|lag_log_capital")
      bp_test <- get_bp_style_test(model)

      data.frame(
        model = model_name,
        observations = get_fitstat(model, "n"),
        r_squared = get_fitstat(model, "r2"),
        adjusted_r_squared = get_fitstat(model, "ar2"),
        within_r_squared = get_fitstat(model, "wr2"),
        within_adjusted_r_squared = get_fitstat(model, "war2"),
        joint_regressor_f_statistic = wald_test[["statistic"]],
        joint_regressor_p_value = wald_test[["p_value"]],
        bp_style_statistic = bp_test[["statistic"]],
        bp_style_p_value = bp_test[["p_value"]],
        stringsAsFactors = FALSE
      )
    })
  )
}

build_correlation_table <- function(data) {
  variables <- c("log_invest", "log_value", "log_capital")
  correlation_matrix <- stats::cor(data[variables], use = "complete.obs")

  data.frame(
    variable = rownames(correlation_matrix),
    correlation_matrix,
    row.names = NULL,
    check.names = FALSE
  )
}

grunfeld_models <- list(
  "OLS: bivariate" = fixest::feols(
    log_invest ~ log_value,
    data = grunfeld_analysis,
    vcov = "hetero"
  ),
  "OLS: + capital control" = fixest::feols(
    log_invest ~ log_value + log_capital,
    data = grunfeld_analysis,
    vcov = "hetero"
  ),
  "Firm FE" = fixest::feols(
    log_invest ~ log_value + log_capital | firm,
    data = grunfeld_analysis,
    vcov = ~firm
  ),
  "Firm + Year FE" = fixest::feols(
    log_invest ~ log_value + log_capital | firm + year,
    data = grunfeld_analysis,
    vcov = ~firm
  ),
  "Lagged covariates FE" = fixest::feols(
    log_invest ~ lag_log_value + lag_log_capital | firm + year,
    data = grunfeld_analysis,
    vcov = ~firm
  )
)

diagnostics <- build_model_diagnostics(grunfeld_models)
correlation_table <- build_correlation_table(grunfeld_analysis)

did_models <- NULL
did_path <- path_dir("data", "processed", "card_krueger_analysis.rds")

if (file.exists(did_path)) {
  did_data <- readRDS(did_path)

  did_models <- list(
    "DID" = fixest::feols(
      employment ~ treated + post + treated_post,
      data = did_data,
      vcov = "hetero"
    )
  )

  log_message("Estimated DID example model.")
} else {
  log_message("No DID analysis data found. Main regression script skipped the DID model.", level = "WARN")
}

main_results <- list(
  grunfeld_models = grunfeld_models,
  diagnostics = diagnostics,
  correlation_table = correlation_table,
  did_models = did_models,
  notes = list(
    grunfeld = c(
      "OLS models use heteroskedasticity-robust standard errors.",
      "Fixed-effects models use firm-clustered standard errors.",
      "The lagged covariates model uses one-year lagged market value and capital stock."
    ),
    did = c(
      "DID is estimated only when CardKrueger analysis data is available.",
      "The example DID model uses heteroskedasticity-robust standard errors."
    )
  )
)

save_rds(main_results, path_dir("data", "processed", "main_models.rds"))
log_message("Main regression models saved.")
