mod_lifetable_ui <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    # --- Tab 1: SMR Adjustment ---
    tabPanel("SMR Adjustment",
             sidebarLayout(
               sidebarPanel(
                 h4("Disease-Specific Mortality"),
                 textInput(ns("lbl_smr"), "Parameter Name:", placeholder = "e.g., Diabetes Mortality"),
                 hr(),
                 numericInput(ns("base_val"), "Gen. Pop. Mortality:", value = 0.005, min = 0, step = 0.001),
                 radioButtons(ns("input_type"), "Input Type:",
                              choices = c("Annual Probability (qx)" = "prob",
                                          "Instantaneous Rate (mx)" = "rate")),
                 numericInput(ns("smr"), "SMR / Hazard Ratio:", value = 1.5, min = 0, step = 0.1),
                 actionButton(ns("calc_smr"), "Adjust & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_smr")),
                 div(class="plot-container", plotOutput(ns("plot_smr")))
               )
             )
    ),

    # --- Tab 2: Linear Interpolation ---
    tabPanel("Linear Interpolation",
             sidebarLayout(
               sidebarPanel(
                 h4("Interpolate Mortality"),
                 p("Generate age-specific rates between two known points."),
                 textInput(ns("lbl_int"), "Parameter Name:", placeholder = "e.g., Age 53 Rate"),
                 hr(),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("age1"), "Age A:", 50), numericInput(ns("mort1"), "Rate A:", 0.004)
                 ),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("age2"), "Age B:", 60), numericInput(ns("mort2"), "Rate B:", 0.009)
                 ),
                 numericInput(ns("target_age"), "Target Age (for Log):", 55),
                 actionButton(ns("calc_interp"), "Interpolate & Generate Table", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_interp")),
                 div(class="plot-container", plotOutput(ns("plot_interp"), height="300px")),
                 br(),
                 h4("Life Table (Age-Wise)"),
                 DT::dataTableOutput(ns("tbl_interp"))
               )
             )
    ),

    # --- Tab 3: Gompertz Fit ---
    tabPanel("Gompertz Fit (Aging)",
             sidebarLayout(
               sidebarPanel(
                 h4("Gompertz Parameterization"),
                 p("Derive 'Aging Parameters' and full life table from two points."),
                 textInput(ns("lbl_gomp"), "Label:", placeholder = "e.g., Male Bg Mortality"),
                 hr(),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("g_age1"), "Age 1:", 40), numericInput(ns("g_rate1"), "Rate 1:", 0.002)
                 ),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("g_age2"), "Age 2:", 80), numericInput(ns("g_rate2"), "Rate 2:", 0.080)
                 ),
                 helpText("Fits: Rate(t) = Alpha * exp(Beta * Age)"),
                 actionButton(ns("calc_gomp"), "Fit & Generate Table", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_gomp")),
                 div(class="plot-container", plotOutput(ns("plot_gomp"), height="300px")),
                 br(),
                 h4("Life Table (Age-Wise)"),
                 DT::dataTableOutput(ns("tbl_gomp"))
               )
             )
    ),

    # --- Tab 4: DEALE ---
    tabPanel("Life Expectancy (DEALE)",
             sidebarLayout(
               sidebarPanel(
                 h4("DEALE & Excess Mortality"),
                 textInput(ns("lbl_deale"), "Label:", placeholder = "e.g., Excess HF Mortality"),
                 hr(),
                 radioButtons(ns("deale_mode"), "Calculation Mode:",
                              choices = c("Simple: LE \u2194 Rate" = "simple",
                                          "Advanced: Calculate Excess Rate" = "excess")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'simple'", ns("deale_mode")),
                                  radioButtons(ns("deale_dir"), "Direction:",
                                               choices = c("LE (Years) \u2192 Rate" = "le2r", "Rate \u2192 LE (Years)" = "r2le")),
                                  conditionalPanel(condition = sprintf("input['%s'] == 'le2r'", ns("deale_dir")),
                                                   numericInput(ns("val_le"), "Life Expectancy (Years):", value = 20, min = 0.1)),
                                  conditionalPanel(condition = sprintf("input['%s'] == 'r2le'", ns("deale_dir")),
                                                   numericInput(ns("val_rate_deale"), "Mortality Rate (r):", value = 0.05, min = 0.0001))
                 ),
                 conditionalPanel(condition = sprintf("input['%s'] == 'excess'", ns("deale_mode")),
                                  numericInput(ns("le_observed"), "Observed LE (Disease Cohort):", value = 3.2, min = 0.1),
                                  numericInput(ns("le_background"), "Background LE (Healthy/Pop):", value = 14.5, min = 0.1),
                                  helpText("Calculates: (1/Observed) - (1/Background)")
                 ),
                 actionButton(ns("calc_deale"), "Calculate & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_deale"))
               )
             )
    )
  )
}

