# ==============================================================================
# MODULE: HOW TO USE (EXPANDED TUTORIALS)
# ==============================================================================
mod_howtouse_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    div(class = "about-header", style = "padding: 20px; text-align: left; margin-bottom: 20px;",
        h2(icon("graduation-cap"), " User Guide & Tutorials"),
        p("A comprehensive guide to utilizing ParCC for Health Economic Modeling.")
    ),
    
    navlistPanel(
      widths = c(3, 9),
      "Getting Started",
      tabPanel("The Lab Notebook",
               h3("Workflow: Ensuring Reproducibility"),
               p("In HTA, documenting ", em("how"), " you derived a parameter is as important as the number itself. ParCC acts as your digital logbook."),
               div(class = "well",
                   tags$ol(
                     tags$li(strong("Label It:"), " Always type a specific name in the 'Label' box first (e.g., 'PFS Control Arm' or 'Cost of Surgery')."),
                     tags$li(strong("Calculate & Log:"), " Click the blue action button. This calculates the result AND saves it to your temporary session log."),
                     tags$li(strong("Review:"), " Go to the 'Report' tab to see a table of all your logged parameters."),
                     tags$li(strong("Export:"), " Download the HTML Report. Append this to your manuscript or HTA dossier as a technical appendix.")
                   )
               )
      ),
      
      "Core Conversions",
      tabPanel("Rates vs. Probabilities",
               h3("Tutorial 1: The Safety Data Problem"),
               p(class="text-info", strong("Concept:"), " Rates are like speed (instantaneous), while Probabilities are like the chance of arriving within a specific time. You cannot plug a Rate directly into a Markov Model."),
               
               h4("The Real-World Scenario"),
               p("You are modeling a new drug for Atrial Fibrillation. The clinical trial reports the rate of 'Major Bleeding' as:"),
               div(class="well", "2.5 events per 100 patient-years"),
               
               h4("The Common Mistake"),
               p("A beginner might divide 2.5 by 100 and enter ", strong("0.025"), " into the model. This is mathematically incorrect because it ignores that patients who bleed are removed from the 'at-risk' pool during the year."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("Converters > Rate \u2194 Probability"), "."),
                 tags$li("Input Rate = ", strong("2.5"), "."),
                 tags$li("Select Multiplier = ", strong("'Per 100'"), "."),
                 tags$li("Input Time = ", strong("1"), " (for a 1-year model cycle)."),
                 tags$li("Click Convert. Result: ", strong("0.02469"), ".")
               ),
               p("Use ", strong("0.02469"), " in your Markov trace. The difference becomes massive for high-event rates (e.g., mortality in oncology).")
      ),
      
      tabPanel("Time Rescaling",
               h3("Tutorial 2: The Cycle Mismatch"),
               p(class="text-info", strong("Concept:"), " Risks compound over time. A 10% risk over 2 years is NOT the same as 5% risk per year."),
               
               h4("The Real-World Scenario"),
               p("You are building a Diabetes model with ", strong("1-year cycles"), ". You use the ", strong("UKPDS Risk Engine"), " (a famous calculator) to predict coronary heart disease. It gives you a ", strong("10-year probability of 20%"), "."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("Converters > Time Rescaling"), "."),
                 tags$li("Input Original Probability = ", strong("0.20"), "."),
                 tags$li("Input Original Time = ", strong("10"), " (Years)."),
                 tags$li("Input New Time = ", strong("1"), " (Year)."),
                 tags$li("Result: ", strong("0.0223"), " (approx 2.23%).")
               ),
               p("Notice that 2.23% is ", em("higher"), " than the simple average (2.0%). This correction ensures your model doesn't underestimate early events.")
      ),
      
      tabPanel("HR Conversion",
               h3("Tutorial 2B: Applying a Hazard Ratio from a Trial"),
               p(class="text-info", strong("Concept:"), " When a trial reports a Hazard Ratio (HR), you cannot simply multiply the control probability by the HR. The HR operates on the instantaneous rate, not on the probability."),

               h4("The Real-World Scenario (PLATO Trial)"),
               p("You are building a cost-effectiveness model for ", strong("Ticagrelor vs Aspirin"), " in Acute Coronary Syndrome. The PLATO trial (Wallentin et al., NEJM 2009) reports:"),
               div(class = "well",
                   tags$ul(
                     tags$li("CV Death in the Aspirin (control) arm: ", strong("5.25%"), " at 12 months"),
                     tags$li("Hazard Ratio for CV Death (Ticagrelor vs Aspirin): ", strong("HR = 0.79"), " (95% CI: 0.69 - 0.91)")
                   )
               ),

               h4("The Common Mistake"),
               p("A beginner might calculate 0.0525 \u00d7 0.79 = 0.0415 (4.15%). This is ", strong("incorrect"), " because the HR acts on the instantaneous rate, not the probability. The error grows larger with higher event rates and longer time horizons."),

               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("HR Converter"), "."),
                 tags$li("Enter Control Probability = ", strong("0.0525"), "."),
                 tags$li("Set Time Horizon = ", strong("1 Year"), "."),
                 tags$li("Enter HR = ", strong("0.79"), ", with CI ", strong("0.69"), " to ", strong("0.91"), "."),
                 tags$li("Click ", strong("Convert & Log"), ".")
               ),

               h4("The Result"),
               p("ParCC calculates:"),
               div(class = "well",
                   tags$ul(
                     tags$li("Control Rate: -ln(1 - 0.0525) / 1 = ", strong("0.05391"), " per year"),
                     tags$li("Intervention Rate: 0.05391 \u00d7 0.79 = ", strong("0.04259"), " per year"),
                     tags$li("Intervention Probability: 1 - e^(-0.04259) = ", strong("0.04170"), " (correct)"),
                     tags$li("ARR = 1.08% | NNT = 93")
                   )
               ),

               p("Compare: the naive multiplication gives 4.15%, while the correct method gives 4.17%. For high-event-rate outcomes (e.g., mortality in metastatic cancer where control p = 0.40), the discrepancy can exceed ", strong("2 percentage points"), "."),

               h4("When to Use This Tool"),
               tags$ul(
                 tags$li("Converting trial HRs into Markov model transition probabilities"),
                 tags$li("Applying relative treatment effects from network meta-analyses"),
                 tags$li("Adjusting subgroup-specific probabilities using pooled HRs"),
                 tags$li("Any scenario where you have a baseline probability and an HR from a different study")
               )
      ),

      "Evidence Synthesis",
      tabPanel("OR \u2194 RR & Effect Sizes",
               h3("Tutorial: Network Meta-Analysis Preparation"),
               p(class="text-info", strong("Concept:"), " Different trials report results in different metrics (Odds Ratios, Relative Risks, Standardised Mean Differences). Before you can combine them in a Network Meta-Analysis (NMA), you must convert everything to a common scale."),

               h4("The Real-World Scenario"),
               p("You are conducting an NMA comparing three treatments for Major Depression. Your systematic review found:"),
               div(class = "well",
                   tags$ul(
                     tags$li(strong("Trial A (Drug vs Placebo):"), " OR = 1.85 for 'Response' (50% reduction in HAM-D). Baseline response rate in the placebo arm = 30%."),
                     tags$li(strong("Trial B (Drug vs Placebo):"), " RR = 1.42 for 'Response'."),
                     tags$li(strong("Trial C (Drug vs Placebo):"), " Reports a continuous outcome: SMD = 0.45 (Cohen's d) on HAM-D score.")
                   )
               ),
               p("To pool these in a single NMA, you need all three on the same scale."),

               h4("Step 1: Convert OR to RR (Zhang & Yu Method)"),
               tags$ol(
                 tags$li("Navigate to ", strong("Converters > Core Converters > OR \u2194 RR"), "."),
                 tags$li("Select direction: ", strong("OR \u2192 RR"), "."),
                 tags$li("Input OR = ", strong("1.85"), ", Baseline Risk = ", strong("0.30"), "."),
                 tags$li("Result: ", strong("RR = 1.42"), ".")
               ),
               p("The Zhang & Yu formula adjusts for baseline risk: RR = OR / (1 - p", tags$sub("0"), " + p", tags$sub("0"), " \u00d7 OR). Note how OR overstates the effect compared to RR when the outcome is common (>10%)."),

               h4("Step 2: Convert SMD to log(OR) (Chinn Method)"),
               tags$ol(
                 tags$li("Switch to the ", strong("Effect Size Conversions"), " tab."),
                 tags$li("Select direction: ", strong("SMD \u2192 log(OR)"), "."),
                 tags$li("Input SMD = ", strong("0.45"), "."),
                 tags$li("Result: log(OR) = ", strong("0.816"), ", i.e. OR = 2.26.")
               ),
               p("The Chinn (2000) formula uses the logistic approximation: log(OR) = SMD \u00d7 \u03c0/\u221a3. This is the standard approach endorsed by the Cochrane Handbook for combining binary and continuous outcomes."),

               h4("When to Use This"),
               div(class = "use-case-box",
                   span(class = "use-case-title", "Key Applications"),
                   tags$ul(
                     tags$li("Network meta-analysis requiring a common effect metric"),
                     tags$li("Converting trial-level ORs to RRs for clinical interpretability"),
                     tags$li("Combining binary and continuous outcomes in mixed-treatment comparisons"),
                     tags$li("Verifying that a rare-disease approximation (OR \u2248 RR) is valid for your baseline risk")
                   )
               )
      ),

      tabPanel("NNT/NNH & Log-rank \u2192 HR",
               h3("Tutorial: From Published Statistics to Model Inputs"),
               p(class="text-info", strong("Concept:"), " Systematic reviews often encounter trials that report incomplete survival data. You may find a log-rank p-value but no HR, or you may need to express a treatment effect as NNT for a formulary committee. ParCC bridges these gaps."),

               h4("Scenario A: Extracting a Hazard Ratio from a Log-rank Test"),
               p("You are conducting a systematic review of adjuvant chemotherapy in colon cancer. An older trial (published 2005) reports:"),
               div(class = "well",
                   tags$ul(
                     tags$li("Log-rank chi-squared = ", strong("6.8")),
                     tags$li("Total events (deaths) = ", strong("142")),
                     tags$li("The trial favours the treatment arm.")
                   )
               ),
               p("The paper does not report a Hazard Ratio."),

               h4("The ParCC Solution (Log-rank \u2192 HR)"),
               tags$ol(
                 tags$li("Navigate to ", strong("Converters > HR Converter > Log-rank \u2192 HR"), "."),
                 tags$li("Select input: ", strong("Chi-squared statistic"), "."),
                 tags$li("Input chi-squared = ", strong("6.8"), ", Total events = ", strong("142"), "."),
                 tags$li("Select direction: ", strong("Treatment is better"), " (HR < 1)."),
                 tags$li("Result: ", strong("HR = 0.68"), " (95% CI: 0.51 - 0.91).")
               ),
               p("This uses the Peto approximation: log(HR) \u2248 \u00b1z/\u221a(E/4), where z = \u221a(\u03c7\u00b2). This method is recommended by the Cochrane Handbook when only summary statistics are available."),

               h4("Scenario B: Computing NNT for a Formulary Decision"),
               p("A hospital Pharmacy & Therapeutics committee asks: 'How many patients do we need to treat with Drug X to prevent one death?' The trial reports:"),
               div(class = "well",
                   tags$ul(
                     tags$li("12-month mortality: Control = 18%, Intervention = 12%")
                   )
               ),

               h4("The ParCC Solution (NNT Calculator)"),
               tags$ol(
                 tags$li("Navigate to ", strong("Converters > HR Converter > NNT/NNH"), "."),
                 tags$li("Select input mode: ", strong("Two Probabilities"), "."),
                 tags$li("Input Control = ", strong("0.18"), ", Intervention = ", strong("0.12"), "."),
                 tags$li("Result: ARR = ", strong("6.0%"), ", NNT = ", strong("17"), ".")
               ),
               p("Interpretation: For every 17 patients treated with Drug X instead of the comparator for 12 months, one additional death is prevented. This is a clinically meaningful and easily communicated number."),

               h4("When to Use These Tools"),
               div(class = "use-case-box",
                   span(class = "use-case-title", "Key Applications"),
                   tags$ul(
                     tags$li("Systematic reviews where older trials lack HR estimates"),
                     tags$li("Indirect treatment comparisons needing HR inputs from published statistics"),
                     tags$li("Communicating treatment effects to clinicians and formulary committees"),
                     tags$li("Sensitivity analyses varying NNT across plausible baseline risk ranges")
                   )
               )
      ),

      "Advanced Modeling",
      tabPanel("Survival Curves",
               h3("Tutorial 3: Extrapolating Survival"),
               p(class="text-info", strong("Concept:"), " Trials are short (e.g., 3 years), but models are long (e.g., Lifetime). You must fit a mathematical curve to the trial data to predict what happens after the trial ends."),
               
               h4("The Real-World Scenario"),
               p("You are modeling a chemotherapy drug. The trial stopped at 36 months. You have a PDF of the Kaplan-Meier curve but no raw patient data."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Look at the published curve. Pick two points that summarize the shape."),
                 tags$li("Point 1: At Month 12, survival is ", strong("80%"), "."),
                 tags$li("Point 2: At Month 36, survival is ", strong("50%"), "."),
                 tags$li("Navigate to ", strong("Survival > Weibull (From 2 Time Points)"), "."),
                 tags$li("Input these values."),
                 tags$li("Result: ParCC calculates the ", strong("Shape"), " and ", strong("Scale"), " parameters."),
                 tags$li("Check the Plot: Does the blue line pass through your points? If yes, use these parameters to project out to 20 years.")
               )
      ),
      
      tabPanel("Bg Mortality (SMR)",
               h3("Tutorial 4: The 'Sick Cohort' Problem"),
               p(class="text-info", strong("Concept:"), " Census Life Tables describe the average healthy person. Your patients are sick. If you use the census table, your model will wrongly assume your patients live as long as healthy people."),
               
               h4("The Real-World Scenario"),
               p("You are modeling a cohort of 60-year-old smokers. The Census says the mortality rate for age 60 is ", strong("0.008"), ". Literature says smokers have a Hazard Ratio (SMR) of ", strong("2.5"), " vs non-smokers."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("Bg Mortality > SMR Adjustment"), "."),
                 tags$li("Input Base Rate = ", strong("0.008"), "."),
                 tags$li("Input SMR = ", strong("2.5"), "."),
                 tags$li("Result: ", strong("0.0198"), "."),
               ),
               p("You have created a 'Synthetic Life Table'. Use ", strong("0.0198"), " as the background mortality probability for age 60 in your model.")
      ),
      
      tabPanel("Dirichlet & Log-Logistic",
               h3("Tutorial: Advanced Distributions for Markov Models"),
               p(class="text-info", strong("Concept:"), " Standard PSA uses Beta (utilities) and Gamma (costs). But two common modelling situations need specialised distributions: (1) multinomial transition probabilities require the Dirichlet distribution to maintain row-sum = 1, and (2) diseases with hump-shaped hazards (e.g., post-surgical risk) need the Log-Logistic survival model."),

               h4("Part A: Dirichlet for Transition Matrices"),
               p("You are building a 3-state Markov model for Chronic Kidney Disease (Stable \u2192 Progressed \u2192 Dead). From a cohort study of 200 patients observed for 1 year starting in the 'Stable' state:"),
               div(class = "well",
                   tags$ul(
                     tags$li("150 remained Stable"),
                     tags$li("35 progressed to CKD Stage 4"),
                     tags$li("15 died")
                   )
               ),
               p("These three probabilities must sum to 1.0 in every PSA iteration. If you sample them independently (e.g., three separate Beta distributions), they will almost never sum to 1, breaking the model."),

               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("PSA > Dirichlet (Multinomial)"), "."),
                 tags$li("Enter observed counts: ", strong("150, 35, 15"), "."),
                 tags$li("Enter state labels: ", strong("Stable, Progressed, Dead"), "."),
                 tags$li("Click ", strong("Fit & Sample"), ".")
               ),
               p("ParCC calculates Dirichlet parameters (\u03b1 = observed counts) and draws samples using the Gamma decomposition method. Each draw is a complete probability vector that sums to exactly 1.0. Copy the R code snippet directly into your PSA loop."),

               h4("Part B: Log-Logistic for Non-Monotonic Hazards"),
               p("You are modelling recovery after hip replacement surgery. The hazard of revision is:"),
               div(class = "well",
                   tags$ul(
                     tags$li("Low immediately after surgery (patient is closely monitored)"),
                     tags$li("Peaks around year 5-7 (implant loosening)"),
                     tags$li("Declines after year 10 (survivors have well-fixed implants)")
                   )
               ),
               p("Neither Exponential (constant hazard) nor Weibull (monotonic hazard) can capture this hump-shaped pattern. The Log-Logistic distribution can."),

               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("From a published KM curve, identify two time-survival points:"),
                 tags$li("Point 1: At Year 5, implant survival = ", strong("92%"), "."),
                 tags$li("Point 2: At Year 15, implant survival = ", strong("78%"), "."),
                 tags$li("Navigate to ", strong("Survival > Log-Logistic (From 2 Time Points)"), "."),
                 tags$li("Enter the values. ParCC solves for \u03b1 (scale) and \u03b2 (shape)."),
                 tags$li("Check that \u03b2 > 1 in the output (confirms the hump-shaped hazard you expect).")
               ),

               h4("Choosing the Right Survival Distribution"),
               div(class = "well",
                   tags$table(style = "width: 100%;",
                     tags$tr(tags$th("Distribution"), tags$th("Hazard Shape"), tags$th("Best For")),
                     tags$tr(tags$td("Exponential"), tags$td("Constant"), tags$td("Stable chronic conditions")),
                     tags$tr(tags$td("Weibull"), tags$td("Monotonic (up or down)"), tags$td("Cancer mortality, device failure")),
                     tags$tr(tags$td("Log-Logistic"), tags$td("Hump-shaped or decreasing"), tags$td("Post-surgical revision, immune response"))
                   )
               )
      ),

      "Uncertainty (PSA)",
      tabPanel("PSA: Utilities (Beta)",
               h3("Tutorial 5A: Parameterizing Utilities"),
               p(class="text-info", strong("Concept:"), " Utility values (Quality of Life) are bounded between 0 (Death) and 1 (Perfect Health). If you use a Normal distribution in PSA, the model might randomly sample a value like 1.05, which is impossible and invalidates the result."),
               
               h4("The Real-World Scenario"),
               p("A Quality of Life study reports the utility of 'Stable Disease' as ", strong("Mean = 0.76"), " with a ", strong("Standard Error = 0.03"), "."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("PSA > Beta Distribution"), " (The standard for bounded 0-1 data)."),
                 tags$li("Input Mean = ", strong("0.76"), "."),
                 tags$li("Input SE = ", strong("0.03"), "."),
                 tags$li("Result: ParCC calculates ", strong("Alpha = 202.1"), " and ", strong("Beta = 63.8"), "."),
                 tags$li("Copy these two parameters into TreeAge or R for your PSA definition.")
               )
      ),
      
      tabPanel("PSA: Costs (Gamma)",
               h3("Tutorial 5B: Parameterizing Costs"),
               p(class="text-info", strong("Concept:"), " Costs are skewed. Most patients cost a little, but a few cost a lot (long tail). Also, costs cannot be negative. A Normal distribution is symmetric and allows negatives, so it is wrong for costs."),
               
               h4("The Real-World Scenario"),
               p("A costing study reports the mean cost of surgery is ", strong("INR 25,000"), " with a Standard Error of ", strong("INR 5,000"), "."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("PSA > Gamma Distribution"), " (The standard for costs)."),
                 tags$li("Input Mean = ", strong("25000"), ", SE = ", strong("5000"), "."),
                 tags$li("Result: ParCC calculates ", strong("Shape (k)"), " and ", strong("Scale (theta)"), "."),
                 tags$li(strong("Tip:"), " If SE is missing but you have a range (e.g., INR 15k - 35k), use the 'Mean & Range' option to estimate SE via the Rule of 4.")
               )
      ),
      
      "Finance & Pricing",
      tabPanel("Inflation (Historical Data)",
               h3("Tutorial 6: Updating Old Costs"),
               p(class="text-info", strong("Concept:"), " Money loses value over time. You cannot use a cost from 2019 in a 2025 model without adjusting for inflation."),
               
               h4("The Real-World Scenario"),
               p("You are conducting a Budget Impact Analysis for 2025. The only reliable costing study for the surgery was conducted in ", strong("2019"), ", reporting a cost of ", strong("INR 12,000"), "."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("Financial > Inflation"), "."),
                 tags$li("Input Cost = ", strong("12000"), "."),
                 tags$li("Select 'Using Price Indices (CPI)' for accuracy, or 'Average Rate' (e.g., 5%) for estimates."),
                 tags$li("Set Base Year = ", strong("2019"), ", Target Year = ", strong("2025"), "."),
                 tags$li("Result: The adjusted cost (e.g., ", strong("INR 16,081"), ") reflects current purchasing power.")
               )
      ),
      
      tabPanel("Discounting (Future Value)",
               h3("Tutorial 7: Adjusting for Time Preference"),
               p(class="text-info", strong("Concept:"), " Society values health and money ", em("today"), " more than in the future. Costs and QALYs occurring in future years must be 'discounted' to their Present Value (PV)."),
               
               h4("The Real-World Scenario"),
               p("Your model predicts that a patient will need a revision surgery in ", strong("Year 10"), ". The current cost of that surgery is ", strong("INR 200,000"), ". The HTAIn guideline mandates a ", strong("3%"), " discount rate."),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("Financial > Discounting"), "."),
                 tags$li("Input Undiscounted Value = ", strong("200000"), "."),
                 tags$li("Input Discount Rate = ", strong("3"), "."),
                 tags$li("Input Time = ", strong("10"), "."),
                 tags$li("Result: ", strong("INR 148,818"), ". This is the value you enter into the Year 10 cost column of your model.")
               )
      ),
      
      tabPanel("Value-Based Pricing",
               h3("Tutorial 8: The Negotiation (POCT Example)"),
               p(class="text-info", strong("Concept:"), " Value-Based Pricing (VBP) calculates the maximum price a payer *should* pay, given the health benefit and the cost of associated care."),
               
               h4("The Real-World Scenario: 'SepsiQuick'"),
               p("You are a startup launching 'SepsiQuick', a new Point-of-Care Test (POCT) for sepsis. It gives results in 15 mins vs. 24 hours for the old lab test."),
               
               h5("The Evidence:"),
               tags$ul(
                 tags$li(strong("Benefit:"), " Early treatment saves ", strong("0.02 QALYs"), " per patient."),
                 tags$li(strong("Comparator Cost:"), " The old lab test costs ", strong("INR 500"), "."),
                 tags$li(strong("Associated Cost:"), " To use SepsiQuick, a nurse must spend 20 mins (Cost = ", strong("INR 200"), ")."),
                 tags$li(strong("WTP Threshold:"), " The government pays ", strong("INR 100,000"), " per QALY.")
               ),
               
               h4("The Question: What price should you set?"),
               
               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("ICER / NMB > Value-Based Pricing"), "."),
                 tags$li("Input Incremental QALYs (\u0394E) = ", strong("0.02"), "."),
                 tags$li("Input Comparator Cost = ", strong("500"), "."),
                 tags$li("Input Associated Costs = ", strong("200"), "."),
                 tags$li("Input Target WTP = ", strong("100000"), "."),
                 tags$li("Assume 1 Unit per patient."),
                 tags$li("Click Calculate.")
               ),
               
               h4("The Interpretation (Waterfall Logic)"),
               tags$ul(
                 tags$li(strong("Clinical Value:"), " 0.02 * 100,000 = INR 2,000 (Value created)."),
                 tags$li(strong("Savings:"), " + INR 500 (Money diverted from old test)."),
                 tags$li(strong("Total Headroom:"), " INR 2,500 (Total Budget in the pot)."),
                 tags$li(strong("Minus Nurse Time:"), " - INR 200 (Must pay the nurse first)."),
                 tags$li(strong("Max Price:"), " ", strong("INR 2,300"), ". This is the highest justifiable price.")
               ),
               p("If you price it at INR 3,000, ParCC will recommend: ", span(style="color:orange; font-weight:bold;", "Reduce Price by 23%."))
      ),

      "Budget & Population Impact",
      tabPanel("Budget Impact Analysis",
               h3("Tutorial: 5-Year Budget Impact for a New Technology"),
               p(class="text-info", strong("Concept:"), " A Budget Impact Analysis (BIA) estimates the financial consequences of adopting a new health technology from the payer's perspective over a short time horizon (typically 1-5 years). Unlike CEA, BIA focuses on affordability, not value for money."),

               h4("The Real-World Scenario"),
               p("You are advising a state health insurance programme on adopting a new oral anticoagulant (NOAC) to replace warfarin for Atrial Fibrillation. You need to estimate the 5-year budget impact."),
               div(class = "well",
                   tags$ul(
                     tags$li(strong("Covered Population:"), " 10,000,000 (state insurance enrolees)"),
                     tags$li(strong("AF Prevalence:"), " 0.8% (80,000 patients)"),
                     tags$li(strong("Eligible for Anticoagulation:"), " 60% of AF patients (48,000)"),
                     tags$li(strong("Uptake Trajectory:"), " Year 1: 10%, Year 2: 25%, Year 3: 45%, Year 4: 60%, Year 5: 70%"),
                     tags$li(strong("Current Therapy (Warfarin):"), " Per-patient annual cost = 8,000 (drug + INR monitoring)"),
                     tags$li(strong("New Therapy (NOAC):"), " Per-patient annual cost = 22,000 (drug only, no monitoring)"),
                     tags$li(strong("Discount Rate:"), " 3% per year")
                   )
               ),

               h4("The ParCC Solution"),
               tags$ol(
                 tags$li("Navigate to ", strong("Economics > Budget Impact"), "."),
                 tags$li("Enter Population = ", strong("10,000,000"), "."),
                 tags$li("Enter Prevalence = ", strong("0.008"), ", Eligible % = ", strong("60"), "."),
                 tags$li("Enter the 5-year uptake values: ", strong("10, 25, 45, 60, 70"), "."),
                 tags$li("Enter Per-Patient Cost (New) = ", strong("22,000"), ", (Current) = ", strong("8,000"), "."),
                 tags$li("Set Discount Rate = ", strong("3"), "%."),
                 tags$li("Click ", strong("Calculate BIA"), ".")
               ),

               h4("Reading the Output"),
               p("ParCC produces a year-by-year table and chart showing:"),
               tags$ul(
                 tags$li(strong("Target Population:"), " 48,000 eligible patients (fixed each year)."),
                 tags$li(strong("Year 1 Impact:"), " 4,800 patients switch (10% uptake). Incremental cost = 4,800 \u00d7 (22,000 - 8,000) = 67.2 million."),
                 tags$li(strong("Year 5 Impact:"), " 33,600 patients on NOAC (70% uptake). Incremental cost is higher but discounted."),
                 tags$li(strong("Cumulative 5-Year Impact:"), " The discounted total represents the additional budget the insurer needs.")
               ),

               h4("ISPOR Good Practice Checklist"),
               div(class = "use-case-box",
                   span(class = "use-case-title", "Key Considerations for BIA"),
                   tags$ul(
                     tags$li("Use a short time horizon (1-5 years) matching the payer's budget cycle"),
                     tags$li("Model uptake realistically (S-curve adoption, not instant switching)"),
                     tags$li("Include only direct costs relevant to the payer perspective"),
                     tags$li("Present undiscounted results as the primary analysis (discounted as secondary)"),
                     tags$li("Run scenario analyses on uptake rates and eligible population")
                   )
               )
      )
    )
  )
}

