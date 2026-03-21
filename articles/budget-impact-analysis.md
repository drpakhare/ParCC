# Budget Impact Analysis

## Overview

A Budget Impact Analysis (BIA) estimates the financial consequences of
adopting a new health technology from the **payer’s perspective** over a
short time horizon (typically 1-5 years). Unlike cost-effectiveness
analysis, BIA focuses on **affordability**, not value for money. ParCC
implements the ISPOR BIA Good Practice framework.

## Tutorial: 5-Year BIA for a New Oral Anticoagulant

### The Scenario

You are advising a state health insurance programme on adopting a new
oral anticoagulant (NOAC) to replace warfarin for Atrial Fibrillation.

| Parameter                    | Value                                                 |
|------------------------------|-------------------------------------------------------|
| Covered population           | 10,000,000 enrolees                                   |
| AF prevalence                | 0.8% (80,000 patients)                                |
| Eligible for anticoagulation | 60% of AF patients (48,000)                           |
| Uptake trajectory            | Yr 1: 10%, Yr 2: 25%, Yr 3: 45%, Yr 4: 60%, Yr 5: 70% |
| Current therapy (warfarin)   | INR 8,000/patient/year (drug + INR monitoring)        |
| New therapy (NOAC)           | INR 22,000/patient/year (drug only)                   |
| Discount rate                | 3% per year                                           |

### The Framework

The BIA compares two scenarios:

- **Current scenario:** All eligible patients receive warfarin.
- **New scenario:** A proportion (based on uptake) switch to the NOAC;
  the rest stay on warfarin.

$$BI_{t} = N_{target} \times Uptake_{t} \times \left( C_{new} - C_{current} \right) \times \frac{1}{(1 + r)^{t - 1}}$$

### In ParCC

1.  Navigate to **Costs & Outcomes \> Budget Impact Analysis**.
2.  Enter Population = **10,000,000**.
3.  Enter Prevalence = **0.8%**, Eligible = **60%**.
4.  Enter uptake: **10, 25, 45, 60, 70**.
5.  Enter Per-Patient Cost (New) = **22,000**, (Current) = **8,000**.
6.  Set Discount Rate = **3%**.
7.  Click **Calculate BIA**.

### Reading the Output

ParCC produces:

- **Target population:** 48,000 eligible patients (fixed each year).
- **Year-by-year table:** Shows patients on each therapy, costs under
  both scenarios, and the incremental budget impact (undiscounted and
  discounted).
- **Stacked bar + line chart:** Bars show costs under each scenario; the
  red line shows the incremental budget impact.
- **5-year cumulative total:** The discounted sum represents the
  additional budget the insurer needs to allocate.

### Interpreting Year 1

- 4,800 patients switch (10% uptake)
- Incremental cost per patient: INR 22,000 - INR 8,000 = INR 14,000
- Year 1 budget impact: 4,800 x INR 14,000 = INR 67.2 million

## Key Modelling Decisions

### Time Horizon

ISPOR recommends **1-5 years**, matching the payer’s budget cycle.
Longer horizons introduce too much uncertainty in uptake projections.

### Uptake Trajectory

Real-world adoption follows an S-curve, not instant switching.
Conservative estimates in early years are more credible. ParCC allows
independent specification for each year.

### Discounting

The primary BIA should be **undiscounted** (set rate to 0%) since payers
care about actual cash flows. Discounted results can be presented as a
secondary analysis for consistency with CEA.

### Population Dynamics

ParCC uses a static population (same eligible count each year). For
diseases with significant incidence/mortality, a dynamic population
model may be needed – this is beyond ParCC’s current scope.

## ISPOR Good Practice Checklist

The ISPOR 2012 Task Force recommends:

1.  Use a short time horizon matching the payer’s budget cycle
2.  Model uptake realistically (not instant switching)
3.  Include only direct costs relevant to the payer perspective
4.  Present undiscounted results as primary analysis
5.  Run scenario analyses on uptake rates and eligible population
6.  Report year-by-year results, not just cumulative totals

## References

1.  Sullivan SD, Mauskopf JA, Augustovski F, et al. Budget impact
    analysis – principles of good practice: report of the ISPOR 2012
    Budget Impact Analysis Good Practice II Task Force. *Value in
    Health*. 2014;17(1):5-14.
2.  Mauskopf JA, Sullivan SD, Annemans L, et al. Principles of good
    practice for budget impact analysis: report of the ISPOR Task Force
    on Good Research Practices. *Value in Health*. 2007;10(5):336-347.
