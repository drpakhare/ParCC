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
                 tags$li("Navigate to ", strong("Converters > Rate ↔ Probability"), "."),
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
                 tags$li("Input Incremental QALYs (ΔE) = ", strong("0.02"), "."),
                 tags$li("Input Comparator Cost = ", strong("500"), "."),
                 tags$li("Input Associated Costs = ", strong("200"), "."),
                 tags$li("Input Target WTP = ", strong("100000"), "."),
                 tags$li("Assume 1 Unit per patient."),
                 tags$li("Click Calculate.")
               ),
               
               h4("The Interpretation (Waterfall Logic)"),
               tags$ul(
                 tags$li(strong("Clinical Value:"), " 0.02 × 100,000 = INR 2,000 (Value created)."),
                 tags$li(strong("Savings:"), " + INR 500 (Money diverted from old test)."),
                 tags$li(strong("Total Headroom:"), " INR 2,500 (Total Budget in the pot)."),
                 tags$li(strong("Minus Nurse Time:"), " - INR 200 (Must pay the nurse first)."),
                 tags$li(strong("Max Price:"), " ", strong("INR 2,300"), ". This is the highest justifiable price.")
               ),
               p("If you price it at INR 3,000, ParCC will recommend: ", span(style="color:orange; font-weight:bold;", "Reduce Price by 23%."))
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
      
      "Advanced Models",
      tabPanel("Survival Analysis",
               h3("Parametric Survival Models"),
               h4("1. Exponential Distribution"),
               p("$$\\lambda = \\frac{\\ln(2)}{M}, \\quad S(t) = e^{-\\lambda t}$$"),
               h4("2. Weibull Distribution"),
               p("$$\\ln(-\\ln(S(t))) = \\ln(\\lambda) + \\gamma \\ln(t)$$"),
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
                   p("$$\\sigma_{log}^2 = \\ln\\left(1 + \\frac{SE^2}{\\mu^2}\\right), \\quad \\mu_{log} = \\ln(\\mu) - 0.5 \\sigma_{log}^2$$")
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
               h1("ParCC"),
               p("Parameter Converter & Calculator for Health Economic Evaluation")
           ),
           
           div(class = "about-card",
               h3("Development Team"),
               p(class = "lead", "This tool was developed by the Regional Resource Centre for Health Technology Assessment (RRC-HTA), AIIMS Bhopal team."),
               p(strong("Under the aegis of:"), " HTAIn, DHR, MoHFW, GoI."),
               
               hr(),
               h4("Technical Acknowledgement"),
               p("This application was architected and code-generated with the assistance of Large Language Models (Google Gemini), under the supervision of RRC-HTA researchers."),
               
               hr(),
               h4("Suggested Citation"),
               div(class = "well", style = "font-family: monospace; font-size: 0.9em;",
                   "Regional Resource Centre for HTA, AIIMS Bhopal. (2025). ParCC: Parameter Converter & Calculator for Health Economic Evaluation (Version 6.2) [Software]. Available at: [URL]"
               ),
               
               hr(),
               h4("Disclaimer"),
               p("This tool is intended for research and educational purposes only. While every effort has been made to ensure the accuracy of the algorithms, the developers accept no liability for errors or omissions in the calculations or for decisions made based on these results. Users are encouraged to verify critical parameters manually."),
               
               hr(),
               h4("License"),
               p("Released under the MIT Open Source License."),
               p(icon("envelope"), " Contact: hta@aiimsbhopal.edu.in")
           )
    )
  )
}