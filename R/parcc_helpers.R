# ParCC Helper Functions
# Standalone mathematical functions for HTA parameter conversions.
# These mirror the calculations performed inside the Shiny modules
# and are exposed for testing and programmatic use.

# --- Core Conversions ---------------------------------------------------

#' Convert rate to probability
#' @param rate Event rate (per unit time)
#' @param t Time period (cycle length)
#' @return Probability of event over time t
#' @noRd
rate_to_prob <- function(rate, t = 1) {
  stopifnot(rate >= 0, t > 0)
  1 - exp(-rate * t)
}

#' Convert probability to rate
#' @param prob Probability (0 < prob < 1)
#' @param t Time period (cycle length)
#' @return Event rate per unit time
#' @noRd
prob_to_rate <- function(prob, t = 1) {
  stopifnot(prob > 0, prob < 1, t > 0)
  -log(1 - prob) / t
}

#' Convert odds to probability
#' @param odds Odds value
#' @return Probability
#' @noRd
odds_to_prob <- function(odds) {
  stopifnot(odds >= 0)
  odds / (1 + odds)
}

#' Convert probability to odds
#' @param prob Probability (0 < prob < 1)
#' @return Odds
#' @noRd
prob_to_odds <- function(prob) {
  stopifnot(prob > 0, prob < 1)
  prob / (1 - prob)
}

#' Rescale probability to a different time period
#' @param p_old Probability over original time period
#' @param t_old Original time period
#' @param t_new New time period
#' @return Probability over new time period
#' @noRd
rescale_prob <- function(p_old, t_old, t_new) {
  stopifnot(p_old > 0, p_old < 1, t_old > 0, t_new > 0)
  1 - (1 - p_old)^(t_new / t_old)
}

#' Convert odds ratio to relative risk (Zhang and Yu 1998)
#' @param or Odds ratio
#' @param p0 Baseline risk in control group
#' @return Relative risk
#' @noRd
or_to_rr <- function(or, p0) {
  stopifnot(or > 0, p0 > 0, p0 < 1)
  or / (1 - p0 + p0 * or)
}

#' Convert relative risk to odds ratio
#' @param rr Relative risk
#' @param p0 Baseline risk in control group
#' @return Odds ratio
#' @noRd
rr_to_or <- function(rr, p0) {
  stopifnot(rr > 0, p0 > 0, p0 < 1)
  rr * (1 - p0) / (1 - rr * p0)
}

#' Convert standardised mean difference to log odds ratio (Chinn 2000)
#' @param smd Standardised mean difference
#' @return Log odds ratio
#' @noRd
smd_to_log_or <- function(smd) {
  smd * pi / sqrt(3)
}

#' Convert log odds ratio to standardised mean difference (Chinn 2000)
#' @param log_or Log odds ratio
#' @return Standardised mean difference
#' @noRd
log_or_to_smd <- function(log_or) {
  log_or * sqrt(3) / pi
}

# --- Hazard Ratio Conversion --------------------------------------------

#' Convert hazard ratio to intervention probability
#' @param p_control Control-arm event probability
#' @param hr Hazard ratio
#' @param t_control Time period for control probability
#' @param t_output Desired output cycle length
#' @return Intervention-arm event probability
#' @noRd
hr_to_prob <- function(p_control, hr, t_control = 1, t_output = 1) {
  stopifnot(p_control > 0, p_control < 1, hr > 0, t_control > 0, t_output > 0)
  r_control <- -log(1 - p_control) / t_control
  r_intervention <- r_control * hr
  1 - exp(-r_intervention * t_output)
}

#' Calculate absolute risk reduction
#' @param p_control Control-arm probability
#' @param p_intervention Intervention-arm probability
#' @return Absolute risk reduction
#' @noRd
calc_arr <- function(p_control, p_intervention) {
  p_control - p_intervention
}

#' Calculate number needed to treat
#' @param arr Absolute risk reduction
#' @return NNT (ceiling-rounded integer)
#' @noRd
calc_nnt <- function(arr) {
  stopifnot(arr != 0)
  ceiling(1 / abs(arr))
}

#' Convert log-rank statistic to hazard ratio (Peto approximation)
#' @param z Z-statistic (from chi-square or p-value)
#' @param total_events Total number of events across both arms
#' @param favours_intervention Logical; TRUE if treatment arm has fewer events
#' @return Named list: hr, hr_low, hr_high, se_log_hr
#' @noRd
logrank_to_hr <- function(z, total_events, favours_intervention = TRUE) {
  stopifnot(z >= 0, total_events > 0)
  sign_factor <- if (favours_intervention) -1 else 1
  log_hr <- sign_factor * 2 * z / sqrt(total_events)
  se_log_hr <- 2 / sqrt(total_events)
  list(
    hr       = exp(log_hr),
    hr_low   = exp(log_hr - 1.96 * se_log_hr),
    hr_high  = exp(log_hr + 1.96 * se_log_hr),
    se_log_hr = se_log_hr
  )
}

# --- Survival Distributions ----------------------------------------------

#' Fit Weibull parameters from two Kaplan-Meier time-points
#' @param t1 First time point
#' @param s1 Survival at t1
#' @param t2 Second time point
#' @param s2 Survival at t2
#' @return Named list: gamma (shape), lambda (scale)
#' @noRd
weibull_from_km <- function(t1, s1, t2, s2) {
  stopifnot(t1 > 0, t2 > t1, s1 > 0, s1 < 1, s2 > 0, s2 < s1)
  y1 <- log(-log(s1))
  x1 <- log(t1)
  y2 <- log(-log(s2))
  x2 <- log(t2)
  gamma <- (y2 - y1) / (x2 - x1)
  lambda <- exp(y1 - gamma * x1)
  list(gamma = gamma, lambda = lambda)
}

