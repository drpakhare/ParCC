# HR-Based Probability Converter

## The Problem

One of the most common tasks in health economic modelling is converting
a **control group probability** to an **intervention group probability**
using a **Hazard Ratio (HR)** from a clinical trial. This arises
whenever:

- You have baseline event rates from a registry or observational study
- A trial reports relative treatment effects as HRs
- You need transition probabilities for both arms of a Markov model

A common mistake is to multiply the probability directly by the HR
(i.e., $p_{int} = p_{ctrl} \times HR$). This is mathematically incorrect
because the HR operates on the **instantaneous rate**, not on the
cumulative probability.

## The Three-Step Method

Under the **proportional hazards assumption** (the HR is constant over
time):

**Step 1: Convert control probability to rate**

$$r_{control} = - \frac{\ln\left( 1 - p_{control} \right)}{t}$$

**Step 2: Apply the Hazard Ratio**

$$r_{intervention} = r_{control} \times HR$$

**Step 3: Convert back to probability**

$$p_{intervention} = 1 - e^{- r_{intervention} \times t_{cycle}}$$

## Worked Example 1: PLATO Trial (Ticagrelor vs Aspirin)

The PLATO trial (Wallentin et al., NEJM 2009) compared Ticagrelor to
Aspirin in Acute Coronary Syndrome. Key results at 12 months:

| Endpoint       | Aspirin (Control) | HR (95% CI)        |
|----------------|-------------------|--------------------|
| CV Death       | 5.25%             | 0.79 (0.69 - 0.91) |
| MI             | 6.43%             | 0.84 (0.75 - 0.95) |
| Stroke         | 1.38%             | 1.01 (0.79 - 1.28) |
| Major Bleeding | 11.43%            | 1.04 (0.95 - 1.13) |

### CV Death Conversion

``` r
# PLATO trial - CV Death
p_control <- 0.0525   # 5.25% at 12 months
hr <- 0.79             # Ticagrelor vs Aspirin
t <- 1                 # 1 year

# Step 1: Probability -> Rate
r_control <- -log(1 - p_control) / t
cat("Step 1 - Control rate:", round(r_control, 5), "per year\n")
#> Step 1 - Control rate: 0.05393 per year

# Step 2: Apply HR
r_intervention <- r_control * hr
cat("Step 2 - Intervention rate:", round(r_intervention, 5), "per year\n")
#> Step 2 - Intervention rate: 0.0426 per year

# Step 3: Rate -> Probability
p_intervention <- 1 - exp(-r_intervention * t)
cat("Step 3 - Intervention probability:", round(p_intervention, 5), "\n\n")
#> Step 3 - Intervention probability: 0.04171

# Compare with naive method
p_naive <- p_control * hr
cat("Correct method:", round(p_intervention, 5), "\n")
#> Correct method: 0.04171
cat("Naive (p x HR):", round(p_naive, 5), "\n")
#> Naive (p x HR): 0.04147
cat("Difference:", round((p_intervention - p_naive) * 10000, 2), "per 10,000 patients\n")
#> Difference: 2.34 per 10,000 patients
```

### With 95% Confidence Interval

``` r
# Apply CI bounds
hr_low <- 0.69
hr_high <- 0.91

p_low <- 1 - exp(-r_control * hr_low * t)
p_high <- 1 - exp(-r_control * hr_high * t)

cat("Intervention probability: ", round(p_intervention, 5),
    " (95% CI:", round(p_low, 5), "to", round(p_high, 5), ")\n")
#> Intervention probability:  0.04171  (95% CI: 0.03653 to 0.04789 )

# Clinical impact
arr <- p_control - p_intervention
nnt <- ceiling(1 / arr)
cat("ARR:", round(arr * 100, 2), "%\n")
#> ARR: 1.08 %
cat("NNT:", nnt, "\n")
#> NNT: 93
```

## Worked Example 2: High Event Rate (Oncology)

The error from naive multiplication grows with higher event rates.
Consider an oncology model where the control arm 2-year mortality is
40%:

