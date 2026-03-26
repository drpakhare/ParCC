# Test background mortality functions

test_that("SMR adjustment on probability scale is correct", {
  # prob = 0.01, SMR = 2
  # rate = -log(0.99), adjusted rate = 2 * rate, prob = 1 - exp(-adj_rate)
  p_pop <- 0.01
  smr <- 2
  rate_pop <- -log(1 - p_pop)
  expected <- 1 - exp(-rate_pop * smr)
  expect_equal(smr_adjust(p_pop, smr, input_is_prob = TRUE), expected, tolerance = 1e-10)
})

test_that("SMR adjustment on rate scale is correct", {
  rate <- 0.02
  smr <- 1.5
  expected <- 1 - exp(-rate * smr)
  expect_equal(smr_adjust(rate, smr, input_is_prob = FALSE), expected, tolerance = 1e-10)
})

test_that("SMR = 1 preserves population probability", {
  p_pop <- 0.05
  result <- smr_adjust(p_pop, 1.0, input_is_prob = TRUE)
  expect_equal(result, p_pop, tolerance = 1e-10)
})

test_that("Gompertz fitting recovers known parameters", {
  alpha_true <- 0.00005
  beta_true <- 0.085
  age1 <- 40
  age2 <- 70
  r1 <- alpha_true * exp(beta_true * age1)
  r2 <- alpha_true * exp(beta_true * age2)
  fit <- gompertz_from_points(age1, r1, age2, r2)
  expect_equal(fit$alpha, alpha_true, tolerance = 1e-10)
  expect_equal(fit$beta, beta_true, tolerance = 1e-10)
  expect_equal(fit$doubling_time, log(2) / beta_true, tolerance = 1e-10)
})

test_that("DEALE life expectancy to rate conversion", {
  expect_equal(deale_le_to_rate(50), 0.02)
  expect_equal(deale_le_to_rate(10), 0.10)
  # Round-trip
  le <- 25
  r <- deale_le_to_rate(le)
  expect_equal(1 / r, le, tolerance = 1e-10)
})
