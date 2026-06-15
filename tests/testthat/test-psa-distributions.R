# Test PSA distribution fitting (method of moments)

test_that("Beta MoM produces valid parameters", {
  fit <- beta_mom(0.8, 0.05)
  expect_true(fit$alpha > 0)
  expect_true(fit$beta > 0)
  # Verify mean recovers: alpha/(alpha+beta) = mu
  expect_equal(fit$alpha / (fit$alpha + fit$beta), 0.8, tolerance = 1e-10)
})

test_that("Beta MoM recovers correct variance", {
  mu <- 0.6
  se <- 0.1
  fit <- beta_mom(mu, se)
  v_expected <- se^2
  v_actual <- (fit$alpha * fit$beta) /
    ((fit$alpha + fit$beta)^2 * (fit$alpha + fit$beta + 1))
  expect_equal(v_actual, v_expected, tolerance = 1e-10)
})

test_that("Gamma MoM produces valid parameters", {
  fit <- gamma_mom(500, 100)
  expect_true(fit$shape > 0)
  expect_true(fit$rate > 0)
  # Verify mean: shape/rate = mu
  expect_equal(fit$shape / fit$rate, 500, tolerance = 1e-10)
})

test_that("Gamma MoM recovers correct variance", {
  mu <- 200
  se <- 50
  fit <- gamma_mom(mu, se)
  v_expected <- se^2
  # Var = shape / rate^2
  v_actual <- fit$shape / fit$rate^2
  expect_equal(v_actual, v_expected, tolerance = 1e-10)
})

test_that("LogNormal MoM produces valid parameters", {
  fit <- lognormal_mom(1.5, 0.3)
  expect_true(is.finite(fit$meanlog))
  expect_true(fit$sdlog > 0)
  # Verify mean: exp(meanlog + sdlog^2/2) = mu
  mu_back <- exp(fit$meanlog + fit$sdlog^2 / 2)
  expect_equal(mu_back, 1.5, tolerance = 1e-10)
})

test_that("LogNormal MoM recovers correct variance", {
  mu <- 2.0
  se <- 0.5
  fit <- lognormal_mom(mu, se)
  # Var = (exp(sdlog^2) - 1) * exp(2*meanlog + sdlog^2)
  v_actual <- (exp(fit$sdlog^2) - 1) * exp(2 * fit$meanlog + fit$sdlog^2)
  expect_equal(v_actual, se^2, tolerance = 1e-10)
})
