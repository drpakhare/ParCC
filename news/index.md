# Changelog

## ParCC 1.4.0

CRAN release: 2026-03-30

### New Modules

- **Budget Impact Analysis** – 5-year BIA framework with population
  sizing, uptake curves, and discounting (ISPOR Good Practice
  guidelines).
- **PPP Currency Converter** – Purchasing Power Parity conversion across
  30 countries (World Bank 2022 ICP data), market exchange rate
  comparison, and WHO-CHOICE WTP threshold assessment (1x and 3x GDP per
  capita).

### New Conversions

- **OR to RR / RR to OR** – Convert between Odds Ratios and Relative
  Risks using baseline risk (Zhang & Yu 1998 method).
- **Effect Size Transformations** – Convert between SMD and log(OR)
  using the Chinn (2000) formula for network meta-analysis preparation.
- **Standalone NNT/NNH Calculator** – Calculate Number Needed to Treat
  from four input modes: ARR, RR + baseline, OR + baseline, or direct
  probabilities.
- **Log-rank to HR** – Estimate Hazard Ratios from published log-rank
  chi-square or p-value using the Peto approximation.

### New Distributions and Models

- **Dirichlet Distribution** – Fit Dirichlet parameters for multinomial
  transition probabilities in Markov models (via Gamma decomposition).
- **Log-Logistic Survival** – Third survival extrapolation option with
  non-monotonic (hump-shaped) hazard support.
- **Annuity / PV Stream Calculator** – Present value of recurring annual
  costs (ordinary annuity and annuity due).

### Interface Improvements

- **Global Currency Selector** – Switch between INR, USD, EUR, GBP, JPY,
  BRL, THB, AUD, CAD, and custom currencies. All economic modules update
  automatically.
- **Interactive Tool Overview** – Collapsible accordion on the Home page
  with clickable tool items that navigate directly to the relevant
  module.
- **Restructured Navbar** – Explicit, user-friendly labels with logical
  groupings (Convert, Survival Curves, Costs & Outcomes, Learn).
- Five new pkgdown vignettes with worked examples.

## ParCC 1.3.0

### New Features

- **HR Converter Module** – Convert Hazard Ratios to time-dependent
  transition probabilities; compare multiple HRs simultaneously.
- **Enhanced Output Panels** – Step-by-step explanations, rendered
  MathJax formulas, and literature citations on every output panel.
- **Batch HR Conversion** – CSV upload for bulk HR-based conversions
  alongside existing rate and odds batch modes.
- **pkgdown Documentation Site** – Hosted at
  <https://drpakhare.github.io/ParCC/> with vignettes for all core
  workflows.

## ParCC 1.2.0

- Initial public release with core converters, survival extrapolation,
  PSA distributions, financial tools, ICER/NMB, VBP, diagnostics, and
  Lab Notebook.
