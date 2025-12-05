# Tutorial

``` r
library(ParCC)
#> Warning: replacing previous import 'shiny::dataTableOutput' by
#> 'DT::dataTableOutput' when loading 'ParCC'
#> Warning: replacing previous import 'shiny::renderDataTable' by
#> 'DT::renderDataTable' when loading 'ParCC'
```

**ParCC (Parameter Converter & Calculator)** is designed to bridge the
gap between reported clinical statistics and the specific input
parameters required for Health Economic models.

This guide provides step-by-step tutorials for solving common modeling
challenges using the application.

## 1. The Lab Notebook Workflow

In Health Technology Assessment (HTA), reproducibility is critical.
ParCC acts as your digital logbook to ensure every parameter can be
audited.

1.  **Label It:** Before calculating, type a specific name in the
    ‘Label’ box (e.g., *“PFS Control Arm”* or *“Cost of Surgery”*).

2.  **Calculate & Log:** Click the blue action button. This calculates
    the result **AND** saves it to your temporary session log.

3.  **Review:** Go to the **Report** tab to see a table of all your
    logged parameters.

4.  **Export:** Download the HTML Report. This document serves as
    a **Technical Appendix** for your manuscript or HTA dossier.

## 2. Core Conversions

### Tutorial 1: The Safety Data Problem (Rates to Probabilities)

**The Context:** You are modeling a new anticoagulant. The key safety
endpoint is “Major Bleeding.”

**The Challenge:** The clinical trial reports the incidence rate
as: *“2.5 major bleeds per 100 patient-years.”*

**The Mistake:** Simply dividing 2.5 by 100 gives 0.025. This ignores
the fact that patients who bleed are removed from the “at-risk” pool
during the year.

**The ParCC Solution:**

1.  Navigate to **Converters \> Rate ↔︎ Probability**.

2.  Input Rate = `2.5`.

3.  Select Multiplier = `'Per 100'`.

4.  Input Time = `1` (for a 1-year model cycle).

5.  **Result:** `0.02469`. This is the precise annual probability for
    your Markov trace.

### Tutorial 2: The Cycle Mismatch (Time Rescaling)

**The Context:** You are using the **UKPDS Risk Engine** for a diabetes
model. It predicts the **10-year** risk of coronary heart disease (e.g.,
20%).

**The Challenge:** Your Markov model runs on **1-year** cycles. Dividing
20% by 10 (2% per year) is wrong because risk compounds over time.

**The ParCC Solution:**

1.  Navigate to **Converters \> Time Rescaling**.

2.  Input Original Probability = `0.20`.

3.  Input Original Time = `10` Years.

4.  Input New Time = `1` Year.

5.  **Result:** `0.0223` (approx 2.23%). Notice that the actual annual
    risk is higher than the simple average implies.

## 3. Advanced Modeling

### Tutorial 3: Extrapolating Survival Curves

**The Context:** You need to project outcomes over 20 years for an
oncology drug, but the trial only ran for 3 years. You do not have IPD,
only a published Kaplan-Meier curve.

**The ParCC Solution:**

1.  Look at the published curve. Pick two points that summarize the
    shape.

    - *Point 1:* At Month 12, survival is 80%.

    - *Point 2:* At Month 36, survival is 50%.

2.  Navigate to **Survival \> Weibull (From 2 Time Points)**.

3.  Input these values (`12, 0.8` and `36, 0.5`).

4.  **Result:** ParCC calculates the **Shape** and **Scale** parameters
    to extrapolate the curve.

5.  **Validation:** Check the plot to ensure the blue line passes
    through your points.

### Tutorial 4: The “Sick Cohort” Problem (SMR)

**The Context:** You are modeling Heart Failure patients aged 65. The
general population mortality rate for age 65 is `0.013`. Using this
would overestimate their life expectancy.

**The ParCC Solution:**

1.  Navigate to **Bg Mortality \> SMR Adjustment**.

2.  Input Base Rate = `0.013`.

3.  Input SMR (Hazard Ratio) from literature (e.g., `2.5`).

4.  **Result:** `0.032`. Use this adjusted probability for your “Natural
    Death” node.

## 4. Uncertainty & Pricing

### Tutorial 5: Parameterizing Costs (PSA)

**The Context:** You are running a Probabilistic Sensitivity Analysis
(PSA). A costing study reports the mean cost of surgery
is **₹25,000** (SE **₹5,000**).

**The Challenge:** Using a Normal distribution is incorrect because
costs are skewed and cannot be negative.

**The ParCC Solution:**

1.  Navigate to **PSA \> Gamma Distribution** (The standard for costs).

2.  Input Mean = `25000`, SE = `5000`.

3.  **Result:** ParCC calculates **Shape (k)** and **Scale
    (theta)** parameters.

4.  **Tip:** If SE is missing but you have a range (e.g., ₹15k - ₹35k),
    use the ‘Mean & Range’ option to estimate SE via the Rule of 4.

### Tutorial 6: Value-Based Pricing (Headroom Analysis)

**The Context:** Your new technology provides **0.5 additional
QALYs** but requires an expensive implantation surgery (**₹50,000**).
The government WTP threshold is **₹100,000 per QALY**. What is the
maximum price you can charge for the device?

**The ParCC Solution:**

1.  Navigate to **Value-Based Pricing**.

2.  Input Clinical Benefit (`0.5`) and WTP (`100000`).

3.  Input Associated Costs (`50000`).

4.  **Result:** The tool performs a ‘Headroom Analysis’.

    - **Total Value:** ₹50,000 (0.5 \* 100k).

    - **Headroom:** ₹50,000 (Value) - ₹50,000 (Surgery Cost) = **0**.

5.  **Outcome:** Even though the benefit is valuable, the surgery eats
    up the entire budget. The device price must be **₹0** to be
    cost-effective at this threshold.

## References

- **Sonnenberg FA, Beck JR.** Markov models in medical decision making:
  a practical guide. *Med Decis Making*. 1993;13(4):322-338.

- **Briggs A, Claxton K, Sculpher M.** *Decision Modelling for Health
  Economic Evaluation*. Oxford University Press; 2006.

- **Collett D.** *Modelling Survival Data in Medical Research*. 3rd
  ed. Chapman and Hall/CRC; 2015.

- **Cosh E, et al.** The value of ‘innovation headroom’. *Value in
  Health*. 2007;10(4):312-315.