# ==============================================================================
# MODULE: FORMULAE
# ==============================================================================
mod_formulae_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    div(class = "about-header", style = "padding: 15px; margin-bottom: 20px;",
        h2("Mathematical Framework"),
        p("Standardized equations used for parameter estimation.")
    ),
    
    navlistPanel(
      widths = c(3, 9),
      "Core Conversions",
      tabPanel("Rates & Probabilities",
               h3("Rates and Probabilities"),
               p("The relationship between an instantaneous rate \\(r\\) and a probability \\(p\\) over time \\(t\\) is governed by the exponential function."),
               div(class = "well",
                   p(strong("Rate to Probability:")),
                   p("$$p = 1 - e^{-rt}$$"),
                   p(strong("Probability to Rate:")),
                   p("$$r = -\\frac{\\ln(1-p)}{t}$$")
               ),
               tags$small(icon("book"), " Reference: Sonnenberg FA, Beck JR. Markov models in medical decision making. Med Decis Making. 1993.")
      ),
      
      tabPanel("Odds & Probabilities",
               h3("Odds and Probabilities"),
               div(class = "well",
                   p(strong("Odds to Probability:")),
                   p("$$p = \\frac{\\text{Odds}}{1 + \\text{Odds}}$$"),
                   p(strong("Probability to Odds:")),
                   p("$$\\text{Odds} = \\frac{p}{1 - p}$$")
               ),
               tags$small(icon("book"), " Reference: Briggs A, et al. Oxford University Press; 2006.")
      ),
      
      tabPanel("Time Rescaling",
               h3("Time Rescaling"),
               div(class = "well",
                   p("$$p_{new} = 1 - (1 - p_{old})^{\\frac{t_{new}}{t_{old}}}$$")
               ),
               tags$small(icon("book"), " Reference: Fleurence RL, et al. Pharmacoeconomics. 2007.")
      ),

      tabPanel("HR-Based Conversion",
               h3("Hazard Ratio to Intervention Probability"),
               p("When a clinical trial reports a Hazard Ratio (HR) comparing an intervention to a control, the intervention probability is derived by applying the HR to the control group's underlying rate."),
               div(class = "well",
                   p(strong("Step 1: Control Probability to Rate")),
                   p("$$r_{control} = -\\frac{\\ln(1 - p_{control})}{t}$$"),
                   p(strong("Step 2: Apply Hazard Ratio")),
                   p("$$r_{intervention} = r_{control} \\times HR$$"),
                   p(strong("Step 3: Rate to Intervention Probability")),
                   p("$$p_{intervention} = 1 - e^{-r_{intervention} \\times t_{cycle}}$$")
               ),
               p(strong("Key Assumption:"), " The Proportional Hazards assumption states that the HR is constant over time. This is standard in Markov cohort models."),
               p(strong("Clinical Measures:")),
               div(class = "well",
                   p("$$ARR = p_{control} - p_{intervention}$$"),
                   p("$$RRR = \\frac{ARR}{p_{control}}$$"),
                   p("$$NNT = \\lceil \\frac{1}{ARR} \\rceil$$")
               ),
               tags$small(icon("book"), " References: Sonnenberg FA, Beck JR. Med Decis Making. 1993; Briggs A, et al. Oxford University Press; 2006; NICE DSU TSD 14. 2013.")
      ),

      tabPanel("OR \u2194 RR & Effect Sizes",
               h3("OR-RR Conversion (Zhang & Yu)"),
               div(class = "well",
                   p(strong("OR to RR:")),
                   p("$$RR = \\frac{OR}{1 - p_0 + p_0 \\times OR}$$"),
                   p(strong("RR to OR:")),
                   p("$$OR = \\frac{RR \\times (1 - p_0)}{1 - RR \\times p_0}$$")
               ),
               p("where \\(p_0\\) = baseline risk in the control group."),
               tags$small(icon("book"), " Reference: Zhang J, Yu KF. What's the relative risk? JAMA. 1998;280(19):1690-1691."),
               hr(),
               h3("Effect Size Conversions"),
               div(class = "well",
                   p(strong("SMD to log(OR) (Chinn 2000):")),
                   p("$$\\ln(OR) = SMD \\times \\frac{\\pi}{\\sqrt{3}} \\approx SMD \\times 1.8138$$"),
                   p(strong("log(OR) to log(RR):")),
                   p("$$\\ln(RR) = \\ln\\left(\\frac{e^{\\ln(OR)}}{1 - p_0 + p_0 \\times e^{\\ln(OR)}}\\right)$$")
               ),
               tags$small(icon("book"), " Reference: Chinn S. A simple method for converting an odds ratio to effect size. Stat Med. 2000;19(22):3127-3131.")
      ),

      tabPanel("NNT & Log-rank to HR",
               h3("Number Needed to Treat"),
               div(class = "well",
                   p("$$NNT = \\lceil \\frac{1}{ARR} \\rceil = \\lceil \\frac{1}{p_{control} - p_{intervention}} \\rceil$$"),
                   p(strong("From RR and baseline risk:")),
                   p("$$ARR = p_0 \\times (1 - RR)$$"),
                   p(strong("From OR and baseline risk:")),
                   p("$$p_1 = \\frac{OR \\times p_0}{1 - p_0 + OR \\times p_0}, \\quad ARR = p_0 - p_1$$")
               ),
               hr(),
               h3("Log-rank to Hazard Ratio (Peto)"),
               div(class = "well",
                   p(strong("From chi-squared:")),
                   p("$$\\ln(HR) = \\pm \\frac{\\sqrt{\\chi^2}}{\\sqrt{E/4}}$$"),
                   p(strong("From p-value:")),
                   p("$$z = \\Phi^{-1}(1 - p/2), \\quad \\ln(HR) = \\pm \\frac{z}{\\sqrt{E/4}}$$"),
                   p(strong("95% CI:")),
                   p("$$\\ln(HR) \\pm \\frac{1.96}{\\sqrt{E/4}}$$")
               ),
               p("where \\(E\\) = total number of events across both arms."),
               tags$small(icon("book"), " Reference: Tierney JF, et al. Practical methods for incorporating summary time-to-event data into meta-analysis. Trials. 2007;8:16.")
      ),

      "Advanced Models",
      tabPanel("Survival Analysis",
               h3("Parametric Survival Models"),
               h4("1. Exponential Distribution"),
               p("$$\\lambda = \\frac{\\ln(2)}{M}, \\quad S(t) = e^{-\\lambda t}$$"),
               h4("2. Weibull Distribution"),
               p("$$\\ln(-\\ln(S(t))) = \\ln(\\lambda) + \\gamma \\ln(t)$$"),
               h4("3. Log-Logistic Distribution"),
               p("$$S(t) = \\frac{1}{1 + (t/\\alpha)^\\beta}$$"),
               p(strong("Hazard function:")),
               p("$$h(t) = \\frac{(\\beta/\\alpha)(t/\\alpha)^{\\beta-1}}{1 + (t/\\alpha)^\\beta}$$"),
               p("When \\(\\beta > 1\\), the hazard is hump-shaped (rises then falls). When \\(\\beta \\leq 1\\), the hazard is monotonically decreasing."),
               tags$small(icon("book"), " Reference: Collett D. Modelling Survival Data in Medical Research.")
      ),
      
      tabPanel("PSA (Method of Moments)",
               h3("Method of Moments"),
               div(class="well",
                   strong("Beta Distribution (0-1):"),
                   p("$$\\alpha = \\mu \\left( \\frac{\\mu(1-\\mu)}{SE^2} - 1 \\right), \\quad \\beta = (1-\\mu) \\left( \\frac{\\mu(1-\\mu)}{SE^2} - 1 \\right)$$"),
                   strong("Gamma Distribution (>0):"),
                   p("$$k = \\frac{\\mu^2}{SE^2}, \\quad \\theta = \\frac{SE^2}{\\mu}$$"),
                   strong("LogNormal Distribution:"),
                   p("$$\\sigma_{log}^2 = \\ln\\left(1 + \\frac{SE^2}{\\mu^2}\\right), \\quad \\mu_{log} = \\ln(\\mu) - 0.5 \\sigma_{log}^2$$"),
                   strong("Dirichlet Distribution (Multinomial):"),
                   p("$$\\boldsymbol{\\alpha} = (n_1, n_2, \\ldots, n_K) \\quad \\text{where } n_i \\text{ = observed counts}$$"),
                   p("Sampling via Gamma decomposition: draw \\(X_i \\sim \\text{Gamma}(\\alpha_i, 1)\\), then \\(p_i = X_i / \\sum X_j\\). The resulting vector \\((p_1, \\ldots, p_K)\\) sums to 1.")
               ),
               h4("Approximation (Rule of 4)"),
               p("$$SE \\approx \\frac{\\text{High} - \\text{Low}}{4}$$")
      ),
      
      tabPanel("Background Mortality",
               h3("Mortality Adjustments"),
               p(strong("SMR Adjustment:")),
               p("$$r_{disease} = r_{pop} \\times SMR$$"),
               p(strong("Linear Interpolation:")),
               p("$$y = y_1 + (x - x_1) \\frac{y_2 - y_1}{x_2 - x_1}$$"),
               p(strong("Gompertz Law:")),
               p("$$r(t) = \\alpha \\cdot e^{\\beta t}$$"),
               p(strong("DEALE (Excess Mortality):")),
               p("$$r_{disease} = \\frac{1}{LE_{observed}} - \\frac{1}{LE_{background}}$$")
      ),
      
      "Economic Results",
      tabPanel("ICER & NMB",
               h3("Outcome Metrics"),
               p("$$ICER = \\frac{\\Delta Cost}{\\Delta Effect}$$"),
               p(strong("Net Monetary Benefit (iNMB):")),
               p("$$iNMB = (\\Delta Effect \\times WTP) - \\Delta Cost$$")
      ),
      
      tabPanel("Value-Based Pricing",
               h3("Innovation Headroom Method"),
               p("Calculating the maximum justifiable unit price (\\(P_{max}\\)) based on the WTP threshold."),
               div(class="well",
                   p("1. Calculate Total Allowable Cost (Headroom):"),
                   p("$$C_{max} = (\\Delta E \\times WTP) + C_{comparator}$$"),
                   p("2. Subtract Fixed Associated Costs ($C_a$) and divide by units ($N$):"),
                   p("$$P_{max} = \\frac{C_{max} - C_a}{N}$$")
               ),
               tags$small(icon("book"), " Reference: Cosh E, et al. The value of 'innovation headroom'. Value in Health. 2007.")
      ),

      tabPanel("Annuity / PV Stream",
               h3("Present Value of Recurring Costs"),
               div(class = "well",
                   p(strong("Ordinary Annuity"), " (payments at end of each period):"),
                   p("$$PV = C \\times \\frac{1 - (1 + r)^{-n}}{r}$$"),
                   p(strong("Annuity Due"), " (payments at beginning of each period):"),
                   p("$$PV = C \\times \\frac{1 - (1 + r)^{-n}}{r} \\times (1 + r)$$")
               ),
               p("where \\(C\\) = annual cost, \\(r\\) = discount rate, \\(n\\) = number of years.")
      ),

      tabPanel("Budget Impact Analysis",
               h3("ISPOR BIA Framework"),
               div(class = "well",
                   p(strong("Target Population:")),
                   p("$$N_{target} = N_{total} \\times Prevalence \\times Eligible\\%$$"),
                   p(strong("Year-Specific Budget Impact:")),
                   p("$$BI_t = N_{target} \\times Uptake_t \\times (C_{new} - C_{current}) \\times \\frac{1}{(1+r)^t}$$"),
                   p(strong("Cumulative Budget Impact:")),
                   p("$$BI_{total} = \\sum_{t=1}^{T} BI_t$$")
               ),
               tags$small(icon("book"), " Reference: Sullivan SD, et al. Budget impact analysis - principles of good practice: report of the ISPOR 2012 Budget Impact Analysis Good Practice II Task Force. Value Health. 2014;17(1):5-14.")
      )
    )
  )
}

