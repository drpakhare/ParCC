mod_lifetable_ui <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    # --- Tab 1: SMR Adjustment ---
    tabPanel("SMR Adjustment",
             sidebarLayout(
               sidebarPanel(
                 h4("Disease-Specific Mortality"),
                 textInput(ns("lbl_smr"), "Parameter Name:", placeholder = "e.g., Diabetes Mortality"),
                 hr(),
                 numericInput(ns("base_val"), "Gen. Pop. Mortality:", value = 0.005, min = 0, step = 0.001),
                 radioButtons(ns("input_type"), "Input Type:", 
                              choices = c("Annual Probability (qx)" = "prob", 
                                          "Instantaneous Rate (mx)" = "rate")),
                 numericInput(ns("smr"), "SMR / Hazard Ratio:", value = 1.5, min = 0, step = 0.1),
                 actionButton(ns("calc_smr"), "Adjust & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_smr")),
                 div(class="plot-container", plotOutput(ns("plot_smr")))
               )
             )
    ),
    
    # --- Tab 2: Linear Interpolation ---
    tabPanel("Linear Interpolation",
             sidebarLayout(
               sidebarPanel(
                 h4("Interpolate Mortality"),
                 p("Generate age-specific rates between two known points."),
                 textInput(ns("lbl_int"), "Parameter Name:", placeholder = "e.g., Age 53 Rate"),
                 hr(),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("age1"), "Age A:", 50), numericInput(ns("mort1"), "Rate A:", 0.004)
                 ),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("age2"), "Age B:", 60), numericInput(ns("mort2"), "Rate B:", 0.009)
                 ),
                 numericInput(ns("target_age"), "Target Age (for Log):", 55),
                 actionButton(ns("calc_interp"), "Interpolate & Generate Table", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_interp")),
                 div(class="plot-container", plotOutput(ns("plot_interp"), height="300px")),
                 br(),
                 h4("Life Table (Age-Wise)"),
                 DT::dataTableOutput(ns("tbl_interp"))
               )
             )
    ),
    
    # --- Tab 3: Gompertz Fit ---
    tabPanel("Gompertz Fit (Aging)",
             sidebarLayout(
               sidebarPanel(
                 h4("Gompertz Parameterization"),
                 p("Derive 'Aging Parameters' and full life table from two points."),
                 textInput(ns("lbl_gomp"), "Label:", placeholder = "e.g., Male Bg Mortality"),
                 hr(),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("g_age1"), "Age 1:", 40), numericInput(ns("g_rate1"), "Rate 1:", 0.002)
                 ),
                 div(style="display:flex; gap:5px;",
                     numericInput(ns("g_age2"), "Age 2:", 80), numericInput(ns("g_rate2"), "Rate 2:", 0.080)
                 ),
                 helpText("Fits: Rate(t) = Alpha * exp(Beta * Age)"),
                 actionButton(ns("calc_gomp"), "Fit & Generate Table", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_gomp")),
                 div(class="plot-container", plotOutput(ns("plot_gomp"), height="300px")),
                 br(),
                 h4("Life Table (Age-Wise)"),
                 DT::dataTableOutput(ns("tbl_gomp"))
               )
             )
    ),
    
    # --- Tab 4: DEALE ---
    tabPanel("Life Expectancy (DEALE)",
             sidebarLayout(
               sidebarPanel(
                 h4("DEALE & Excess Mortality"),
                 textInput(ns("lbl_deale"), "Label:", placeholder = "e.g., Excess HF Mortality"),
                 hr(),
                 radioButtons(ns("deale_mode"), "Calculation Mode:", 
                              choices = c("Simple: LE ↔ Rate" = "simple", 
                                          "Advanced: Calculate Excess Rate" = "excess")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'simple'", ns("deale_mode")),
                                  radioButtons(ns("deale_dir"), "Direction:", 
                                               choices = c("LE (Years) → Rate" = "le2r", "Rate → LE (Years)" = "r2le")),
                                  conditionalPanel(condition = sprintf("input['%s'] == 'le2r'", ns("deale_dir")),
                                                   numericInput(ns("val_le"), "Life Expectancy (Years):", value = 20, min = 0.1)),
                                  conditionalPanel(condition = sprintf("input['%s'] == 'r2le'", ns("deale_dir")),
                                                   numericInput(ns("val_rate_deale"), "Mortality Rate (r):", value = 0.05, min = 0.0001))
                 ),
                 conditionalPanel(condition = sprintf("input['%s'] == 'excess'", ns("deale_mode")),
                                  numericInput(ns("le_observed"), "Observed LE (Disease Cohort):", value = 3.2, min = 0.1),
                                  numericInput(ns("le_background"), "Background LE (Healthy/Pop):", value = 14.5, min = 0.1),
                                  helpText("Calculates: (1/Observed) - (1/Background)")
                 ),
                 actionButton(ns("calc_deale"), "Calculate & Log", class = "btn-primary", width = "100%")
               ),
               mainPanel(
                 uiOutput(ns("res_deale")),
                 p(style="margin-top:20px; font-size:0.9em; color:#666;", 
                   "The DEALE method assumes constant mortality rates.")
               )
             )
    )
  )
}

