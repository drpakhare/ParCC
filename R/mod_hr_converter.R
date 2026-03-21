# ==============================================================================
# MODULE: HR-BASED PROBABILITY CONVERTER
# Converts standard/control group probabilities to intervention group
# probabilities using hazard ratios from clinical trials.
# ==============================================================================

mod_hr_converter_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    # --- Single Conversion ---
    tabPanel("HR Converter",
             sidebarLayout(
               sidebarPanel(
                 h4(icon("exchange-alt"), " Hazard Ratio Converter"),
                 p(class = "text-info", "Convert a control group probability to an intervention group probability using a published Hazard Ratio."),

                 textInput(ns("label"), "Parameter Name:",
                           placeholder = "e.g., Mortality - Ticagrelor vs Aspirin"),
                 hr(),

                 # --- Control Group Inputs ---
                 h5(icon("users"), " Control / Standard Group"),
                 numericInput(ns("p_control"), "Probability (Control):",
                              value = 0.05, min = 0.0001, max = 0.9999, step = 0.01),

                 div(style = "display:flex; gap:10px;",
                     numericInput(ns("t_control"), "Time Horizon:", value = 1, min = 0.001, width = "50%"),
                     selectInput(ns("t_unit"), "Unit:",
                                 choices = c("Years", "Months", "Weeks"),
                                 selected = "Years", width = "50%")
                 ),

                 hr(),
                 # --- Hazard Ratio Inputs ---
                 h5(icon("chart-line"), " Hazard Ratio (from Trial)"),
                 numericInput(ns("hr"), "HR (Point Estimate):",
                              value = 0.84, min = 0.001, max = 10, step = 0.01),

                 checkboxInput(ns("use_ci"), "Include 95% CI for HR", value = TRUE),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == true", ns("use_ci")),
                   div(style = "display:flex; gap:10px;",
                       numericInput(ns("hr_low"), "HR Lower:", value = 0.74, min = 0.001, step = 0.01, width = "50%"),
                       numericInput(ns("hr_high"), "HR Upper:", value = 0.95, min = 0.001, step = 0.01, width = "50%")
                   )
                 ),

                 hr(),
                 # --- Model Cycle ---
                 h5(icon("sync-alt"), " Target Model Cycle"),
                 checkboxInput(ns("rescale"), "Rescale to different cycle length", value = FALSE),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == true", ns("rescale")),
                   div(style = "display:flex; gap:10px;",
                       numericInput(ns("t_new"), "New Cycle:", value = 1, min = 0.001, width = "50%"),
                       selectInput(ns("t_new_unit"), "Unit:",
                                   choices = c("Years", "Months", "Weeks"),
                                   selected = "Months", width = "50%")
                   )
                 ),

                 br(),
                 actionButton(ns("calc"), "Convert & Log", class = "btn-primary", width = "100%")
               ),

               mainPanel(
                 # Results Panel
                 uiOutput(ns("result_panel")),

                 # Comparison Plot
                 div(class = "plot-container", plotOutput(ns("comparison_plot"), height = "350px")),

                 br(),
                 # Summary Table
                 h4("Step-by-Step Calculation"),
                 DT::dataTableOutput(ns("steps_table"))
               )
             )
    ),

    # --- Scenario Comparison ---
    tabPanel("Multi-HR Comparison",
             sidebarLayout(
               sidebarPanel(
                 h4(icon("layer-group"), " Compare Multiple HRs"),
                 p(class = "text-info", "Compare intervention probabilities across different HRs (e.g., subgroup analyses or multiple comparators)."),

                 numericInput(ns("mc_p_control"), "Control Probability:",
                              value = 0.12, min = 0.0001, max = 0.9999, step = 0.01),
                 numericInput(ns("mc_time"), "Time Horizon (Years):", value = 1, min = 0.001),

                 hr(),
                 h5("Enter HRs (comma-separated):"),
                 textInput(ns("mc_hrs"), "Hazard Ratios:",
                           value = "0.70, 0.80, 0.90, 1.00, 1.20",
                           placeholder = "e.g., 0.70, 0.80, 0.90"),
                 textInput(ns("mc_labels"), "Labels (optional):",
                           value = "Drug A, Drug B, Drug C, Control, Drug D",
                           placeholder = "e.g., Ticagrelor, Prasugrel"),

                 br(),
                 actionButton(ns("calc_mc"), "Compare", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("mc_result")),
                 div(class = "plot-container", plotOutput(ns("mc_plot"), height = "400px")),
                 br(),
                 DT::dataTableOutput(ns("mc_table"))
               )
             )
    )
  )
}