mod_lifetable_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {

    add_to_log <- function(label, type, inputs, result, note) {
      new_entry <- data.frame(
        Time   = format(Sys.time(), "%H:%M:%S"),
        Label  = ifelse(label == "", "Unlabeled", label),
        Module = type,
        Input  = inputs,
        Result = result,
        Notes  = note,
        stringsAsFactors = FALSE
      )
      logger$entries <- rbind(logger$entries, new_entry)
      showNotification("Added to Report", type = "message")
    }

    mathjax_trigger <- tags$script("if(window.MathJax){MathJax.Hub.Queue(['Typeset', MathJax.Hub]);}")

    # ================================================================
    # TAB 1: SMR ADJUSTMENT
    # ================================================================
    smr_data <- reactiveVal(NULL)
    observeEvent(input$calc_smr, {
      base <- input$base_val; smr <- input$smr
      if(input$input_type == "prob") {
        if(base >= 1) { output$res_smr <- renderUI(div(class="result-box", style="color:red", "Error: Prob < 1")); return() }
        rate_pop <- -log(1 - base)
      } else { rate_pop <- base }
      rate_adj <- rate_pop * smr
      prob_adj <- 1 - exp(-rate_adj)
      prob_pop <- 1 - exp(-rate_pop)

      output$res_smr <- renderUI(tagList(
        # Result
        div(class="result-box", HTML(paste0(
          "<span class='result-label'>SMR-Adjusted Mortality</span><br>",
          "Gen. Pop. Rate: ", round(rate_pop, 5), "<br>",
          "Adjusted Rate: ", round(rate_adj, 5), "<br><br>",
          "<span class='result-value'>Adjusted Probability = ", round(prob_adj, 5), "</span>"
        ))),
        # Explanation
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            tags$ol(
              tags$li(HTML(paste0(
                strong("Convert to rate: "),
                if(input$input_type == "prob") {
                  paste0("The input probability of ", base, " was converted to an instantaneous rate: r = -ln(1 - ",
                         base, ") = ", strong(round(rate_pop, 5)), ".")
                } else {
                  paste0("The input was already an instantaneous rate: r = ", strong(round(rate_pop, 5)), ".")
                }
              ))),
              tags$li(HTML(paste0(
                strong("Apply SMR: "), "The population rate was multiplied by the SMR of ", smr,
                ": r_adj = ", round(rate_pop, 5), " \u00d7 ", smr, " = ", strong(round(rate_adj, 5)), "."
              ))),
              tags$li(HTML(paste0(
                strong("Back to probability: "), "p_adj = 1 - exp(-", round(rate_adj, 5),
                ") = ", strong(round(prob_adj, 5)), "."
              )))
            ),
            p(HTML(paste0(
              icon("info-circle"), " ",
              "The SMR (Standardised Mortality Ratio) acts as a multiplier on the ",
              strong("rate"), " scale, not the probability scale. ",
              "For example, heart failure patients have an SMR of 2-5, meaning their mortality rate is 2-5 times that of the general population of the same age."
            )))
        ),
        # Formula
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
            p("$$r_{pop} = -\\ln(1 - q_x)$$"),
            p("$$r_{adj} = r_{pop} \\times SMR$$"),
            p("$$q_{adj} = 1 - e^{-r_{adj}}$$"),
            p(style = "font-size:0.85em; color:#666;",
              "The SMR must be applied to instantaneous rates (not probabilities) to preserve the proportional hazards assumption.")
        ),
        # Citation
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Jhund PS, et al. Long-term trends in first hospitalization for heart failure and subsequent survival. <em>Eur Heart J</em>. 2009;30(4):413-421.")),
              tags$li(HTML("Fleurence RL, Hollenbeak CS. Rates and probabilities in economic modelling. <em>Pharmacoeconomics</em>. 2007;25(1):3-6.")),
              tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. OUP; 2006."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$lbl_smr, "Bg Mortality (SMR)", paste0("Base=", base, ", SMR=", smr), paste0("Prob=", round(prob_adj,5)), "SMR Adjust")
      smr_data(data.frame(Group = c("Gen Pop", "Disease"), Probability = c(prob_pop, prob_adj)))
    })

    output$plot_smr <- renderPlot({
      req(smr_data())
      ggplot(smr_data(), aes(Group, Probability, fill=Group)) +
        geom_bar(stat="identity", width=0.5) +
        scale_fill_manual(values=c("#c0392b", "#003366")) +
        theme_minimal() + ylim(0, max(smr_data()$Probability) * 1.3) +
        labs(title = "Annual Mortality Probability", y = "Probability", x = "") +
        geom_text(aes(label = round(Probability, 5)), vjust = -0.5, fontface = "bold")
    })

    # ================================================================
    # TAB 2: LINEAR INTERPOLATION
    # ================================================================
    interp_data <- reactiveVal(NULL)
    observeEvent(input$calc_interp, {
      slope <- (input$mort2 - input$mort1) / (input$age2 - input$age1)
      m_target <- input$mort1 + slope * (input$target_age - input$age1)
      p_target <- 1 - exp(-m_target)

      output$res_interp <- renderUI(tagList(
        # Result
        div(class="result-box", HTML(paste0(
          "<span class='result-label'>Interpolated Result (Age ", input$target_age, ")</span><br>",
          "<span class='result-value'>Rate = ", round(m_target, 5), "</span>",
          "<span class='result-value'>Probability = ", round(p_target, 5), "</span>"
        ))),
        # Explanation
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "Life tables (e.g., SRS India, WHO GHO) typically report mortality in 5- or 10-year age bands. ",
              "When a Markov model uses 1-year cycles, age-specific rates are needed for ",
              strong("each year"), " of age."
            ))),
            tags$ol(
              tags$li(HTML(paste0(
                strong("Slope: "), "m = (", input$mort2, " - ", input$mort1, ") / (",
                input$age2, " - ", input$age1, ") = ", strong(round(slope, 6)), " per year."
              ))),
              tags$li(HTML(paste0(
                strong("Interpolated rate at age ", input$target_age, ": "),
                input$mort1, " + ", round(slope, 6), " \u00d7 (", input$target_age, " - ", input$age1,
                ") = ", strong(round(m_target, 5)), "."
              ))),
              tags$li(HTML(paste0(
                strong("Probability: "), "p = 1 - exp(-", round(m_target, 5), ") = ",
                strong(round(p_target, 5)), "."
              )))
            ),
            p(HTML(paste0(
              icon("exclamation-triangle"), " ",
              strong("Limitation: "), "Linear interpolation assumes mortality increases at a constant ",
              "additive rate between age points. For long intervals (>10 years), log-linear interpolation ",
              "or a Gompertz fit may be more accurate."
            )))
        ),
        # Formula
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
            p("$$m_x = m_A + \\frac{m_B - m_A}{Age_B - Age_A} \\times (x - Age_A)$$"),
            p("$$q_x = 1 - e^{-m_x}$$"),
            p(style = "font-size:0.85em; color:#666;",
              "Where m_x is the interpolated rate at age x, and q_x is the corresponding annual probability.")
        ),
        # Citation
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Preston SH, Heuveline P, Guillot M. <em>Demography: Measuring and Modeling Population Processes</em>. Wiley-Blackwell; 2001.")),
              tags$li(HTML("Registrar General of India. <em>Sample Registration System (SRS) Abridged Life Tables</em>."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$lbl_int, "Bg Mortality (Linear)", paste0("Target Age=", input$target_age), paste0("Rate=", round(m_target,5)), "Linear Interp")
      ages <- seq(min(input$age1, input$age2), max(input$age1, input$age2), by=1)
      rates <- input$mort1 + slope * (ages - input$age1)
      interp_data(data.frame(Age=ages, Rate=rates))
    })

    output$plot_interp <- renderPlot({
      req(interp_data())
      ggplot(interp_data(), aes(Age, Rate)) +
        geom_line(color="#27ae60", size=1) +
        geom_point(aes(x=input$target_age,
                       y=input$mort1 + (input$mort2-input$mort1)/(input$age2-input$age1)*(input$target_age-input$age1)),
                   color="red", size=3) +
        theme_minimal() +
        labs(title = "Interpolated Mortality Rates", y = "Rate (mx)", x = "Age")
    })

    # TABLE INTERPOLATION
    output$tbl_interp <- DT::renderDataTable({
      req(interp_data())
      df <- interp_data()
      df$Annual_Prob <- 1 - exp(-df$Rate)

      DT::datatable(df,
                    extensions = 'Buttons',
                    options = list(
                      dom = 'Blfrtip',
                      pageLength = 10,
                      lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'All')),
                      buttons = list(
                        list(extend = 'copy', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'csv', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'excel', exportOptions = list(modifier = list(page = 'all')))
                      )
                    ),
                    rownames = FALSE) %>%
        DT::formatRound(columns=c("Rate", "Annual_Prob"), digits=5)
    })

    # ================================================================
    # TAB 3: GOMPERTZ FIT
    # ================================================================
    gomp_data <- reactiveVal(NULL)
    observeEvent(input$calc_gomp, {
      t1 <- input$g_age1; r1 <- input$g_rate1
      t2 <- input$g_age2; r2 <- input$g_rate2
      if(t1 == t2 || r1 <= 0 || r2 <= 0) {
        output$res_gomp <- renderUI(div(class="result-box", style="color:red", "Error: Different ages and positive rates required."))
        return()
      }
      y1 <- log(r1); y2 <- log(r2)
      beta <- (y2 - y1) / (t2 - t1)
      ln_alpha <- y1 - beta * t1
      alpha <- exp(ln_alpha)

      # Doubling time interpretation
      doubling_time <- log(2) / beta

      output$res_gomp <- renderUI(tagList(
        # Result
        div(class="result-box", HTML(paste0(
          "<span class='result-label'>Gompertz Parameters</span><br>",
          "Alpha (\u03b1): ", format(alpha, scientific=TRUE, digits=4), "<br>",
          "Beta (\u03b2): ", round(beta, 5), "<br><br>",
          "<small>Rate(Age) = \u03b1 \u00d7 exp(\u03b2 \u00d7 Age)</small>"
        ))),
        # Explanation
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "The Gompertz law of mortality states that the force of mortality increases ",
              strong("exponentially"), " with age. This is one of the most fundamental observations in ",
              "demography, holding remarkably well between ages 30-90."
            ))),
            tags$ol(
              tags$li(HTML(paste0(
                strong("Log-linearization: "), "Taking ln of both points: ln(", r1, ") = ", round(y1, 4),
                " at age ", t1, " and ln(", r2, ") = ", round(y2, 4), " at age ", t2, "."
              ))),
              tags$li(HTML(paste0(
                strong("Slope (\u03b2): "), "(", round(y2, 4), " - ", round(y1, 4), ") / (",
                t2, " - ", t1, ") = ", strong(round(beta, 5)),
                ". This means the mortality rate doubles every ", strong(round(doubling_time, 1)), " years."
              ))),
              tags$li(HTML(paste0(
                strong("Intercept (\u03b1): "), "exp(", round(y1, 4), " - ", round(beta, 5), " \u00d7 ", t1,
                ") = ", strong(format(alpha, scientific=TRUE, digits=4)), "."
              )))
            ),
            p(HTML(paste0(
              icon("info-circle"), " ",
              "The Gompertz model is widely used in HTA for background mortality when life tables are unavailable ",
              "or when smooth extrapolation beyond published age ranges is needed."
            )))
        ),
        # Formula
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
            p("$$\\mu(x) = \\alpha \\cdot e^{\\beta x}$$"),
            p("$$\\ln(\\mu(x)) = \\ln(\\alpha) + \\beta x$$"),
            p("$$\\beta = \\frac{\\ln(r_2) - \\ln(r_1)}{Age_2 - Age_1}, \\quad \\alpha = \\exp\\left(\\ln(r_1) - \\beta \\cdot Age_1\\right)$$"),
            p(style = "font-size:0.85em; color:#666;",
              "The doubling time of mortality = ln(2)/\u03b2. A typical value of \u03b2 \u2248 0.085 gives a doubling time of ~8 years.")
        ),
        # Citation
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Gompertz B. On the nature of the function expressive of the law of human mortality. <em>Phil Trans R Soc Lond</em>. 1825;115:513-583.")),
              tags$li(HTML("Missov TI, et al. The Gompertz force of mortality in terms of the modal age at death. <em>Demographic Research</em>. 2015;32:1031-1048.")),
              tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. OUP; 2006."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$lbl_gomp, "Bg Mortality (Gompertz)", paste0("Age ", t1, "/", t2), paste0("Alpha=", format(alpha, digits=3), " Beta=", round(beta,4)), "Gompertz Fit")
      ages <- seq(min(t1, t2), max(t1, t2), by=1)
      rates <- alpha * exp(beta * ages)
      gomp_data(data.frame(Age=ages, Rate=rates))
    })

    output$plot_gomp <- renderPlot({
      req(gomp_data())
      ggplot(gomp_data(), aes(Age, Rate)) +
        geom_line(color="#8e44ad", size=1.2) +
        theme_minimal() +
        labs(title="Gompertz Mortality Curve", y="Rate \u03bc(x)", x = "Age")
    })

    # TABLE GOMPERTZ
    output$tbl_gomp <- DT::renderDataTable({
      req(gomp_data())
      df <- gomp_data()
      df$Annual_Prob <- 1 - exp(-df$Rate)

      DT::datatable(df,
                    extensions = 'Buttons',
                    options = list(
                      dom = 'Blfrtip',
                      pageLength = 10,
                      lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'All')),
                      buttons = list(
                        list(extend = 'copy', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'csv', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'excel', exportOptions = list(modifier = list(page = 'all')))
                      )
                    ),
                    rownames = FALSE) %>%
        DT::formatRound(columns=c("Rate", "Annual_Prob"), digits=5)
    })

    # ================================================================
    # TAB 4: DEALE
    # ================================================================
    observeEvent(input$calc_deale, {

      if(input$deale_mode == "simple") {
        if(input$deale_dir == "le2r") {
          req(input$val_le)
          r <- 1 / input$val_le

          output$res_deale <- renderUI(tagList(
            # Result
            div(class="result-box", HTML(paste0(
              "<span class='result-label'>DEALE: Life Expectancy \u2192 Rate</span><br>",
              "<span class='result-value'>Total Mortality Rate = ", round(r, 5), "</span>"
            ))),
            # Explanation
            div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
                p(HTML(paste0(
                  "The DEALE (Declining Exponential Approximation of Life Expectancy) assumes survival follows ",
                  "an exponential distribution with a constant hazard rate. Under this assumption, ",
                  "life expectancy is simply the reciprocal of the rate."
                ))),
                p(HTML(paste0(
                  "With LE = ", strong(input$val_le), " years: r = 1 / ", input$val_le,
                  " = ", strong(round(r, 5)), " per year."
                ))),
                p(HTML(paste0(
                  icon("exclamation-triangle"), " ",
                  strong("Limitation: "), "The constant-rate assumption means the DEALE overestimates ",
                  "life expectancy for younger cohorts (where hazard increases with age) and underestimates ",
                  "it for older cohorts. It works best as a quick approximation."
                )))
            ),
            # Formula
            div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
                h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
                p("$$r = \\frac{1}{LE}$$"),
                p("$$S(t) = e^{-rt}$$"),
                p(style = "font-size:0.85em; color:#666;",
                  "Under constant hazard: LE = 1/r = Mean survival time = Median/ln(2).")
            ),
            # Citation
            div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
                tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                  tags$li(HTML("Beck JR, Pauker SG, et al. A convenient approximation of life expectancy (the 'DEALE'). <em>Am J Med</em>. 1982;73(6):883-888.")),
                  tags$li(HTML("Naimark D, et al. The half-cycle correction revisited. <em>Med Decis Making</em>. 2013;33(7):961-970."))
                )
            ),
            mathjax_trigger
          ))

          add_to_log(input$lbl_deale, "DEALE", paste0("LE=", input$val_le), paste0("Rate=", round(r, 5)), "DEALE (Simple)")

        } else {
          req(input$val_rate_deale)
          le <- 1 / input$val_rate_deale

          output$res_deale <- renderUI(tagList(
            # Result
            div(class="result-box", HTML(paste0(
              "<span class='result-label'>DEALE: Rate \u2192 Life Expectancy</span><br>",
              "<span class='result-value'>Life Expectancy = ", round(le, 2), " Years</span>"
            ))),
            # Explanation
            div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
                p(HTML(paste0(
                  "With a constant mortality rate of ", strong(input$val_rate_deale),
                  " per year, the expected life expectancy under the DEALE approximation is: ",
                  "LE = 1 / ", input$val_rate_deale, " = ", strong(round(le, 2)), " years."
                ))),
                p(HTML(paste0(
                  icon("info-circle"), " ",
                  "This is equivalent to saying the cohort's survival curve is S(t) = exp(-",
                  input$val_rate_deale, " \u00d7 t), and the area under this curve (= LE) is ", round(le, 2), " years."
                )))
            ),
            # Formula
            div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
                h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
                p("$$LE = \\frac{1}{r}$$"),
                p(style = "font-size:0.85em; color:#666;",
                  "Under the exponential assumption, LE equals the reciprocal of the constant hazard rate.")
            ),
            # Citation
            div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
                tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                  tags$li(HTML("Beck JR, Pauker SG, et al. A convenient approximation of life expectancy (the 'DEALE'). <em>Am J Med</em>. 1982;73(6):883-888.")),
                  tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. OUP; 2006."))
                )
            ),
            mathjax_trigger
          ))

          add_to_log(input$lbl_deale, "DEALE", paste0("Rate=", input$val_rate_deale), paste0("LE=", round(le, 2)), "DEALE (Simple)")
        }

      } else {
        # ADVANCED: Excess Rate
        req(input$le_observed, input$le_background)
        le_obs <- input$le_observed; le_bg <- input$le_background
        if (le_obs >= le_bg) { output$res_deale <- renderUI(div(class="result-box", style="color:red", "Error: Disease LE must be < Background LE")); return() }

        r_total <- 1 / le_obs
        r_bg <- 1 / le_bg
        r_disease <- r_total - r_bg

        output$res_deale <- renderUI(tagList(
          # Result
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>DEALE: Excess Mortality Decomposition</span><br>",
            "Total Rate (1/LE_obs): ", round(r_total, 4), "<br>",
            "Background Rate (1/LE_bg): ", round(r_bg, 4), "<br><br>",
            "<span class='result-value' style='color:#c0392b'>Excess Disease Rate = ", round(r_disease, 5), "</span>"
          ))),
          # Explanation
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "This decomposes the total mortality of a disease cohort into background (age-related) mortality ",
                "and the ", strong("excess mortality due to the disease"), " itself."
              ))),
              tags$ol(
                tags$li(HTML(paste0(
                  strong("Total rate: "), "r_total = 1 / ", le_obs, " = ", strong(round(r_total, 4)),
                  " (the combined rate of dying from any cause in the disease cohort)."
                ))),
                tags$li(HTML(paste0(
                  strong("Background rate: "), "r_bg = 1 / ", le_bg, " = ", strong(round(r_bg, 4)),
                  " (the rate if they only had normal age-related mortality)."
                ))),
                tags$li(HTML(paste0(
                  strong("Excess rate: "), round(r_total, 4), " - ", round(r_bg, 4), " = ",
                  strong(round(r_disease, 5)),
                  ". This is the additional hazard attributable to the disease."
                )))
              ),
              p(HTML(paste0(
                icon("info-circle"), " ",
                "This decomposition is essential in Markov models where background mortality and disease-specific ",
                "mortality must be modelled as separate transition probabilities. ",
                "For example, in metastatic cancer, the disease-specific rate determines transitions from 'Stable' to 'Dead (Cancer)', ",
                "while the background rate determines 'Stable' to 'Dead (Other Causes)'."
              )))
          ),
          # Formula
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
              p("$$r_{total} = \\frac{1}{LE_{observed}}$$"),
              p("$$r_{background} = \\frac{1}{LE_{healthy}}$$"),
              p("$$r_{disease} = r_{total} - r_{background}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "Additive decomposition of hazard rates under the DEALE (constant rate) assumption.")
          ),
          # Citation
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Beck JR, Pauker SG, et al. A convenient approximation of life expectancy (the 'DEALE'). <em>Am J Med</em>. 1982;73(6):883-888.")),
                tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. OUP; 2006. Chapter 3.")),
                tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$lbl_deale, "DEALE", paste0("LE_obs=", le_obs, ", LE_bg=", le_bg), paste0("Excess Rate=", round(r_disease, 5)), "DEALE (Excess)")
      }
    })
  })
}
