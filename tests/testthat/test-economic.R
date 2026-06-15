# Test economic calculation functions

test_that("discounting is correct", {
  # PV = FV / (1 + r)^t
  expect_equal(discount_pv(100, 0.03, 0), 100)
  expect_equal(discount_pv(100, 0.03, 1), 100 / 1.03, tolerance = 1e-10)
  expect_equal(discount_pv(100, 0.05, 10), 100 / 1.05^10, tolerance = 1e-10)
  # Zero discount rate preserves value
  expect_equal(discount_pv(500, 0, 20), 500)
})

test_that("ICER calculation is correct", {
  expect_equal(calc_icer(10000, 2), 5000)
  expect_equal(calc_icer(-5000, 1), -5000)
  expect_equal(calc_icer(0, 5), 0)
})

test_that("iNMB calculation is correct", {
  # iNMB = dE * WTP - dC
  expect_equal(calc_inmb(10000, 2, 50000), 2 * 50000 - 10000)
  # Cost-effective: iNMB > 0
  expect_true(calc_inmb(10000, 2, 50000) > 0)
  # Not cost-effective at low WTP
  expect_true(calc_inmb(10000, 2, 1000) < 0)
})

test_that("ICER and iNMB agree on cost-effectiveness", {
  d_cost <- 15000
  d_eff <- 0.5
  wtp <- 50000
  icer <- calc_icer(d_cost, d_eff)
  inmb <- calc_inmb(d_cost, d_eff, wtp)
  # If ICER < WTP, then iNMB > 0 (and vice versa)
  expect_equal(icer < wtp, inmb > 0)
})

test_that("PPP conversion is correct", {
  # US to India: cost_USD / PPP_US * PPP_India
  # PPP_US ~ 1 (reference), PPP_India ~ 22.88 (example)
  cost_usd <- 50000
  ppp_us <- 1
  ppp_india <- 22.88
  result <- ppp_convert(cost_usd, ppp_us, ppp_india)
  expect_equal(result, 50000 * 22.88, tolerance = 0.01)
})

test_that("PPP conversion with same country returns same value", {
  cost <- 1000
  ppp <- 15.5
  expect_equal(ppp_convert(cost, ppp, ppp), cost, tolerance = 1e-10)
})