mod_hr_converter_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {

    # Unit conversion factors (to years)
    unit_to_years <- list("Years" = 1, "Months" = 1/12, "Weeks" = 1/52.1775)

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

    # ============================================================
    # MAIN CONVERTER
    # ============================================================
    observeEvent(input$calc, {

      p_c <- input$p_control
      hr  <- input$hr
      t_c <- input$t_control * unit_to_years[[input$t_unit]]

      # Validate
      if (p_c <= 0 || p_c >= 1) {
        output$result_panel <- renderUI(div(class = "result-box", style = "border-left-color: red;",
                                            span(style = "color:red;", "Error: Probability must be between 0 and 1 (exclusive).")))
        return()
      }
      if (hr <= 0) {
        output$result_panel <- renderUI(div(class = "result-box", style = "border-left-color: red;",
                                            span(style = "color:red;", "Error: Hazard Ratio must be positive.")))
        return()
      }

      # ---- STEP 1: Probability to Rate (control) ----
      r_control <- -log(1 - p_c) / t_c

      # ---- STEP 2: Apply HR ----
      r_intervention <- r_control * hr

      # ---- STEP 3: Rate to Probability (intervention) ----
      # Determine output time horizon
      if (input$rescale) {
        t_out <- input$t_new * unit_to_years[[input$t_new_unit]]
        t_out_label <- paste(input$t_new, input$t_new_unit)
      } else {
        t_out <- t_c
        t_out_label <- paste(input$t_control, input$t_unit)
      }

      p_intervention <- 1 - exp(-r_intervention * t_out)

      # Also compute p_control for same output time (for comparison)
      p_control_out <- 1 - exp(-r_control * t_out)

      # ---- CI Calculations ----
      ci_html <- ""
      p_low <- NA; p_high <- NA
      if (input$use_ci) {
        r_low  <- r_control * input$hr_low
        r_high <- r_control * input$hr_high
        p_low  <- 1 - exp(-r_low * t_out)
        p_high <- 1 - exp(-r_high * t_out)
        ci_html <- paste0(
          "<br><span class='result-label'>95% CI (Intervention Probability)</span>",
          "<span class='result-value' style='font-size:1.1em;'>",
          round(p_low, 5), " to ", round(p_high, 5),
          "</span>"
        )
      }

      # ---- Absolute & Relative Risk Reduction ----
      arr <- p_control_out - p_intervention
      rrr <- arr / p_control_out
      nnt <- ifelse(arr > 0, ceiling(1 / arr), NA)

      risk_html <- ""
      if (hr < 1) {
        risk_html <- paste0(
          "<br><span class='result-label'>Clinical Impact</span>",
          "<span style='color:#27ae60; font-weight:600;'>",
          "ARR = ", round(arr * 100, 2), "% | ",
          "RRR = ", round(rrr * 100, 1), "% | ",
          "NNT = ", ifelse(!is.na(nnt), nnt, "N/A"),
          "</span>"
        )
      } else if (hr > 1) {
        ari <- abs(arr)
        nnh <- ifelse(ari > 0, ceiling(1 / ari), NA)
        risk_html <- paste0(
          "<br><span class='result-label'>Clinical Impact</span>",
          "<span style='color:#e74c3c; font-weight:600;'>",
          "ARI = ", round(ari * 100, 2), "% (Harm) | ",
          "NNH = ", ifelse(!is.na(nnh), nnh, "N/A"),
          "</span>"
        )
      }

      # ============================================================
      # OUTPUT: Results + Explanation + Formula + Citation
      # ============================================================
      output$result_panel <- renderUI({
        tagList(
          # --- RESULT BOX ---
          div(class = "result-box",
              HTML(paste0(
                "<span class='result-label'>Control Probability (", t_out_label, ")</span>",
                "<span class='result-value'>", round(p_control_out, 5), "</span>",
                "<br>",
                "<span class='result-label'>Intervention Probability (", t_out_label, ") &mdash; HR = ", hr, "</span>",
                "<span class='result-value' style='color:#0056b3;'>", round(p_intervention, 5), "</span>",
                ci_html,
                risk_html
              ))
          ),

          # --- EXPLANATION BOX ---
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p("The conversion follows a three-step process assuming proportional hazards (constant HR over time):"),
              tags$ol(
                tags$li(HTML(paste0(
                  strong("Probability \u2192 Rate (Control):"),
                  " The control probability (", round(p_c, 4), ") was converted to an instantaneous rate using the inverse exponential formula: ",
                  "r = -ln(1 - p) / t = ", strong(round(r_control, 5)), " per year."
                ))),
                tags$li(HTML(paste0(
                  strong("Apply Hazard Ratio:"),
                  " The intervention rate was derived by multiplying the control rate by the HR: ",
                  "r\u2099\u2091\u1d61 = ", round(r_control, 5), " \u00d7 ", hr, " = ",
                  strong(round(r_intervention, 5)), " per year."
                ))),
                tags$li(HTML(paste0(
                  strong("Rate \u2192 Probability (Intervention):"),
                  " The intervention rate was converted back to a probability over ", t_out_label, ": ",
                  "p = 1 - e^(-r\u00d7t) = ", strong(round(p_intervention, 5)), "."
                )))
              ),
              if (hr < 1) {
                p(HTML(paste0(
                  icon("info-circle"), " ",
                  "A HR of ", hr, " means the intervention group has a ",
                  strong(round((1 - hr) * 100, 1), "% lower"),
                  " instantaneous risk of the event compared to the control group."
                )))
              } else if (hr > 1) {
                p(HTML(paste0(
                  icon("exclamation-triangle"), " ",
                  "A HR of ", hr, " means the intervention group has a ",
                  strong(round((hr - 1) * 100, 1), "% higher"),
                  " instantaneous risk of the event compared to the control group."
                )))
              }
          ),

          # --- FORMULA BOX ---
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formulas Applied", style = "margin-top:0;"),
              p("Under the proportional hazards assumption:"),
              p("$$r_{control} = -\\frac{\\ln(1 - p_{control})}{t}$$"),
              p("$$r_{intervention} = r_{control} \\times HR$$"),
              p("$$p_{intervention} = 1 - e^{-r_{intervention} \\times t_{cycle}}$$"),
              p(style = "font-size:0.85em; color:#666; margin-top:10px;",
                strong("Key Assumption: "),
                "The Hazard Ratio is constant over time (proportional hazards). ",
                "This is standard practice in Markov cohort models and is recommended by NICE DSU TSD 14.")
          ),
          # Trigger MathJax to typeset dynamic content
          tags$script("if(window.MathJax){MathJax.Hub.Queue(['Typeset', MathJax.Hub]);}"),

          # --- CITATION BOX ---
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                      tags$li(HTML("Sonnenberg FA, Beck JR. Markov models in medical decision making: a practical guide. <em>Med Decis Making</em>. 1993;13(4):322-338.")),
                      tags$li(HTML("Briggs A, Claxton K, Sculpher M. <em>Decision Modelling for Health Economic Evaluation</em>. Oxford University Press; 2006.")),
                      tags$li(HTML("Fleurence RL, Hollenbeak CS. Rates and probabilities in economic modelling. <em>Pharmacoeconomics</em>. 2007;25(1):3-12.")),
                      tags$li(HTML("NICE Decision Support Unit. TSD 14: Survival analysis for economic evaluations. 2013.")),
                      tags$li(HTML("Woods BS, et al. Country-level cost-effectiveness thresholds. <em>J Med Econ</em>. 2016."))
              )
          )
        )
      })

      # ---- Comparison Plot ----
      output$comparison_plot <- renderPlot({
        t_max <- t_out * 3
        t_seq <- seq(0, t_max, length.out = 200)

        s_control <- exp(-r_control * t_seq)
        s_interv  <- exp(-r_intervention * t_seq)

        plot_df <- data.frame(
          Time = rep(t_seq, 2),
          Survival = c(s_control, s_interv),
          Group = rep(c("Control", "Intervention"), each = length(t_seq))
        )

        ggplot(plot_df, aes(x = Time, y = Survival, color = Group, fill = Group)) +
          geom_line(linewidth = 1.2) +
          geom_area(alpha = 0.08, position = "identity") +
          geom_vline(xintercept = t_out, linetype = "dashed", color = "grey40", linewidth = 0.5) +
          annotate("text", x = t_out, y = 0.98, label = paste0("Model cycle = ", t_out_label),
                   hjust = -0.05, size = 3.5, color = "grey30") +
          geom_point(data = data.frame(
            Time = c(t_out, t_out),
            Survival = c(1 - p_control_out, 1 - p_intervention),
            Group = c("Control", "Intervention")
          ), size = 3) +
          scale_color_manual(values = c("Control" = "#e74c3c", "Intervention" = "#2980b9")) +
          scale_fill_manual(values = c("Control" = "#e74c3c", "Intervention" = "#2980b9")) +
          theme_minimal(base_size = 13) +
          ylim(0, 1) +
          labs(
            title = "Projected Survival: Control vs Intervention",
            subtitle = paste0("HR = ", hr, " | Control p = ", round(p_control_out, 4),
                              " | Intervention p = ", round(p_intervention, 4)),
            x = "Time (Years)", y = "S(t)", color = "Group", fill = "Group"
          ) +
          theme(
            legend.position = "bottom",
            plot.title = element_text(face = "bold", color = "#003366")
          )
      })

      # ---- Steps Table ----
      steps_df <- data.frame(
        Step = c("1. Input", "2. Control Rate", "3. Intervention Rate", "4. Intervention Prob"),
        Description = c(
          paste0("Control p = ", round(p_c, 5), " over ", input$t_control, " ", input$t_unit),
          paste0("r_control = -ln(1 - ", round(p_c, 5), ") / ", round(t_c, 4)),
          paste0("r_intervention = ", round(r_control, 5), " x ", hr),
          paste0("p_intervention = 1 - exp(-", round(r_intervention, 5), " x ", round(t_out, 4), ")")
        ),
        Value = c(
          paste0("p = ", round(p_c, 5)),
          paste0(round(r_control, 5), " /year"),
          paste0(round(r_intervention, 5), " /year"),
          round(p_intervention, 5)
        ),
        stringsAsFactors = FALSE
      )

      if (input$use_ci) {
        steps_df <- rbind(steps_df, data.frame(
          Step = "5. 95% CI",
          Description = paste0("HR range [", input$hr_low, ", ", input$hr_high, "]"),
          Value = paste0("[", round(p_low, 5), ", ", round(p_high, 5), "]"),
          stringsAsFactors = FALSE
        ))
      }

      if (!is.na(nnt) && hr < 1) {
        steps_df <- rbind(steps_df, data.frame(
          Step = "6. NNT",
          Description = paste0("1 / ARR = 1 / ", round(arr, 5)),
          Value = nnt,
          stringsAsFactors = FALSE
        ))
      }

      output$steps_table <- DT::renderDataTable({
        DT::datatable(steps_df, options = list(dom = 't', pageLength = 10, ordering = FALSE),
                      rownames = FALSE)
      })

      # ---- Log ----
      log_input <- paste0("p_ctrl=", round(p_c, 5), ", HR=", hr,
                          ", t=", input$t_control, " ", input$t_unit)
      log_result <- paste0("p_int=", round(p_intervention, 5))
      if (input$use_ci) {
        log_result <- paste0(log_result, " [", round(p_low, 5), "-", round(p_high, 5), "]")
      }

      add_to_log(input$label, "HR Conversion", log_input, log_result, "Proportional Hazards")
    })

    # ============================================================
    # MULTI-HR COMPARISON
    # ============================================================
    observeEvent(input$calc_mc, {
      p_c <- input$mc_p_control
      t_c <- input$mc_time

      hrs <- as.numeric(trimws(unlist(strsplit(input$mc_hrs, ","))))
      labels <- trimws(unlist(strsplit(input$mc_labels, ",")))

      if (length(labels) < length(hrs)) {
        labels <- c(labels, paste0("HR=", hrs[(length(labels) + 1):length(hrs)]))
      }

      r_control <- -log(1 - p_c) / t_c

      results <- data.frame(
        Label = labels[1:length(hrs)],
        HR = hrs,
        Rate = r_control * hrs,
        Probability = 1 - exp(-(r_control * hrs) * t_c),
        stringsAsFactors = FALSE
      )
      results$ARR <- p_c - results$Probability
      results$NNT <- ifelse(results$ARR > 0, ceiling(1 / results$ARR), NA)

      output$mc_result <- renderUI({
        div(class = "result-box",
            HTML(paste0(
              "<span class='result-label'>Baseline: Control p = ", round(p_c, 4),
              " over ", t_c, " year(s)</span>",
              "<span class='result-value'>Control Rate = ", round(r_control, 5), " /year</span>"
            ))
        )
      })

      output$mc_plot <- renderPlot({
        # Compute survival curves for each
        t_seq <- seq(0, t_c * 2, length.out = 200)

        plot_data <- do.call(rbind, lapply(1:nrow(results), function(i) {
          data.frame(
            Time = t_seq,
            Survival = exp(-results$Rate[i] * t_seq),
            Group = results$Label[i],
            stringsAsFactors = FALSE
          )
        }))

        ggplot(plot_data, aes(x = Time, y = Survival, color = Group)) +
          geom_line(linewidth = 1.1) +
          geom_vline(xintercept = t_c, linetype = "dashed", color = "grey50") +
          theme_minimal(base_size = 13) +
          ylim(0, 1) +
          labs(
            title = "Survival Comparison Across Hazard Ratios",
            subtitle = paste0("Control probability = ", round(p_c, 4), " over ", t_c, " year(s)"),
            x = "Time (Years)", y = "S(t)", color = "Comparator"
          ) +
          theme(
            legend.position = "bottom",
            plot.title = element_text(face = "bold", color = "#003366")
          )
      })

      output$mc_table <- DT::renderDataTable({
        DT::datatable(results,
                      options = list(dom = 't', pageLength = 20, ordering = FALSE),
                      rownames = FALSE) %>%
          DT::formatRound(columns = c("Rate", "Probability", "ARR"), digits = 5)
      })
    })

  })
}
