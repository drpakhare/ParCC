# Test survival distribution fitting

test_that("Weibull fitting recovers known parameters", {
  # Generate two KM points from known Weibull(gamma=1.5, lambda=0.01)
  gamma_true <- 1.5
  lambda_true <- 0.01
  t1 <- 12
  t2 <- 24
  s1 <- exp(-lambda_true * t1^gamma_true)
  s2 <- exp(-lambda_true * t2^gamma_true)
  fit <- weibull_from_km(t1, s1, t2, s2)
  expect_equal(fit$gamma, gamma_true, tolerance = 1e-8)
  expect_equal(fit$lambda, lambda_true, tolerance = 1e-8)
})

test_that("Weibull survival function is correct", {
  expect_equal(weibull_surv(0, 1.5, 0.01), 1.0)
  # S(t) = exp(-lambda * t^gamma)
  expect_equal(weibull_surv(10, 1.5, 0.01), exp(-0.01 * 10^1.5), tolerance = 1e-10)
})

test_that("Exponential is Weibull with gamma = 1", {
  lambda <- 0.05
  t_test <- 5
  # Weibull with gamma=1 should equal exponential
  expect_equal(weibull_surv(t_test, 1, lambda), exp(-lambda * t_test), tolerance = 1e-10)
})

test_that("Log-Logistic fitting recovers known parameters", {
  alpha_true <- 20
  beta_true <- 2.0
  t1 <- 10
  t2 <- 30
  s1 <- 1 / (1 + (t1 / alpha_true)^beta_true)
  s2 <- 1 / (1 + (t2 / alpha_true)^beta_true)
  fit <- loglogistic_from_km(t1, s1, t2, s2)
  expect_equal(fit$alpha, alpha_true, tolerance = 1e-6)
  expect_equal(fit$beta, beta_true, tolerance = 1e-6)
})

test_that("Log-Logistic survival function is correct", {
  expect_equal(loglogistic_surv(0, 20, 2), 1.0)
  # At t = alpha, S = 0.5 (median)
  expect_equal(loglogistic_surv(20, 20, 2), 0.5, tolerance = 1e-10)
})

test_that("Log-Logistic median is alpha", {
  # For any beta, S(alpha) = 1 / (1 + 1) = 0.5
  for (beta in c(0.5, 1, 2, 5)) {
    expect_equal(loglogistic_surv(15, 15, beta), 0.5, tolerance = 1e-10)
  }
})