# ==============================================================================
# MODULE: ABOUT
# ==============================================================================
mod_about_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    column(8, offset = 2,
           div(class = "about-header",
               h1("ParCC v1.4"),
               p("Parameter Converter & Calculator for Health Economic Evaluation"),
               p(style = "font-size: 0.9em; opacity: 0.8;", "R Package Edition")
           ),

           div(class = "about-card",
               h3("Development Team"),
               p(class = "lead", "This tool was developed by the Regional Resource Centre for Health Technology Assessment (RRC-HTA), AIIMS Bhopal team."),
               p(strong("Under the aegis of:"), " HTAIn, DHR, MoHFW, GoI."),

               hr(),
               h4("Features"),
               tags$table(style = "width:100%; border-collapse: collapse;",
                 tags$thead(
                   tags$tr(style = "border-bottom: 2px solid #003366;",
                     tags$th(style = "padding: 8px; text-align: left;", "Module"),
                     tags$th(style = "padding: 8px; text-align: left;", "Capabilities")
                   )
                 ),
                 tags$tbody(
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "Converters"),
                     tags$td(style = "padding: 8px;", "Rate-Probability, Odds-Probability, Time Rescaling, OR-RR (Zhang & Yu), Effect Size (Chinn)")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "HR Converter"),
                     tags$td(style = "padding: 8px;", "HR-to-probability, multi-HR comparison, NNT/NNH calculator, Log-rank to HR (Peto)")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "Survival"),
                     tags$td(style = "padding: 8px;", "Exponential, Weibull & Log-Logistic extrapolation from KM data")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "Bg Mortality"),
                     tags$td(style = "padding: 8px;", "SMR adjustment, Linear interpolation, Gompertz fit, DEALE")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "PSA Distributions"),
                     tags$td(style = "padding: 8px;", "Beta, Gamma, LogNormal (Method of Moments), Dirichlet (Multinomial)")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "Diagnostics"),
                     tags$td(style = "padding: 8px;", "PPV/NPV from sensitivity, specificity, and prevalence")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "Financial"),
                     tags$td(style = "padding: 8px;", "Cost inflation, discounting, annuity/PV stream calculator")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "ICER & NMB"),
                     tags$td(style = "padding: 8px;", "Incremental cost-effectiveness ratio, incremental net monetary benefit")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "Value-Based Pricing"),
                     tags$td(style = "padding: 8px;", "Headroom analysis, maximum justifiable price, WTP breakeven")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee; background: #f0fff0;",
                     tags$td(style = "padding: 8px; font-weight: bold; color: #155724;", "Budget Impact (New)"),
                     tags$td(style = "padding: 8px;", "5-year BIA framework with population uptake curves and discounting (ISPOR)")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee; background: #f0fff0;",
                     tags$td(style = "padding: 8px; font-weight: bold; color: #155724;", "PPP Converter (New)"),
                     tags$td(style = "padding: 8px;", "PPP conversion (30 countries), market FX comparison, WHO-CHOICE WTP thresholds (1x & 3x GDP/capita)")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee; background: #f0fff0;",
                     tags$td(style = "padding: 8px; font-weight: bold; color: #155724;", "Global Currency (New)"),
                     tags$td(style = "padding: 8px;", "INR, USD, EUR, GBP, JPY, BRL, THB, AUD, CAD, and custom currencies")
                   ),
                   tags$tr(style = "border-bottom: 1px solid #eee;",
                     tags$td(style = "padding: 8px; font-weight: bold;", "Batch Processing"),
                     tags$td(style = "padding: 8px;", "Bulk rate-probability, odds-probability, and HR-based conversions with CSV upload/download")
                   )
                 )
               ),
               p(style = "margin-top: 10px; font-size: 0.85em; color: #666;",
                 "All modules include step-by-step explanations, rendered formulas, and literature citations on the output panel."),

               hr(),
               h4("Technical Acknowledgement"),
               p("This application was architected and code-generated with the assistance of Large Language Models (Google Gemini, Anthropic Claude), under the supervision of RRC-HTA researchers."),

               hr(),
               h4("Links"),
               tags$ul(style = "list-style: none; padding-left: 0;",
                 tags$li(style = "margin-bottom: 8px;",
                   icon("globe"), " ",
                   tags$a(href = "https://drpakhare.github.io/ParCC/",
                          target = "_blank", "Documentation & Vignettes"),
                   tags$span(style = "color: #888; font-size: 0.85em;", " - pkgdown site with tutorials and formula references")
                 ),
                 tags$li(style = "margin-bottom: 8px;",
                   icon("github"), " ",
                   tags$a(href = "https://github.com/drpakhare/ParCC",
                          target = "_blank", "GitHub Repository"),
                   tags$span(style = "color: #888; font-size: 0.85em;", " - source code, issues, and releases")
                 ),
                 tags$li(style = "margin-bottom: 8px;",
                   icon("box-open"), " ",
                   tags$span("Install from GitHub: "),
                   tags$code("remotes::install_github(\"drpakhare/ParCC\")")
                 )
               ),

               hr(),
               h4("Suggested Citation"),
               div(class = "well", style = "font-family: monospace; font-size: 0.9em;",
                   "Regional Resource Centre for HTA, AIIMS Bhopal. (2025). ParCC: Parameter Converter & Calculator for Health Economic Evaluation (Version 1.4.0) [R package]. Available at: https://drpakhare.github.io/ParCC/"
               ),

               hr(),
               h4("Disclaimer"),
               p("This tool is intended for research and educational purposes only. While every effort has been made to ensure the accuracy of the algorithms, the developers accept no liability for errors or omissions in the calculations or for decisions made based on these results. Users are encouraged to verify critical parameters manually."),

               hr(),
               h4("License"),
               p("Released under the MIT Open Source License."),
               p(icon("envelope"), " Contact: hta@aiimsbhopal.edu.in"),
               p(icon("globe"), " ",
                 tags$a(href = "https://drpakhare.github.io/ParCC/",
                        target = "_blank", "https://drpakhare.github.io/ParCC/"))
           )
    )
  )
}