# Test core parameter conversions
# These verify the mathematical functions that underlie ParCC's Shiny modules.

test_that("rate to probability conversion is correct", {
  # p = 1 - exp(-r * t)
  expect_equal(rate_to_prob(0.1, 1), 1 - exp(-0.1), tolerance = 1e-10)
  expect_equal(rate_to_prob(0.05, 2), 1 - exp(-0.1), tolerance = 1e-10)
  # Zero rate gives zero probability

  expect_equal(rate_to_prob(0, 1), 0)
  # High rate approaches 1

  expect_true(rate_to_prob(10, 1) > 0.99)
})

test_that("probability to rate conversion is correct", {
  # r = -ln(1 - p) / t
  expect_equal(prob_to_rate(0.1, 1), -log(0.9), tolerance = 1e-10)
  expect_equal(prob_to_rate(0.5, 1), log(2), tolerance = 1e-10)
})

test_that("rate-probability round-trip is identity", {
  for (r in c(0.01, 0.05, 0.1, 0.5, 1.0)) {
    p <- rate_to_prob(r, 1)
    r_back <- prob_to_rate(p, 1)
    expect_equal(r_back, r, tolerance = 1e-10)
  }
})

test_that("odds-probability conversions are correct", {
  expect_equal(odds_to_prob(1), 0.5)
  expect_equal(odds_to_prob(3), 0.75)
  expect_equal(odds_to_prob(0), 0)
  expect_equal(prob_to_odds(0.5), 1)
  expect_equal(prob_to_odds(0.75), 3)
})

test_that("odds-probability round-trip is identity", {
  for (p in c(0.1, 0.25, 0.5, 0.75, 0.9)) {
    o <- prob_to_odds(p)
    p_back <- odds_to_prob(o)
    expect_equal(p_back, p, tolerance = 1e-10)
  }
})

test_that("probability time rescaling is correct", {
  # 1-year prob rescaled to 6-month cycle
  p_annual <- 0.1
  p_half <- rescale_prob(p_annual, 1, 0.5)
  # Verify: applying half-year prob twice recovers annual
  p_recovered <- 1 - (1 - p_half)^2
  expect_equal(p_recovered, p_annual, tolerance = 1e-10)
})

test_that("OR to RR conversion (Zhang and Yu) is correct", {
  # When baseline risk is low, OR ~ RR
  expect_equal(or_to_rr(1.5, 0.01), 1.5, tolerance = 0.01)
  # Known example: OR = 2, p0 = 0.5, RR should be 4/3
  expect_equal(or_to_rr(2, 0.5), 2 / (1 - 0.5 + 0.5 * 2), tolerance = 1e-10)
  # OR = 1 gives RR = 1 regardless of baseline
  expect_equal(or_to_rr(1, 0.3), 1, tolerance = 1e-10)
})

test_that("RR to OR round-trip is identity", {
  for (p0 in c(0.05, 0.1, 0.3, 0.5)) {
    or_in <- 2.5
    rr <- or_to_rr(or_in, p0)
    or_back <- rr_to_or(rr, p0)
    expect_equal(or_back, or_in, tolerance = 1e-10)
  }
})

test_that("Chinn SMD-logOR conversions are correct", {
  # log(OR) = SMD * pi / sqrt(3)
  expect_equal(smd_to_log_or(1), pi / sqrt(3), tolerance = 1e-10)
  expect_equal(smd_to_log_or(0), 0)
  # Round-trip
  for (smd in c(-1, -0.5, 0, 0.5, 1, 2)) {
    expect_equal(log_or_to_smd(smd_to_log_or(smd)), smd, tolerance = 1e-10)
  }
})
