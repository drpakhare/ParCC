mod_core_conv_ui <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    # --- Rate <-> Prob ---
    tabPanel("Rate \u2194 Probability",
             sidebarLayout(
               sidebarPanel(
                 h4("Rate & Probability"),
                 # Label Input
                 textInput(ns("lbl_rp"), "Parameter Name:", placeholder = "e.g., PFS Control Arm"),
                 hr(),

                 radioButtons(ns("rp_dir"), "Direction:", c("Rate to Prob"="r2p", "Prob to Rate"="p2r")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'r2p'", ns("rp_dir")),
                                  div(style="display:flex; gap:10px;",
                                      numericInput(ns("val_rate"), "Rate:", 5, width="50%"),
                                      selectInput(ns("rate_mult"), "Per:",
                                                  choices = c("1 (Raw)"=1, "100"=100, "1,000"=1000, "100,000"=1e5),
                                                  selected=1000, width="50%")
                                  )
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
    )
  )
}

mod_core_conv_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {

    # Helper to add to log
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

    # MathJax retrigger script
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
          # Result
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Rate to Probability</span>",
            "<span class='result-value'>Probability = ", round(p, 5), "</span>"
          ))),
          # Explanation
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
                "Note: simple division (", input$val_rate, " / ", input$rate_mult, " = ", round(r, 5),
                ") would overestimate the probability because it ignores that patients who experience the event ",
                "are removed from the at-risk pool during the time period."
              )))
          ),
          # Formula
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$p = 1 - e^{-r \\times t}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "where r is the instantaneous rate and t is the time horizon.")
          ),
          # Citation
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
                   paste0("p=", round(p,5)),
                   "Exponential")
      } else {
        p_in <- input$val_prob
        r <- -log(1 - p_in)/t

        output$res_rp <- renderUI(tagList(
          # Result
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Probability to Rate</span>",
            "<span class='result-value'>Rate = ", round(r, 5), " per unit time</span>",
            "<br><small>Per 100 = ", round(r*100, 3), " | Per 1,000 = ", round(r*1000, 2), "</small>"
          ))),
          # Explanation
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The probability of ", strong(round(p_in, 5)), " over ", strong(t), " time units ",
                "was converted to an instantaneous rate using the inverse of the exponential formula: ",
                "r = -ln(1 - ", round(p_in, 5), ") / ", t, " = ", strong(round(r, 5)), " per unit time."
              )))
          ),
          # Formula
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$r = -\\frac{\\ln(1 - p)}{t}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "The inverse of the exponential conversion.")
          ),
          # Citation
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Fleurence RL, Hollenbeak CS. Rates and probabilities in economic modelling. <em>Pharmacoeconomics</em>. 2007;25(1):3-12.")),
                tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. Oxford University Press; 2006."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$lbl_rp, "Prob->Rate",
                   paste0("p=", p_in, ", t=", t),
                   paste0("r=", round(r,5)),
                   "Inverse Exponential")
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
              p(HTML(paste0(
                "Odds of ", strong(round(odds_in, 5)), " means for every 1 non-event there are ", round(odds_in, 5), " events. ",
                "The probability is: p = ", round(odds_in, 5), " / (1 + ", round(odds_in, 5), ") = ", strong(round(p, 5)), "."
              )))
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
              p(HTML(paste0(
                "A probability of ", strong(round(p_in, 5)), " translates to odds of: ",
                round(p_in, 5), " / (1 - ", round(p_in, 5), ") = ", strong(round(o, 5)), ". ",
                "This means there are approximately ", round(o, 2), " events for every 1 non-event."
              )))
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
              "The time ratio is ", round(ratio, 4),
              ", so: p<sub>new</sub> = 1 - (1 - ", round(input$tr_prob, 5), ")<sup>", round(ratio, 4), "</sup> = ",
              strong(round(p_new, 5)), "."
            ))),
            p(HTML(paste0(
              icon("info-circle"), " ",
              "Simple linear rescaling (dividing or multiplying) is incorrect because risk compounds over time. ",
              "A 10-year probability of 20% does ", strong("not"), " equal 2% per year."
            )))
        ),
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
            p("$$p_{new} = 1 - (1 - p_{old})^{\\frac{t_{new}}{t_{old}}}$$"),
            p(style = "font-size:0.85em; color:#666;",
              "Assumes a constant underlying hazard rate across both time periods.")
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

      add_to_log(input$lbl_tr, "Time Rescale",
                 paste0("p_old=", input$tr_prob, ", Ratio=", round(ratio,3)),
                 paste0("p_new=", round(p_new,5)),
                 "Linear Rate Assumption")
    })
  })
}
