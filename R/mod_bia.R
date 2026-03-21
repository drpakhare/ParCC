mod_bia_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4(icon("chart-area"), " Budget Impact Analysis"),
      textInput(ns("label"), "Analysis Name:", placeholder = "e.g., New Oncology Drug - BIA"),
      hr(),

      h5("1. Population"),
      numericInput(ns("pop"), "Total Population:", value = 1000000, min = 1),
      numericInput(ns("prevalence"), "Disease Prevalence (%):", value = 1, min = 0, max = 100, step = 0.1),
      numericInput(ns("eligible"), "Treatment Eligible (%):", value = 50, min = 0, max = 100, step = 1),

      hr(),
      h5("2. Market Uptake (% of eligible patients)"),
      helpText("Enter uptake for each year (Year 1 to 5)."),
      div(style="display:flex; gap:5px; flex-wrap:wrap;",
          numericInput(ns("uptake1"), "Yr 1:", value = 10, min = 0, max = 100, width = "18%"),
          numericInput(ns("uptake2"), "Yr 2:", value = 25, min = 0, max = 100, width = "18%"),
          numericInput(ns("uptake3"), "Yr 3:", value = 40, min = 0, max = 100, width = "18%"),
          numericInput(ns("uptake4"), "Yr 4:", value = 50, min = 0, max = 100, width = "18%"),
          numericInput(ns("uptake5"), "Yr 5:", value = 55, min = 0, max = 100, width = "18%")
      ),

      hr(),
      h5("3. Per-Patient Costs (Annual)"),
      numericInput(ns("cost_new"), "New Intervention Cost:", value = 50000, min = 0),
      numericInput(ns("cost_current"), "Current Standard of Care Cost:", value = 20000, min = 0),

      hr(),
      h5("4. Discount Rate"),
      numericInput(ns("bia_disc"), "Discount Rate (%):", value = 0, min = 0, max = 20, step = 0.5),
      helpText("Set to 0% for undiscounted BIA (common practice). Discount if required by HTA agency."),

      br(),
      actionButton(ns("calc"), "Calculate BIA", class = "btn-primary", width = "100%")
    ),
    mainPanel(
      uiOutput(ns("res_bia")),
      br(),
      div(class = "plot-container", plotOutput(ns("plot_bia"), height = "400px")),
      br(),
      DT::dataTableOutput(ns("tbl_bia"))
    )
  )
}

