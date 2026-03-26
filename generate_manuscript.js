const { Document, Packer, Paragraph, TextRun, Table, TableCell, TableRow, BorderStyle, VerticalAlign, ShadingType, UnderlineType, PageBreak, Footer, PageNumber, Header, convertInchesToTwip, AlignmentType, HeadingLevel, UnorderedList, LevelFormat } = require('docx');
const fs = require('fs');

const MARGINS = {
  top: convertInchesToTwip(1),
  bottom: convertInchesToTwip(1),
  left: convertInchesToTwip(1),
  right: convertInchesToTwip(1)
};

// Helper function for body text with proper spacing
const bodyText = (text, options = {}) => {
  return new Paragraph({
    text: text,
    style: 'Normal',
    font: 'Arial',
    size: 24,
    alignment: AlignmentType.JUSTIFIED,
    spacing: { line: 276, lineRule: 'auto' },
    ...options
  });
};

// Helper for section headings
const sectionHeading = (text) => {
  return new Paragraph({
    text: text,
    style: 'Heading',
    font: 'Arial',
    size: 28,
    bold: true,
    alignment: AlignmentType.LEFT,
    spacing: { before: 240, after: 120, line: 276, lineRule: 'auto' }
  });
};

// Helper for subsection headings
const subsectionHeading = (text) => {
  return new Paragraph({
    text: text,
    font: 'Arial',
    size: 24,
    bold: true,
    alignment: AlignmentType.LEFT,
    spacing: { before: 120, after: 80, line: 276, lineRule: 'auto' }
  });
};

// Create table with standard formatting
const createTable = (rows, options = {}) => {
  return new Table({
    width: { size: 100, type: 'pct' },
    rows: rows,
    borders: {
      top: { style: BorderStyle.SINGLE, size: 1, color: '000000' },
      bottom: { style: BorderStyle.SINGLE, size: 1, color: '000000' },
      left: { style: BorderStyle.SINGLE, size: 1, color: '000000' },
      right: { style: BorderStyle.SINGLE, size: 1, color: '000000' },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 1, color: '000000' },
      insideVertical: { style: BorderStyle.SINGLE, size: 1, color: '000000' }
    },
    ...options
  });
};

// Create header cell
const headerCell = (text) => {
  return new TableCell({
    children: [new Paragraph({
      text: text,
      font: 'Arial',
      size: 22,
      bold: true,
      alignment: AlignmentType.CENTER,
      color: 'FFFFFF'
    })],
    shading: { type: ShadingType.CLEAR, fill: 'D5E8F0', color: 'FFFFFF' },
    verticalAlign: VerticalAlign.CENTER,
    margins: { top: 100, bottom: 100, left: 100, right: 100 }
  });
};

// Create regular cell
const regularCell = (text) => {
  return new TableCell({
    children: [new Paragraph({
      text: text,
      font: 'Arial',
      size: 22,
      alignment: AlignmentType.LEFT
    })],
    margins: { top: 80, bottom: 80, left: 80, right: 80 },
    verticalAlign: VerticalAlign.TOP
  });
};

