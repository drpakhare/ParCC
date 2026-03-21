mod_survival_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Survival Analysis"),
      textInput(ns("label"), "Parameter Name:", placeholder = "e.g., OS Curve - Treatment"),
      hr(),

      selectInput(ns("surv_method"), "Select Method:",
                  choices = c("Exponential (From Median)" = "exp",
                              "Weibull (From 2 Time Points)" = "weibull",
                              "Log-Logistic (From 2 Time Points)" = "loglogistic")),

      # Exponential Inputs
      conditionalPanel(condition = sprintf("input['%s'] == 'exp'", ns("surv_method")),
                       p(class="text-info", "Requires constant hazard assumption."),
                       radioButtons(ns("exp_dir"), "Direction:",
                                    c("Median \u2192 Rate"="med2rate", "Rate \u2192 Median"="rate2med")),
                       conditionalPanel(condition = sprintf("input['%s'] == 'med2rate'", ns("exp_dir")),
                                        numericInput(ns("val_med"), "Median Survival Time:", value = 12, min = 0.01)
                       ),
                       conditionalPanel(condition = sprintf("input['%s'] == 'rate2med'", ns("exp_dir")),
                                        numericInput(ns("val_haz"), "Hazard Rate (lambda):", value = 0.05, min = 0.0001)
                       )
      ),

      # Weibull Inputs
      conditionalPanel(condition = sprintf("input['%s'] == 'weibull'", ns("surv_method")),
                       p(class="text-info", "Calibrate Weibull using 2 points from KM curve."),
                       h5("Point 1"),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("w_t1"), "Time 1:", 12), numericInput(ns("w_s1"), "Surv 1:", 0.8, 0, 1, 0.01)),
                       h5("Point 2"),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("w_t2"), "Time 2:", 36), numericInput(ns("w_s2"), "Surv 2:", 0.4, 0, 1, 0.01))
      ),

      # Log-Logistic Inputs
      conditionalPanel(condition = sprintf("input['%s'] == 'loglogistic'", ns("surv_method")),
                       p(class="text-info", "Calibrate Log-Logistic using 2 points from KM curve."),
                       h5("Point 1"),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("ll_t1"), "Time 1:", 12), numericInput(ns("ll_s1"), "Surv 1:", 0.8, 0, 1, 0.01)),
                       h5("Point 2"),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("ll_t2"), "Time 2:", 36), numericInput(ns("ll_s2"), "Surv 2:", 0.4, 0, 1, 0.01))
      ),

      hr(),
      numericInput(ns("max_t"), "Plot/Table Max Time:", 60),
      actionButton(ns("calc"), "Calculate & Log", class = "btn-primary", width = "100%")
    ),
    mainPanel(
      uiOutput(ns("res")),
      div(class="plot-container", plotOutput(ns("plot"), height="350px")),
      br(),
      h4("Markov Trace (Cycle-Wise)"),
      p(class="text-info", style="font-size:0.9em;", "Transition Prob (tp) represents probability of surviving the interval (t-1 to t)."),
      DT::dataTableOutput(ns("tbl_surv"))
    )
  )
}

