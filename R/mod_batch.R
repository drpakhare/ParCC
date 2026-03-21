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
      DT::dataTableOutput(ns("preview_table")),

      # Explanation panel for HR conversion
      uiOutput(ns("hr_explanation"))
    )
  )
}

mod_batch_server <- function(id, logger = NULL) {
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
        ID = 1:6,
        Description = c("CV Death (PLATO)", "MI (PLATO)", "Stroke (PLATO)",
                         "Major Bleeding (PLATO)", "Dyspnea AE", "All-cause Mortality"),
        Control_Prob = c(0.0525, 0.0643, 0.0138, 0.1143, 0.0789, 0.0595),
        Time_Horizon = c(1, 1, 1, 1, 1, 1),
        Hazard_Ratio = c(0.79, 0.84, 1.01, 1.04, 1.37, 0.78),
        stringsAsFactors = FALSE
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
                                "Odds -> Probability" = "o2p",
                                "HR -> Intervention Probability" = "hr2p")),

        selectInput(ns("val_col"), "Select Value Column:", choices = cols,
                    selected = cols[grep("Rate|Odds|Prob|Val", cols, ignore.case = TRUE)[1]]),

        # Time inputs (for Rate and HR conversions)
        conditionalPanel(
          condition = sprintf("input['%s'] == 'r2p' || input['%s'] == 'hr2p'", ns("conv_type"), ns("conv_type")),
          radioButtons(ns("time_source"), "Time Horizon Source:",
                       choices = c("Constant (e.g., all 1 year)" = "const",
                                   "From Column" = "col")),
          conditionalPanel(condition = sprintf("input['%s'] == 'const'", ns("time_source")),
                           numericInput(ns("const_time"), "Time (t):", value = 1)
          ),
          conditionalPanel(condition = sprintf("input['%s'] == 'col'", ns("time_source")),
                           selectInput(ns("time_col"), "Select Time Column:", choices = cols,
                                       selected = cols[grep("Time|Year", cols, ignore.case = TRUE)[1]])
          )
        ),

        # HR column (for HR conversion)
        conditionalPanel(
          condition = sprintf("input['%s'] == 'hr2p'", ns("conv_type")),
          selectInput(ns("hr_col"), "Select HR Column:", choices = cols,
                      selected = cols[grep("HR|Hazard|hr", cols, ignore.case = TRUE)[1]])
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

      } else if(input$conv_type == "o2p") {
        # Odds to Prob
        df$Converted_Prob <- val / (1 + val)
        df$Conversion_Note <- paste0("Odds(", input$val_col, ") to Prob")

      } else if(input$conv_type == "hr2p") {
        # HR-based conversion: Control Prob -> Intervention Prob
        req(input$hr_col)

        if(input$time_source == "const") {
          t <- input$const_time
        } else {
          t <- as.numeric(df[[input$time_col]])
        }

        hr_vals <- as.numeric(df[[input$hr_col]])
        p_control <- val

        # Step 1: p -> rate
        r_control <- -log(1 - p_control) / t
        # Step 2: apply HR
        r_intervention <- r_control * hr_vals
        # Step 3: rate -> p
        df$Rate_Control <- round(r_control, 6)
        df$Rate_Intervention <- round(r_intervention, 6)
        df$Intervention_Prob <- 1 - exp(-r_intervention * t)
        df$ARR <- p_control - df$Intervention_Prob
        df$NNT <- ifelse(df$ARR > 0, ceiling(1 / df$ARR), NA)
        df$Conversion_Note <- paste0("HR(", input$hr_col, ") applied to ", input$val_col)
      }

      processed_data(df)
    })

    # Render Table
    output$preview_table <- DT::renderDataTable({
      req(processed_data())

      round_cols <- intersect(names(processed_data()),
                              c("Converted_Prob", "Intervention_Prob", "Rate_Control",
                                "Rate_Intervention", "ARR"))

      dt <- DT::datatable(processed_data(),
                          extensions = 'Buttons',
                          options = list(scrollX = TRUE, pageLength = 10,
                                         dom = 'Blfrtip',
                                         buttons = list('copy', 'csv', 'excel')))
      for (col in round_cols) {
        if (col %in% names(processed_data())) {
          dt <- dt %>% DT::formatRound(columns = col, digits = 5)
        }
      }
      dt
    })

    # HR Explanation panel
    output$hr_explanation <- renderUI({
      req(input$conv_type == "hr2p", processed_data())

      tagList(
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " Batch HR Conversion Method", style = "color:#155724; margin-top:0;"),
            p("For each row, the conversion follows three steps:"),
            tags$ol(
              tags$li(HTML(paste0(strong("Control Prob \u2192 Rate:"),
                                  " r = -ln(1 - p_control) / t"))),
              tags$li(HTML(paste0(strong("Apply HR:"),
                                  " r_intervention = r_control \u00d7 HR"))),
              tags$li(HTML(paste0(strong("Rate \u2192 Intervention Prob:"),
                                  " p_intervention = 1 - e^(-r_intervention \u00d7 t)")))
            ),
            p(style = "font-size:0.85em; color:#666;",
              "Assumes proportional hazards (constant HR). ",
              "Ref: Briggs A, et al. Decision Modelling for Health Economic Evaluation. OUP; 2006.")
        )
      )
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