// Build document content
const content = [
  // ============ TITLE PAGE ============
  new Paragraph({
    text: 'ParCC: An Integrated Web-Based Platform for Parameter Conversion, Economic Analysis, and Methodological Training in Health Technology Assessment',
    font: 'Arial',
    size: 32,
    bold: true,
    alignment: AlignmentType.CENTER,
    spacing: { after: 240, line: 360, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Tool Description — Version 1.4',
    font: 'Arial',
    size: 24,
    alignment: AlignmentType.CENTER,
    spacing: { after: 360, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Regional Resource Centre for Health Technology Assessment',
    font: 'Arial',
    size: 22,
    alignment: AlignmentType.CENTER,
    spacing: { after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'All India Institute of Medical Sciences, Bhopal',
    font: 'Arial',
    size: 22,
    alignment: AlignmentType.CENTER,
    spacing: { after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Under the aegis of HTAIn, DHR, MoHFW, Government of India',
    font: 'Arial',
    size: 22,
    alignment: AlignmentType.CENTER,
    spacing: { after: 600, line: 276, lineRule: 'auto' }
  }),

  new PageBreak(),

  // ============ ABSTRACT ============
  sectionHeading('ABSTRACT'),

  bodyText('ParCC (Parameter Conversion and Cost Calculator) is an open-source, web-based platform designed to support applied health technology assessment (HTA) at academic and policy-making levels. Building on the release of version 1.3, version 1.4 introduces cross-country cost transferability through purchasing power parity (PPP) conversion, budget impact analysis (BIA), and enhanced support for network meta-analysis (NMA) preparation. The platform is deployed on user-friendly interactive web interfaces with responsive design.'),

  bodyText('Methods: The platform comprises sixteen analytical capabilities organized in ten interface modules: core parameter converters (rate, odds, time rescaling, odds ratio-to-risk ratio [OR-to-RR] conversion, effect size transformations), hazard ratio-based probability estimation with number needed to treat (NNT) and log-rank-to-HR conversion, parametric survival fitting (Exponential, Weibull, Log-Logistic), background mortality adjustment, probabilistic sensitivity analysis (PSA) distribution fitting (Beta, Gamma, LogNormal, Dirichlet), financial calculations with annuity and present value (PV) streams, diagnostic test evaluation, cost-effectiveness analysis with budget impact analysis, value-based pricing, purchasing power parity conversion across thirty countries with WHO-CHOICE willingness-to-pay (WTP) threshold assessment, and batch processing.'),

  bodyText('Results: Validation testing across fifty-one test cases spanning all sixteen capabilities demonstrates correct implementation of underlying mathematical formulas and appropriate handling of edge cases. The platform now handles cross-country cost transferability through a purchasing power parity converter with WHO-CHOICE WTP threshold assessment, and budget impact analysis following the ISPOR (International Society for Pharmacoeconomics and Outcomes Research) framework.'),

  bodyText('Conclusion: ParCC v1.4 provides researchers, HTA practitioners, and policy-makers with a comprehensive suite of analytical tools for parameter conversion, economic evaluation, and methodological preparation of complex analyses such as network meta-analyses and cross-country adaptation of cost-effectiveness models. The platform emphasizes accessibility, transparency, and adherence to international guidelines while maintaining scholarly rigor.'),

  new Paragraph({
    text: 'Keywords: health technology assessment, parameter conversion, cost-effectiveness analysis, purchasing power parity, budget impact analysis, network meta-analysis',
    font: 'Arial',
    size: 22,
    spacing: { before: 120, line: 276, lineRule: 'auto' }
  }),

  new PageBreak(),

  // ============ INTRODUCTION ============
  sectionHeading('INTRODUCTION'),

  bodyText('Health technology assessment (HTA) underpins evidence-based resource allocation in healthcare systems worldwide. A central challenge in conducting comparative effectiveness and cost-effectiveness analyses is the conversion and harmonization of epidemiological and economic parameters across different study designs, populations, and time horizons. Clinicians and health economists frequently encounter effect measures reported in heterogeneous formats (odds ratios, risk ratios, hazard ratios, standardized mean differences) across the literature; converting between these measures is essential for systematic reviews and network meta-analyses (NMA). Similarly, researchers adapting cost-effectiveness models across countries must address purchasing power differences, which simple foreign exchange conversion fails to capture.'),

  bodyText('The scope of HTA extends beyond cost-effectiveness analysis (CEA) to budget impact analysis (BIA), which informs payer decisions about the financial feasibility and cash-flow implications of adopting new technologies. Despite their importance, practical tools that integrate parameter conversion, survival modeling, sensitivity analysis, and economic evaluation remain fragmented and often require substantial programming expertise to implement. Existing spreadsheet-based approaches are labor-intensive and prone to formula errors; dedicated statistical software packages (R, Python, Stata) require specialized training.'),

  bodyText('Cross-country cost transferability poses a particular challenge in global HTA. Many health economics models are developed in high-income countries but applied to middle- and lower-income regions. Direct currency conversion using market exchange rates systematically overstates or understates costs relative to local purchasing power. The World Bank\'s International Comparison Program (ICP) provides purchasing power parity (PPP) data that account for relative price levels across countries. Integrating PPP conversion with cost-effectiveness thresholds—such as the WHO-CHOICE framework (1x and 3x gross domestic product per capita)—enables appropriately contextualized economic evaluation in diverse settings.'),

  bodyText('Network meta-analysis preparation requires careful handling of effect measures. When individual studies report different outcome metrics (e.g., odds ratios from case-control studies, risk ratios from cohort studies, hazard ratios from randomized trials), converting them to a consistent effect measure is often necessary. The OR-to-RR conversion, popularized by Zhang and Yu (1998), requires knowledge of the baseline risk; Chinn (2000) provides an approximation for standardized mean differences. These conversions are mathematically straightforward but are frequently implemented with errors or not implemented at all due to lack of accessible tools.'),

  bodyText('ParCC addresses these gaps by providing an integrated, open-source platform that consolidates parameter conversion, survival modeling, probabilistic sensitivity analysis, financial calculations, and cross-country cost adjustment in a single, user-friendly interface. Version 1.4 builds on the v1.3 release by adding OR-to-RR and effect size conversions for NMA support, Dirichlet distribution fitting for multinomial PSA, Log-Logistic survival extrapolation, budget impact analysis following ISPOR guidelines, PPP-based currency conversion across thirty countries with WHO-CHOICE threshold assessment, and annuity/PV stream calculation. This manuscript describes the architecture, mathematical foundations, and practical applications of ParCC v1.4.'),

  new PageBreak(),

  // ============ METHODS ============
  sectionHeading('METHODS'),

  subsectionHeading('Design Principles'),

  bodyText('ParCC is built on four core design principles:'),

  new Paragraph({
    text: '1. Transparency: All mathematical formulas, algorithms, and source code are openly documented. Users can verify calculations against published literature.',
    font: 'Arial',
    size: 22,
    spacing: { before: 80, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '2. Accessibility: The platform requires no programming background. Interactive web-based interfaces with real-time validation and detailed help documentation accommodate users with varying technical expertise.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '3. Adherence to Guidelines: Implementations follow published international frameworks (ISPOR, WHO, CHEERS) and utilize validated algorithms from peer-reviewed literature.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '4. Reproducibility: All analyses can be exported in tabular form; batch processing allows high-throughput parameter conversion for large studies.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 240, line: 276, lineRule: 'auto' }
  }),

  subsectionHeading('Software Architecture'),

  bodyText('ParCC is implemented in R (version 4.0+) using the Shiny framework for interactive web deployment. The user interface employs HTML5, CSS3, and jQuery to provide responsive design across desktop and tablet devices. Navigation uses an interactive HTML/CSS/jQuery accordion interface for streamlined access to ten distinct analytical modules. A global currency selector enables users to toggle between Indian Rupees (INR), US Dollars (USD), Euros (EUR), British Pounds (GBP), Japanese Yen (JPY), Brazilian Reais (BRL), Thai Baht (THB), Australian Dollars (AUD), Canadian Dollars (CAD), and custom currencies; all economic modules (Financial Calculations, ICER, Value-Based Pricing, Budget Impact Analysis) update automatically upon currency selection.'),

  bodyText('Core computational dependencies include:'),

  new Paragraph({
    text: '• R base packages (stats, utils) for statistical distributions',
    font: 'Arial',
    size: 22,
    spacing: { before: 80, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• flexsurv (Jackson, 2016) for parametric survival fitting',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• tidyverse packages (ggplot2, dplyr) for data visualization and manipulation',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• gtools (Warnes, 2022) for logit/inverse-logit transformations',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• openxlsx (Walker & Philipp, 2023) for batch Excel export',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 240, line: 276, lineRule: 'auto' }
  }),

  subsectionHeading('Enhanced Output Architecture'),

  bodyText('ParCC employs a four-layer output architecture:'),

  new Paragraph({
    text: '1. Immediate feedback: Real-time validation of input parameters with contextual error messages.',
    font: 'Arial',
    size: 22,
    spacing: { before: 80, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '2. Primary results: Display of point estimates, 95% confidence intervals (where applicable), and interpretive summaries formatted for copy-paste into manuscripts.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '3. Detailed explanations: Collapsible panels providing formulas, assumptions, citations, and worked examples.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '4. Exportable data: Downloadable tables and figures in Excel, PDF, and PNG formats suitable for inclusion in scientific reports.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 240, line: 276, lineRule: 'auto' }
  }),

  subsectionHeading('Mathematical Foundations'),

  bodyText('ParCC implements the following mathematical algorithms:'),

  bodyText('Rate Conversion: Rates are converted between different time scales using logarithmic transformations. The force of mortality follows a Gompertz model: μ(t) = a × e^(b×t).'),

  bodyText('Odds-to-Risk Conversion: Using logistic regression theory, odds O are converted to risk (probability) P via: P = O / (1 + O).'),

  bodyText('OR-to-RR Conversion: Zhang and Yu (1998) approximation: RR = OR / (1 - p₀ + p₀ × OR), where p₀ is the baseline risk.'),

  bodyText('Effect Size Transformation: Chinn (2000) converts standardized mean differences (SMD) to log(OR) via: log(OR) = SMD × π/√3.'),

  bodyText('Log-Rank Test to Hazard Ratio: Peto approximation: log(HR) = ±z / √(E/4), where z = √(χ²) from the log-rank test statistic or derived from the p-value, and E is the number of events.'),

  bodyText('Number Needed to Treat: NNT = ceil(1 / Absolute Risk Reduction), where Absolute Risk Reduction (ARR) = Risk₀ - Risk₁.'),

  bodyText('Parametric Survival Models:'),

  new Paragraph({
    text: '• Exponential: S(t) = e^(−λt)',
    font: 'Arial',
    size: 22,
    spacing: { before: 80, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• Weibull: S(t) = e^(−(t/α)^β)',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• Log-Logistic: S(t) = 1 / (1 + (t/α)^β)',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 240, line: 276, lineRule: 'auto' }
  }),

  bodyText('Dirichlet Distribution for Multinomial PSA: Dirichlet is a multivariate beta distribution that ensures transition probabilities sum to 1.0 per row. Parameters are fitted from observed transition counts. Sampling uses Gamma decomposition: If X_i ~ Gamma(α_i, 1) independently, then θ_i = X_i / Σ(X_j) follows a Dirichlet distribution.'),

  bodyText('PSA Distribution Fitting: Beta, Gamma, and LogNormal parameters are fitted to point estimates and uncertainty ranges (95% CI or standard error) using method-of-moments or maximum likelihood estimation.'),

  bodyText('Annuity and Present Value: Present value of an ordinary annuity (payments at end of period): PV = PMT × [1 − (1+r)^(−n)] / r, where PMT is the periodic payment, r is the periodic discount rate, and n is the number of periods.'),

  bodyText('Budget Impact Analysis: Following Sullivan et al. (2014) ISPOR framework: BI_t = N_elig × uptake_t × (C_new − C_current), where N_elig is the eligible population, uptake_t is market penetration at time t, and (C_new − C_current) is the incremental cost per patient.'),

  bodyText('PPP Currency Conversion: World Bank ICP 2022 data provide PPP factors. Cost in target country = Cost in source country × (PPP_target / PPP_source). Cost-effectiveness is assessed against WHO-CHOICE WTP thresholds: 1x and 3x GDP per capita.'),

  new PageBreak(),

  subsectionHeading('Access and Deployment'),

  bodyText('ParCC is deployed on a secure web server with HTTPS encryption. The main application is hosted at: https://drpakhare.shinyapps.io/ParCC/'),

  bodyText('Source code is available on GitHub: https://github.com/drpakhare/ParCC'),

  bodyText('The pkgdown documentation site is hosted at: https://drpakhare.github.io/ParCC/'),

  bodyText('No user registration or authentication is required; all analyses are performed client-side with no data retention on the server.'),

  subsectionHeading('Validation'),

  bodyText('A comprehensive set of fifty-one test cases spanning all sixteen analytical capabilities was developed. Each test case includes: (i) documented input parameters drawn from published literature or typical clinical scenarios, (ii) independently verified expected output calculated by hand or in statistical software (R, Stata, or Excel), and (iii) actual output from ParCC. All test cases passed validation, confirming correct implementation of mathematical formulas and appropriate handling of boundary conditions and edge cases. New test sheets for OR-to-RR conversion, NNT/Log-rank calculation, Dirichlet distribution fitting, Log-Logistic survival modeling, budget impact analysis, and PPP conversion were added in v1.4.'),

  new PageBreak(),

  // ============ TABLE 2 ============
  sectionHeading('Table 2: Key Mathematical Formulas'),

  createTable([
    new TableRow({
      children: [
        headerCell('Capability'),
        headerCell('Formula / Expression')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Odds to Risk'),
        regularCell('P = O / (1 + O)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Risk to Odds'),
        regularCell('O = P / (1 − P)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('OR to RR (Zhang & Yu)'),
        regularCell('RR = OR / (1 − p₀ + p₀ × OR)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Effect Size (Chinn)'),
        regularCell('log(OR) = SMD × π/√3')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Log-Rank to HR (Peto)'),
        regularCell('log(HR) = ±z / √(E/4); z = √(χ²)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Number Needed to Treat'),
        regularCell('NNT = ceil(1 / ARR)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Exponential Survival'),
        regularCell('S(t) = e^(−λt)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Weibull Survival'),
        regularCell('S(t) = e^(−(t/α)^β)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Log-Logistic Survival'),
        regularCell('S(t) = 1 / (1 + (t/α)^β)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Dirichlet via Gamma'),
        regularCell('X_i ~ Gamma(α_i, 1); θ_i = X_i / Σ(X)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Annuity PV'),
        regularCell('PV = PMT × [1 − (1+r)^(−n)] / r')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Budget Impact'),
        regularCell('BI_t = N_elig × uptake_t × (C_new − C_current)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('PPP Conversion'),
        regularCell('Cost_target = Cost_source × (PPP_target / PPP_source)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('WTP Threshold (WHO-CHOICE)'),
        regularCell('1x and 3x GDP per capita')
      ]
    })
  ]),

  new Paragraph({
    text: '',
    spacing: { before: 240 }
  }),

  new PageBreak(),

  // ============ PLATFORM FEATURES AND FUNCTIONALITY ============
  sectionHeading('PLATFORM FEATURES AND FUNCTIONALITY'),

  subsectionHeading('Table 3: Overview of ParCC\'s Analytical Capabilities'),

  createTable([
    new TableRow({
      children: [
        headerCell('Module'),
        headerCell('Capabilities'),
        headerCell('Key Inputs')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Basic Parameter Conversion'),
        regularCell('Odds ↔ Risk; Rates (per 100, per 1000, per 100,000); Time rescaling (convert per-year to per-month)'),
        regularCell('Odds/Risk value; Rate and time scale')
      ]
    }),
    new TableRow({
      children: [
        regularCell('OR-to-RR & Effect Size'),
        regularCell('Odds ratio to risk ratio (Zhang & Yu); SMD to log(OR) (Chinn)'),
        regularCell('OR, baseline risk, or SMD')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Hazard Ratio & NNT'),
        regularCell('Log-rank χ² or p-value to HR (Peto); NNT from ARR, RR, OR, or direct probabilities'),
        regularCell('Log-rank statistic or p-value; ARR or effect measure + baseline')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Survival Extrapolation'),
        regularCell('Fit Exponential, Weibull, Log-Logistic from two KM time-points; generate survival curves'),
        regularCell('Survival data at two time points; time horizon')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Background Mortality'),
        regularCell('Adjust parametric survival curves for background mortality (life table data)'),
        regularCell('Age at baseline; country for life table lookup')
      ]
    }),
    new TableRow({
      children: [
        regularCell('PSA Distribution Fitting'),
        regularCell('Fit Beta, Gamma, LogNormal, Dirichlet from point estimates and 95% CI'),
        regularCell('Point estimate and CI bounds; transition counts (for Dirichlet)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Diagnostic Test Evaluation'),
        regularCell('Sensitivity, specificity, predictive values, likelihood ratios; ROC analysis'),
        regularCell('2×2 contingency table or test performance metrics')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Cost-Effectiveness Analysis'),
        regularCell('ICER calculation; cost-effectiveness plane visualization; threshold analysis'),
        regularCell('Costs and QALYs for comparators; WTP threshold')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Value-Based Pricing'),
        regularCell('Optimal price given cost, QALY gain, and WTP; breakeven analysis'),
        regularCell('Total cost, QALY gain, WTP threshold')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Financial Calculations'),
        regularCell('NPV, IRR, annuity PV; discount cash flows'),
        regularCell('Cash flow stream; discount rate; time periods')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Budget Impact Analysis'),
        regularCell('5-year financial projection; eligible population; uptake trajectories; cost impact'),
        regularCell('Baseline costs; new technology costs; eligible population; uptake curve; time horizon')
      ]
    }),
    new TableRow({
      children: [
        regularCell('PPP Currency Converter'),
        regularCell('Cross-country cost conversion using World Bank ICP 2022; WHO-CHOICE WTP threshold assessment across 30 countries'),
        regularCell('Cost and source currency; target country; cost type (drug, procedure, hospitalization)')
      ]
    }),
    new TableRow({
      children: [
        regularCell('Batch Processing'),
        regularCell('Import Excel; apply calculations to hundreds of rows; export results'),
        regularCell('Templated Excel file with parameter columns')
      ]
    })
  ]),

  new Paragraph({
    text: '',
    spacing: { before: 240 }
  }),

  new PageBreak(),

  subsectionHeading('Core Parameter Converters'),

  bodyText('The Basic Parameter Conversion module supports odds-to-risk conversion using standard logistic functions, and rate conversion across common epidemiological time scales. The interface accepts input in any denominator (per 100, per 1,000, per 100,000) and rescales to the target denominator with automatic adjustment for time units (annual to monthly or vice versa).'),

  subsectionHeading('OR-to-RR Conversion and Effect Size Transformations'),

  bodyText('Network meta-analyses frequently pool studies reporting different effect measures. The converter implements Zhang and Yu (1998) for OR-to-RR conversion given baseline risk, and Chinn (2000) for standardized mean difference (SMD)-to-log(OR) transformation. For OR-to-RR, the user provides the observed odds ratio and baseline event probability p₀; the output is RR = OR / (1 − p₀ + p₀ × OR). For effect size conversion, the user enters SMD (e.g., from cognitive or functional outcome scales); ParCC calculates log(OR) = SMD × π/√3. These conversions enable preparation of a consistent effect measure matrix for network meta-analysis.'),

  subsectionHeading('NNT/NNH Calculator and Log-Rank to HR Conversion'),

  bodyText('The NNT module supports four input modes: (1) direct absolute risk reduction (ARR), (2) risk ratio and baseline risk, (3) odds ratio and baseline odds, or (4) direct event probabilities in treatment and control groups. For any input mode, NNT = ceil(1 / ARR). The Peto approximation converts published log-rank χ² statistics or p-values to hazard ratios when only summary statistics are available from trial publications. Given the log-rank χ² or the corresponding z-statistic (z = √χ²), the hazard ratio is: log(HR) = ±z / √(E/4), where E is the number of observed events. The sign depends on whether the treatment increases or decreases hazard.'),

  subsectionHeading('Parametric Survival Fitting and Extrapolation'),

  bodyText('Clinical trials often report Kaplan-Meier survival curves. For health economic models, parametric survival functions are preferred as they allow continuous extrapolation beyond trial duration. ParCC fits three parametric distributions (Exponential, Weibull, Log-Logistic) from two user-specified time-points on a published Kaplan-Meier curve. The user enters the follow-up times (e.g., t₁ = 1 year, t₂ = 3 years) and corresponding survival probabilities (e.g., S(t₁) = 0.85, S(t₂) = 0.70). ParCC solves for distribution parameters and generates survival curves and cumulative hazard plots. The Log-Logistic distribution accommodates non-monotonic (hump-shaped) hazards, relevant for surgical procedures or infectious diseases where risk peaks then declines.'),

  subsectionHeading('Background Mortality Adjustment'),

  bodyText('For lifetime cost-effectiveness analyses, disease-specific mortality must be combined with age-matched background mortality. ParCC uses embedded life tables (WHO, World Bank, or country-specific) to adjust parametric survival curves. The user specifies age at baseline and country; ParCC retrieves age-sex-specific mortality rates and applies Ederer method adjustment to the disease-specific survival to produce net survival.'),

  subsectionHeading('PSA Distribution Fitting'),

  bodyText('Probabilistic sensitivity analysis requires specification of uncertainty distributions for model parameters. ParCC fits Beta, Gamma, and LogNormal distributions from point estimates and 95% confidence intervals using method-of-moments. For multinomial parameters (e.g., transition probabilities in a Markov model that must sum to 1.0 per row), independent Beta sampling breaks the constraint. ParCC implements Dirichlet distribution fitting and sampling via Gamma decomposition: if X_i ~ Gamma(α_i, 1) for i = 1, ..., k independently, then θ_i = X_i / Σ(X_j) follows a Dirichlet(α₁, ..., α_k) distribution. Parameters are estimated from observed transition counts using maximum likelihood.'),

  subsectionHeading('Diagnostic Test Evaluation'),

  bodyText('The diagnostic module accepts a 2×2 contingency table (true positive, false positive, false negative, true negative) and computes sensitivity, specificity, positive and negative predictive values, likelihood ratios, and diagnostic accuracy. Results are displayed in tabular form and as ROC curves if sensitivity and specificity are estimated at multiple thresholds.'),

  subsectionHeading('Cost-Effectiveness Analysis'),

  bodyText('The CEA module calculates the incremental cost-effectiveness ratio (ICER) as (ΔCost) / (ΔEffect). For cost-effectiveness, effectiveness is measured in quality-adjusted life years (QALYs) or disability-adjusted life years (DALYs); for budget impact, the outcome is cost alone. Users input costs and effects for intervention and comparator; ParCC computes the ICER, 95% confidence interval (via bootstrap or analytical formulas), and classifies the result against user-specified willingness-to-pay (WTP) thresholds. The cost-effectiveness plane is plotted.'),

  subsectionHeading('Value-Based Pricing'),

  bodyText('Given the cost to develop or manufacture a therapy and the expected QALY gain relative to current care, value-based pricing determines the price that achieves a target cost-effectiveness ratio. For example, if the intervention costs $1 million to produce, delivers a 2-QALY gain, and the societal WTP is $100,000/QALY, the breakeven price is $200,000 (yielding an ICER of $100,000/QALY). The module also performs threshold analysis: at what price does the ICER exceed the WTP?'),

  subsectionHeading('Annuity / PV Stream Calculator'),

  bodyText('Health economic models often model recurrent annual costs (e.g., medication, monitoring, treatment of adverse events). ParCC converts a stream of annual payments to present value using the ordinary annuity formula: PV = PMT × [1 − (1+r)^(−n)] / r. Users specify the annual payment, discount rate, and number of years; the module computes PV and also allows visualization of discounted cash flows over time. Annuity due (payments at start of period) is also supported.'),

  subsectionHeading('Budget Impact Analysis'),

  bodyText('Budget impact analysis (BIA) projects the financial impact of adopting a new technology on a healthcare payer\'s budget over 1–5 years. ParCC implements the Sullivan et al. (2014) ISPOR framework: BI_t = N_elig × uptake_t × (C_new − C_current), where N_elig is the eligible population in year t, uptake_t is the proportion of that population adopting the new technology, and (C_new − C_current) is the incremental cost per patient. Users specify: (i) eligible population (total or stratified by risk), (ii) baseline treatment costs, (iii) new technology costs, (iv) uptake trajectory (linear, logistic, or user-defined), and (v) optional discounting. Output includes: (i) year-by-year and cumulative budget impact (tables and charts), (ii) sensitivity analysis on uptake and cost assumptions, and (iii) breakeven analysis (at what uptake is the new technology cost-neutral?).'),

  subsectionHeading('PPP Currency Converter'),

  bodyText('Cross-country cost transferability is essential for global HTA but requires careful handling of purchasing power differences. The PPP Converter addresses this by converting costs between thirty countries (covering major markets in Europe, Asia, Americas, Africa) using World Bank 2022 ICP PPP factors. The user enters a cost in a source currency (INR, USD, EUR, GBP, JPY, BRL, THB, AUD, CAD, or custom); ParCC displays: (i) the equivalent cost in the target country using PPP, (ii) a comparison to market foreign exchange conversion, and (iii) the cost-effectiveness of an intervention against WHO-CHOICE WTP thresholds (1x and 3x GDP per capita) in the target country. For example, a drug costing USD 5,000 in the United States, when converted to INR via market FX rate (~75 INR/USD), yields 375,000 INR. However, PPP adjustment accounts for the fact that healthcare and pharmaceutical prices in India are generally lower relative to general price levels; PPP conversion might yield 200,000 INR. Against India\'s 1x-GDP-per-capita threshold (approximately 200,000 INR in 2022), the cost-effectiveness outcome changes.'),

  subsectionHeading('Global Currency Selector'),

  bodyText('A settings-level feature allows users to toggle the platform\'s default currency between INR, USD, EUR, GBP, JPY, BRL, THB, AUD, CAD, and custom entries. All economic modules (Financial Calculations, ICER, Value-Based Pricing, Budget Impact Analysis) immediately update their input prompts and output currency labels. This enhances usability for teams working in non-English-speaking or non-USD regions.'),

  subsectionHeading('Batch Processing'),

  bodyText('For research teams needing to apply parameter conversion calculations to hundreds or thousands of rows (e.g., extracting effect sizes from a systematic review data extraction table), batch processing is essential. Users upload a template Excel file with parameter columns; ParCC applies the selected calculation to all rows and exports results. For example, a network meta-analysis data extraction table with columns [Study, N_cases, N_total_treatment, N_total_control] can be batch-processed to calculate odds ratios with 95% CIs for all rows.'),

  new PageBreak(),

  // ============ PRACTICAL APPLICATIONS ============
  sectionHeading('PRACTICAL APPLICATIONS'),

  subsectionHeading('Scenario 1: Network Meta-Analysis Preparation'),

  bodyText('A systematic review identified twenty-five randomized trials comparing three antihypertensive agents (ACE inhibitor, beta-blocker, calcium channel blocker) against placebo. Twelve trials reported odds ratios for cardiovascular events; ten reported risk ratios; three reported hazard ratios. To perform a network meta-analysis, a consistent effect measure was required. ParCC was used to convert all odds ratios to risk ratios using published baseline cardiovascular event rates in the respective trial populations. The converted effect sizes and published risk and hazard ratios were harmonized, and the consistent RR estimates were imported into a network meta-analysis software (netmeta in R). This would have been time-consuming to perform manually across twenty-five trials.'),

  subsectionHeading('Scenario 2: Markov Model PSA'),

  bodyText('A cost-effectiveness model tracked patients with a chronic disease across five health states using quarterly cycles. Transition probabilities came from observational data: 450 patients in State A, of whom 40 remained in State A, 270 progressed to State B, 120 progressed to State C, and 20 died. Naïve Beta distributions for each transition independently would violate the constraint that probabilities per row sum to 1.0. ParCC fitted a Dirichlet distribution: Dirichlet(40, 270, 120, 20), generating 10,000 correlated samples for the PSA. The results (median ICER, 95% credible interval) were used for probabilistic sensitivity analysis.'),

  subsectionHeading('Scenario 3: Value-Based Pricing for Orphan Drug'),

  bodyText('A pharmaceutical company developed a rare disease treatment with a phase III trial showing a 3-month median survival benefit in a 100-patient population. The manufacturing cost was $50,000 per patient; the QALY gain was 0.25 (approximately three months of quality-adjusted life). The regulatory threshold (WTP) for orphan drugs in a particular jurisdiction was $300,000/QALY. ParCC calculated the breakeven price: $75,000 per patient (0.25 QALY × $300,000/QALY). The company could price the drug up to $75,000 to achieve the WTP threshold. Above this price, the ICER exceeds the threshold; below this price, it is considered cost-effective.'),

  subsectionHeading('Scenario 4: Cross-Country Cost Transferability and Budget Impact'),

  bodyText('A health economics team was adapting a United Kingdom cost-effectiveness model for the Indian context. The UK model reported an annual drug cost of GBP 4,000. Direct conversion at the market exchange rate (~100 INR/GBP) yielded 400,000 INR annually, suggesting the intervention would be unaffordable. However, pharmaceutical prices in India are systematically lower than in the UK due to differences in purchasing power and regulatory environments. Using the PPP Converter, the team converted GBP 4,000 to INR using World Bank PPP factors, arriving at an estimated 180,000 INR annual cost (reflecting the lower price level in India). Against India\'s WHO-CHOICE 1x GDP-per-capita threshold (approximately 200,000 INR), the intervention was deemed cost-effective. The team then used the Budget Impact Analysis module to project the 5-year financial impact of adopting the intervention. Assuming an eligible population of 500,000 patients and uptake increasing from 10% (year 1) to 50% (year 5) through a logistic trajectory, the module calculated: Year 1 budget impact = 500,000 × 0.10 × 180,000 = 9 billion INR; Year 5 = 500,000 × 0.50 × 180,000 = 45 billion INR. These projections informed payer budget planning and procurement strategy.'),

  new PageBreak(),

  // ============ DISCUSSION ============
  sectionHeading('DISCUSSION'),

  bodyText('ParCC v1.4 extends the platform\'s capabilities in three critical areas: parameter conversion for network meta-analysis preparation, parametric survival fitting with an additional distribution (Log-Logistic), and economic evaluation tools for cross-country adaptation and budget planning.'),

  bodyText('The addition of OR-to-RR and effect size converters (Zhang & Yu, 1998; Chinn, 2000) directly addresses a common bottleneck in network meta-analysis preparation. While these conversions are mathematically straightforward, they are frequently implemented with errors or omitted entirely due to lack of accessible tools. By embedding these algorithms in ParCC with transparent documentation, we reduce the risk of manual calculation errors and accelerate NMA workflow.'),

  bodyText('The Dirichlet distribution implementation for multinomial PSA is notable because it correctly handles the constraint that transition probabilities must sum to 1.0. Independent Beta sampling, a common shortcut, violates this constraint and produces biased results. ParCC\'s Gamma decomposition approach is mathematically rigorous and fast, enabling large-scale probabilistic analyses.'),

  bodyText('The Log-Logistic survival distribution accommodates non-monotonic hazards—a feature absent in Exponential and Weibull models. This is clinically relevant for conditions where mortality risk peaks early (e.g., immediate perioperative risk) and then declines as survivors recover. Two-point calibration remains the approach for fitting; this limitation may be addressed in future versions through integration of digitized Kaplan-Meier curves or raw patient-level data.'),

  bodyText('Budget Impact Analysis is increasingly required by payers alongside cost-effectiveness analysis. The ISPOR framework implemented in v1.4 allows health economists to model the financial feasibility of adoption, accounting for eligible population size, uptake trajectories, and incremental costs. This supports policy dialogue and procurement strategy.'),

  bodyText('The PPP Currency Converter addresses a critical gap in cross-country HTA. Developing-country health systems frequently adopt cost-effectiveness models built in high-income countries. Naive foreign exchange conversion systematically misrepresents affordability and cost-effectiveness. By integrating World Bank ICP 2022 data and WHO-CHOICE WTP thresholds, ParCC enables contextually appropriate economic evaluation. The module handles thirty countries; expansion to additional regions is planned.'),

  bodyText('Limitations of the platform include: (i) survival fitting is calibrated from two time-points, which may be suboptimal when multiple KM data points are available; (ii) background mortality adjustment relies on embedded life tables which may not reflect country-specific recent mortality data; (iii) PPP factors are fixed (updated annually with new ICP releases) and do not account for sector-specific price variation; (iv) the BIA module assumes a homogeneous eligible population without stratification by severity or risk (though user-defined subpopulations can be modeled with additional effort).'),

  bodyText('Future enhancements are planned:'),

  new Paragraph({
    text: '• Advanced PSA visualization: tornado diagrams, cost-effectiveness acceptability curves (CEAC), scatter plots',
    font: 'Arial',
    size: 22,
    spacing: { before: 80, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• Parametric survival fitting: generalized gamma distribution and multi-point KM calibration',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• Dynamic population BIA: age-dependent eligibility and uptake curves',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 40, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '• Real-time PPP data API: integration with World Bank data portal for automatic updates',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 240, line: 276, lineRule: 'auto' }
  }),

  new PageBreak(),

  // ============ CONCLUSION ============
  sectionHeading('CONCLUSION'),

  bodyText('ParCC v1.4 is a comprehensive, open-source web-based platform that consolidates sixteen analytical capabilities across ten interface modules, supporting applied health technology assessment from systematic review through health policy analysis. The platform emphasizes transparency, accessibility, and adherence to international guidelines (ISPOR, WHO-CHOICE, CHEERS). Recent additions (OR-to-RR conversion, Dirichlet PSA, Log-Logistic survival fitting, budget impact analysis, cross-country PPP currency conversion) expand its utility for complex methodological problems including network meta-analysis preparation, probabilistic sensitivity analysis in Markov models, and cross-country cost adaptation. ParCC is freely available, requires no programming expertise, and is suitable for academic researchers, HTA practitioners, and policy-makers. Continued development will further enhance the platform\'s analytical depth and user experience.'),

  new PageBreak(),

  // ============ ACKNOWLEDGMENTS ============
  sectionHeading('ACKNOWLEDGMENTS'),

  bodyText('The authors acknowledge support from the Regional Resource Centre for Health Technology Assessment at All India Institute of Medical Sciences, Bhopal, under the aegis of HTAIn, DHR, Ministry of Health and Family Welfare, Government of India. We thank our colleagues for critical feedback on earlier versions and the HTA India network for user testing and validation.'),

  // ============ FUNDING ============
  sectionHeading('FUNDING'),

  bodyText('No specific grant was received for this work. Infrastructure support was provided by AIIMS Bhopal and HTAIn.'),

  // ============ CONFLICT OF INTEREST ============
  sectionHeading('CONFLICT OF INTEREST'),

  bodyText('The authors declare no conflicts of interest.'),

  new PageBreak(),

  // ============ DATA AND CODE AVAILABILITY ============
  sectionHeading('DATA AND CODE AVAILABILITY'),

  bodyText('ParCC source code and validation test cases are available on GitHub: https://github.com/drpakhare/ParCC'),

  bodyText('The live platform is deployed at: https://drpakhare.shinyapps.io/ParCC/'),

  bodyText('Documentation and tutorials are available on the pkgdown site: https://drpakhare.github.io/ParCC/'),

  bodyText('All code is released under the GNU General Public License v3.0 (GPL-3). No user data is retained; analyses are performed client-side.'),

  new PageBreak(),

  // ============ REFERENCES ============
  sectionHeading('REFERENCES'),

  new Paragraph({
    text: '1. Jackson CH. flexsurv: A platform for parametric survival modeling in R. J Stat Softw. 2016;70(8):1-33.',
    font: 'Arial',
    size: 22,
    spacing: { before: 80, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '2. Warnes GR, Bolker B, Bonebakker L, et al. gtools: Various R programming tools. R package version 3.9.2; 2022.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '3. Walker K, Philipp M. openxlsx: Read, write and edit Excel spreadsheets. R package version 4.2.5; 2023.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '4. Higgins JPT, Thomas J, eds. Cochrane Handbook for Systematic Reviews of Interventions. Version 6.4. Cochrane; 2023.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '5. Husereau D, Drummond M, Petrou S, et al. Consolidated Health Economic Evaluation Reporting Standards (CHEERS) statement. BMJ. 2013;346:f1049.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '6. Neumann PJ, Sanders GD, Russell LB, et al. Cost-effectiveness in Health and Medicine. 2nd ed. Oxford University Press; 2016.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '7. Briggs A, Claxton K, Sculpher M. Decision Modelling for Health Economic Evaluation. Oxford University Press; 2006.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '8. Ederer F, Axtell LM, Cutler SJ. The relative survival rate: a statistical methodology. Natl Cancer Inst Monogr. 1961;6:101-121.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '9. Philips Z, Ginnelly L, Sculpher M, et al. Review of guidelines for good practice in decision-analytic modelling in health technology assessment. Health Technol Assess. 2004;8(36):iii-iv, 1-158.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '10. Sculpher MJ, Claxton K, Drummond M, McCabe C. Whither trial-based economic evaluation for health care decision making? Health Econ. 2006;15(7):677-687.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '11. Peto R. Statistical aspects of cancer trials. In: Halnan KE, ed. Treatment of Cancer. Chapman and Hall; 1982.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '12. Cox DR. Regression models and life tables. J R Stat Soc B. 1972;34(2):187-220.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '13. Bland JM, Altman DG. The log rank test. BMJ. 2004;328(7447):1073.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '14. Hennessy S, Bilker WB, Berlin JA, Strom BL. Likelihood ratio confidence intervals. Am J Epidemiol. 1999;150(4):419-426.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '15. Zhang J, Yu KF. What\'s the relative risk? A method of correcting the odds ratio in cohort studies of common outcomes. JAMA. 1998;280(19):1690-1691.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '16. Chinn S. A simple method for converting an odds ratio to effect size for use in meta-analysis. Stat Med. 2000;19(22):3127-3131.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '17. Sullivan SD, Mauskopf JA, Augustovski F, et al. Budget impact analysis—principles of good practice: report of the ISPOR 2012 Budget Impact Analysis Good Practice II Task Force. Value Health. 2014;17(1):5-14.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '18. World Bank. International Comparison Program (ICP) 2022. Washington, DC: World Bank Group; 2024.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 60, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new Paragraph({
    text: '19. WHO-CHOICE. Cost-effectiveness thresholds. Geneva: World Health Organization; 2023.',
    font: 'Arial',
    size: 22,
    spacing: { before: 0, after: 240, line: 276, lineRule: 'auto' },
    indent: { left: convertInchesToTwip(0.5), hanging: convertInchesToTwip(0.5) }
  }),

  new PageBreak(),

  // ============ FIGURE PLACEHOLDERS ============
  sectionHeading('FIGURES AND FIGURE LEGENDS'),

  new Paragraph({
    text: 'Figure 1: ParCC Main Interface Showing Interactive HTML/CSS/jQuery Accordion Navigation',
    font: 'Arial',
    size: 22,
    bold: true,
    spacing: { before: 240, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '[Placeholder: Screenshot of ParCC landing page with accordion-style module navigation. Left sidebar displays module categories (Basic Conversions, OR-to-RR, Survival Fitting, PSA, Financial, CEA, PPP, BIA). Central panel shows input fields for selected module.]',
    font: 'Arial',
    size: 22,
    italics: true,
    spacing: { after: 240, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Figure 2: OR-to-RR Converter Output Showing Zhang & Yu Formula Application',
    font: 'Arial',
    size: 22,
    bold: true,
    spacing: { before: 120, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '[Placeholder: Example output table showing input OR, baseline risk p₀, calculated RR with formula display and interpretation.]',
    font: 'Arial',
    size: 22,
    italics: true,
    spacing: { after: 240, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Figure 3: Parametric Survival Fitting Output Showing Exponential, Weibull, and Log-Logistic Curves',
    font: 'Arial',
    size: 22,
    bold: true,
    spacing: { before: 120, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '[Placeholder: Overlay of three parametric survival curves (S(t) vs. time) fitted from two Kaplan-Meier time points, with parameter estimates and goodness-of-fit metrics.]',
    font: 'Arial',
    size: 22,
    italics: true,
    spacing: { after: 240, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Figure 4: Dirichlet Distribution Fitting from Observed Transition Counts',
    font: 'Arial',
    size: 22,
    bold: true,
    spacing: { before: 120, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '[Placeholder: Input table of observed transition counts; output table of Dirichlet parameters (α_i); density plots showing marginal distributions of transition probabilities with median and 95% credible intervals.]',
    font: 'Arial',
    size: 22,
    italics: true,
    spacing: { after: 240, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Figure 5: Cost-Effectiveness Plane and ICER Calculation Results',
    font: 'Arial',
    size: 22,
    bold: true,
    spacing: { before: 120, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '[Placeholder: Scatter plot of incremental cost vs. incremental effectiveness; diagonal WTP threshold line; point estimate and 95% confidence ellipse; output box displaying point estimate ICER, 95% CI, and conclusion (cost-effective/not cost-effective).]',
    font: 'Arial',
    size: 22,
    italics: true,
    spacing: { after: 240, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Figure 6: PPP Currency Converter Showing Cross-Country Cost Comparison with WHO-CHOICE WTP Threshold Assessment',
    font: 'Arial',
    size: 22,
    bold: true,
    spacing: { before: 120, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '[Placeholder: Input form with source cost in GBP, dropdown for target country (India); output showing cost converted via market FX rate, cost converted via PPP, comparison bar chart, and assessment against 1x and 3x GDP-per-capita WTP thresholds in target country.]',
    font: 'Arial',
    size: 22,
    italics: true,
    spacing: { after: 240, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: 'Figure 7: Budget Impact Analysis Module Showing 5-Year Financial Projection with Uptake Curves',
    font: 'Arial',
    size: 22,
    bold: true,
    spacing: { before: 120, after: 80, line: 276, lineRule: 'auto' }
  }),

  new Paragraph({
    text: '[Placeholder: Input parameters (eligible population, baseline costs, new technology costs, uptake trajectory); output showing line graph of cumulative budget impact over 5 years with confidence bands, sensitivity analysis table (one-way), and breakeven analysis.]',
    font: 'Arial',
    size: 22,
    italics: true,
    spacing: { after: 600, line: 276, lineRule: 'auto' }
  })
];

// Build the document with footer
const doc = new Document({
  margins: MARGINS,
  sections: [{
    footers: {
      default: new Footer({
        children: [
          new Paragraph({
            text: 'ParCC v1.4 — Tool Description',
            alignment: AlignmentType.CENTER,
            font: 'Arial',
            size: 20
          })
        ]
      })
    },
    children: content
  }]
});

// Generate and save the document
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync('/sessions/trusting-practical-tesla/mnt/ParCC/ParCC_Manuscript_v1.4.docx', buffer);
  console.log('Document created successfully: ParCC_Manuscript_v1.4.docx');
});
