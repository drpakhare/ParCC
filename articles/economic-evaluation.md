# Economic Evaluation: ICER, NMB, and Value-Based Pricing

## ICER (Incremental Cost-Effectiveness Ratio)

### The Formula

$$ICER = \frac{\Delta Cost}{\Delta Effect} = \frac{C_{intervention} - C_{comparator}}{E_{intervention} - E_{comparator}}$$

### The Scenario – New Diabetes Drug

A trial-based economic evaluation compares a new DPP-4 inhibitor to
metformin monotherapy over 5 years:

| Outcome    | Metformin  | DPP-4 Inhibitor |
|------------|------------|-----------------|
| Total Cost | INR 85,000 | INR 1,42,000    |
| QALYs      | 3.82       | 4.15            |

``` r
c_new <- 142000; c_old <- 85000
e_new <- 4.15; e_old <- 3.82

delta_c <- c_new - c_old
delta_e <- e_new - e_old
icer <- delta_c / delta_e

cat("Incremental Cost: INR", format(delta_c, big.mark = ","), "\n")
#> Incremental Cost: INR 57,000
cat("Incremental QALYs:", delta_e, "\n")
#> Incremental QALYs: 0.33
cat("ICER: INR", format(round(icer), big.mark = ","), "per QALY\n")
#> ICER: INR 172,727 per QALY
```

### Interpretation

The intervention falls in the **NE quadrant** (more costly, more
effective). Compare the ICER to the Willingness-to-Pay (WTP) threshold:

- If ICER \< WTP: Cost-effective
- If ICER \> WTP: Not cost-effective

## Net Monetary Benefit (iNMB)

### The Formula

$$iNMB = (\Delta E \times WTP) - \Delta C$$

iNMB \> 0 means cost-effective at the given WTP.

``` r
wtp <- 100000  # INR per QALY (HTAIn threshold)

inmb <- (delta_e * wtp) - delta_c
cat("iNMB at WTP INR 1,00,000/QALY: INR", format(round(inmb), big.mark = ","), "\n")
#> iNMB at WTP INR 1,00,000/QALY: INR -24,000

if (inmb > 0) {
  cat("Decision: Cost-effective (iNMB > 0)\n")
} else {
  cat("Decision: NOT cost-effective (iNMB < 0)\n")
}
#> Decision: NOT cost-effective (iNMB < 0)
```

## Value-Based Pricing (Headroom Analysis)

### The Scenario – SepsiQuick (Point-of-Care Test for Sepsis)

You are pricing a new rapid diagnostic test for sepsis. The evidence:

- **Clinical benefit:** 0.02 QALYs per patient (from faster treatment
  initiation)
- **Comparator cost:** INR 500 (existing lab-based test)
- **Associated costs:** INR 200 (nurse time for bedside testing)
- **WTP threshold:** INR 1,00,000 per QALY

### The Formulas

$$C_{max} = (\Delta E \times WTP) + C_{comparator}$$

$$P_{max} = \frac{C_{max} - C_{associated}}{N}$$

### Worked Example

``` r
delta_e_test <- 0.02
wtp_threshold <- 100000
c_comparator <- 500
c_associated <- 200
n_units <- 1

c_max <- (delta_e_test * wtp_threshold) + c_comparator
p_max <- (c_max - c_associated) / n_units

cat("Clinical Value: INR", format(delta_e_test * wtp_threshold, big.mark = ","), "\n")
#> Clinical Value: INR 2,000
cat("+ Savings from replacing old test: INR", format(c_comparator, big.mark = ","), "\n")
#> + Savings from replacing old test: INR 500
cat("= Total Headroom: INR", format(c_max, big.mark = ","), "\n")
#> = Total Headroom: INR 2,500
cat("- Nurse time: INR", format(c_associated, big.mark = ","), "\n")
#> - Nurse time: INR 200
cat("= Maximum Justifiable Price: INR", format(p_max, big.mark = ","), "\n")
#> = Maximum Justifiable Price: INR 2,300
```

### What If You Price Above the Headroom?

``` r
proposed_price <- 3000
overpriced_by <- ((proposed_price - p_max) / p_max) * 100

if (proposed_price > p_max) {
  cat("At INR", format(proposed_price, big.mark = ","),
      "the product is", round(overpriced_by, 1), "% above the maximum justifiable price.\n")
  cat("Recommendation: Reduce price by INR",
      format(proposed_price - p_max, big.mark = ","), "\n")
} else {
  cat("Price is within the cost-effective range.\n")
}
#> At INR 3,000 the product is 30.4 % above the maximum justifiable price.
#> Recommendation: Reduce price by INR 700
```

## References

- Drummond MF, et al. *Methods for the Economic Evaluation of Health
  Care Programmes*. 4th ed. Oxford University Press; 2015.
- Cosh E, et al. The value of ‘innovation headroom’. *Value in Health*.
  2007;10(4):312-315.
- HTAIn Methods Guide. Department of Health Research, Ministry of Health
  & Family Welfare, Government of India.