``` r
p_control_onc <- 0.40
hr_onc <- 0.75
t_onc <- 2

# Correct method
r_ctrl <- -log(1 - p_control_onc) / t_onc
r_int <- r_ctrl * hr_onc
p_int_correct <- 1 - exp(-r_int * t_onc)

# Naive method
p_int_naive <- p_control_onc * hr_onc

cat("Control 2-year mortality:", p_control_onc, "\n")
#> Control 2-year mortality: 0.4
cat("HR:", hr_onc, "\n\n")
#> HR: 0.75
cat("Correct intervention probability:", round(p_int_correct, 4), "\n")
#> Correct intervention probability: 0.3183
cat("Naive (p x HR):", round(p_int_naive, 4), "\n")
#> Naive (p x HR): 0.3
cat("Error:", round(abs(p_int_correct - p_int_naive) * 100, 2), "percentage points\n")
#> Error: 1.83 percentage points
cat("This affects", round(abs(p_int_correct - p_int_naive) * 10000), "patients per 10,000\n")
#> This affects 183 patients per 10,000
```

## Worked Example 3: Rescaling to Monthly Cycles

Often you need monthly transition probabilities for your Markov model.
You can combine HR conversion with time rescaling:

``` r
# PLATO CV Death, but for a monthly model
p_annual_ctrl <- 0.0525
hr <- 0.79

# Convert annual probability to rate
r_ctrl <- -log(1 - p_annual_ctrl) / 1
r_int <- r_ctrl * hr

# Convert to monthly probabilities
t_month <- 1/12
p_monthly_ctrl <- 1 - exp(-r_ctrl * t_month)
p_monthly_int <- 1 - exp(-r_int * t_month)

cat("Monthly control probability:", round(p_monthly_ctrl, 6), "\n")
#> Monthly control probability: 0.004484
cat("Monthly intervention probability:", round(p_monthly_int, 6), "\n")
#> Monthly intervention probability: 0.003544
```

## Batch Conversion

For models with multiple health states and transitions, you can upload a
CSV with control probabilities and HRs. Navigate to **Bulk Conversion**
in ParCC and select “HR -\> Intervention Probability”.

### Example CSV format:

    Endpoint,Control_Prob,Hazard_Ratio,Time_Horizon
    CV Death,0.0525,0.79,1
    MI,0.0643,0.84,1
    Stroke,0.0138,1.01,1
    Major Bleeding,0.1143,1.04,1

## Multi-HR Comparison

Use the **Multi-HR Comparison** tab to evaluate how different HRs from
subgroup analyses or network meta-analyses translate into absolute
probabilities. This is useful for:

- Comparing multiple drugs against a common control
- Exploring subgroup-specific treatment effects
- Sensitivity analysis on the HR

## Key Assumptions and Limitations

1.  **Proportional Hazards:** The HR is assumed constant over time. If
    the Kaplan-Meier curves cross, this assumption is violated and
    alternative methods (e.g., piecewise HRs) should be considered.

2.  **Exponential within cycle:** The conversion assumes exponential
    survival within each model cycle. This is standard practice for
    short cycles (1 month, 1 year) but may be less appropriate for very
    long cycles.

3.  **Independent events:** The conversion treats each event
    independently. For competing risks models, additional adjustments
    may be needed.

## References

- Wallentin L, et al. Ticagrelor versus clopidogrel in patients with
  acute coronary syndromes. *N Engl J Med*. 2009;361(11):1045-1057.
- Sonnenberg FA, Beck JR. Markov models in medical decision making. *Med
  Decis Making*. 1993;13(4):322-338.
- Briggs A, Claxton K, Sculpher M. *Decision Modelling for Health
  Economic Evaluation*. Oxford University Press; 2006.
- Fleurence RL, Hollenbeak CS. Rates and probabilities in economic
  modelling. *Pharmacoeconomics*. 2007;25(1):3-12.
- NICE Decision Support Unit. Technical Support Document 14: Survival
  analysis for economic evaluations alongside clinical trials. 2013.