mod_lifetable_server <- function(id, logger) {
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
    
    # --- SMR Logic ---
    smr_data <- reactiveVal(NULL)
    observeEvent(input$calc_smr, {
      base <- input$base_val; smr <- input$smr
      if(input$input_type == "prob") {
        if(base >= 1) { output$res_smr <- renderUI(div(class="result-box", style="color:red", "Error: Prob < 1")); return() }
        rate_pop <- -log(1 - base)
      } else { rate_pop <- base }
      rate_adj <- rate_pop * smr
      prob_adj <- 1 - exp(-rate_adj)
      output$res_smr <- renderUI(div(class="result-box", HTML(paste0(
        "<span class='result-label'>Result</span><br>Adj Rate: ", round(rate_adj, 5), 
        "<br><span class='result-value'>Prob: ", round(prob_adj, 5), "</span>"))))
      add_to_log(input$lbl_smr, "Bg Mortality (SMR)", paste0("Base=", base, ", SMR=", smr), paste0("Prob=", round(prob_adj,5)), "SMR Adjust")
      smr_data(data.frame(Group = c("Gen Pop", "Disease"), Probability = c(1-exp(-rate_pop), prob_adj)))
    })
    output$plot_smr <- renderPlot({ req(smr_data()); ggplot(smr_data(), aes(Group, Probability, fill=Group)) + geom_bar(stat="identity", width=0.5) + scale_fill_manual(values=c("#c0392b", "#003366")) + theme_minimal() + ylim(0,1) })
    
    # --- Interpolation Logic ---
    interp_data <- reactiveVal(NULL)
    observeEvent(input$calc_interp, {
      slope <- (input$mort2 - input$mort1) / (input$age2 - input$age1)
      m_target <- input$mort1 + slope * (input$target_age - input$age1)
      output$res_interp <- renderUI(div(class="result-box", HTML(paste0("<span class='result-value'>Rate: ", round(m_target, 5), "</span>"))))
      add_to_log(input$lbl_int, "Bg Mortality (Linear)", paste0("Target Age=", input$target_age), paste0("Rate=", round(m_target,5)), "Linear Interp")
      ages <- seq(min(input$age1, input$age2), max(input$age1, input$age2), by=1)
      rates <- input$mort1 + slope * (ages - input$age1)
      interp_data(data.frame(Age=ages, Rate=rates))
    })
    output$plot_interp <- renderPlot({ req(interp_data()); ggplot(interp_data(), aes(Age, Rate)) + geom_line(color="#27ae60", size=1) + geom_point(aes(x=input$target_age, y=input$mort1 + (input$mort2-input$mort1)/(input$age2-input$age1)*(input$target_age-input$age1)), color="red", size=3) + theme_minimal() })
    
    # TABLE INTERPOLATION
    output$tbl_interp <- DT::renderDataTable({
      req(interp_data())
      # Calculate Annual Prob for the table
      df <- interp_data()
      df$Annual_Prob <- 1 - exp(-df$Rate)
      
      DT::datatable(df, 
                    extensions = 'Buttons',
                    options = list(
                      dom = 'Blfrtip', 
                      pageLength = 10,
                      lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'All')),
                      buttons = list(
                        list(extend = 'copy', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'csv', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'excel', exportOptions = list(modifier = list(page = 'all')))
                      )
                    ),
                    rownames = FALSE) %>%
        DT::formatRound(columns=c("Rate", "Annual_Prob"), digits=5)
    })
    
    # --- Gompertz Logic ---
    gomp_data <- reactiveVal(NULL)
    observeEvent(input$calc_gomp, {
      t1 <- input$g_age1; r1 <- input$g_rate1
      t2 <- input$g_age2; r2 <- input$g_rate2
      if(t1 == t2 || r1 <= 0 || r2 <= 0) {
        output$res_gomp <- renderUI(div(class="result-box", style="color:red", "Error: Different ages and positive rates required."))
        return()
      }
      y1 <- log(r1); y2 <- log(r2)
      beta <- (y2 - y1) / (t2 - t1)
      ln_alpha <- y1 - beta * t1
      alpha <- exp(ln_alpha)
      
      output$res_gomp <- renderUI(div(class="result-box", HTML(paste0(
        "<span class='result-label'>Gompertz Parameters</span><br>Alpha: ", format(alpha, scientific=TRUE), "<br>Beta: ", round(beta, 5), 
        "<br><small>Rate = Alpha * exp(Beta * Age)</small>"))))
      add_to_log(input$lbl_gomp, "Bg Mortality (Gompertz)", paste0("Age ", t1, "/", t2), paste0("Alpha=", format(alpha, digits=3), " Beta=", round(beta,4)), "Gompertz Fit")
      ages <- seq(min(t1, t2), max(t1, t2), by=1)
      rates <- alpha * exp(beta * ages)
      gomp_data(data.frame(Age=ages, Rate=rates))
    })
    output$plot_gomp <- renderPlot({ req(gomp_data()); ggplot(gomp_data(), aes(Age, Rate)) + geom_line(color="#8e44ad", size=1.2) + theme_minimal() + labs(title="Gompertz Mortality Curve", y="Rate") })
    
    # TABLE GOMPERTZ
    output$tbl_gomp <- DT::renderDataTable({
      req(gomp_data())
      # Calculate Annual Prob for the table
      df <- gomp_data()
      df$Annual_Prob <- 1 - exp(-df$Rate)
      
      DT::datatable(df, 
                    extensions = 'Buttons',
                    options = list(
                      dom = 'Blfrtip', 
                      pageLength = 10,
                      lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'All')),
                      buttons = list(
                        list(extend = 'copy', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'csv', exportOptions = list(modifier = list(page = 'all'))),
                        list(extend = 'excel', exportOptions = list(modifier = list(page = 'all')))
                      )
                    ),
                    rownames = FALSE) %>%
        DT::formatRound(columns=c("Rate", "Annual_Prob"), digits=5)
    })
    
    # --- DEALE Logic ---
    observeEvent(input$calc_deale, {
      res_txt <- ""; log_inp <- ""; log_res <- ""; method_note <- ""
      
      if(input$deale_mode == "simple") {
        if(input$deale_dir == "le2r") {
          req(input$val_le)
          r <- 1 / input$val_le
          res_txt <- paste0("Total Rate = ", round(r, 5))
          log_res <- paste0("Rate=", round(r, 5))
          log_inp <- paste0("LE=", input$val_le)
        } else {
          req(input$val_rate_deale)
          le <- 1 / input$val_rate_deale
          res_txt <- paste0("Life Expectancy = ", round(le, 2), " Years")
          log_res <- paste0("LE=", round(le, 2))
          log_inp <- paste0("Rate=", input$val_rate_deale)
        }
        method_note <- "DEALE (Simple)"
        output$res_deale <- renderUI(div(class="result-box", HTML(paste0("<span class='result-value'>", res_txt, "</span>"))))
        
      } else {
        req(input$le_observed, input$le_background)
        le_obs <- input$le_observed; le_bg <- input$le_background
        if (le_obs >= le_bg) { output$res_deale <- renderUI(div(class="result-box", style="color:red", "Error: Disease LE must be < Bg LE")); return() }
        
        r_total <- 1 / le_obs; r_bg <- 1 / le_bg
        r_disease <- r_total - r_bg
        res_txt <- paste0("Total Rate: ", round(r_total, 4), "<br>Bg Rate: ", round(r_bg, 4), "<br><br><span class='result-value' style='color:#c0392b'>Excess Rate: ", round(r_disease, 5), "</span>")
        log_res <- paste0("Excess Rate=", round(r_disease, 5))
        log_inp <- paste0("LE_obs=", le_obs, ", LE_bg=", le_bg)
        method_note <- "DEALE (Excess)"
        output$res_deale <- renderUI(div(class="result-box", HTML(res_txt)))
      }
      add_to_log(input$lbl_deale, "DEALE", log_inp, log_res, method_note)
    })
  })
}