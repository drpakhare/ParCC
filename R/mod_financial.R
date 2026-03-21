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

                 # --- Data Sources Section ---
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

    mathjax_trigger <- tags$script("if(window.MathJax){MathJax.Hub.Queue(['Typeset', MathJax.Hub]);}")

    # ================================================================
    # TAB 1: INFLATION
    # ================================================================
    observeEvent(input$calc_inf, {

      if (input$inf_method == "rate") {
        # Method A: Compound Rate
        years <- input$y2 - input$y1
        if(years < 0) {
          output$res_inf <- renderUI(div(class="result-box", style="color:red", "Target year must be >= Base year."))
          return()
        }
        multiplier <- (1 + input$rate/100)^years
        new_cost <- input$cost * multiplier

        output$res_inf <- renderUI(tagList(
          # Result
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Inflation Adjustment (Rate Method)</span><br>",
            "Original Cost (", input$y1, "): INR ", format(input$cost, big.mark=","), "<br>",
            "Time Span: ", years, " years at ", input$rate, "% p.a.<br>",
            "Multiplier: ", round(multiplier, 4), "<br><br>",
            "<span class='result-value'>Adjusted Cost (", input$y2, ") = INR ", format(round(new_cost, 2), big.mark=","), "</span>"
          ))),
          # Explanation
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "When cost data from published studies is in a different price year than your analysis, ",
                "it must be ", strong("inflated"), " to a common year for valid comparison. ",
                "This method uses compound growth at a fixed average rate."
              ))),
              tags$ol(
                tags$li(HTML(paste0(
                  strong("Multiplier: "), "(1 + ", input$rate/100, ")<sup>", years, "</sup> = ",
                  strong(round(multiplier, 4)), "."
                ))),
                tags$li(HTML(paste0(
                  strong("Adjusted cost: "), "INR ", format(input$cost, big.mark=","),
                  " \u00d7 ", round(multiplier, 4), " = ",
                  strong(paste0("INR ", format(round(new_cost, 2), big.mark=","))), "."
                )))
              ),
              p(HTML(paste0(
                icon("exclamation-triangle"), " ",
                strong("Note: "), "The CPI (Index) method is preferred when actual index values are available, ",
                "as it captures year-to-year variation in inflation rather than assuming a constant rate. ",
                "The HTAIn Reference Case recommends using the GDP deflator or CPI (Health) where possible."
              )))
          ),
          # Formula
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$Cost_{target} = Cost_{base} \\times (1 + r)^{n}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "Where r is the annual inflation rate and n is the number of years between base and target.")
          ),
          # Citation
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015. Chapter 7.")),
                tags$li(HTML("HTAIn. Indian Reference Case for Economic Evaluation. Department of Health Research, Govt of India; 2023.")),
                tags$li(HTML("Shillcutt SD, et al. Cost effectiveness in low- and middle-income countries. <em>Pharmacoeconomics</em>. 2009;27(11):903-917."))
              )
          ),
          mathjax_trigger
        ))

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
        implied_rate <- if(ratio > 0) (ratio - 1) * 100 else NA

        output$res_inf <- renderUI(tagList(
          # Result
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Inflation Adjustment (CPI Method)</span><br>",
            "Original Cost: INR ", format(input$cost, big.mark=","), "<br>",
            "Index Ratio: ", idx_new, " / ", idx_old, " = ", round(ratio, 4), "<br><br>",
            "<span class='result-value'>Adjusted Cost = INR ", format(round(new_cost, 2), big.mark=","), "</span>"
          ))),
          # Explanation
          div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
              p(HTML(paste0(
                "The CPI (Consumer Price Index) method is the ", strong("gold standard"), " for cost inflation ",
                "in HTA because it uses actual observed price changes rather than assumed rates."
              ))),
              tags$ol(
                tags$li(HTML(paste0(
                  strong("Ratio: "), "CPI_target / CPI_base = ", idx_new, " / ", idx_old,
                  " = ", strong(round(ratio, 4)),
                  ". This means prices increased by ", round(implied_rate, 1), "% over the period."
                ))),
                tags$li(HTML(paste0(
                  strong("Adjusted cost: "), "INR ", format(input$cost, big.mark=","),
                  " \u00d7 ", round(ratio, 4), " = ",
                  strong(paste0("INR ", format(round(new_cost, 2), big.mark=","))), "."
                )))
              ),
              p(HTML(paste0(
                icon("info-circle"), " ",
                "In India, the CPI (Combined, Base 2012=100) is published monthly by MOSPI. ",
                "For healthcare-specific inflation, look for the 'Health' sub-group index. ",
                "Healthcare inflation in India typically exceeds general CPI inflation."
              )))
          ),
          # Formula
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$Cost_{target} = Cost_{base} \\times \\frac{CPI_{target}}{CPI_{base}}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "The CPI ratio captures the cumulative inflation between the two time points, regardless of year-to-year variation.")
          ),
          # Citation
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015. Chapter 7.")),
                tags$li(HTML("HTAIn. Indian Reference Case for Economic Evaluation. Department of Health Research, Govt of India; 2023.")),
                tags$li(HTML("Ministry of Statistics and Programme Implementation (MOSPI). Consumer Price Index Numbers. Government of India."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$lbl_inf, "Inflation (CPI)",
                   paste0("Cost=INR ", input$cost, ", Index ", idx_old, "->", idx_new),
                   paste0("Adj Cost=INR ", round(new_cost,2)), "Index Ratio")
      }
    })

    # ================================================================
    # TAB 2: DISCOUNTING
    # ================================================================
    observeEvent(input$calc_disc, {
      disc_factor <- 1 / ((1 + input$disc_r/100)^input$t)
      discounted_val <- input$val * disc_factor
      value_lost <- input$val - discounted_val

      output$res_disc <- renderUI(tagList(
        # Result
        div(class="result-box", HTML(paste0(
          "<span class='result-label'>Discounting Result</span><br>",
          "Undiscounted Value: ", format(input$val, big.mark=","), "<br>",
          "Discount Rate: ", input$disc_r, "% | Time: ", input$t, " years<br>",
          "Discount Factor: ", round(disc_factor, 4), "<br><br>",
          "<span class='result-value'>Present Value = ", format(round(discounted_val, 2), big.mark=","), "</span>"
        ))),
        # Explanation
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "Discounting reflects society's ", strong("time preference"), " \u2014 the idea that benefits ",
              "received today are valued more than the same benefits received in the future. ",
              "In HTA, both costs and health outcomes (QALYs) occurring in future years are discounted ",
              "to their present value."
            ))),
            tags$ol(
              tags$li(HTML(paste0(
                strong("Discount factor: "), "1 / (1 + ", input$disc_r/100, ")<sup>", input$t,
                "</sup> = ", strong(round(disc_factor, 4)), "."
              ))),
              tags$li(HTML(paste0(
                strong("Present value: "), format(input$val, big.mark=","),
                " \u00d7 ", round(disc_factor, 4), " = ",
                strong(format(round(discounted_val, 2), big.mark=",")), "."
              ))),
              tags$li(HTML(paste0(
                strong("Value adjustment: "), "The future value is reduced by ",
                format(round(value_lost, 2), big.mark=","),
                " (", round((1 - disc_factor) * 100, 1), "%) due to discounting."
              )))
            ),
            p(HTML(paste0(
              icon("info-circle"), " ",
              "In India, the HTAIn Reference Case recommends a discount rate of ",
              strong("3%"), " for both costs and health outcomes, with sensitivity analysis at 0% and 5%. ",
              "NICE (UK) uses 3.5%, while WHO-CHOICE uses 3%."
            )))
        ),
        # Formula
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
            p("$$PV = \\frac{FV}{(1 + r)^t}$$"),
            p("$$\\text{Total Discounted} = \\sum_{t=0}^{T} \\frac{Value_t}{(1 + r)^t}$$"),
            p(style = "font-size:0.85em; color:#666;",
              "PV = Present Value, FV = Future Value, r = annual discount rate, t = years into the future.")
        ),
        # Citation
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015. Chapter 4.")),
              tags$li(HTML("HTAIn. Indian Reference Case for Economic Evaluation. Department of Health Research, Govt of India; 2023.")),
              tags$li(HTML("NICE. Guide to the Methods of Technology Appraisal. 2013. Section 5.6 (Discounting)."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$lbl_disc, "Discounting",
                 paste0("Undisc=", input$val, ", Rate=", input$disc_r, "%, t=", input$t),
                 paste0("Discounted=", round(discounted_val,2)), "PV Formula")
    })
  })
}