mod_bia_server <- function(id, logger, currency) {
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
    cfmt <- function(x) paste0(currency$symbol, " ", format(round(x, 0), big.mark = ","))

    observeEvent(input$calc, {
      # Eligible population
      target_pop <- input$pop * (input$prevalence / 100) * (input$eligible / 100)
      uptakes <- c(input$uptake1, input$uptake2, input$uptake3, input$uptake4, input$uptake5) / 100
      disc_r <- input$bia_disc / 100

      years <- 1:5
      n_new <- target_pop * uptakes
      n_current <- target_pop - n_new

      # Per-patient incremental cost
      incr_cost_pp <- input$cost_new - input$cost_current

      # Annual costs
      cost_new_total <- n_new * input$cost_new
      cost_current_total <- n_current * input$cost_current
      cost_scenario_new <- cost_new_total + cost_current_total
      cost_scenario_old <- rep(target_pop * input$cost_current, 5)
      budget_impact <- cost_scenario_new - cost_scenario_old

      # Discounting
      disc_factors <- 1 / (1 + disc_r)^(years - 1)
      budget_impact_disc <- budget_impact * disc_factors

      total_impact <- sum(budget_impact_disc)

      # Results table
      bia_df <- data.frame(
        Year = years,
        Uptake_Pct = uptakes * 100,
        N_New = round(n_new, 0),
        N_Current = round(n_current, 0),
        Cost_New_Scenario = round(cost_scenario_new, 0),
        Cost_Current_Scenario = round(cost_scenario_old, 0),
        Budget_Impact = round(budget_impact, 0),
        Discount_Factor = round(disc_factors, 4),
        Budget_Impact_Disc = round(budget_impact_disc, 0)
      )

      output$res_bia <- renderUI(tagList(
        div(class = "result-box", style = paste0("border-left-color:", if(total_impact > 0) "#e67e22" else "#27ae60"), HTML(paste0(
          "<span class='result-label'>Budget Impact Analysis (5-Year)</span><br>",
          "Target Population: ", format(round(target_pop, 0), big.mark = ","), " patients<br>",
          "Per-Patient Incremental Cost: ", cfmt(incr_cost_pp), " / year<br><br>",
          "<span class='result-value'>Total 5-Year Budget Impact = ", cfmt(total_impact), "</span>",
          "<br><small>Year 1: ", cfmt(budget_impact_disc[1]),
          " | Year 5: ", cfmt(budget_impact_disc[5]), "</small>"
        ))),
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "The BIA compares the total healthcare cost under the ", strong("new scenario"), " (with market uptake of the new intervention) ",
              "versus the ", strong("current scenario"), " (all patients on standard of care)."
            ))),
            tags$ol(
              tags$li(HTML(paste0(
                strong("Eligible population: "), format(input$pop, big.mark=","),
                " \u00d7 ", input$prevalence, "% \u00d7 ", input$eligible, "% = ",
                strong(format(round(target_pop, 0), big.mark=",")), " patients."
              ))),
              tags$li(HTML(paste0(
                strong("Year-by-year: "), "Uptake determines how many patients switch to the new intervention. ",
                "Budget impact = (New scenario cost) - (Current scenario cost)."
              ))),
              tags$li(HTML(paste0(
                strong("5-year total: "), cfmt(total_impact),
                if (disc_r > 0) paste0(" (discounted at ", input$bia_disc, "%).") else " (undiscounted)."
              )))
            )
        ),
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
            p("$$BI_t = (N_{new,t} \\times C_{new}) + (N_{current,t} \\times C_{current}) - (N_{total} \\times C_{current})$$"),
            p("$$BI_{total} = \\sum_{t=1}^{T} \\frac{BI_t}{(1+r)^{t-1}}$$"),
            p(style = "font-size:0.85em; color:#666;",
              "N_new = eligible population \u00d7 uptake rate. Budget impact is the incremental cost to the payer.")
        ),
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Sullivan SD, et al. Budget impact analysis\u2014principles of good practice: report of the ISPOR 2012 Budget Impact Analysis Good Practice II Task Force. <em>Value in Health</em>. 2014;17(1):5-14.")),
              tags$li(HTML("Mauskopf JA, et al. Principles of good practice for budget impact analysis. <em>Value in Health</em>. 2007;10(5):336-347."))
            )
        ),
        mathjax_trigger
      ))

      # --- Plot ---
      output$plot_bia <- renderPlot({
        plot_df <- data.frame(
          Year = rep(years, 3),
          Value = c(cost_scenario_old, cost_scenario_new, budget_impact_disc),
          Category = rep(c("Current Scenario", "New Scenario", "Budget Impact"), each = 5)
        )
        plot_df$Category <- factor(plot_df$Category, levels = c("Current Scenario", "New Scenario", "Budget Impact"))

        cs <- isolate(currency$symbol)

        ggplot() +
          geom_bar(data = plot_df[plot_df$Category != "Budget Impact",],
                   aes(x = factor(Year), y = Value, fill = Category),
                   stat = "identity", position = "dodge", alpha = 0.8) +
          geom_line(data = plot_df[plot_df$Category == "Budget Impact",],
                    aes(x = Year, y = Value, color = "Budget Impact"),
                    linewidth = 1.5) +
          geom_point(data = plot_df[plot_df$Category == "Budget Impact",],
                     aes(x = Year, y = Value, color = "Budget Impact"), size = 3) +
          scale_fill_manual(values = c("Current Scenario" = "#95a5a6", "New Scenario" = "#003366")) +
          scale_color_manual(values = c("Budget Impact" = "#e74c3c")) +
          theme_minimal(base_size = 13) +
          labs(title = "5-Year Budget Impact Projection",
               y = paste0("Annual Cost (", cs, ")"),
               x = "Year", fill = "", color = "") +
          theme(legend.position = "bottom")
      })

      # --- Table ---
      output$tbl_bia <- DT::renderDataTable({
        DT::datatable(bia_df,
                      options = list(dom = 'Bt', pageLength = 5, buttons = list('copy', 'csv', 'excel')),
                      extensions = 'Buttons',
                      rownames = FALSE) %>%
          DT::formatRound(columns = c("Cost_New_Scenario", "Cost_Current_Scenario", "Budget_Impact", "Budget_Impact_Disc"), digits = 0)
      })

      # --- Log ---
      add_to_log(input$label, "Budget Impact",
                 paste0("Pop=", format(round(target_pop,0), big.mark=","),
                        ", dCost=", cfmt(incr_cost_pp)),
                 paste0("5yr BI=", cfmt(total_impact)),
                 "ISPOR BIA Framework")
    })
  })
}
