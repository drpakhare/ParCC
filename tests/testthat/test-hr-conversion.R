# Test hazard ratio conversion and related functions

test_that("HR to probability conversion follows three-step process", {
  p_ctrl <- 0.20
  hr <- 0.75
  # Step 1: prob to rate
  r_ctrl <- -log(1 - p_ctrl)
  # Step 2: apply HR
  r_int <- r_ctrl * hr
  # Step 3: rate to prob
  expected <- 1 - exp(-r_int)
  expect_equal(hr_to_prob(p_ctrl, hr), expected, tolerance = 1e-10)
})

test_that("HR = 1 gives same probability as control", {
  p_ctrl <- 0.15
  expect_equal(hr_to_prob(p_ctrl, 1.0), p_ctrl, tolerance = 1e-10)
})

test_that("HR conversion handles different cycle lengths", {
  p_ctrl_annual <- 0.10
  hr <- 0.80
  # Convert annual control prob to monthly intervention prob
  p_int_monthly <- hr_to_prob(p_ctrl_annual, hr, t_control = 12, t_output = 1)
  # Should be small (monthly)
  expect_true(p_int_monthly < p_ctrl_annual)
  expect_true(p_int_monthly > 0)
})

test_that("NNT calculation is ceiling-rounded", {
  expect_equal(calc_nnt(0.10), 10)
  expect_equal(calc_nnt(0.15), 7) # ceiling(1/0.15) = 7
  expect_equal(calc_nnt(0.01), 100)
  # Negative ARR (NNH) still returns positive
  expect_equal(calc_nnt(-0.05), 20)
})

test_that("ARR calculation is correct", {
  expect_equal(calc_arr(0.20, 0.15), 0.05)
  expect_equal(calc_arr(0.10, 0.10), 0.00)
})

test_that("log-rank to HR (Peto) is correct", {
  # Chi-square = 4 -> z = 2, E = 100
  res <- logrank_to_hr(z = 2, total_events = 100, favours_intervention = TRUE)
  expect_equal(res$hr, exp(-2 * 2 / sqrt(100)), tolerance = 1e-10)
  expect_equal(res$se_log_hr, 2 / sqrt(100), tolerance = 1e-10)
  expect_true(res$hr_low < res$hr)
  expect_true(res$hr_high > res$hr)
  # HR < 1 when favours intervention
  expect_true(res$hr < 1)
})

test_that("log-rank to HR favours_intervention flag works", {
  res_fav <- logrank_to_hr(2, 100, favours_intervention = TRUE)
  res_not <- logrank_to_hr(2, 100, favours_intervention = FALSE)
  expect_true(res_fav$hr < 1)
  expect_true(res_not$hr > 1)
  # Symmetric on log scale
  expect_equal(log(res_fav$hr), -log(res_not$hr), tolerance = 1e-10)
})
