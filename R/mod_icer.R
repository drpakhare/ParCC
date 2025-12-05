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
      # NEW: Plotly Output for interactivity
      div(class="plot-container", plotlyOutput(ns("plot"), height = "500px")),
      br(),
      # NEW: Threshold Analysis Output
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
      
      if (d_cost < 0 && d_eff > 0) {
        quadrant <- "SE: Dominant"
        status <- "Cost-Effective (Better & Cheaper)"
        col <- "#27ae60" # Green
      } else if (d_cost > 0 && d_eff < 0) {
        quadrant <- "NW: Dominated"
        status <- "Not Cost-Effective (Worse & Costlier)"
        col <- "#c0392b" # Red
      } else if (d_cost > 0 && d_eff > 0) {
        quadrant <- "NE: Trade-off"
        if(inmb > 0) {
          status <- "Cost-Effective (Worth the cost)"
          col <- "#27ae60"
        } else {
          status <- "Not Cost-Effective (Too expensive)"
          col <- "#e67e22"
        }
      } else {
        quadrant <- "SW: Trade-off"
        if(inmb > 0) {
          status <- "Cost-Effective (Savings justify health loss)"
          col <- "#27ae60"
        } else {
          status <- "Not Cost-Effective (Savings do NOT justify health loss)"
          col <- "#e67e22"
        }
      }
      
      output$res <- renderUI(div(class="result-box", HTML(paste0(
        "<span class='result-label'>Incremental Results</span><br>",
        "&Delta; Cost: ", format(d_cost, big.mark=","), "<br>",
        "&Delta; Effect: ", round(d_eff, 4), "<br><br>",
        "<span class='result-label'>Outcomes</span><br>",
        "<span class='result-value'>ICER = ", icer_str, "</span>",
        "<span class='result-value'>iNMB = ", format(round(inmb, 2), big.mark=","), "</span>",
        "<br>Quadrant: ", quadrant, "<br>",
        "<strong style='color:", col, "'>Conclusion: ", status, "</strong>"
      ))))
      
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
      
      # Axis Limits
      limit_e <- max(abs(d$dE)) * 1.5; if(limit_e==0) limit_e <- 1
      limit_c <- max(abs(d$dC), abs(d$dE * d$WTP)) * 1.2; if(limit_c==0) limit_c <- 1000
      
      # WTP Line Coordinates (for Plotly line)
      # y = slope * x
      x_line <- c(-limit_e, limit_e)
      y_line <- x_line * d$WTP
      
      plot_ly() %>%
        # Layout
        layout(
          title = "Cost-Effectiveness Plane",
          xaxis = list(title = "Incremental Effect (QALYs)", range = c(-limit_e, limit_e), zeroline = TRUE, zerolinewidth = 2, zerolinecolor = '#000'),
          yaxis = list(title = "Incremental Cost", range = c(-limit_c, limit_c), zeroline = TRUE, zerolinewidth = 2, zerolinecolor = '#000'),
          showlegend = FALSE,
          # Annotations for Quadrants
          annotations = list(
            list(x = limit_e*0.8, y = limit_c*0.8, text = "NE: Trade-off", showarrow = F, font=list(color="grey", size=10)),
            list(x = -limit_e*0.8, y = limit_c*0.8, text = "NW: Dominated", showarrow = F, font=list(color="#c0392b", size=10)),
            list(x = limit_e*0.8, y = -limit_c*0.8, text = "SE: Dominant", showarrow = F, font=list(color="#27ae60", size=10)),
            list(x = -limit_e*0.8, y = -limit_c*0.8, text = "SW: Trade-off", showarrow = F, font=list(color="grey", size=10))
          )
        ) %>%
        # WTP Threshold Line
        add_lines(x = x_line, y = y_line, 
                  line = list(dash = "dash", color = "#7f8c8d"), 
                  name = "WTP Threshold",
                  hoverinfo = "text", text = paste("WTP =", format(d$WTP, big.mark=","))) %>%
        # Result Point
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