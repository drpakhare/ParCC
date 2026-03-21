# Getting Started with ParCC

## What is ParCC?

**ParCC (Parameter Converter & Calculator)** is a decision support tool
for Health Technology Assessment (HTA). It bridges the gap between
reported clinical statistics and the specific input parameters required
for health economic models such as Markov cohort models, decision trees,
and partitioned survival models.

## Installation

Install ParCC from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("drpakhare/ParCC")
```

## Launching the Application

``` r
library(ParCC)
run_app()
```

This opens a browser-based Shiny application with all calculation tools.

## The Lab Notebook Workflow

Reproducibility is critical in HTA. Every parameter in your model must
be traceable to its source and methodology. ParCC acts as your digital
logbook.

**The 4-Step Workflow:**

1.  **Label It:** Before calculating, type a specific name in the
    ‘Label’ box (e.g., “PFS Control Arm” or “Cost of Surgery - AIIMS
    2023”).

2.  **Calculate & Log:** Click the blue action button. This calculates
    the result AND saves it to your session log with a timestamp.

3.  **Review:** Navigate to the **Report** tab to see a table of all
    logged parameters.

4.  **Export:** Download the HTML Report. This document serves as a
    Technical Appendix for your manuscript or HTA dossier, complete with
    formulas and references.

## Application Overview

ParCC provides 12 calculation modules organized into four categories:

### Parameter Estimation

- **Converters** — Rate/Odds to Probability, Time Rescaling
- **HR Converter** — Apply Hazard Ratios from trials to convert control
  probabilities to intervention probabilities
- **Bulk Conversion** — Upload a CSV and convert an entire column
- **Survival Analysis** — Fit Exponential or Weibull curves from summary
  data
- **Background Mortality** — SMR adjustment, Gompertz fitting, DEALE,
  interpolation

### Uncertainty Analysis

- **PSA** — Fit Beta, Gamma, and LogNormal distributions for
  Probabilistic Sensitivity Analysis

### Financial Adjustments

- **Financial** — Inflation adjustment and discounting calculators

### Decision Outputs

- **Diagnostics** — Bayesian PPV/NPV
- **ICER & NMB** — Cost-effectiveness metrics
- **Value-Based Pricing** — Headroom analysis

## Next Steps

Explore the other vignettes for detailed tutorials:

- [`vignette("core-conversions")`](https://drpakhare.github.io/ParCC/articles/core-conversions.md)
  — Rates, Odds, and Time Rescaling
- [`vignette("hr-probability-converter")`](https://drpakhare.github.io/ParCC/articles/hr-probability-converter.md)
  — Applying Hazard Ratios
- [`vignette("survival-extrapolation")`](https://drpakhare.github.io/ParCC/articles/survival-extrapolation.md)
  — Fitting survival curves
- [`vignette("background-mortality")`](https://drpakhare.github.io/ParCC/articles/background-mortality.md)
  — Mortality adjustments
- [`vignette("psa-distributions")`](https://drpakhare.github.io/ParCC/articles/psa-distributions.md)
  — Parameterizing PSA
- [`vignette("economic-evaluation")`](https://drpakhare.github.io/ParCC/articles/economic-evaluation.md)
  — ICER, NMB, and VBP
- [`vignette("batch-workflow")`](https://drpakhare.github.io/ParCC/articles/batch-workflow.md)
  — Bulk CSV processing

## References

- Briggs A, Claxton K, Sculpher M. *Decision Modelling for Health
  Economic Evaluation*. Oxford University Press; 2006.
- Drummond MF, et al. *Methods for the Economic Evaluation of Health
  Care Programmes*. 4th ed. Oxford University Press; 2015.
