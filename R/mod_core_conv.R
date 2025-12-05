mod_core_conv_ui <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    # --- Rate <-> Prob ---
    tabPanel("Rate ↔ Probability",
             sidebarLayout(
               sidebarPanel(
                 h4("Rate & Probability"),
                 # Label Input
                 textInput(ns("lbl_rp"), "Parameter Name:", placeholder = "e.g., PFS Control Arm"),
                 hr(),
                 
                 radioButtons(ns("rp_dir"), "Direction:", c("Rate to Prob"="r2p", "Prob to Rate"="p2r")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'r2p'", ns("rp_dir")),
                                  div(style="display:flex; gap:10px;",
                                      numericInput(ns("val_rate"), "Rate:", 5, width="50%"),
                                      # UPDATE: Added "100" to the choices below
                                      selectInput(ns("rate_mult"), "Per:", 
                                                  choices = c("1 (Raw)"=1, "100"=100, "1,000"=1000, "100,000"=1e5), 
                                                  selected=1000, width="50%")
                                  )
                 ),
                 conditionalPanel(condition = sprintf("input['%s'] == 'p2r'", ns("rp_dir")),
                                  numericInput(ns("val_prob"), "Probability (p):", 0.1, 0, 1, 0.01)
                 ),
                 numericInput(ns("val_time"), "Time Horizon (t):", 1, min=0.001),
                 
                 actionButton(ns("calc_rp"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_rp")))
             )
    ),
    
    # --- Odds <-> Prob ---
    tabPanel("Odds ↔ Probability",
             sidebarLayout(
               sidebarPanel(
                 h4("Odds & Probability"),
                 textInput(ns("lbl_op"), "Parameter Name:", placeholder = "e.g., AE Nausea"),
                 hr(),
                 radioButtons(ns("op_dir"), "Direction:", c("Odds to Prob"="o2p", "Prob to Odds"="p2o")),
                 conditionalPanel(condition = sprintf("input['%s'] == 'o2p'", ns("op_dir")), numericInput(ns("val_odds"), "Odds:", 1)),
                 conditionalPanel(condition = sprintf("input['%s'] == 'p2o'", ns("op_dir")), numericInput(ns("val_prob_o"), "Prob:", 0.5)),
                 actionButton(ns("calc_op"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_op")))
             )
    ),
    
    # --- Time Rescaling ---
    tabPanel("Time Rescaling",
             sidebarLayout(
               sidebarPanel(
                 h4("Rescale Probability"),
                 textInput(ns("lbl_tr"), "Parameter Name:", placeholder = "e.g., 1-Year to 1-Month"),
                 hr(),
                 numericInput(ns("tr_prob"), "Orig Prob:", 0.1, 0, 1),
                 div(style="display:flex; gap:10px;", numericInput(ns("tr_t1"), "Orig Time:", 1), selectInput(ns("tr_u1"), "", c("Years","Months","Weeks","Days"))),
                 div(style="display:flex; gap:10px;", numericInput(ns("tr_t2"), "New Time:", 1), selectInput(ns("tr_u2"), "", c("Years","Months","Weeks","Days"), "Months")),
                 actionButton(ns("calc_tr"), "Convert & Log", class="btn-primary", width="100%")
               ),
               mainPanel(uiOutput(ns("res_tr")))
             )
    )
  )
}

mod_core_conv_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {
    
    # Helper to add to log
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
      showNotification("Added to Report", type = "message", duration = 2)
    }
    
    # Rate Logic
    observeEvent(input$calc_rp, {
      t <- input$val_time
      if(input$rp_dir == "r2p") {
        # Fix: Ensure mult is numeric
        r <- input$val_rate / as.numeric(input$rate_mult)
        p <- 1 - exp(-r*t)
        output$res_rp <- renderUI(div(class="result-box", HTML(paste0("<span class='result-value'>Prob = ", round(p,5), "</span>"))))
        
        # LOGGING
        add_to_log(input$lbl_rp, "Rate->Prob", 
                   paste0("r=", input$val_rate, "/", input$rate_mult, ", t=", t),
                   paste0("p=", round(p,5)), 
                   "Exponential")
      } else {
        r <- -log(1 - input$val_prob)/t
        output$res_rp <- renderUI(div(class="result-box", HTML(paste0(
          "<span class='result-value'>Rate = ", round(r,5), "</span>",
          "<br><small>Per 100 = ", round(r*100, 3), "</small>", 
          "<br><small>Per 1000 = ", round(r*1000, 2), "</small>"
        ))))
        
        # LOGGING
        add_to_log(input$lbl_rp, "Prob->Rate", 
                   paste0("p=", input$val_prob, ", t=", t),
                   paste0("r=", round(r,5)), 
                   "Inverse Exponential")
      }
    })
    
    # Odds Logic
    observeEvent(input$calc_op, {
      if(input$op_dir == "o2p") {
        p <- input$val_odds / (1 + input$val_odds)
        output$res_op <- renderUI(div(class="result-box", HTML(paste0("<span class='result-value'>Prob = ", round(p,5), "</span>"))))
        add_to_log(input$lbl_op, "Odds->Prob", paste0("Odds=", input$val_odds), paste0("p=", round(p,5)), "Logistic")
      } else {
        o <- input$val_prob_o / (1 - input$val_prob_o)
        output$res_op <- renderUI(div(class="result-box", HTML(paste0("<span class='result-value'>Odds = ", round(o,5), "</span>"))))
        add_to_log(input$lbl_op, "Prob->Odds", paste0("p=", input$val_prob_o), paste0("Odds=", round(o,5)), "Logistic")
      }
    })
    
    # Time Logic
    unit_factors <- list("Years" = 365.25, "Months" = 30.4375, "Weeks" = 7, "Days" = 1)
    observeEvent(input$calc_tr, {
      ratio <- (input$tr_t2 * unit_factors[[input$tr_u2]]) / (input$tr_t1 * unit_factors[[input$tr_u1]])
      p_new <- 1 - (1 - input$tr_prob)^(ratio)
      output$res_tr <- renderUI(div(class="result-box", HTML(paste0("<span class='result-value'>New Prob = ", round(p_new,5), "</span>"))))
      add_to_log(input$lbl_tr, "Time Rescale", 
                 paste0("p_old=", input$tr_prob, ", Ratio=", round(ratio,3)), 
                 paste0("p_new=", round(p_new,5)), 
                 "Linear Rate Assumption")
    })
  })
}