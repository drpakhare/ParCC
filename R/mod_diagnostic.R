mod_diagnostic_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Bayes' Theorem"),
      # NEW: Label
      textInput(ns("label"), "Test Name:", placeholder = "e.g., Rapid Antigen Test"),
      hr(),
      
      numericInput(ns("sens"), "Sensitivity (%):", 90, 0, 100),
      numericInput(ns("spec"), "Specificity (%):", 95, 0, 100),
      numericInput(ns("prev"), "Prevalence (%):", 10, 0, 100),
      actionButton(ns("calc"), "Calculate & Log", class="btn-primary", width="100%")
    ),
    mainPanel(
      uiOutput(ns("res")),
      div(class="plot-container", plotOutput(ns("plot")))
    )
  )
}

mod_diagnostic_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {
    diag_data <- reactiveVal(NULL)
    
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
    
    observeEvent(input$calc, {
      se <- input$sens/100; sp <- input$spec/100; p <- input$prev/100
      
      ppv <- (se * p) / (se * p + (1 - sp) * (1 - p))
      npv <- (sp * (1 - p)) / (sp * (1 - p) + (1 - se) * p)
      
      output$res <- renderUI(div(class = "result-box", HTML(paste0(
        "<span class='result-value'>PPV = ", round(ppv * 100, 1), "%</span>",
        "<span class='result-value'>NPV = ", round(npv * 100, 1), "%</span>"
      ))))
      
      # LOGGING
      add_to_log(input$label, "Diagnostics", 
                 paste0("Sens=", input$sens, "%, Spec=", input$spec, "%, Prev=", input$prev, "%"), 
                 paste0("PPV=", round(ppv*100,1), "%, NPV=", round(npv*100,1), "%"), 
                 "Bayes Theorem")
      
      # Plot Data
      x_prev <- seq(0.01, 0.99, length.out = 100)
      y_ppv <- (se * x_prev) / (se * x_prev + (1 - sp) * (1 - x_prev))
      diag_data(data.frame(Prev = x_prev, PPV = y_ppv))
    })
    
    output$plot <- renderPlot({
      req(diag_data())
      ggplot(diag_data(), aes(Prev, PPV)) +
        geom_line(color = "#27ae60", size = 1.5) +
        geom_vline(xintercept = input$prev/100, linetype="dashed") +
        theme_minimal() + labs(title="PPV vs Prevalence", y="PPV", x="Prevalence") + ylim(0,1)
    })
  })
}