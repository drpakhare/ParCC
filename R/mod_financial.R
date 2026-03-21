mod_financial_ui <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    tabPanel("Inflation",
             sidebarLayout(
               sidebarPanel(
                 h4("Cost Inflation"),
                 textInput(ns("lbl_inf"), "Parameter Name:", placeholder = "e.g., Drug Acquisition Cost"),
                 hr(),

                 numericInput(ns("cost"), "Original Cost:", value = 1000, min = 0),

                 radioButtons(ns("inf_method"), "Adjustment Method:",
                              choices = c("Using Average % Rate" = "rate",
                                          "Using Price Indices (CPI)" = "cpi")),

                 conditionalPanel(condition = sprintf("input['%s'] == 'rate'", ns("inf_method")),
                                  numericInput(ns("rate"), "Avg Annual Inflation Rate (%):", value = 5, min = 0, step = 0.1),
                                  div(style="display:flex; gap:10px;",
                                      numericInput(ns("y1"), "Base Year:", 2018),
                                      numericInput(ns("y2"), "Target Year:", 2024))
                 ),

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

                 div(class="well", style="margin-top: 20px;",
                     h5(icon("database"), " Official Data Sources"),
                     p("Use these links to find CPI values for various economies:"),
                     tags$ul(style="list-style-type: none; padding-left: 10px;",
                             tags$li(icon("arrow-up-right-from-square"), tags$a(href="https://dbie.rbi.org.in/", target="_blank", " Reserve Bank of India (DBIE)"), " - India"),
                             tags$li(icon("arrow-up-right-from-square"), tags$a(href="https://data.bls.gov/timeseries/CUUR0000SA0", target="_blank", " Bureau of Labor Statistics"), " - USA (CPI-U)"),
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

                 numericInput(ns("val"), "Undiscounted Value (at Time t):", value = 5000),
                 helpText("Enter raw cost or QALYs occurring in the future year."),

                 numericInput(ns("disc_r"), "Discount Rate (%):", value = 3, min = 0, step = 0.1),
                 numericInput(ns("t"), "Time (Years into future):", value = 10, min = 0),
                 actionButton(ns("calc_disc"), "Calculate & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(uiOutput(ns("res_disc")))
             )
    ),
    tabPanel("Annuity / PV Stream",
             sidebarLayout(
               sidebarPanel(
                 h4("Present Value of Cost Stream"),
                 textInput(ns("lbl_ann"), "Parameter Name:", placeholder = "e.g., Annual Drug Cost"),
                 hr(),

                 numericInput(ns("ann_pmt"), "Annual Payment / Cost:", value = 10000, min = 0),
                 numericInput(ns("ann_r"), "Discount Rate (%):", value = 3, min = 0, step = 0.1),
                 numericInput(ns("ann_n"), "Number of Years:", value = 10, min = 1, max = 100),
                 radioButtons(ns("ann_timing"), "Payment Timing:",
                              choices = c("End of year (ordinary annuity)" = "end",
                                          "Beginning of year (annuity due)" = "begin")),
                 actionButton(ns("calc_ann"), "Calculate & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(uiOutput(ns("res_ann")))
             )
    )
  )
}

mod_financial_server <- function(id, logger, currency) {
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

    # Helper: format currency value
    cfmt <- function(x) paste0(currency$symbol, " ", format(round(x, 2), big.mark = ","))

    # ================================================================
    # TAB 1: INFLATION
    # ================================================================
    observeEvent(input$calc_inf, {

      if (input$inf_method == "rate") {
        years <- input$y2 - input$y1
        if(years < 0) {
          output$res_inf <- renderUI(div(class="result-box", style="color:red", "Target year must be >= Base year."))
          return()
        }
        multiplier <- (1 + input$rate/100)^years
        new_cost <- input$cost * multiplier

        output$res_inf <- renderUI(tagList(
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Inflation Adjustment (Rate Method)</span><br>",
            "Original Cost (", input$y1, "): ", cfmt(input$cost), "<br>",
            "Time Span: ", years, " years at ", input$rate, "% p.a.<br>",
            "Multiplier: ", round(multiplier, 4), "<br><br>",
            "<span class='result-value'>Adjusted Cost (", input$y2, ") = ", cfmt(new_cost), "</span>"
          ))),
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
                  strong("Adjusted cost: "), cfmt(input$cost),
                  " \u00d7 ", round(multiplier, 4), " = ",
                  strong(cfmt(new_cost)), "."
                )))
              ),
              p(HTML(paste0(
                icon("exclamation-triangle"), " ",
                strong("Note: "), "The CPI (Index) method is preferred when actual index values are available, ",
                "as it captures year-to-year variation in inflation rather than assuming a constant rate."
              )))
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$Cost_{target} = Cost_{base} \\times (1 + r)^{n}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "Where r is the annual inflation rate and n is the number of years between base and target.")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015. Chapter 7.")),
                tags$li(HTML("Shillcutt SD, et al. Cost effectiveness in low- and middle-income countries. <em>Pharmacoeconomics</em>. 2009;27(11):903-917."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$lbl_inf, "Inflation (Rate)",
                   paste0("Cost=", cfmt(input$cost), ", Rate=", input$rate, "%, Yrs=", years),
                   paste0("Adj Cost=", cfmt(new_cost)), "Compound Interest")

      } else {
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
          div(class="result-box", HTML(paste0(
            "<span class='result-label'>Inflation Adjustment (CPI Method)</span><br>",
            "Original Cost: ", cfmt(input$cost), "<br>",
            "Index Ratio: ", idx_new, " / ", idx_old, " = ", round(ratio, 4), "<br><br>",
            "<span class='result-value'>Adjusted Cost = ", cfmt(new_cost), "</span>"
          ))),
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
                  strong("Adjusted cost: "), cfmt(input$cost),
                  " \u00d7 ", round(ratio, 4), " = ",
                  strong(cfmt(new_cost)), "."
                )))
              )
          ),
          div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
              h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
              p("$$Cost_{target} = Cost_{base} \\times \\frac{CPI_{target}}{CPI_{base}}$$"),
              p(style = "font-size:0.85em; color:#666;",
                "The CPI ratio captures the cumulative inflation between the two time points.")
          ),
          div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
              h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
              tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015. Chapter 7.")),
                tags$li(HTML("Turner HC, et al. Adjusting for inflation and currency changes within health economic studies. <em>Value in Health</em>. 2019;22(9):1026-1032."))
              )
          ),
          mathjax_trigger
        ))

        add_to_log(input$lbl_inf, "Inflation (CPI)",
                   paste0("Cost=", cfmt(input$cost), ", Index ", idx_old, "->", idx_new),
                   paste0("Adj Cost=", cfmt(new_cost)), "Index Ratio")
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
        div(class="result-box", HTML(paste0(
          "<span class='result-label'>Discounting Result</span><br>",
          "Undiscounted Value: ", format(input$val, big.mark=","), "<br>",
          "Discount Rate: ", input$disc_r, "% | Time: ", input$t, " years<br>",
          "Discount Factor: ", round(disc_factor, 4), "<br><br>",
          "<span class='result-value'>Present Value = ", format(round(discounted_val, 2), big.mark=","), "</span>"
        ))),
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "Discounting reflects society's ", strong("time preference"), " \u2014 the idea that benefits ",
              "received today are valued more than the same benefits received in the future."
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
              "Common discount rates: India (HTAIn) 3%, UK (NICE) 3.5%, WHO-CHOICE 3%. ",
              "Sensitivity analysis at 0% and 5% is generally recommended."
            )))
        ),
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
            p("$$PV = \\frac{FV}{(1 + r)^t}$$"),
            p(style = "font-size:0.85em; color:#666;",
              "PV = Present Value, FV = Future Value, r = annual discount rate, t = years into the future.")
        ),
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015. Chapter 4.")),
              tags$li(HTML("NICE. Guide to the Methods of Technology Appraisal. 2013. Section 5.6 (Discounting)."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$lbl_disc, "Discounting",
                 paste0("Undisc=", input$val, ", Rate=", input$disc_r, "%, t=", input$t),
                 paste0("Discounted=", round(discounted_val,2)), "PV Formula")
    })

    # ================================================================
    # TAB 3: ANNUITY / PV STREAM
    # ================================================================
    observeEvent(input$calc_ann, {
      C <- input$ann_pmt
      r <- input$ann_r / 100
      n <- input$ann_n

      if (r == 0) {
        pv <- C * n
      } else {
        pv <- C * (1 - (1 + r)^(-n)) / r
      }

      # Annuity due adjustment
      if (input$ann_timing == "begin") {
        pv <- pv * (1 + r)
      }

      total_nominal <- C * n
      discount_savings <- total_nominal - pv

      # Year-by-year table
      yr_data <- data.frame(
        Year = 1:n,
        Nominal = rep(C, n),
        Discount_Factor = 1 / (1 + r)^(if (input$ann_timing == "begin") (0:(n-1)) else (1:n)),
        stringsAsFactors = FALSE
      )
      yr_data$PV <- yr_data$Nominal * yr_data$Discount_Factor

      output$res_ann <- renderUI(tagList(
        div(class="result-box", HTML(paste0(
          "<span class='result-label'>Present Value of Cost Stream</span><br>",
          "Annual Payment: ", cfmt(C), " for ", n, " years at ", input$ann_r, "%<br>",
          "Timing: ", if(input$ann_timing == "begin") "Beginning of year (annuity due)" else "End of year (ordinary)", "<br>",
          "Total Nominal: ", cfmt(total_nominal), "<br><br>",
          "<span class='result-value'>Present Value = ", cfmt(pv), "</span>",
          "<br><small>Discounting saves ", cfmt(discount_savings), " (", round(discount_savings/total_nominal*100, 1), "% reduction)</small>"
        ))),
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "When a cost recurs annually (e.g., drug maintenance, monitoring), the total discounted cost ",
              "over the time horizon is the ", strong("present value of an annuity"), ". ",
              "Each year's payment is discounted to today's value and summed."
            ))),
            p(HTML(paste0(
              "At ", input$ann_r, "% discount rate over ", n, " years, the annuity factor is ",
              strong(round(pv / C, 4)), ". ",
              "This means ", cfmt(C), " per year is equivalent to a lump sum of ", strong(cfmt(pv)), " today."
            )))
        ),
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
            p("$$PV_{ordinary} = C \\times \\frac{1 - (1+r)^{-n}}{r}$$"),
            p("$$PV_{due} = PV_{ordinary} \\times (1 + r)$$"),
            p(style = "font-size:0.85em; color:#666;",
              "C = annual payment, r = discount rate, n = number of years.")
        ),
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015.")),
              tags$li(HTML("Gray AM, et al. <em>Applied Methods of Cost-effectiveness Analysis in Healthcare</em>. OUP; 2011."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$lbl_ann, "Annuity/PV Stream",
                 paste0("C=", cfmt(C), ", r=", input$ann_r, "%, n=", n),
                 paste0("PV=", cfmt(pv)), if(input$ann_timing == "begin") "Annuity Due" else "Ordinary Annuity")
    })
  })
}
