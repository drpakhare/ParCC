mod_vbp_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Value-Based Pricing (Headroom)"),
      textInput(ns("label"), "Technology Name:", placeholder = "e.g., New Implant / Drug / Test"),
      hr(),
      
      h5("1. Clinical Benefit"),
      numericInput(ns("delta_e"), "Incremental QALYs (ΔE):", value = 0.5, step = 0.01),
      
      h5("2. Comparator Costs"),
      numericInput(ns("cost_c"), "Total Cost of Standard Care:", value = 10000),
      
      h5("3. Intervention Costs (Disaggregated)"),
      numericInput(ns("cost_assoc"), "Associated Costs (Admin/Surgery/AEs):", value = 5000),
      numericInput(ns("current_price"), "Current Unit Price:", value = 1000),
      numericInput(ns("units"), "Units per Patient:", value = 30),
      helpText("Total Current Cost = (Price * Units) + Associated Costs"),
      
      hr(),
      h5("4. Threshold Settings"),
      numericInput(ns("wtp_base"), "Target WTP Threshold:", value = 20000),
      
      actionButton(ns("calc"), "Calculate Pricing", class = "btn-primary", width = "100%")
    ),
    mainPanel(
      # Top Summary Box
      uiOutput(ns("res_summary")),
      br(),
      
      # Visualization tabset with Explanations
      tabsetPanel(
        tabPanel("Price Map (Breakeven)", 
                 div(class="plot-container", plotlyOutput(ns("plot_price_map"))),
                 div(class="well", style="margin-top: 15px; font-size: 0.9em;",
                     h5(icon("circle-info"), " How to read this chart:"),
                     tags$ul(
                       tags$li(strong("Red Dashed Line (Current Price):"), " The fixed market price of the technology."),
                       tags$li(strong("Blue Solid Line (Value-Based Price):"), " The maximum justifiable price as society's Willingness-to-Pay (WTP) increases."),
                       tags$li(strong("Crossing Point (Diamond):"), " The Breakeven Point. If your Target WTP is to the RIGHT of this point, the technology is Cost-Effective (Green Zone). If to the LEFT, it is overpriced (Red Zone).")
                     )
                 )
        ),
        tabPanel("Headroom Waterfall",
                 div(class="plot-container", plotOutput(ns("plot_waterfall"))),
                 div(class="well", style="margin-top: 15px; font-size: 0.9em;",
                     h5(icon("circle-info"), " Understanding the Headroom Logic:"),
                     tags$ol(
                       tags$li("We start with money already spent on the ", strong("Comparator"), "."),
                       tags$li("We add the monetary value of the ", strong("Health Benefit"), " (ΔE × WTP)."),
                       tags$li("This sum is the ", strong("Total Headroom"), " (Total Allowable Budget)."),
                       tags$li("Crucially, we must SUBTRACT fixed ", strong("Associated Costs"), " (surgery, administration, side effects)."),
                       tags$li("The remaining bar is the ", strong("Max Technology Budget"), " available to pay for the new intervention itself.")
                     )
                 )
        )
      )
    )
  )
}

