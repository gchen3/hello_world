source(here::here("code", "00_setup.R"))

grunfeld_analysis <- readRDS(here::here("data", "processed", "grunfeld_analysis.rds"))
did_data <- readRDS(here::here("data", "processed", "card_krueger_analysis.rds"))

safe_fitstat <- function(model, type) {
  value <- tryCatch(fixest::fitstat(model, type)[[type]], error = function(e) NA_real_)
  as.numeric(value)
}

safe_wald <- function(model) {
  test <- tryCatch(
    {
      captured_test <- NULL
      utils::capture.output(
        captured_test <- fixest::wald(model, keep = "log_value|log_capital|lag_log_value|lag_log_capital")
      )
      captured_test
    },
    error = function(e) NULL
  )

  if (is.null(test)) {
    return(c(statistic = NA_real_, p_value = NA_real_))
  }

  c(statistic = unname(test$stat), p_value = unname(test$p))
}

bp_style_test <- function(model) {
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

diagnostics <- dplyr::bind_rows(lapply(names(grunfeld_models), function(model_name) {
  model <- grunfeld_models[[model_name]]
  wald_test <- safe_wald(model)
  bp_test <- bp_style_test(model)

  data.frame(
    model = model_name,
    observations = safe_fitstat(model, "n"),
    r_squared = safe_fitstat(model, "r2"),
    adjusted_r_squared = safe_fitstat(model, "ar2"),
    within_r_squared = safe_fitstat(model, "wr2"),
    within_adjusted_r_squared = safe_fitstat(model, "war2"),
    joint_regressor_f_statistic = wald_test[["statistic"]],
    joint_regressor_p_value = wald_test[["p_value"]],
    bp_style_statistic = bp_test[["statistic"]],
    bp_style_p_value = bp_test[["p_value"]],
    stringsAsFactors = FALSE
  )
}))

correlation_matrix <- stats::cor(
  grunfeld_analysis[c("log_invest", "log_value", "log_capital")],
  use = "complete.obs"
)

correlation_table <- data.frame(
  variable = rownames(correlation_matrix),
  correlation_matrix,
  row.names = NULL,
  check.names = FALSE
)

did_models <- list(
  "DID" = fixest::feols(
    employment ~ treated + post + treated_post,
    data = did_data,
    vcov = "hetero"
  )
)

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
      "The DID model uses heteroskedasticity-robust standard errors."
    )
  )
)

saveRDS(main_results, here::here("data", "processed", "main_models.rds"))
log_message("Saved main regression models.")
