mod_core_conv_ui <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    # --- Rate <-> Prob ---
    tabPanel("Rate \u2194 Probability",
             sidebarLayout(
               sidebarPanel(
                 h4("Rate & Probability"),
                 textInput(ns("lbl_rp"), "Parameter Name:", placeholder = "e.g., PFS Control Arm"),
                 hr(),
                 radioButtons(ns("rp_dir"), "Direction:", c("Rate to Prob"="r2p", "Prob to Rate"="p2r")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'r2p'", ns("rp_dir")),
                                  div(style="display:flex; gap:10px;",
                                      numericInput(ns("val_rate"), "Rate:", 5, width="50%"),
                                      selectInput(ns("rate_mult"), "Per:",
                                                  choices = c("1 (Raw)"=1, "100"=100, "1,000"=1000, "100,000"=1e5),
                                                  selected=1000, width="50%"))
                 ),
                 conditionalPanel(condition = sprintf("input['%s'] == 'p2r'", ns("rp_dir")),
                                  numericInput(ns("val_prob"), "Probability (p):", 0.1, 0, 1, 0.01)
                 ),
                 numericInput(ns("val_time"), "Time Horizon (t):", 1, min=0.001),
                 actionButton(ns("calc_rp"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_rp")))
             )
    ),

    # --- Odds <-> Prob ---
    tabPanel("Odds \u2194 Probability",
             sidebarLayout(
               sidebarPanel(
                 h4("Odds & Probability"),
                 textInput(ns("lbl_op"), "Parameter Name:", placeholder = "e.g., AE Nausea"),
                 hr(),
                 radioButtons(ns("op_dir"), "Direction:", c("Odds to Prob"="o2p", "Prob to Odds"="p2o")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'o2p'", ns("op_dir")), numericInput(ns("val_odds"), "Odds:", 1)),
                 conditionalPanel(condition = sprintf("input['%s'] == 'p2o'", ns("op_dir")), numericInput(ns("val_prob_o"), "Prob:", 0.5)),
                 actionButton(ns("calc_op"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_op")))
             )
    ),

    # --- Time Rescaling ---
    tabPanel("Time Rescaling",
             sidebarLayout(
               sidebarPanel(
                 h4("Rescale Probability"),
                 textInput(ns("lbl_tr"), "Parameter Name:", placeholder = "e.g., 1-Year to 1-Month"),
                 hr(),
                 numericInput(ns("tr_prob"), "Orig Prob:", 0.1, 0, 1),
                 div(style="display:flex; gap:10px;", numericInput(ns("tr_t1"), "Orig Time:", 1), selectInput(ns("tr_u1"), "", c("Years","Months","Weeks","Days"))),
                 div(style="display:flex; gap:10px;", numericInput(ns("tr_t2"), "New Time:", 1), selectInput(ns("tr_u2"), "", c("Years","Months","Weeks","Days"), "Months")),
                 actionButton(ns("calc_tr"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_tr")))
             )
    ),

    # --- OR <-> RR ---
    tabPanel("OR \u2194 RR",
             sidebarLayout(
               sidebarPanel(
                 h4("Odds Ratio \u2194 Relative Risk"),
                 textInput(ns("lbl_or"), "Parameter Name:", placeholder = "e.g., MI outcome, PLATO"),
                 hr(),
                 radioButtons(ns("or_dir"), "Direction:",
                              c("OR to RR" = "or2rr", "RR to OR" = "rr2or")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'or2rr'", ns("or_dir")),
                                  numericInput(ns("val_or"), "Odds Ratio:", 0.84, min = 0.001, step = 0.01)),
                 conditionalPanel(condition = sprintf("input['%s'] == 'rr2or'", ns("or_dir")),
                                  numericInput(ns("val_rr"), "Relative Risk:", 0.87, min = 0.001, step = 0.01)),
                 numericInput(ns("p0_or"), "Baseline Risk (Control Probability):", 0.1, min = 0.001, max = 0.999, step = 0.01),
                 helpText("The event probability in the control/unexposed group."),
                 actionButton(ns("calc_or"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_or")))
             )
    ),

    # --- Effect Size ---
    tabPanel("Effect Size",
             sidebarLayout(
               sidebarPanel(
                 h4("Effect Size Conversions"),
                 textInput(ns("lbl_es"), "Parameter Name:", placeholder = "e.g., NMA - Drug A vs B"),
                 hr(),
                 radioButtons(ns("es_dir"), "Direction:",
                              c("SMD to log(OR)" = "smd2lor",
                                "log(OR) to SMD" = "lor2smd",
                                "log(OR) to log(RR)" = "lor2lrr")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'smd2lor'", ns("es_dir")),
                                  numericInput(ns("val_smd"), "Standardized Mean Difference:", 0.3, step = 0.01),
                                  numericInput(ns("se_smd"), "SE of SMD:", 0.1, min = 0.001, step = 0.01)),
                 conditionalPanel(condition = sprintf("input['%s'] == 'lor2smd'", ns("es_dir")),
                                  numericInput(ns("val_lor"), "log(OR):", 0.5, step = 0.01),
                                  numericInput(ns("se_lor"), "SE of log(OR):", 0.15, min = 0.001, step = 0.01)),
                 conditionalPanel(condition = sprintf("input['%s'] == 'lor2lrr'", ns("es_dir")),
                                  numericInput(ns("val_lor2"), "log(OR):", 0.5, step = 0.01),
                                  numericInput(ns("p0_es"), "Baseline Risk (Control):", 0.2, min = 0.001, max = 0.999, step = 0.01)),
                 actionButton(ns("calc_es"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_es")))
             )
    )
  )
}

mod_core_conv_server <- function(id, logger) {
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
      showNotification("Added to Report", type = "message", duration = 2)
    }

    mathjax_trigger <- tags$script("if(window.MathJax){MathJax.Hub.Queue(['Typeset', MathJax.Hub]);}")

    # ==================================================================
    # RATE <-> PROBABILITY
    # ==================================================================
    observeEvent(input$calc_rp, {
      t <- input$val_time
      if(input$rp_dir == "r2p") {
        r <- input$val_rate / as.numeric(input$rate_mult)
        p <- 1 - exp(-r*t)

        output$res_rp <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Rate to Probability</span>",
            "<span class='result-value'>Probability = ", round(p, 5), "</span>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The reported rate of ", strong(input$val_rate), " per ", input$rate_mult,
                " was converted to a per-person rate: r = ", input$val_rate, " / ", input$rate_mult, " = ", strong(round(r, 5)), ".",
                " Over a time horizon of ", strong(t), ", the probability was computed using the exponential formula: ",
                "p = 1 - e<sup>-", round(r, 5), " \u00d7 ", t, "</sup> = ", strong(round(p, 5)), "."
              ))),
              p(HTML(paste0(
                icon("info-circle"), " ",
                "Note: simple division would overestimate the probability because it ignores that patients who experience the event ",
                "are removed from the at-risk pool during the time period."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$p = 1 - e^{-r \\times t}$$"),
              p(style = "font-size:0.85em; color:#666;", "where r is the instantaneous rate and t is the time horizon.")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Fleurence RL, Hollenbeak CS. Rates and probabilities in economic modelling. <em>Pharmacoeconomics</em>. 2007;25(1):3-12.")),
                tags$li(HTML("Sonnenberg FA, Beck JR. Markov models in medical decision making. <em>Med Decis Making</em>. 1993;13(4):322-338."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$lbl_rp, "Rate->Prob",
                   paste0("r=", input$val_rate, "/", input$rate_mult, ", t=", t),
                   paste0("p=", round(p,5)), "Exponential")
      } else {
        p_in <- input$val_prob
        r <- -log(1 - p_in)/t

        output$res_rp <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Probability to Rate</span>",
            "<span class='result-value'>Rate = ", round(r, 5), " per unit time</span>",
            "<br><small>Per 100 = ", round(r*100, 3), " | Per 1,000 = ", round(r*1000, 2), "</small>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The probability of ", strong(round(p_in, 5)), " over ", strong(t), " time units ",
                "was converted to an instantaneous rate: r = -ln(1 - ", round(p_in, 5), ") / ", t, " = ", strong(round(r, 5)), "."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$r = -\\frac{\\ln(1 - p)}{t}$$")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Fleurence RL, Hollenbeak CS. Rates and probabilities in economic modelling. <em>Pharmacoeconomics</em>. 2007;25(1):3-12.")),
                tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. Oxford University Press; 2006."))
              )
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_rp, "Prob->Rate", paste0("p=", p_in, ", t=", t), paste0("r=", round(r,5)), "Inverse Exponential")
      }
    })

    # ==================================================================
    # ODDS <-> PROBABILITY
    # ==================================================================
    observeEvent(input$calc_op, {
      if(input$op_dir == "o2p") {
        odds_in <- input$val_odds
        p <- odds_in / (1 + odds_in)

        output$res_op <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Odds to Probability</span>",
            "<span class='result-value'>Probability = ", round(p, 5), "</span>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0("Odds of ", strong(round(odds_in, 5)), " means for every 1 non-event there are ", round(odds_in, 5), " events. ",
                "The probability is: p = ", round(odds_in, 5), " / (1 + ", round(odds_in, 5), ") = ", strong(round(p, 5)), ".")))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$p = \\frac{\\text{Odds}}{1 + \\text{Odds}}$$")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " Reference", style = "margin-top:0; color:#003366;"),
              p(style = "font-size:0.85em;", HTML("Bland JM, Altman DG. The odds ratio. <em>BMJ</em>. 2000;320(7247):1468."))
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_op, "Odds->Prob", paste0("Odds=", odds_in), paste0("p=", round(p,5)), "Logistic")
      } else {
        p_in <- input$val_prob_o
        o <- p_in / (1 - p_in)

        output$res_op <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Probability to Odds</span>",
            "<span class='result-value'>Odds = ", round(o, 5), "</span>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0("A probability of ", strong(round(p_in, 5)), " translates to odds of: ",
                round(p_in, 5), " / (1 - ", round(p_in, 5), ") = ", strong(round(o, 5)), ".")))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$\\text{Odds} = \\frac{p}{1 - p}$$")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " Reference", style = "margin-top:0; color:#003366;"),
              p(style = "font-size:0.85em;", HTML("Bland JM, Altman DG. The odds ratio. <em>BMJ</em>. 2000;320(7247):1468."))
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_op, "Prob->Odds", paste0("p=", p_in), paste0("Odds=", round(o,5)), "Logistic")
      }
    })

    # ==================================================================
    # TIME RESCALING
    # ==================================================================
    unit_factors <- list("Years" = 365.25, "Months" = 30.4375, "Weeks" = 7, "Days" = 1)
    observeEvent(input$calc_tr, {
      ratio <- (input$tr_t2 * unit_factors[[input$tr_u2]]) / (input$tr_t1 * unit_factors[[input$tr_u1]])
      p_new <- 1 - (1 - input$tr_prob)^(ratio)

      output$res_tr <- renderUI(tagList(
        div(class="result-box", HTML(paste0(
          "<span class='result-label'>Time Rescaling Result</span>",
          "<span class='result-value'>New Probability = ", round(p_new, 5), "</span>",
          "<br><small>Time ratio = ", round(ratio, 4), "</small>"
        ))),
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "The original probability of ", strong(round(input$tr_prob, 5)),
              " over ", strong(paste0(input$tr_t1, " ", input$tr_u1)),
              " was rescaled to ", strong(paste0(input$tr_t2, " ", input$tr_u2)),
              " using the constant-rate assumption."
            ))),
            p(HTML(paste0(
              icon("info-circle"), " ",
              "Simple linear rescaling (dividing or multiplying) is incorrect because risk compounds over time."
            )))
        ),
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
            p("$$p_{new} = 1 - (1 - p_{old})^{\\frac{t_{new}}{t_{old}}}$$"),
            p(style = "font-size:0.85em; color:#666;", "Assumes a constant underlying hazard rate.")
        ),
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Fleurence RL, Hollenbeak CS. Rates and probabilities in economic modelling. <em>Pharmacoeconomics</em>. 2007;25(1):3-12.")),
              tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. Oxford University Press; 2006."))
            )
        ),
        mathjax_trigger
      ))
      add_to_log(input$lbl_tr, "Time Rescale", paste0("p_old=", input$tr_prob, ", Ratio=", round(ratio,3)),
                 paste0("p_new=", round(p_new,5)), "Linear Rate Assumption")
    })

    # ==================================================================
    # OR <-> RR CONVERSION
    # ==================================================================
    observeEvent(input$calc_or, {
      p0 <- input$p0_or

      if (input$or_dir == "or2rr") {
        or_val <- input$val_or
        # Zhang & Yu formula: RR = OR / (1 - p0 + p0 * OR)
        rr <- or_val / (1 - p0 + p0 * or_val)
        # Approximate SE propagation: SE(RR) ~ RR * SE(OR) / OR (not computed without SE input)

        output$res_or <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Odds Ratio to Relative Risk</span>",
            "<span class='result-value'>RR = ", round(rr, 4), "</span>",
            "<br><small>OR = ", or_val, " | Baseline risk (p\u2080) = ", p0, "</small>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The OR of ", strong(or_val), " was converted to a RR using the baseline risk p\u2080 = ", strong(p0), ". ",
                "RR = ", or_val, " / (1 - ", p0, " + ", p0, " \u00d7 ", or_val, ") = ", strong(round(rr, 4)), "."
              ))),
              p(HTML(paste0(
                icon("info-circle"), " ",
                "For rare events (p\u2080 < 0.1), OR \u2248 RR. Here the discrepancy is ",
                strong(round(abs(or_val - rr), 4)), ". ",
                if (p0 > 0.1) "Because the baseline risk is >10%, the OR overstates the RR substantially." else "Given the low baseline risk, OR and RR are quite close."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula (Zhang & Yu)", style = "margin-top:0;"),
              p("$$RR = \\frac{OR}{1 - p_0 + p_0 \\times OR}$$"),
              p(style = "font-size:0.85em; color:#666;", "where p\u2080 is the event probability in the control group.")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Zhang J, Yu KF. What's the relative risk? A method of correcting the odds ratio in cohort studies of common outcomes. <em>JAMA</em>. 1998;280(19):1690-1691.")),
                tags$li(HTML("Grant RL. Converting an odds ratio to a range of plausible relative risks for better communication. <em>BMJ</em>. 2014;348:f7450."))
              )
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_or, "OR->RR", paste0("OR=", or_val, ", p0=", p0), paste0("RR=", round(rr,4)), "Zhang & Yu")

      } else {
        rr_val <- input$val_rr
        # Inverse: OR = RR * (1 - p0) / (1 - RR * p0)
        or_out <- rr_val * (1 - p0) / (1 - rr_val * p0)

        output$res_or <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Relative Risk to Odds Ratio</span>",
            "<span class='result-value'>OR = ", round(or_out, 4), "</span>",
            "<br><small>RR = ", rr_val, " | Baseline risk (p\u2080) = ", p0, "</small>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The RR of ", strong(rr_val), " was converted to an OR using baseline risk p\u2080 = ", strong(p0), ": ",
                "OR = ", rr_val, " \u00d7 (1 - ", p0, ") / (1 - ", rr_val, " \u00d7 ", p0, ") = ", strong(round(or_out, 4)), "."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$OR = \\frac{RR \\times (1 - p_0)}{1 - RR \\times p_0}$$")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Zhang J, Yu KF. What's the relative risk? <em>JAMA</em>. 1998;280(19):1690-1691.")),
                tags$li(HTML("Grant RL. Converting an odds ratio to a range of plausible relative risks. <em>BMJ</em>. 2014;348:f7450."))
              )
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_or, "RR->OR", paste0("RR=", rr_val, ", p0=", p0), paste0("OR=", round(or_out,4)), "Inverse Zhang & Yu")
      }
    })

    # ==================================================================
    # EFFECT SIZE CONVERSIONS
    # ==================================================================
    observeEvent(input$calc_es, {

      if (input$es_dir == "smd2lor") {
        # Chinn (2000): log(OR) = SMD * pi / sqrt(3)
        smd <- input$val_smd
        se_smd <- input$se_smd
        lor <- smd * pi / sqrt(3)
        se_lor <- se_smd * pi / sqrt(3)
        or_val <- exp(lor)

        output$res_es <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>SMD to log(OR)</span>",
            "<span class='result-value'>log(OR) = ", round(lor, 4), "</span>",
            "<span class='result-value'>OR = ", round(or_val, 4), "</span>",
            "<br><small>SE of log(OR) = ", round(se_lor, 4), "</small>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The SMD of ", strong(smd), " was converted to the log-odds scale using Chinn's approximation: ",
                "log(OR) = ", smd, " \u00d7 \u03c0 / \u221a3 = ", strong(round(lor, 4)),
                ". The corresponding OR = e<sup>", round(lor, 4), "</sup> = ", strong(round(or_val, 4)), "."
              ))),
              p(HTML(paste0(
                icon("info-circle"), " ",
                "This conversion is widely used in network meta-analysis (NMA) when combining studies ",
                "that report continuous and binary outcomes."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula (Chinn 2000)", style = "margin-top:0;"),
              p("$$\\ln(OR) = SMD \\times \\frac{\\pi}{\\sqrt{3}} \\approx SMD \\times 1.8138$$"),
              p(style = "font-size:0.85em; color:#666;", "Assumes logistic distribution for the underlying latent variable.")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Chinn S. A simple method for converting an odds ratio to effect size for use in meta-analysis. <em>Stat Med</em>. 2000;19(22):3127-3131.")),
                tags$li(HTML("Dias S, et al. <em>Network Meta-Analysis for Decision-Making</em>. Wiley; 2018."))
              )
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_es, "SMD->logOR", paste0("SMD=", smd, " SE=", se_smd),
                   paste0("logOR=", round(lor,4), " OR=", round(or_val,4)), "Chinn 2000")

      } else if (input$es_dir == "lor2smd") {
        lor <- input$val_lor
        se_lor <- input$se_lor
        smd <- lor * sqrt(3) / pi
        se_smd <- se_lor * sqrt(3) / pi
        or_val <- exp(lor)

        output$res_es <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>log(OR) to SMD</span>",
            "<span class='result-value'>SMD = ", round(smd, 4), "</span>",
            "<br><small>OR = ", round(or_val, 4), " | SE of SMD = ", round(se_smd, 4), "</small>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The log(OR) of ", strong(lor), " (OR = ", round(or_val, 4),
                ") was converted to SMD: ", lor, " \u00d7 \u221a3 / \u03c0 = ", strong(round(smd, 4)), "."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$SMD = \\ln(OR) \\times \\frac{\\sqrt{3}}{\\pi} \\approx \\ln(OR) \\times 0.5513$$")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " Reference", style = "margin-top:0; color:#003366;"),
              p(style = "font-size:0.85em;", HTML("Chinn S. A simple method for converting an odds ratio to effect size. <em>Stat Med</em>. 2000;19(22):3127-3131."))
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_es, "logOR->SMD", paste0("logOR=", lor, " SE=", se_lor),
                   paste0("SMD=", round(smd,4)), "Chinn 2000")

      } else {
        # log(OR) to log(RR) via baseline risk
        lor <- input$val_lor2
        p0 <- input$p0_es
        or_val <- exp(lor)
        # RR = OR / (1 - p0 + p0*OR)
        rr <- or_val / (1 - p0 + p0 * or_val)
        lrr <- log(rr)

        output$res_es <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>log(OR) to log(RR)</span>",
            "<span class='result-value'>log(RR) = ", round(lrr, 4), "</span>",
            "<span class='result-value'>RR = ", round(rr, 4), "</span>",
            "<br><small>OR = ", round(or_val, 4), " | Baseline risk = ", p0, "</small>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "First, OR = exp(", lor, ") = ", round(or_val, 4), ". Then, using baseline risk p\u2080 = ", p0,
                ": RR = ", round(or_val, 4), " / (1 - ", p0, " + ", p0, " \u00d7 ", round(or_val, 4), ") = ",
                strong(round(rr, 4)), ". Therefore log(RR) = ", strong(round(lrr, 4)), "."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$RR = \\frac{OR}{1 - p_0 + p_0 \\times OR}$$"),
              p("$$\\ln(RR) = \\ln\\left(\\frac{OR}{1 - p_0 + p_0 \\times OR}\\right)$$")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Zhang J, Yu KF. What's the relative risk? <em>JAMA</em>. 1998;280(19):1690-1691.")),
                tags$li(HTML("Dias S, et al. <em>Network Meta-Analysis for Decision-Making</em>. Wiley; 2018."))
              )
          ),
          mathjax_trigger
        ))
        add_to_log(input$lbl_es, "logOR->logRR", paste0("logOR=", lor, ", p0=", p0),
                   paste0("logRR=", round(lrr,4), " RR=", round(rr,4)), "Zhang & Yu + NMA")
      }
    })
  })
}
