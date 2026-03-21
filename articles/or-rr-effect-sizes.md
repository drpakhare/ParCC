# OR ↔ RR Conversion & Effect Size Transformations

## Overview

Network Meta-Analysis (NMA) requires all treatment effects on a common
scale. However, trials report results as Odds Ratios, Relative Risks, or
Standardised Mean Differences depending on the outcome type. ParCC
provides bidirectional conversions to unify these metrics before
pooling.

## Tutorial: Preparing Data for an NMA in Depression

### The Scenario

You are conducting an NMA comparing three antidepressants. Your
systematic review found:

- **Trial A (Drug vs Placebo):** OR = 1.85 for “Response” (≥50%
  reduction in HAM-D). Baseline response in placebo arm = 30%.
- **Trial B (Drug vs Placebo):** RR = 1.42 for “Response”.
- **Trial C (Drug vs Placebo):** Reports a continuous outcome: SMD =
  0.45 (Cohen’s d) on HAM-D score.

To pool these in a single NMA, you need all three on the same scale.

### Step 1: Convert OR to RR (Zhang & Yu Method)

The Zhang & Yu (1998) formula accounts for baseline risk:

$$RR = \frac{OR}{1 - p_{0} + p_{0} \times OR}$$

where $p_{0}$ is the baseline risk in the control group.

**In ParCC:**

1.  Navigate to **Convert \> Rate ↔︎ Probability \> OR ↔︎ RR** tab.
2.  Select direction: **OR → RR**.
3.  Input OR = **1.85**, Baseline Risk = **0.30**.
4.  Result: **RR ≈ 1.42**.

### Why This Matters

If the outcome were rare (\<10%), OR ≈ RR and conversion wouldn’t
matter. But with a 30% baseline risk, the OR of 1.85 overstates the
effect compared to the RR of 1.42. Failing to convert would bias the
NMA.

### Step 2: Convert SMD to log(OR) (Chinn Method)

The Chinn (2000) approximation uses the logistic distribution:

$$\ln(OR) = SMD \times \frac{\pi}{\sqrt{3}} \approx SMD \times 1.8138$$

**In ParCC:**

1.  Switch to the **Effect Size Conversions** tab.
2.  Select direction: **SMD → log(OR)**.
3.  Input SMD = **0.45**.
4.  Result: log(OR) = **0.816**, i.e. OR ≈ **2.26**.

### Step 3: Convert log(OR) to log(RR)

To bring Trial C onto the RR scale (matching Trials A and B):

$$\ln(RR) = \ln\left( \frac{e^{\ln{(OR)}}}{1 - p_{0} + p_{0} \times e^{\ln{(OR)}}} \right)$$

ParCC chains the Chinn and Zhang & Yu methods automatically.

## When to Use These Conversions

| Scenario                                | Conversion                              | Method                                    |
|-----------------------------------------|-----------------------------------------|-------------------------------------------|
| NMA mixing binary effect measures       | OR → RR or RR → OR                      | Zhang & Yu (1998)                         |
| NMA mixing binary + continuous outcomes | SMD → log(OR)                           | Chinn (2000)                              |
| Clinical interpretation of OR           | OR → RR                                 | Zhang & Yu — RR is more intuitive         |
| Checking the rare-disease approximation | Compare OR and RR at your baseline risk | If they diverge \>10%, convert explicitly |

## The Rare-Disease Approximation

When the baseline risk is very low ($p_{0} < 0.10$), OR ≈ RR
mathematically. ParCC displays a note when this approximation holds. For
common outcomes (\>10%), always convert explicitly.

## References

1.  Zhang J, Yu KF. What’s the relative risk? A method of correcting the
    odds ratio in cohort studies of common outcomes. *JAMA*.
    1998;280(19):1690-1691.
2.  Chinn S. A simple method for converting an odds ratio to effect size
    for use in meta-analysis. *Statistics in Medicine*.
    2000;19(22):3127-3131.
3.  Cochrane Handbook for Systematic Reviews of Interventions, Chapter
    12: Synthesizing and presenting findings using other methods.
