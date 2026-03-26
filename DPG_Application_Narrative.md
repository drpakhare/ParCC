# ParCC — Digital Public Goods Application Narrative

**Nominee:** ParCC (Parameter Converter & Calculator for Health
Technology Assessment) **Version:** 1.4.0 **Type:** Open-Source Software
**Submitting Organisation:** Regional Resource Centre for Health
Technology Assessment (RRC-HTA), All India Institute of Medical Sciences
(AIIMS), Bhopal, India **Contact:** Abhijit Pakhare,
<drpakhare@gmail.com>

------------------------------------------------------------------------

## Indicator 1: SDG Relevance

### Primary SDG: Goal 3 — Good Health and Well-being

**Target 3.8: Achieve universal health coverage (UHC), including
financial risk protection, access to quality essential health-care
services and access to safe, effective, quality and affordable essential
medicines and vaccines for all.**

ParCC directly supports the analytical infrastructure required for UHC
implementation. Health Technology Assessment (HTA) is the evidence-based
process by which countries decide which health technologies — drugs,
diagnostics, devices, procedures — to include in publicly funded benefit
packages. Every UHC decision involves comparing the costs and health
outcomes of competing technologies, which requires mathematical
parameter transformations: converting clinical trial results (rates,
hazard ratios, odds ratios, survival curves) into the transition
probabilities, distribution parameters, and cost estimates that
decision-analytic models consume.

In low- and middle-income countries (LMICs), HTA capacity is constrained
by limited access to commercial modelling software (which carries
substantial licensing fees), shortage of trained health economists, and
fragmented analytical workflows that undermine reproducibility. ParCC
addresses all three barriers by providing a free, browser-based platform
that automates routine HTA calculations while embedding methodological
education in every output.

Specific contributions to Target 3.8: - Enables evidence-based
priority-setting for national essential medicines lists and benefit
packages - Supports budget impact analysis to assess the affordability
of new health technologies - Facilitates cross-country cost
transferability through purchasing power parity conversion, essential
for adapting economic evidence generated in high-income countries to
LMIC contexts - Builds local HTA capacity through pedagogical output
design (step-by-step explanations, formulas, citations with every
calculation)

**Target 3.b: Support the research and development of vaccines and
medicines for the communicable and non-communicable diseases that
primarily affect developing countries.**

HTA evidence informs R&D investment decisions by quantifying the value
of new health technologies. ParCC’s value-based pricing module enables
researchers in developing countries to independently assess the maximum
justifiable price for new interventions, reducing reliance on pricing
analyses generated in high-income settings.

### Secondary SDG: Goal 17 — Partnerships for the Goals

**Target 17.6: Enhance North-South, South-South and triangular regional
and international cooperation on and access to science, technology and
innovation.**

ParCC is developed in India under the HTAIn programme (Department of
Health Research, Government of India) and designed for adoption across
the Regional Resource Centre network. Its open-source availability
enables South-South transfer of HTA methodology and tools. The PPP
Currency Converter with 30-country coverage specifically facilitates
cross-country evidence adaptation.

------------------------------------------------------------------------

## Indicator 2: Open Licensing

**License:** MIT License

**Evidence:** - LICENSE file in repository:
<https://github.com/drpakhare/ParCC/blob/master/LICENSE> - DESCRIPTION
file specifying `License: MIT + file LICENSE`:
<https://github.com/drpakhare/ParCC/blob/master/DESCRIPTION>

The MIT License is an OSI-approved open-source license that permits
unrestricted use, modification, distribution, and commercial use with
attribution. It is listed among the DPG Standard’s approved licenses for
software.

------------------------------------------------------------------------

## Indicator 3: Clear Ownership

**Owner:** Regional Resource Centre for Health Technology Assessment
(RRC-HTA), Department of Community and Family Medicine, All India
Institute of Medical Sciences (AIIMS), Bhopal, India.

**Developed under:** Health Technology Assessment in India (HTAIn)
programme, Department of Health Research (DHR), Ministry of Health and
Family Welfare (MoHFW), Government of India.

**Evidence:** - Copyright notice in LICENSE file: “Copyright (c) 2025
RRC-HTA Team, AIIMS Bhopal” - About page in the application credits the
development team and institutional affiliation - GitHub repository
maintained by principal investigator:
<https://github.com/drpakhare/ParCC> - AIIMS Bhopal is a publicly funded
Institute of National Importance under the Government of India

------------------------------------------------------------------------

## Indicator 4: Platform Independence

ParCC is built entirely on open-source technologies with no mandatory
proprietary dependencies.