mod_vbp_server <- function(id, logger) {
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
    
    vbp_res <- reactiveVal(NULL)
    
    observeEvent(input$calc, {
      # Inputs
      dE <- input$delta_e
      Cc <- input$cost_c
      Ca <- input$cost_assoc
      P_curr <- input$current_price
      N <- input$units
      WTP <- input$wtp_base
      
      # 1. Calculate Headroom (Total Allowable Cost)
      total_allowable_cost <- (dE * WTP) + Cc
      
      # 2. Calculate Max Unit Price
      p_max <- (total_allowable_cost - Ca) / N
      
      # 3. Calculate Breakeven WTP
      # P_curr = [ (dE * WTP_break) + Cc - Ca ] / N
      # WTP_break = [ (P_curr * N) + Ca - Cc ] / dE
      total_current_cost_intervention <- (P_curr * N) + Ca
      
      # Handle div by zero if dE is 0
      if(dE == 0) {
        wtp_breakeven <- NA
      } else {
        wtp_breakeven <- (total_current_cost_intervention - Cc) / dE
      }
      
      # 4. Status Logic with INR text
      if (p_max < 0) {
        status <- "Not Viable (Associated costs exceed total value)"
        sub_status <- "Even at Price=0, the technology is not cost-effective due to high associated costs (e.g., surgery/admin)."
        col <- "#c0392b"
      } else if (P_curr > p_max) {
        discount_pct <- (1 - (p_max / P_curr)) * 100
        status <- paste0("Reduce Price by ", round(discount_pct, 1), "%")
        sub_status <- paste0("Current price (INR ", format(P_curr, big.mark=","), ") exceeds value (INR ", format(round(p_max,2), big.mark=","), ").")
        col <- "#e67e22" # Orange
      } else {
        status <- "No Discount Needed (Bargain!)"
        sub_status <- paste0("Current price (INR ", format(P_curr, big.mark=","), ") is below the maximum justifiable limit (INR ", format(round(p_max,2), big.mark=","), ").")
        col <- "#27ae60" # Green
      }
      
      # UI Output
      output$res_summary <- renderUI(div(class="result-box", style=paste0("border-left-color:", col), HTML(paste0(
        "<span class='result-label'>Pricing Strategy</span><br>",
        "Current Price: <strong>INR ", format(P_curr, big.mark=","), "</strong><br>",
        "Max Justifiable Price (VBP): <strong>INR ", format(round(p_max, 2), big.mark=","), "</strong><br><br>",
        "<span class='result-label'>Breakeven Analysis</span><br>",
        "Ideally, price should match value at WTP: <strong>INR ", ifelse(is.na(wtp_breakeven), "N/A", format(round(wtp_breakeven,0), big.mark=",")), "</strong><br><br>",
        "<strong style='color:", col, "'>Recommendation: ", status, "</strong><br>",
        "<small>", sub_status, "</small>"
      ))))
      
      # Logging
      add_to_log(input$label, "Value-Based Pricing", 
                 paste0("dE=", dE, ", WTP=", WTP, ", CurrPrice=", P_curr),
                 paste0("VBP=", round(p_max, 2), ", Breakeven WTP=", round(wtp_breakeven, 2)),
                 "Headroom Method")
      
      vbp_res(list(
        dE=dE, Cc=Cc, Ca=Ca, N=N, P_curr=P_curr, WTP=WTP, P_max=p_max, WTP_break=wtp_breakeven
      ))
    })
    
    # --- PLOT 1: Interactive Price Map (Price vs WTP) ---
    output$plot_price_map <- renderPlotly({
      req(vbp_res())
      d <- vbp_res()
      
      # Generate WTP range
      break_pt <- if(is.na(d$WTP_break)) d$WTP else d$WTP_break
      max_x <- max(d$WTP, break_pt) * 1.5
      if(max_x == 0) max_x <- 50000
      
      wtp_seq <- seq(0, max_x, length.out = 100)
      price_seq <- ((d$dE * wtp_seq) + d$Cc - d$Ca) / d$N
      
      plot_df <- data.frame(WTP = wtp_seq, MaxPrice = price_seq)
      
      p <- plot_ly(plot_df, x = ~WTP, y = ~MaxPrice, type = 'scatter', mode = 'lines',
                   line = list(color = '#003366', width = 3),
                   name = "Value-Based Price (Max)") %>%
        add_lines(y = d$P_curr, name = "Current Price", line = list(color = '#c0392b', dash = 'dash')) %>%
        add_segments(x = d$WTP, xend = d$WTP, 
                     y = min(plot_df$MaxPrice), yend = max(plot_df$MaxPrice),
                     line = list(color = 'grey', dash = 'dot'),
                     name = "Target WTP") %>%
        layout(
          title = "Pricing & Reimbursement Map",
          xaxis = list(title = "Willingness-to-Pay (Threshold)"),
          yaxis = list(title = "Unit Price (INR)"),
          legend = list(orientation = "h", x = 0.1, y = -0.2)
        )
      
      if(!is.na(d$WTP_break)) {
        p <- p %>% add_markers(x = d$WTP_break, y = d$P_curr, 
                               marker = list(size = 12, color = 'orange', symbol = 'diamond'),
                               name = "Breakeven Point",
                               hoverinfo = "text",
                               text = paste0("<b>Breakeven</b><br>WTP: ", format(round(d$WTP_break,0), big.mark=","))) %>%
          layout(annotations = list(
            list(x = d$WTP_break, y = d$P_curr, text = "Breakeven", showarrow = T, arrowhead = 2, ax = 0, ay = -40)
          ))
      }
      p
    })
    
    # --- PLOT 2: Waterfall ---
    output$plot_waterfall <- renderPlot({
      req(vbp_res())
      d <- vbp_res()
      
      val_clinical <- d$dE * d$WTP
      total_allowable <- val_clinical + d$Cc
      room_for_drug <- total_allowable - d$Ca
      
      df <- data.frame(
        Category = c("1. Comparator Cost", "2. Benefit Value (+)", "3. Total Headroom", "4. Assoc. Costs (-)", "5. Max Tech Budget"),
        Value = c(d$Cc, val_clinical, total_allowable, -d$Ca, room_for_drug),
        Type = c("Base", "Add", "Subtotal", "Subtract", "Final")
      )
      df$Category <- factor(df$Category, levels = df$Category)
      
      ggplot(df, aes(x=Category, y=Value, fill=Type)) +
        geom_bar(stat="identity") +
        geom_text(aes(label=format(round(Value,0), big.mark=",")), vjust= ifelse(df$Value >= 0, -0.5, 1.5), fontface="bold") +
        scale_fill_manual(values=c("#95a5a6", "#27ae60", "#003366", "#c0392b", "#8e44ad")) +
        theme_minimal() +
        geom_hline(yintercept=0, color="black") +
        labs(title = "Headroom Analysis (Budget Breakdown)", y = "Monetary Value (INR)", x="", 
             subtitle = paste0("At WTP = INR ", format(d$WTP, big.mark=","))) +
        theme(axis.text.x = element_text(angle = 15, hjust = 1))
    })
  })
}