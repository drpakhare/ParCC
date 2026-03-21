mod_icer_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("ICER & NMB Calculator"),
      textInput(ns("label"), "Analysis Label:", placeholder = "e.g., Base Case Analysis"),
      hr(),

      h5("Intervention (New Strategy)"),
      div(style="display:flex; gap:5px;",
          numericInput(ns("cost_i"), "Total Cost:", value = 50000),
          numericInput(ns("eff_i"), "Total QALYs:", value = 1.5, step = 0.01)
      ),

      h5("Comparator (Standard of Care)"),
      div(style="display:flex; gap:5px;",
          numericInput(ns("cost_c"), "Total Cost:", value = 10000),
          numericInput(ns("eff_c"), "Total QALYs:", value = 1.0, step = 0.01)
      ),

      hr(),
      numericInput(ns("wtp"), "WTP Threshold:", value = 20000, step = 1000),
      helpText("Willingness-to-Pay per QALY."),

      actionButton(ns("calc"), "Calculate & Log", class = "btn-primary", width = "100%")
    ),
    mainPanel(
      uiOutput(ns("res")),
      br(),
      div(class="plot-container", plotlyOutput(ns("plot"), height = "500px")),
      br(),
      uiOutput(ns("res_threshold"))
    )
  )
}

mod_icer_server <- function(id, logger) {
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

    res_data <- reactiveVal(NULL)

    observeEvent(input$calc, {
      d_cost <- input$cost_i - input$cost_c
      d_eff  <- input$eff_i - input$eff_c
      wtp    <- input$wtp

      # 1. Calculate ICER
      if (d_eff == 0) {
        icer <- NA
        icer_str <- "Undefined (Delta Effect = 0)"
      } else {
        icer <- d_cost / d_eff
        icer_str <- format(round(icer, 2), big.mark=",")
      }

      # 2. Calculate iNMB
      inmb <- (d_eff * wtp) - d_cost

      # 3. Status Logic
      quadrant <- ""
      status <- ""
      col <- ""
      quadrant_explain <- ""

      if (d_cost < 0 && d_eff > 0) {
        quadrant <- "SE: Dominant"
        status <- "Cost-Effective (Better & Cheaper)"
        col <- "#27ae60"
        quadrant_explain <- "The intervention is both more effective and less costly than the comparator. This is the strongest possible result - no WTP threshold is needed to justify adoption."
      } else if (d_cost > 0 && d_eff < 0) {
        quadrant <- "NW: Dominated"
        status <- "Not Cost-Effective (Worse & Costlier)"
        col <- "#c0392b"
        quadrant_explain <- "The intervention is both less effective and more costly. It is dominated and should not be adopted under any WTP threshold."
      } else if (d_cost > 0 && d_eff > 0) {
        quadrant <- "NE: Trade-off"
        if(inmb > 0) {
          status <- "Cost-Effective (Worth the cost)"
          col <- "#27ae60"
        } else {
          status <- "Not Cost-Effective (Too expensive)"
          col <- "#e67e22"
        }
        quadrant_explain <- paste0("The intervention is more effective but also more costly. The ICER of ", icer_str, " is compared to the WTP threshold of ", format(wtp, big.mark = ","), " to determine cost-effectiveness.")
      } else {
        quadrant <- "SW: Trade-off"
        if(inmb > 0) {
          status <- "Cost-Effective (Savings justify health loss)"
          col <- "#27ae60"
        } else {
          status <- "Not Cost-Effective (Savings do NOT justify health loss)"
          col <- "#e67e22"
        }
        quadrant_explain <- "The intervention is less effective but also cheaper. The question is whether the savings justify the health loss."
      }

      output$res <- renderUI(tagList(
        # Result
        div(class="result-box", style=paste0("border-left-color:", col), HTML(paste0(
          "<span class='result-label'>Incremental Results</span><br>",
          "&Delta; Cost: ", format(d_cost, big.mark=","), "<br>",
          "&Delta; Effect: ", round(d_eff, 4), "<br><br>",
          "<span class='result-label'>Outcomes</span><br>",
          "<span class='result-value'>ICER = ", icer_str, "</span>",
          "<span class='result-value'>iNMB = ", format(round(inmb, 2), big.mark=","), "</span>",
          "<br>Quadrant: ", quadrant, "<br>",
          "<strong style='color:", col, "'>Conclusion: ", status, "</strong>"
        ))),
        # Explanation
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            tags$ul(
              tags$li(HTML(paste0(
                strong("ICER: "), "The Incremental Cost-Effectiveness Ratio = ",
                format(d_cost, big.mark = ","), " / ", round(d_eff, 4), " = ",
                strong(icer_str), " per QALY gained. ",
                "This represents the additional cost of producing one extra QALY with the intervention."
              ))),
              tags$li(HTML(paste0(
                strong("iNMB: "), "The incremental Net Monetary Benefit = (",
                round(d_eff, 4), " \u00d7 ", format(wtp, big.mark = ","), ") - ",
                format(d_cost, big.mark = ","), " = ", strong(format(round(inmb, 2), big.mark = ",")), ". ",
                if (inmb > 0) "A positive iNMB indicates cost-effectiveness at this WTP." else "A negative iNMB indicates the intervention is not cost-effective at this WTP."
              )))
            ),
            p(HTML(paste0(icon("info-circle"), " ", quadrant_explain)))
        ),
        # Formula
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
            p("$$ICER = \\frac{\\Delta Cost}{\\Delta Effect} = \\frac{C_{int} - C_{comp}}{E_{int} - E_{comp}}$$"),
            p("$$iNMB = (\\Delta Effect \\times WTP) - \\Delta Cost$$"),
            p(style = "font-size:0.85em; color:#666;",
              "Cost-effective if ICER < WTP, or equivalently if iNMB > 0.")
        ),
        # Citation
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015.")),
              tags$li(HTML("Stinnett AA, Mullahy J. Net health benefits: a new framework for the analysis of uncertainty in cost-effectiveness analysis. <em>Med Decis Making</em>. 1998;18(2):S68-S80.")),
              tags$li(HTML("Fenwick E, et al. Representing uncertainty: the role of cost-effectiveness acceptability curves. <em>Health Econ</em>. 2001;10(8):779-787."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$label, "ICER / NMB",
                 paste0("dC=", d_cost, ", dE=", d_eff, ", WTP=", wtp),
                 paste0("ICER=", icer_str, ", iNMB=", round(inmb, 2)),
                 status)

      res_data(data.frame(dE = d_eff, dC = d_cost, WTP = wtp, Label = input$label))
    })

    # INTERACTIVE PLOTLY
    output$plot <- renderPlotly({
      req(res_data())
      d <- res_data()

      limit_e <- max(abs(d$dE)) * 1.5; if(limit_e==0) limit_e <- 1
      limit_c <- max(abs(d$dC), abs(d$dE * d$WTP)) * 1.2; if(limit_c==0) limit_c <- 1000

      x_line <- c(-limit_e, limit_e)
      y_line <- x_line * d$WTP

      plot_ly() %>%
        layout(
          title = "Cost-Effectiveness Plane",
          xaxis = list(title = "Incremental Effect (QALYs)", range = c(-limit_e, limit_e), zeroline = TRUE, zerolinewidth = 2, zerolinecolor = '#000'),
          yaxis = list(title = "Incremental Cost", range = c(-limit_c, limit_c), zeroline = TRUE, zerolinewidth = 2, zerolinecolor = '#000'),
          showlegend = FALSE,
          annotations = list(
            list(x = limit_e*0.8, y = limit_c*0.8, text = "NE: Trade-off", showarrow = FALSE, font=list(color="grey", size=10)),
            list(x = -limit_e*0.8, y = limit_c*0.8, text = "NW: Dominated", showarrow = FALSE, font=list(color="#c0392b", size=10)),
            list(x = limit_e*0.8, y = -limit_c*0.8, text = "SE: Dominant", showarrow = FALSE, font=list(color="#27ae60", size=10)),
            list(x = -limit_e*0.8, y = -limit_c*0.8, text = "SW: Trade-off", showarrow = FALSE, font=list(color="grey", size=10))
          )
        ) %>%
        add_lines(x = x_line, y = y_line,
                  line = list(dash = "dash", color = "#7f8c8d"),
                  name = "WTP Threshold",
                  hoverinfo = "text", text = paste("WTP =", format(d$WTP, big.mark=","))) %>%
        add_markers(x = d$dE, y = d$dC,
                    marker = list(size = 15, color = "#003366"),
                    name = "Result",
                    hoverinfo = "text",
                    text = paste0("<b>", d$Label, "</b><br>",
                                  "Delta Cost: ", format(d$dC, big.mark=","), "<br>",
                                  "Delta Effect: ", round(d$dE, 4)))
    })
  })
}