**Core stack:** - R (open source, GPL-2/GPL-3) — runtime environment -
Shiny (open source, GPL-3) — web application framework - ggplot2,
plotly, DT, rmarkdown, magrittr (all open source) — supporting packages

**Deployment options (all open):** - Local R installation on any
operating system (Windows, macOS, Linux) - Any Shiny-compatible hosting
platform (Shiny Server Open Source, Posit Connect, ShinyApps.io,
self-hosted) - No database dependency — all reference data (PPP factors,
life tables) is embedded as static data within the package

**Browser requirements:** Any modern web browser (Chrome, Firefox,
Safari, Edge). No browser plugins or extensions required.

**No closed components exist.** The entire source code is publicly
available and can be built, modified, and deployed without any
proprietary software or services.

------------------------------------------------------------------------

## Indicator 5: Documentation

ParCC provides comprehensive documentation at multiple levels.

**Source code:** - Complete R package source:
<https://github.com/drpakhare/ParCC> - Modular architecture with named
modules (`mod_core_conv`, `mod_hr_converter`, `mod_survival`, `mod_psa`,
`mod_bia`, `mod_ppp`, etc.) - R documentation for all exported functions
(accessible via
[`?run_app`](https://drpakhare.github.io/ParCC/reference/run_app.md) in
R)

**User documentation (pkgdown site):** -
<https://drpakhare.github.io/ParCC/> - 13 vignettes with worked examples
covering all modules - Topics include: getting started, core
conversions, HR conversion, survival extrapolation, background
mortality, PSA distributions, economic evaluation, batch workflow,
OR-RR/effect sizes, NNT/log-rank, budget impact, Dirichlet/Log-Logistic,
PPP converter - Each vignette uses realistic clinical scenarios from
published trials (PLATO, RE-LY, UKPDS, CheckMate)

**In-application documentation:** - Formula Reference tab listing all
mathematical equations with derivations and citations - Tutorial tab
with step-by-step guides for each module - Every calculation output
includes: plain-English explanation, rendered LaTeX formula, and
literature citations

**Installation instructions:** -
`remotes::install_github("drpakhare/ParCC")` — one-line installation
from GitHub - Package submitted to CRAN for further accessibility

------------------------------------------------------------------------

## Indicator 6: Data Extraction Mechanism

ParCC supports data import and export in non-proprietary formats.

**Export capabilities:** - Batch processing module: CSV download of all
converted parameters - Lab Notebook: HTML download of complete session
audit trail (all inputs, outputs, formulas, timestamps, citations) -
Comparison tables (PPP, BIA): CSV download via DT (DataTables)
interface - All plots: Interactive (plotly) with built-in PNG/SVG export

**Import capabilities:** - Batch module accepts CSV upload for bulk
conversions (rate-probability, odds-probability, HR-based) - All input
is through the browser interface — no proprietary file formats required

**No personally identifiable information is collected, stored, or
processed.** ParCC is a computational tool that operates on mathematical
parameters (rates, probabilities, costs). It does not handle patient
data, clinical records, or any PII.

------------------------------------------------------------------------

## Indicator 7: Privacy and Applicable Laws

**ParCC does not collect, store, transmit, or process any personally
identifiable information (PII).**

The application is a computational calculator that accepts mathematical
inputs (rates, probabilities, hazard ratios, costs) and returns
calculated outputs. It has:

- No user accounts or authentication
- No data storage beyond the browser session
- No analytics, tracking, or telemetry
- No cookies (beyond standard Shiny session management)
- No external API calls (all reference data is embedded statically)
- No server-side logging of user inputs

**When deployed locally** (via
[`run_app()`](https://drpakhare.github.io/ParCC/reference/run_app.md)),
all computation occurs on the user’s own machine. No data leaves the
local environment.

**When deployed on a hosted server**, standard web server logs may
record IP addresses per the hosting provider’s policies, but the ParCC
application itself does not initiate or control any data collection.

**Applicable laws considered:** - Information Technology Act, 2000
(India) — no PII processing, therefore no compliance obligation under
the IT (Reasonable Security Practices) Rules - GDPR (EU) — no personal
data processing; no data controller/processor role - HIPAA (US) — no
protected health information involved

------------------------------------------------------------------------

## Indicator 8: Standards and Best Practices

### Health Technology Assessment Standards

ParCC implements methods from the established HTA methodology
literature:

- **Rate-probability conversion:** Fleurence & Hollenbeak (2007),
  Pharmacoeconomics
- **HR-based conversion:** Proportional hazards assumption per Collett
  (2015)
- **OR-to-RR:** Zhang & Yu (1998), JAMA — <doi:10.1001/jama.280.19.1690>
- **Effect size transformation:** Chinn (2000), Statistics in Medicine
- **Survival extrapolation:** Latimer (2013), NICE DSU TSD 14
- **PSA distribution fitting:** Briggs, Claxton & Sculpher (2006),
  Oxford University Press
- **Budget impact analysis:** Sullivan et al. (2014), ISPOR BIA Good
  Practice II Task Force
- **Cost-effectiveness reporting:** CHEERS 2022 Statement (Husereau et
  al., BMJ 2022)
- **Indian HTA guidelines:** HTAIn Reference Case for Economic
  Evaluation (DHR, 2023)
- **PPP methodology:** World Bank International Comparison Program (ICP)
  2022
- **WTP thresholds:** WHO-CHOICE framework

### Software Development Standards

- **R package standards:** Passes R CMD check with 0 errors, 0 warnings,
  0 notes
- **CRAN compliance:** Package submitted to the Comprehensive R Archive
  Network following all CRAN policies
- **Version control:** Git with public GitHub repository
- **Documentation:** roxygen2 for function documentation, pkgdown for
  website generation, knitr for vignettes
- **Validation:** 51 test cases with independent Excel verification
  (supplementary material)
- **Modular architecture:** Shiny moduleServer pattern for
  maintainability

### Open Standards

- **Data formats:** CSV for import/export (RFC 4180)
- **Documentation:** HTML (W3C), Markdown
- **Mathematical notation:** LaTeX via MathJax
- **Licensing:** SPDX-identified (MIT)

------------------------------------------------------------------------

## Indicator 9: Do No Harm by Design

### Data Privacy and Security

- **No PII collection:** ParCC processes only mathematical parameters,
  never patient or personal data
- **No persistent storage:** All session data exists only in browser
  memory during active use
- **No external data transmission:** All reference data (PPP factors,
  exchange rates, GDP figures) is embedded within the package; no API
  calls are made
- **Local deployment option:** For sensitive analytical work, users can
  run ParCC entirely on their own machine with no network connectivity
  required

### Accuracy and Validation

Given that ParCC outputs may inform health resource allocation
decisions, computational accuracy is a safety concern. Mitigation
measures include:

- **51-case validation protocol:** Test cases covering all 16 analytical
  capabilities, verified against independent Excel calculations to 5
  decimal places
- **Published methodology only:** Every formula is traceable to
  peer-reviewed literature with citations displayed alongside results
- **Transparency by design:** The four-layer output architecture
  (result, explanation, formula, citation) enables users to verify every
  calculation step rather than trusting a black box
- **Explicit disclaimers:** The About page states: “This tool is
  intended for research and educational purposes only. The developers
  accept no liability for errors or omissions in the calculations or for
  decisions made based on these results. Users are encouraged to verify
  critical parameters manually.”

### Preventing Misuse

- ParCC is a parameter conversion and calculation tool, not a
  decision-making system. It does not recommend treatment choices, drug
  approvals, or policy actions.
- All outputs include methodological context explaining assumptions and
  limitations (e.g., the proportional hazards assumption for HR
  conversion, the static population assumption for BIA).
- The Lab Notebook audit trail promotes accountability by documenting
  exactly what was calculated and how.

### Content and Interaction

- ParCC is not a social platform and has no user-to-user interaction
  features
- No user-generated content, messaging, or community features exist
- No content moderation is required as the tool produces only
  mathematical outputs

------------------------------------------------------------------------

## Summary

ParCC is a free, open-source, browser-based platform that automates the
routine mathematical operations required for Health Technology
Assessment. It directly supports SDG 3 (Good Health and Well-being) by
enabling evidence-based health resource allocation decisions,
particularly in low- and middle-income countries where commercial HTA
software is inaccessible. The platform combines computation with
embedded methodological education, building local analytical capacity
alongside immediate practical utility. It collects no personal data,
depends on no proprietary software, and is validated against 51
independent test cases. Developed under India’s national HTA programme
(HTAIn) and released under the MIT license, ParCC is designed for
adoption across the global HTA community.

------------------------------------------------------------------------

## Key URLs

| Resource         | URL                                                                       |
|------------------|---------------------------------------------------------------------------|
| Live application | <https://019d0dce-b522-bb76-f20b-8cfa598859a4.share.connect.posit.cloud/> |
| Documentation    | <https://drpakhare.github.io/ParCC/>                                      |
| Source code      | <https://github.com/drpakhare/ParCC>                                      |
| License          | <https://github.com/drpakhare/ParCC/blob/master/LICENSE>                  |
| Vignettes        | <https://drpakhare.github.io/ParCC/articles/>                             |
| Bug reports      | <https://github.com/drpakhare/ParCC/issues>                               |