#' Weibull survival function
#' @param t Time
#' @param gamma Shape parameter
#' @param lambda Scale parameter
#' @return Survival probability
#' @noRd
weibull_surv <- function(t, gamma, lambda) {
  exp(-lambda * t^gamma)
}

#' Fit Log-Logistic parameters from two Kaplan-Meier time-points
#' @param t1 First time point
#' @param s1 Survival at t1
#' @param t2 Second time point
#' @param s2 Survival at t2
#' @return Named list: alpha, beta
#' @noRd
loglogistic_from_km <- function(t1, s1, t2, s2) {
  stopifnot(t1 > 0, t2 > t1, s1 > 0, s1 < 1, s2 > 0, s2 < s1)
  y1 <- log(1 / s1 - 1)
  x1 <- log(t1)
  y2 <- log(1 / s2 - 1)
  x2 <- log(t2)
  beta_ll <- (y2 - y1) / (x2 - x1)
  log_alpha <- -y1 / beta_ll + x1
  list(alpha = exp(log_alpha), beta = beta_ll)
}

#' Log-Logistic survival function
#' @param t Time
#' @param alpha Scale parameter
#' @param beta Shape parameter
#' @return Survival probability
#' @noRd
loglogistic_surv <- function(t, alpha, beta) {
  1 / (1 + (t / alpha)^beta)
}

# --- PSA Distributions ---------------------------------------------------

#' Fit Beta distribution via method of moments
#' @param mu Mean
#' @param se Standard error
#' @return Named list: alpha, beta
#' @noRd
beta_mom <- function(mu, se) {
  stopifnot(mu > 0, mu < 1, se > 0)
  v <- se^2
  stopifnot(v < mu * (1 - mu))
  term <- (mu * (1 - mu) / v) - 1
  list(alpha = mu * term, beta = (1 - mu) * term)
}

#' Fit Gamma distribution via method of moments
#' @param mu Mean
#' @param se Standard error
#' @return Named list: shape (k), rate (1/theta)
#' @noRd
gamma_mom <- function(mu, se) {
  stopifnot(mu > 0, se > 0)
  v <- se^2
  list(shape = mu^2 / v, rate = mu / v)
}

#' Fit LogNormal distribution via method of moments
#' @param mu Mean (on natural scale)
#' @param se Standard error (on natural scale)
#' @return Named list: meanlog, sdlog
#' @noRd
lognormal_mom <- function(mu, se) {
  stopifnot(mu > 0, se > 0)
  v <- se^2
  s2 <- log(1 + v / mu^2)
  list(meanlog = log(mu) - 0.5 * s2, sdlog = sqrt(s2))
}

# --- Background Mortality ------------------------------------------------

#' SMR-adjusted mortality probability
#' @param prob_or_rate Population mortality (probability or rate)
#' @param smr Standardised mortality ratio
#' @param input_is_prob TRUE if input is probability, FALSE if rate
#' @return Adjusted mortality probability
#' @noRd
smr_adjust <- function(prob_or_rate, smr, input_is_prob = TRUE) {
  stopifnot(smr > 0)
  rate_pop <- if (input_is_prob) -log(1 - prob_or_rate) else prob_or_rate
  rate_adj <- rate_pop * smr
  1 - exp(-rate_adj)
}

#' Fit Gompertz mortality parameters from two age-rate points
#' @param age1 First age
#' @param rate1 Mortality rate at age1
#' @param age2 Second age
#' @param rate2 Mortality rate at age2
#' @return Named list: alpha, beta, doubling_time
#' @noRd
gompertz_from_points <- function(age1, rate1, age2, rate2) {
  stopifnot(rate1 > 0, rate2 > 0, age2 != age1)
  beta <- (log(rate2) - log(rate1)) / (age2 - age1)
  alpha <- exp(log(rate1) - beta * age1)
  list(alpha = alpha, beta = beta, doubling_time = log(2) / beta)
}

#' DEALE: life expectancy to rate
#' @param le Life expectancy (years)
#' @return Constant hazard rate
#' @noRd
deale_le_to_rate <- function(le) {
  stopifnot(le > 0)
  1 / le
}

# --- Economic Calculations -----------------------------------------------

#' Discount a future value to present
#' @param fv Future value
#' @param rate Discount rate (annual, as decimal)
#' @param t Number of years
#' @return Present value
#' @noRd
discount_pv <- function(fv, rate, t) {
  stopifnot(rate >= 0, t >= 0)
  fv / (1 + rate)^t
}

#' Calculate ICER
#' @param d_cost Incremental cost
#' @param d_eff Incremental effect
#' @return ICER value
#' @noRd
calc_icer <- function(d_cost, d_eff) {
  stopifnot(d_eff != 0)
  d_cost / d_eff
}

#' Calculate incremental net monetary benefit
#' @param d_cost Incremental cost
#' @param d_eff Incremental effect
#' @param wtp Willingness-to-pay threshold
#' @return iNMB value
#' @noRd
calc_inmb <- function(d_cost, d_eff, wtp) {
  (d_eff * wtp) - d_cost
}

#' PPP cost conversion between two countries
#' @param cost_lcu Cost in source local currency units
#' @param ppp_src PPP conversion factor for source country
#' @param ppp_tgt PPP conversion factor for target country
#' @return Cost in target local currency units (PPP-adjusted)
#' @noRd
ppp_convert <- function(cost_lcu, ppp_src, ppp_tgt) {
  stopifnot(ppp_src > 0, ppp_tgt > 0)
  (cost_lcu / ppp_src) * ppp_tgt
}
