mod_survival_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Survival Analysis"),
      textInput(ns("label"), "Parameter Name:", placeholder = "e.g., OS Curve - Treatment"),
      hr(),
      
      selectInput(ns("surv_method"), "Select Method:", 
                  choices = c("Exponential (From Median)" = "exp",
                              "Weibull (From 2 Time Points)" = "weibull")),
      
      # Exponential Inputs
      conditionalPanel(condition = sprintf("input['%s'] == 'exp'", ns("surv_method")),
                       p(class="text-info", "Requires constant hazard assumption."),
                       radioButtons(ns("exp_dir"), "Direction:", 
                                    c("Median → Rate"="med2rate", "Rate → Median"="rate2med")),
                       conditionalPanel(condition = sprintf("input['%s'] == 'med2rate'", ns("exp_dir")),
                                        numericInput(ns("val_med"), "Median Survival Time:", value = 12, min = 0.01)
                       ),
                       conditionalPanel(condition = sprintf("input['%s'] == 'rate2med'", ns("exp_dir")),
                                        numericInput(ns("val_haz"), "Hazard Rate (lambda):", value = 0.05, min = 0.0001)
                       )
      ),
      
      # Weibull Inputs
      conditionalPanel(condition = sprintf("input['%s'] == 'weibull'", ns("surv_method")),
                       p(class="text-info", "Calibrate Weibull using 2 points from KM curve."),
                       h5("Point 1"),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("w_t1"), "Time 1:", 12), numericInput(ns("w_s1"), "Surv 1:", 0.8, 0, 1, 0.01)),
                       h5("Point 2"),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("w_t2"), "Time 2:", 36), numericInput(ns("w_s2"), "Surv 2:", 0.4, 0, 1, 0.01))
      ),
      
      hr(),
      numericInput(ns("max_t"), "Plot/Table Max Time:", 60),
      actionButton(ns("calc"), "Calculate & Log", class = "btn-primary", width = "100%")
    ),
    mainPanel(
      uiOutput(ns("res")),
      div(class="plot-container", plotOutput(ns("plot"), height="350px")),
      br(),
      h4("Markov Trace (Cycle-Wise)"),
      p(class="text-info", style="font-size:0.9em;", "Transition Prob (tp) represents probability of surviving the interval (t-1 to t)."),
      DT::dataTableOutput(ns("tbl_surv"))
    )
  )
}

mod_survival_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {
    
    surv_plot_data <- reactiveVal(NULL)
    surv_table_data <- reactiveVal(NULL)
    
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
      # 1. Setup Time Sequences
      # Smooth for plot (100 points)
      t_seq_plot <- seq(0, input$max_t, length.out = 100)
      # Integer for table (0, 1, 2... Max)
      t_seq_tbl <- 0:input$max_t
      
      if (input$surv_method == "exp") {
        # --- Exponential Logic ---
        if (input$exp_dir == "med2rate") {
          rate <- log(2) / input$val_med
          med <- input$val_med
          inp_str <- paste0("Median=", med)
        } else {
          rate <- input$val_haz
          med <- log(2) / rate
          inp_str <- paste0("Hazard=", rate)
        }
        
        # Calculate Vectors
        probs_plot <- exp(-rate * t_seq_plot)
        probs_tbl  <- exp(-rate * t_seq_tbl)
        
        # Prepare Outputs
        surv_plot_data(data.frame(Time = t_seq_plot, Survival = probs_plot))
        
        output$res <- renderUI(div(class = "result-box", HTML(paste0(
          "<span class='result-label'>Exponential Params</span><br>",
          "<span class='result-value'>Hazard (lambda) = ", round(rate, 5), "</span>",
          "Median = ", round(med, 2)
        ))))
        
        add_to_log(input$label, "Survival (Exp)", inp_str, paste0("Lambda=", round(rate,5)), "Constant Hazard")
        
      } else {
        # --- Weibull Logic ---
        t1 <- input$w_t1; s1 <- input$w_s1
        t2 <- input$w_t2; s2 <- input$w_s2
        
        if(s1 <= 0 || s1 >= 1 || s2 <= 0 || s2 >= 1 || t1 == t2) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: Inputs must be distinct and probabilities between 0-1."))
          surv_plot_data(NULL)
          surv_table_data(NULL)
          return()
        } else {
          y1 <- log(-log(s1)); x1 <- log(t1)
          y2 <- log(-log(s2)); x2 <- log(t2)
          
          gamma <- (y2 - y1) / (x2 - x1)
          lambda <- exp(y1 - gamma * x1)
          
          # Calculate Vectors
          probs_plot <- exp(-lambda * t_seq_plot^gamma)
          probs_tbl  <- exp(-lambda * t_seq_tbl^gamma)
          
          surv_plot_data(data.frame(Time = t_seq_plot, Survival = probs_plot))
          
          output$res <- renderUI(div(class = "result-box", HTML(paste0(
            "<span class='result-label'>Weibull Params</span><br>",
            "<span class='result-value'>Shape (gamma) = ", round(gamma, 4), "</span>",
            "<span class='result-value'>Scale (lambda) = ", format(lambda, scientific=TRUE), "</span>"
          ))))
          
          add_to_log(input$label, "Survival (Weibull)", 
                     paste0("P1(",t1,",",s1,") P2(",t2,",",s2,")"), 
                     paste0("Shape=", round(gamma,4), ", Scale=", format(lambda, scientific=TRUE)), 
                     "2-Point Calibration")
        }
      }
      
      # --- Generate Table Data (Common Step) ---
      if (!is.null(surv_plot_data())) {
        # Calculate Interval Transition Probability: Tp = S(t) / S(t-1)
        # S(0) is 1. S(1)/S(0) = S(1).
        
        tp <- numeric(length(probs_tbl))
        tp[1] <- 1 # Cycle 0
        
        for(i in 2:length(probs_tbl)) {
          # Prob of surviving to t, given survived to t-1
          prev <- probs_tbl[i-1]
          curr <- probs_tbl[i]
          if(prev > 0) tp[i] <- curr / prev else tp[i] <- 0
        }
        
        # Hazard for interval (approx)
        haz_t <- -log(tp)
        
        surv_table_data(data.frame(
          Cycle = t_seq_tbl,
          Survival_S_t = probs_tbl,
          Trans_Prob_tp = tp,
          Interval_Hazard = haz_t
        ))
      }
    })
    
    # Plot Output
    output$plot <- renderPlot({
      req(surv_plot_data())
      ggplot(surv_plot_data(), aes(x = Time, y = Survival)) +
        geom_line(color = "#003366", size = 1.2) +
        geom_area(fill = "#003366", alpha = 0.1) +
        theme_minimal() + ylim(0, 1) +
        labs(title = "Projected Survival Curve", y = "S(t)", x = "Time")
    })
    
    # Table Output
    output$tbl_surv <- DT::renderDataTable({
      req(surv_table_data())
      DT::datatable(surv_table_data(), 
                    extensions = 'Buttons',
                    options = list(
                      dom = 'Blfrtip', 
                      pageLength = 10,
                      lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'All')),
                      buttons = list('copy', 'csv', 'excel')
                    ),
                    rownames = FALSE) %>%
        DT::formatRound(columns=c("Survival_S_t", "Trans_Prob_tp", "Interval_Hazard"), digits=5)
    })
  })
}