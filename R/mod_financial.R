mod_financial_ui <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    tabPanel("Inflation",
             sidebarLayout(
               sidebarPanel(
                 h4("Cost Inflation"),
                 textInput(ns("lbl_inf"), "Parameter Name:", placeholder = "e.g., Drug Acquisition Cost"),
                 hr(),
                 
                 # 1. Cost Input
                 numericInput(ns("cost"), "Original Cost (INR):", value = 1000, min = 0),
                 
                 # 2. Method Selection
                 radioButtons(ns("inf_method"), "Adjustment Method:",
                              choices = c("Using Average % Rate" = "rate",
                                          "Using Price Indices (CPI)" = "cpi")),
                 
                 # 3A. Rate Inputs
                 conditionalPanel(condition = sprintf("input['%s'] == 'rate'", ns("inf_method")),
                                  numericInput(ns("rate"), "Avg Annual Inflation Rate (%):", value = 5, min = 0, step = 0.1),
                                  div(style="display:flex; gap:10px;",
                                      numericInput(ns("y1"), "Base Year:", 2018),
                                      numericInput(ns("y2"), "Target Year:", 2024))
                 ),
                 
                 # 3B. CPI Inputs
                 conditionalPanel(condition = sprintf("input['%s'] == 'cpi'", ns("inf_method")),
                                  helpText("Enter the Index value (e.g., CPI) for the respective years."),
                                  div(style="display:flex; gap:10px;",
                                      numericInput(ns("cpi_old"), "Base Index (Old):", value = 139.7),
                                      numericInput(ns("cpi_new"), "Target Index (New):", value = 185.3))
                 ),
                 
                 actionButton(ns("calc_inf"), "Adjust & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_inf")),
                 
                 # --- NEW: Data Sources Section ---
                 div(class="well", style="margin-top: 20px;",
                     h5(icon("database"), " Official Data Sources"),
                     p("Use these links to find CPI values for India and Global economies:"),
                     tags$ul(style="list-style-type: none; padding-left: 10px;",
                             tags$li(icon("arrow-up-right-from-square"), tags$a(href="https://dbie.rbi.org.in/", target="_blank", " Reserve Bank of India (DBIE)"), " - Standard Macroeconomic Data"),
                             tags$li(icon("arrow-up-right-from-square"), tags$a(href="https://mospi.gov.in/", target="_blank", " MOSPI (Govt of India)"), " - Official CPI (General)"),
                             tags$li(icon("arrow-up-right-from-square"), tags$a(href="https://labourbureau.gov.in/", target="_blank", " Labour Bureau"), " - CPI for Industrial Workers (CPI-IW)"),
                             tags$li(icon("arrow-up-right-from-square"), tags$a(href="https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG", target="_blank", " World Bank Data"), " - Global Inflation Indices")
                     )
                 ),
                 
                 div(class="alert alert-info", style="font-size: 0.9em;",
                     icon("lightbulb"), " **Tip:** For healthcare-specific adjustments, look for the 'Health' subgroup index within the general CPI reports if available, or use the general CPI as a conservative proxy."
                 )
               )
             )
    ),
    tabPanel("Discounting",
             sidebarLayout(
               sidebarPanel(
                 h4("Discounting Calculator"),
                 textInput(ns("lbl_disc"), "Parameter Name:", placeholder = "e.g., QALYs Year 10"),
                 hr(),
                 
                 # HTA-SPECIFIC TERMINOLOGY
                 numericInput(ns("val"), "Undiscounted Value (at Time t):", value = 5000),
                 helpText("Enter raw Cost (INR) or QALYs occurring in the future year."),
                 
                 numericInput(ns("disc_r"), "Discount Rate (%):", value = 3, min = 0, step = 0.1),
                 numericInput(ns("t"), "Time (Years into future):", value = 10, min = 0),
                 actionButton(ns("calc_disc"), "Calculate & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(uiOutput(ns("res_disc")))
             )
    )
  )
}

mod_financial_server <- function(id, logger) {
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
    
    # --- Inflation Logic ---
    observeEvent(input$calc_inf, {
      
      if (input$inf_method == "rate") {
        # Method A: Rate
        years <- input$y2 - input$y1
        if(years < 0) {
          output$res_inf <- renderUI(div(class="result-box", style="color:red", "Target year must be >= Base year."))
          return()
        }
        new_cost <- input$cost * ((1 + input$rate/100)^years)
        
        # Added "INR" to display
        out_html <- paste0("<span class='result-label'>Rate Adjustment</span><br>Time Span: ", years, " Years<br><br>",
                           "<span class='result-value'>Adjusted Cost = INR ", format(round(new_cost, 2), big.mark=","), "</span>")
        
        # Added "INR" to log
        add_to_log(input$lbl_inf, "Inflation (Rate)", 
                   paste0("Cost=INR ", input$cost, ", Rate=", input$rate, "%, Yrs=", years), 
                   paste0("Adj Cost=INR ", round(new_cost,2)), "Compound Interest")
        
      } else {
        # Method B: CPI (Index)
        idx_old <- input$cpi_old
        idx_new <- input$cpi_new
        
        if (idx_old <= 0 || idx_new <= 0) {
          output$res_inf <- renderUI(div(class="result-box", style="color:red", "Indices must be positive."))
          return()
        }
        
        ratio <- idx_new / idx_old
        new_cost <- input$cost * ratio
        
        # Added "INR" to display
        out_html <- paste0("<span class='result-label'>Index Adjustment</span><br>Inflation Factor: ", round(ratio, 4), "<br><br>",
                           "<span class='result-value'>Adjusted Cost = INR ", format(round(new_cost, 2), big.mark=","), "</span>")
        
        # Added "INR" to log
        add_to_log(input$lbl_inf, "Inflation (CPI)", 
                   paste0("Cost=INR ", input$cost, ", Index ", idx_old, "->", idx_new), 
                   paste0("Adj Cost=INR ", round(new_cost,2)), "Index Ratio")
      }
      
      output$res_inf <- renderUI(div(class="result-box", HTML(out_html)))
    })
    
    # --- Discounting Logic ---
    observeEvent(input$calc_disc, {
      discounted_val <- input$val / ((1 + input$disc_r/100)^input$t)
      
      output$res_disc <- renderUI(div(class="result-box", HTML(paste0(
        "<span class='result-label'>Result</span><br>",
        "Undiscounted: ", format(input$val, big.mark=","), "<br>",
        "Discount Factor: ", round(1/((1+input$disc_r/100)^input$t), 4), "<br><br>",
        "<span class='result-value'>Discounted Value = ", format(round(discounted_val, 2), big.mark=","), "</span>"
      ))))
      
      add_to_log(input$lbl_disc, "Discounting", 
                 paste0("Undisc=", input$val, ", Rate=", input$disc_r, "%, t=", input$t), 
                 paste0("Discounted=", round(discounted_val,2)), "PV Formula")
    })
  })
}