mod_survival_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {

    surv_plot_data <- reactiveVal(NULL)
    surv_table_data <- reactiveVal(NULL)

    # Helper Log Function
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

    # MathJax retrigger
    mathjax_trigger <- tags$script("if(window.MathJax){MathJax.Hub.Queue(['Typeset', MathJax.Hub]);}")

    observeEvent(input$calc, {
      # 1. Setup Time Sequences
      t_seq_plot <- seq(0, input$max_t, length.out = 100)
      t_seq_tbl <- 0:input$max_t

      if (input$surv_method == "exp") {
        # --- Exponential Logic ---
        if (input$exp_dir == "med2rate") {
          rate <- log(2) / input$val_med
          med <- input$val_med
          inp_str <- paste0("Median=", med)
        } else {
          rate <- input$val_haz
          med <- log(2) / rate
          inp_str <- paste0("Hazard=", rate)
        }

        probs_plot <- exp(-rate * t_seq_plot)
        probs_tbl  <- exp(-rate * t_seq_tbl)
        surv_plot_data(data.frame(Time = t_seq_plot, Survival = probs_plot))

        output$res <- renderUI(tagList(
          # Result
          div(class = "result-box", HTML(paste0(
            "<span class='result-label'>Exponential Survival Parameters</span><br>",
            "<span class='result-value'>Hazard Rate (\u03bb) = ", round(rate, 5), "</span>",
            "<br><span class='result-value'>Median Survival = ", round(med, 2), "</span>"
          ))),
          # Explanation
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              if (input$exp_dir == "med2rate") {
                p(HTML(paste0(
                  "The median survival time of ", strong(round(med, 2)),
                  " was used to derive the constant hazard rate: \u03bb = ln(2) / ", round(med, 2),
                  " = ", strong(round(rate, 5)), ". ",
                  "Under the exponential assumption, 50% of patients survive beyond the median. ",
                  "The survival function S(t) = e<sup>-\u03bb\u00d7t</sup> generates the Markov trace below."
                )))
              } else {
                p(HTML(paste0(
                  "The hazard rate \u03bb = ", strong(round(rate, 5)),
                  " was used to derive the median: Median = ln(2) / ", round(rate, 5),
                  " = ", strong(round(med, 2)), ". ",
                  "This is the time at which 50% of the cohort has experienced the event."
                )))
              },
              p(HTML(paste0(
                icon("exclamation-triangle"), " ",
                strong("Limitation: "), "The exponential distribution assumes a constant hazard over time. ",
                "In oncology, this is often unrealistic. Consider Weibull fitting if the hazard changes over time."
              )))
          ),
          # Formula
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
              p("$$\\lambda = \\frac{\\ln(2)}{\\text{Median}}$$"),
              p("$$S(t) = e^{-\\lambda t}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "Transition probability for cycle t: tp(t) = S(t)/S(t-1)")
          ),
          # Citation
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Collett D. <em>Modelling Survival Data in Medical Research</em>. 3rd ed. Chapman and Hall/CRC; 2015.")),
                tags$li(HTML("Latimer NR. Survival analysis for economic evaluations alongside clinical trials. <em>Med Decis Making</em>. 2013;33(6):743-754.")),
                tags$li(HTML("NICE DSU TSD 14: Survival analysis for economic evaluations. 2013."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$label, "Survival (Exp)", inp_str, paste0("Lambda=", round(rate,5)), "Constant Hazard")

      } else if (input$surv_method == "weibull") {
        # --- Weibull Logic ---
        t1 <- input$w_t1; s1 <- input$w_s1
        t2 <- input$w_t2; s2 <- input$w_s2

        if(s1 <= 0 || s1 >= 1 || s2 <= 0 || s2 >= 1 || t1 == t2) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: Inputs must be distinct and probabilities between 0-1."))
          surv_plot_data(NULL)
          surv_table_data(NULL)
          return()
        } else {
          y1 <- log(-log(s1)); x1 <- log(t1)
          y2 <- log(-log(s2)); x2 <- log(t2)

          gamma <- (y2 - y1) / (x2 - x1)
          lambda <- exp(y1 - gamma * x1)

          probs_plot <- exp(-lambda * t_seq_plot^gamma)
          probs_tbl  <- exp(-lambda * t_seq_tbl^gamma)
          surv_plot_data(data.frame(Time = t_seq_plot, Survival = probs_plot))

          hazard_interp <- if (gamma > 1) "increasing (common in cancer)" else if (gamma < 1) "decreasing (common post-surgery)" else "constant (reduces to exponential)"

          output$res <- renderUI(tagList(
            # Result
            div(class = "result-box", HTML(paste0(
              "<span class='result-label'>Weibull Survival Parameters</span><br>",
              "<span class='result-value'>Shape (\u03b3) = ", round(gamma, 4), "</span>",
              "<span class='result-value'>Scale (\u03bb) = ", format(lambda, scientific=TRUE), "</span>"
            ))),
            # Explanation
            div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
                p(HTML(paste0(
                  "Two points from the Kaplan-Meier curve were used: ",
                  "S(", t1, ") = ", s1, " and S(", t2, ") = ", s2, ". ",
                  "Using the log-log transformation ln(-ln(S(t))) = ln(\u03bb) + \u03b3\u00d7ln(t), ",
                  "the system of two equations was solved to yield ",
                  "Shape (\u03b3) = ", strong(round(gamma, 4)), " and Scale (\u03bb) = ", strong(format(lambda, scientific=TRUE)), "."
                ))),
                p(HTML(paste0(
                  icon("info-circle"), " ",
                  "A shape of ", round(gamma, 4), " indicates the hazard is ", strong(hazard_interp), "."
                )))
            ),
            # Formula
            div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
                h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
                p("$$S(t) = e^{-\\lambda t^{\\gamma}}$$"),
                p("$$\\ln(-\\ln(S(t))) = \\ln(\\lambda) + \\gamma \\ln(t)$$"),
                p(style = "font-size:0.85em; color:#666;",
                  "The 2-point calibration solves the linearized form for \u03bb and \u03b3.")
            ),
            # Citation
            div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
                tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                  tags$li(HTML("Collett D. <em>Modelling Survival Data in Medical Research</em>. 3rd ed. Chapman and Hall/CRC; 2015.")),
                  tags$li(HTML("Latimer NR. Survival analysis for economic evaluations alongside clinical trials. <em>Med Decis Making</em>. 2013;33(6):743-754.")),
                  tags$li(HTML("NICE DSU TSD 14: Survival analysis for economic evaluations. 2013."))
                )
            ),
            mathjax_trigger
          ))

          add_to_log(input$label, "Survival (Weibull)",
                     paste0("P1(",t1,",",s1,") P2(",t2,",",s2,")"),
                     paste0("Shape=", round(gamma,4), ", Scale=", format(lambda, scientific=TRUE)),
                     "2-Point Calibration")
        }

      } else if (input$surv_method == "loglogistic") {
        # --- Log-Logistic Logic ---
        t1 <- input$ll_t1; s1 <- input$ll_s1
        t2 <- input$ll_t2; s2 <- input$ll_s2

        if(s1 <= 0 || s1 >= 1 || s2 <= 0 || s2 >= 1 || t1 == t2) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: Inputs must be distinct and probabilities between 0-1."))
          surv_plot_data(NULL)
          surv_table_data(NULL)
          return()
        }

        # Log-Logistic: S(t) = 1 / (1 + (t/alpha)^beta)
        # => 1/S - 1 = (t/alpha)^beta
        # => ln(1/S - 1) = beta*ln(t) - beta*ln(alpha)
        y1 <- log(1/s1 - 1); x1 <- log(t1)
        y2 <- log(1/s2 - 1); x2 <- log(t2)

        beta_ll <- (y2 - y1) / (x2 - x1)
        log_alpha <- -y1/beta_ll + x1
        alpha_ll <- exp(log_alpha)

        probs_plot <- 1 / (1 + (t_seq_plot / alpha_ll)^beta_ll)
        probs_plot[1] <- 1  # S(0) = 1
        probs_tbl  <- 1 / (1 + (t_seq_tbl / alpha_ll)^beta_ll)
        probs_tbl[1] <- 1

        surv_plot_data(data.frame(Time = t_seq_plot, Survival = probs_plot))

        hazard_interp <- if (beta_ll > 1) "initially increasing then decreasing (hump-shaped)" else if (beta_ll < 1) "monotonically decreasing" else "constant (reduces to exponential)"

        output$res <- renderUI(tagList(
          div(class = "result-box", HTML(paste0(
            "<span class='result-label'>Log-Logistic Survival Parameters</span><br>",
            "<span class='result-value'>Shape (\u03b2) = ", round(beta_ll, 4), "</span>",
            "<span class='result-value'>Scale (\u03b1) = ", round(alpha_ll, 4), "</span>",
            "<br><small>Median survival = \u03b1 = ", round(alpha_ll, 2), " (the scale parameter equals the median)</small>"
          ))),
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "Two points from the Kaplan-Meier curve were used: ",
                "S(", t1, ") = ", s1, " and S(", t2, ") = ", s2, ". ",
                "Using the log-odds transformation ln(1/S - 1) = \u03b2\u00d7ln(t) - \u03b2\u00d7ln(\u03b1), ",
                "the parameters were derived: ",
                "Shape (\u03b2) = ", strong(round(beta_ll, 4)),
                " and Scale (\u03b1) = ", strong(round(alpha_ll, 4)), "."
              ))),
              p(HTML(paste0(
                icon("info-circle"), " ",
                "The hazard function is ", strong(hazard_interp),
                ". Log-Logistic is particularly useful in oncology when the hazard peaks and then declines ",
                "(e.g., post-surgical mortality). Unlike Weibull, it allows non-monotonic hazards."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
              p("$$S(t) = \\frac{1}{1 + (t/\\alpha)^\\beta}$$"),
              p("$$h(t) = \\frac{(\\beta/\\alpha)(t/\\alpha)^{\\beta-1}}{1 + (t/\\alpha)^\\beta}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "\u03b1 = scale (equals median survival), \u03b2 = shape (>1 gives hump-shaped hazard).")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Collett D. <em>Modelling Survival Data in Medical Research</em>. 3rd ed. CRC Press; 2015.")),
                tags$li(HTML("Latimer NR. Survival analysis for economic evaluations. <em>Med Decis Making</em>. 2013;33(6):743-754.")),
                tags$li(HTML("NICE DSU TSD 14: Survival analysis for economic evaluations. 2013."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$label, "Survival (Log-Logistic)",
                   paste0("P1(",t1,",",s1,") P2(",t2,",",s2,")"),
                   paste0("Shape=", round(beta_ll,4), ", Scale=", round(alpha_ll,4)),
                   "2-Point Calibration")
      }

      # --- Generate Table Data (Common Step) ---
      if (!is.null(surv_plot_data())) {
        tp <- numeric(length(probs_tbl))
        tp[1] <- 1
        for(i in 2:length(probs_tbl)) {
          prev <- probs_tbl[i-1]
          curr <- probs_tbl[i]
          if(prev > 0) tp[i] <- curr / prev else tp[i] <- 0
        }
        haz_t <- -log(tp)
        surv_table_data(data.frame(
          Cycle = t_seq_tbl,
          Survival_S_t = probs_tbl,
          Trans_Prob_tp = tp,
          Interval_Hazard = haz_t
        ))
      }
    })

    # Plot Output
    output$plot <- renderPlot({
      req(surv_plot_data())
      ggplot(surv_plot_data(), aes(x = Time, y = Survival)) +
        geom_line(color = "#003366", size = 1.2) +
        geom_area(fill = "#003366", alpha = 0.1) +
        theme_minimal() + ylim(0, 1) +
        labs(title = "Projected Survival Curve", y = "S(t)", x = "Time")
    })

    # Table Output
    output$tbl_surv <- DT::renderDataTable({
      req(surv_table_data())
      DT::datatable(surv_table_data(),
                    extensions = 'Buttons',
                    options = list(
                      dom = 'Blfrtip',
                      pageLength = 10,
                      lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'All')),
                      buttons = list('copy', 'csv', 'excel')
                    ),
                    rownames = FALSE) %>%
        DT::formatRound(columns=c("Survival_S_t", "Trans_Prob_tp", "Interval_Hazard"), digits=5)
    })
  })
}
