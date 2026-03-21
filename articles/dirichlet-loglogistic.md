# Dirichlet Distribution & Log-Logistic Survival

## Overview

Standard PSA uses Beta (utilities) and Gamma (costs). Two common
modelling situations need specialised distributions: **multinomial
transition probabilities** require the Dirichlet to maintain row-sum
constraints, and **diseases with hump-shaped hazards** need the
Log-Logistic survival model.

## Part A: Dirichlet for Transition Matrices

### The Problem

You are building a 3-state Markov model for Chronic Kidney Disease
(Stable → Progressed → Dead). From a cohort of 200 patients observed for
1 year starting in “Stable”:

- 150 remained Stable
- 35 progressed to CKD Stage 4
- 15 died

These three probabilities (0.75, 0.175, 0.075) **must sum to 1.0** in
every PSA iteration. If you sample them independently using three Beta
distributions, they will almost never sum to 1 — breaking the model.

### The Dirichlet Solution

The Dirichlet distribution is the multivariate generalisation of the
Beta. Its parameters are the observed counts:

$${\mathbf{α}} = (150,35,15)$$

Each sample from a Dirichlet is a complete probability vector that sums
to exactly 1.0.

### Sampling via Gamma Decomposition

ParCC uses the standard algorithm:

1.  Draw $X_{i} \sim \text{Gamma}\left( \alpha_{i},1 \right)$ for each
    state
2.  Compute $p_{i} = X_{i}/\sum_{j}X_{j}$
3.  The resulting $\left( p_{1},p_{2},p_{3} \right)$ is
    Dirichlet-distributed and sums to 1

### In ParCC

1.  Navigate to **Uncertainty (PSA)** and select **Dirichlet
    (Multinomial)**.
2.  Enter counts: **150, 35, 15**.
3.  Enter labels: **Stable, Progressed, Dead**.
4.  Click **Fit & Sample**.

ParCC displays the Dirichlet parameters, mean proportions, a bar chart
of sampled proportions, and a ready-to-use R code snippet for your PSA
loop.

### When to Use Dirichlet vs Independent Betas

| Situation                                      | Use                                    |
|------------------------------------------------|----------------------------------------|
| Single probability (e.g., utility, event rate) | Beta distribution                      |
| Two mutually exclusive outcomes                | Beta (one parameter determines both)   |
| Three or more mutually exclusive outcomes      | **Dirichlet** — guarantees row-sum = 1 |
| Transition matrix row in a Markov model        | **Dirichlet** for each row             |

## Part B: Log-Logistic Survival

### The Problem

You are modelling recovery after hip replacement surgery. The hazard of
revision is:

- Low immediately after surgery (close monitoring)
- Peaks around year 5–7 (implant loosening)
- Declines after year 10 (survivors have well-fixed implants)

Neither Exponential (constant hazard) nor Weibull (monotonic hazard) can
capture this **hump-shaped** pattern.

### The Log-Logistic Distribution

The survival function is:

$$S(t) = \frac{1}{1 + (t/\alpha)^{\beta}}$$

The hazard function is:

$$h(t) = \frac{(\beta/\alpha)(t/\alpha)^{\beta - 1}}{1 + (t/\alpha)^{\beta}}$$

When $\beta > 1$, the hazard rises to a peak then falls — exactly the
hump shape needed.

### In ParCC

From a published Kaplan-Meier curve, identify two time-survival points:

- Point 1: At Year 5, implant survival = **92%**
- Point 2: At Year 15, implant survival = **78%**

1.  Navigate to **Survival Curves \> Fit Survival Curve**.
2.  Select method: **Log-Logistic (From 2 Time Points)**.
3.  Enter the values.
4.  ParCC solves for α (scale) and β (shape).
5.  Verify β \> 1 in the output to confirm the expected hump-shaped
    hazard.

### Calibration Method

ParCC uses the log-odds transformation. Since
$S(t) = 1/\left( 1 + (t/\alpha)^{\beta} \right)$:

$$\ln\left( \frac{1 - S(t)}{S(t)} \right) = \beta\ln(t) - \beta\ln(\alpha)$$

Two points yield two equations, solved for α and β.

### Choosing the Right Survival Distribution

| Distribution     | Hazard Shape                         | Best For                                    |
|------------------|--------------------------------------|---------------------------------------------|
| Exponential      | Constant                             | Stable chronic conditions                   |
| Weibull          | Monotonic (increasing or decreasing) | Cancer mortality, device failure            |
| **Log-Logistic** | **Hump-shaped or decreasing**        | **Post-surgical revision, immune response** |

### Extrapolation Warning

As with all parametric survival models, extrapolation beyond the
observed data requires clinical justification. The Log-Logistic’s long
tail means it predicts higher long-term survival than the Weibull —
validate this against clinical expectations.

## References

1.  Briggs A, Claxton K, Sculpher M. *Decision Modelling for Health
    Economic Evaluation*. Oxford University Press; 2006. Chapter 4:
    Probabilistic Sensitivity Analysis.
2.  Collett D. *Modelling Survival Data in Medical Research*. 3rd
    ed. Chapman & Hall/CRC; 2015. Chapter 5: Log-Logistic Models.
3.  NICE Decision Support Unit Technical Support Document 14: Survival
    Analysis for Economic Evaluations Alongside Clinical Trials. 2013.
