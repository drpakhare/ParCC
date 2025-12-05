mod_batch_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Bulk Conversion"),
      p("Convert multiple parameters at once by uploading a CSV."),
      
      # 1. Input Options
      h5("1. Data Source"),
      fileInput(ns("file1"), "Upload CSV File",
                accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv")),
      actionButton(ns("load_sample"), "Load Sample Dataset", icon = icon("table"), 
                   style = "background-color: #f8f9fa; color: #444; border-color: #ddd; width: 100%; margin-bottom: 15px;"),
      
      # 2. Configuration (Conditional on data presence)
      uiOutput(ns("col_selectors")),
      
      hr(),
      # 3. Action
      actionButton(ns("process"), "Run Bulk Conversion", class = "btn-primary", width = "100%"),
      br(), br(),
      # 4. Download
      downloadButton(ns("downloadData"), "Download Results", class = "btn-success", style = "width:100%;")
    ),
    mainPanel(
      h4("Data Preview"),
      p(class="text-info", "Upload a file or load the sample dataset to view data here."),
      DT::dataTableOutput(ns("preview_table"))
    )
  )
}

mod_batch_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Store data in reactive values to allow multiple sources (Upload vs Sample)
    vals <- reactiveValues(raw = NULL)
    
    # Observer for File Upload
    observeEvent(input$file1, {
      req(input$file1)
      vals$raw <- read.csv(input$file1$datapath, stringsAsFactors = FALSE)
    })
    
    # Observer for Sample Data
    observeEvent(input$load_sample, {
      vals$raw <- data.frame(
        ID = 1:5,
        Description = c("Trial Arm A", "Trial Arm B", "Observational Cohort", "Literature Source 1", "Literature Source 2"),
        Reported_Rate = c(0.015, 0.025, 0.10, 0.005, 0.05),
        Time_Horizon = c(1, 1, 5, 1, 10),
        Odds_Ratio = c(1.2, 0.8, 1.5, 2.0, 0.5)
      )
    })
    
    # Dynamic UI: Select Columns based on loaded data
    output$col_selectors <- renderUI({
      req(vals$raw)
      cols <- names(vals$raw)
      ns <- session$ns
      
      tagList(
        h5("2. Configuration"),
        selectInput(ns("conv_type"), "Conversion Type:", 
                    choices = c("Rate -> Probability" = "r2p", 
                                "Odds -> Probability" = "o2p")),
        
        selectInput(ns("val_col"), "Select Value Column:", choices = cols, selected = cols[grep("Rate|Odds|Val", cols)[1]]),
        
        # Conditionals for Time inputs in Batch
        conditionalPanel(condition = sprintf("input['%s'] == 'r2p'", ns("conv_type")),
                         radioButtons(ns("time_source"), "Time Horizon Source:",
                                      choices = c("Constant (e.g., all 1 year)" = "const", 
                                                  "From Column" = "col")),
                         conditionalPanel(condition = sprintf("input['%s'] == 'const'", ns("time_source")),
                                          numericInput(ns("const_time"), "Time (t):", value = 1)
                         ),
                         conditionalPanel(condition = sprintf("input['%s'] == 'col'", ns("time_source")),
                                          selectInput(ns("time_col"), "Select Time Column:", choices = cols, selected = cols[grep("Time|Year", cols)[1]])
                         )
        )
      )
    })
    
    # Processed Data Reactive
    processed_data <- reactiveVal(NULL)
    
    observeEvent(input$process, {
      req(vals$raw, input$val_col)
      df <- vals$raw
      val <- as.numeric(df[[input$val_col]])
      
      if(input$conv_type == "r2p") {
        # Determine Time
        if(input$time_source == "const") {
          t <- input$const_time
        } else {
          t <- as.numeric(df[[input$time_col]])
        }
        
        # Calculation: p = 1 - exp(-r*t)
        df$Converted_Prob <- 1 - exp(-val * t)
        df$Conversion_Note <- paste0("Rate(", input$val_col, ") to Prob")
        
      } else {
        # Odds to Prob
        df$Converted_Prob <- val / (1 + val)
        df$Conversion_Note <- paste0("Odds(", input$val_col, ") to Prob")
      }
      
      processed_data(df)
    })
    
    # Render Table
    output$preview_table <- DT::renderDataTable({
      req(processed_data())
      DT::datatable(processed_data(), options = list(scrollX = TRUE, pageLength = 5)) %>%
        DT::formatRound(columns = "Converted_Prob", digits = 5)
    })
    
    # Download Handler
    output$downloadData <- downloadHandler(
      filename = function() {
        paste("ParCC_Bulk_Output_", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        write.csv(processed_data(), file, row.names = FALSE)
      }
    )
  })
}