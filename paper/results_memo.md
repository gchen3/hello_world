# Results Memo: Grunfeld Investment Analysis

## What We Analyze

This memo summarizes a reproducible analysis of the `plm::Grunfeld` panel dataset. The analysis links firm investment to two firm-level measures: market value and capital stock. The sample contains 200 firm-year observations. An optional difference-in-differences example based on `AER::CardKrueger` is not included because that dataset was not available in this environment.

The goal is to describe the patterns clearly, not to make a causal claim. The main finding is that investment is strongly and positively associated with market value and capital stock in simple OLS models. The association remains positive in firm fixed-effects models, but it becomes smaller and statistically imprecise after adding both firm and year fixed effects or using lagged covariates.

## 1. Research Method And Regression Equations

The analysis uses a panel-data research design. Each observation is a firm-year, so the same firms are observed across multiple years. The outcome is logged investment. The main explanatory variable is logged market value, and logged capital stock is included as a control variable because investment is likely related to the productive capacity of the firm.

The first model is a pooled OLS regression. The bivariate version estimates the raw association between logged investment and logged market value, while the controlled version adds logged capital stock:

log(investment_it) = α + β₁ log(market_value_it) + β₂ log(capital_stock_it) + ε_it

The next models add firm fixed effects and then firm plus year fixed effects. Firm fixed effects control for time-invariant differences across firms, such as persistent size, management style, or industry position. Year fixed effects control for economy-wide shocks or common time trends that affect all firms in the same year:

log(investment_it) = β₁ log(market_value_it) + β₂ log(capital_stock_it) + γ_i + δ_t + ε_it

The lagged-covariate model keeps the firm and year fixed effects but uses one-year lagged market value and capital stock:

log(investment_it) = β₁ log(market_value_i,t-1) + β₂ log(capital_stock_i,t-1) + γ_i + δ_t + ε_it

The robustness model replaces the logged market value and logged capital stock variables with winsorized versions:

log(investment_it) = β₁ winsorized_log_market_value_it + β₂ winsorized_log_capital_stock_it + γ_i + δ_t + ε_it

The control variables are logged capital stock, firm fixed effects, and year fixed effects. OLS models use heteroskedasticity-robust standard errors, while fixed-effects models use firm-clustered standard errors.

| Control variable | Included in | Purpose |
|---|---|---|
| Logged capital stock | OLS, firm/year fixed effects, robustness | Controls for the firm's productive capacity, which is likely related to investment. |
| Firm fixed effects | Firm/year fixed effects, robustness | Controls for time-invariant differences across firms. |
| Year fixed effects | Firm/year fixed effects, robustness | Controls for common shocks or trends affecting all firms in a given year. |

## 2. Correlations And Variable Relationships

Artifact: [`table_0_correlation_matrix.html`](../output/tables/table_0_correlation_matrix.html)

The correlation matrix shows that logged investment is strongly correlated with logged market value (`0.854`) and also positively correlated with logged capital stock (`0.718`). Logged market value and logged capital stock have a more moderate correlation (`0.463`), which supports including both variables in the controlled models without treating them as duplicates.

## 3. Sample And Descriptive Patterns

Artifact: [`table_1_summary_statistics.html`](../output/tables/table_1_summary_statistics.html)

Table 1 establishes the scale and spread of the data. Average investment is 145.96, but the standard deviation is 216.88 and values range from 0.93 to 1,486.70. Market value and capital stock also vary widely: average market value is 1,081.68 with a standard deviation of 1,314.47, while average capital stock is 276.02 with a standard deviation of 301.10.

This large variation motivates the use of logged variables in the regression analysis. Logs make the distributions easier to compare and allow coefficients to be read approximately as percentage associations.

## 4. Visual Evidence

Artifact: [`figure_1_distribution.png`](../output/figures/figure_1_distribution.png)

Figure 1 shows the distribution of logged investment. Raw investment has a wide range, while the logged scale compresses very large values and makes the main mass of observations easier to inspect.

Artifact: [`figure_2_main_relationship.png`](../output/figures/figure_2_main_relationship.png)

Figure 2 presents the bivariate relationship between log market value and log investment. The fitted line slopes upward, showing a positive raw association. This visual pattern supports the simple OLS results, but it does not separate firm-specific differences, economy-wide year effects, or other confounding factors from the relationship of interest.

## 5. Main Regression Evidence

Artifact: [`table_2_main_results.html`](../output/tables/table_2_main_results.html)

Table 2 is formatted in journal style with models as columns, coefficient stars, standard errors in parentheses, and rows that identify controls and fixed effects. The bivariate OLS model estimates a strong positive association between log market value and log investment (`1.00`). After adding the log capital stock control, the market value estimate is smaller but remains large and positive (`0.77`), while log capital stock is also positive (`0.38`).

The firm fixed-effects model still shows positive and statistically significant estimates for market value (`0.59`) and capital stock (`0.26`). After adding year fixed effects, the estimates fall to `0.33` for market value and `0.08` for capital stock, and both become statistically imprecise. The lagged-covariate fixed-effects model is more cautious: lagged market value is `0.13` and lagged capital stock is `0.03`, with neither estimate statistically distinguishable from zero.

The clearest interpretation is descriptive: firms or firm-years with higher market value and capital stock also tend to have higher investment. The fixed-effects results suggest caution before interpreting that relationship as causal.

## 6. Diagnostics And Specification Tests

Artifact: [`table_4_model_diagnostics.html`](../output/tables/table_4_model_diagnostics.html)

Table 4 adds model diagnostics and tests. The joint regressor tests show that market value and capital stock are jointly informative in the OLS, firm fixed-effects, and firm plus year fixed-effects models. The lagged-covariate model is not jointly significant, reinforcing the more cautious interpretation of that specification. The Breusch-Pagan-style diagnostics indicate heteroskedasticity in several specifications, supporting the use of robust or clustered standard errors.

## 7. Robustness Check

Artifact: [`table_a1_robustness.html`](../output/tables/table_a1_robustness.html)

Table A1 reports two robustness checks. The winsorized fixed-effects model repeats the firm and year fixed-effects regression after winsorizing the logged market value and logged capital stock variables. The first-difference model instead uses year-to-year changes within firms.

The winsorized estimates are close to the main fixed-effects estimates. The estimate for winsorized log market value is `0.33` with a p-value of `0.10`, and the estimate for winsorized log capital stock is `0.09` with a p-value of `0.17`. The first-difference model estimates a positive association for changes in market value (`0.58`) and a negative association for changes in capital stock (`-0.07`). Together, the robustness checks show that the positive market value relationship is visible in several specifications, but its strength and precision depend on how within-firm and time variation are modeled.

## Bottom Line

The descriptive evidence and simple OLS model point to a clear positive relationship between investment, market value, and capital stock. The expanded analysis shows that this relationship is robust in sign across several models, but its magnitude and statistical precision decline after adding more demanding controls, especially year fixed effects and lagged covariates. The results are best presented as evidence of a strong descriptive association, with a clear warning that the within-firm/year evidence is more cautious and should not be overstated as causal.
