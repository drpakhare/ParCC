# ParCC Tutorial Index

## ParCC Vignette Library

**ParCC (Parameter Converter & Calculator)** provides a comprehensive
set of tutorials organized by topic. Each vignette includes realistic
clinical scenarios, worked examples with R code, and references to the
underlying methodology.

### Getting Started

- **[`vignette("getting-started")`](https://drpakhare.github.io/ParCC/articles/getting-started.md)**
  – Installation, launching the app, and the Lab Notebook workflow

### Core Conversions

- **[`vignette("core-conversions")`](https://drpakhare.github.io/ParCC/articles/core-conversions.md)**
  – Rate to Probability, Odds to Probability, and Time Rescaling with
  real-world examples from the RE-LY trial and UKPDS Risk Engine

### Hazard Ratio Conversion (NEW in v1.3.0)

- **[`vignette("hr-probability-converter")`](https://drpakhare.github.io/ParCC/articles/hr-probability-converter.md)**
  – Converting control group probabilities to intervention probabilities
  using Hazard Ratios. Includes worked examples from the PLATO trial
  (Ticagrelor vs Aspirin) and oncology models.

### Survival Extrapolation

- **[`vignette("survival-extrapolation")`](https://drpakhare.github.io/ParCC/articles/survival-extrapolation.md)**
  – Fitting Exponential and Weibull survival curves from published
  Kaplan-Meier data when IPD is unavailable

### Background Mortality

- **[`vignette("background-mortality")`](https://drpakhare.github.io/ParCC/articles/background-mortality.md)**
  – SMR adjustment, DEALE, Gompertz parameterization, and linear
  interpolation for adjusting census life tables to disease-specific
  cohorts

### Probabilistic Sensitivity Analysis

- **[`vignette("psa-distributions")`](https://drpakhare.github.io/ParCC/articles/psa-distributions.md)**
  – Fitting Beta (utilities), Gamma (costs), and LogNormal (HRs)
  distributions using the Method of Moments. Includes the Rule of 4
  approximation.

### Economic Evaluation

- **[`vignette("economic-evaluation")`](https://drpakhare.github.io/ParCC/articles/economic-evaluation.md)**
  – ICER calculation, Net Monetary Benefit, and Value-Based Pricing
  (Headroom Analysis) with Indian HTA context

### Batch Processing

- **[`vignette("batch-workflow")`](https://drpakhare.github.io/ParCC/articles/batch-workflow.md)**
  – Uploading CSV files for bulk conversion, including the new HR-based
  batch conversion

## Key References

- **Sonnenberg FA, Beck JR.** Markov models in medical decision making.
  *Med Decis Making*. 1993;13(4):322-338.
- **Briggs A, Claxton K, Sculpher M.** *Decision Modelling for Health
  Economic Evaluation*. Oxford University Press; 2006.
- **Collett D.** *Modelling Survival Data in Medical Research*. 3rd
  ed. Chapman and Hall/CRC; 2015.
- **Drummond MF, et al.** *Methods for the Economic Evaluation of Health
  Care Programmes*. 4th ed. Oxford University Press; 2015.
- **Cosh E, et al.** The value of ‘innovation headroom’. *Value in
  Health*. 2007;10(4):312-315.
- **NICE DSU.** Technical Support Document 14: Survival analysis for
  economic evaluations. 2013.
