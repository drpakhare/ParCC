mod_vbp_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Value-Based Pricing (Headroom)"),
      textInput(ns("label"), "Technology Name:", placeholder = "e.g., New Implant / Drug / Test"),
      hr(),

      h5("1. Clinical Benefit"),
      numericInput(ns("delta_e"), "Incremental QALYs (\u0394E):", value = 0.5, step = 0.01),

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
      uiOutput(ns("res_summary")),
      br(),

      tabsetPanel(
        tabPanel("Price Map (Breakeven)",
                 div(class="plot-container", plotlyOutput(ns("plot_price_map"))),
                 div(class="well", style="margin-top: 15px; font-size: 0.9em;",
                     h5(icon("circle-info"), " How to read this chart:"),
                     tags$ul(
                       tags$li(strong("Red Dashed Line (Current Price):"), " The fixed market price of the technology."),
                       tags$li(strong("Blue Solid Line (Value-Based Price):"), " The maximum justifiable price as society's Willingness-to-Pay (WTP) increases."),
                       tags$li(strong("Crossing Point (Diamond):"), " The Breakeven Point.")
                     )
                 )
        ),
        tabPanel("Headroom Waterfall",
                 div(class="plot-container", plotOutput(ns("plot_waterfall"))),
                 div(class="well", style="margin-top: 15px; font-size: 0.9em;",
                     h5(icon("circle-info"), " Understanding the Headroom Logic:"),
                     tags$ol(
                       tags$li("Start with money already spent on the ", strong("Comparator"), "."),
                       tags$li("Add the monetary value of the ", strong("Health Benefit"), " (Delta E * WTP)."),
                       tags$li("This sum is the ", strong("Total Headroom"), "."),
                       tags$li("Subtract fixed ", strong("Associated Costs"), " (surgery, administration, side effects)."),
                       tags$li("The remaining bar is the ", strong("Max Technology Budget"), ".")
                     )
                 )
        )
      )
    )
  )
}

mod_vbp_server <- function(id, logger, currency) {
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

    cfmt <- function(x) paste0(currency$symbol, " ", format(round(x, 2), big.mark = ","))

    vbp_res <- reactiveVal(NULL)

    observeEvent(input$calc, {
      dE <- input$delta_e
      Cc <- input$cost_c
      Ca <- input$cost_assoc
      P_curr <- input$current_price
      N <- input$units
      WTP <- input$wtp_base

      total_allowable_cost <- (dE * WTP) + Cc
      p_max <- (total_allowable_cost - Ca) / N

      total_current_cost_intervention <- (P_curr * N) + Ca
      if(dE == 0) { wtp_breakeven <- NA } else {
        wtp_breakeven <- (total_current_cost_intervention - Cc) / dE
      }

      if (p_max < 0) {
        status <- "Not Viable (Associated costs exceed total value)"
        sub_status <- "Even at Price=0, the technology is not cost-effective due to high associated costs."
        col <- "#c0392b"
      } else if (P_curr > p_max) {
        discount_pct <- (1 - (p_max / P_curr)) * 100
        status <- paste0("Reduce Price by ", round(discount_pct, 1), "%")
        sub_status <- paste0("Current price (", cfmt(P_curr), ") exceeds value (", cfmt(p_max), ").")
        col <- "#e67e22"
      } else {
        status <- "No Discount Needed (Bargain!)"
        sub_status <- paste0("Current price (", cfmt(P_curr), ") is below the maximum justifiable limit (", cfmt(p_max), ").")
        col <- "#27ae60"
      }

      val_clinical <- dE * WTP

      output$res_summary <- renderUI(tagList(
        div(class="result-box", style=paste0("border-left-color:", col), HTML(paste0(
          "<span class='result-label'>Pricing Strategy</span><br>",
          "Current Price: <strong>", cfmt(P_curr), "</strong><br>",
          "Max Justifiable Price (VBP): <strong>", cfmt(p_max), "</strong><br><br>",
          "<span class='result-label'>Breakeven Analysis</span><br>",
          "Breakeven WTP: <strong>", ifelse(is.na(wtp_breakeven), "N/A", cfmt(wtp_breakeven)), "</strong><br><br>",
          "<strong style='color:", col, "'>Recommendation: ", status, "</strong><br>",
          "<small>", sub_status, "</small>"
        ))),
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            tags$ol(
              tags$li(HTML(paste0(
                strong("Clinical Value: "), "\u0394E \u00d7 WTP = ", round(dE, 3),
                " \u00d7 ", format(WTP, big.mark = ","), " = ",
                strong(cfmt(val_clinical)), "."
              ))),
              tags$li(HTML(paste0(
                strong("Total Headroom: "), "Clinical Value + Comparator Cost = ",
                format(round(val_clinical, 0), big.mark = ","), " + ",
                format(Cc, big.mark = ","), " = ",
                strong(cfmt(total_allowable_cost)), "."
              ))),
              tags$li(HTML(paste0(
                strong("Subtract Associated Costs: "), cfmt(total_allowable_cost),
                " - ", cfmt(Ca), " = ",
                strong(cfmt(total_allowable_cost - Ca)), " available for technology."
              ))),
              tags$li(HTML(paste0(
                strong("Max Unit Price: "), cfmt(total_allowable_cost - Ca),
                " / ", N, " units = ",
                strong(cfmt(p_max)), " per unit."
              )))
            ),
            if (P_curr > p_max && p_max >= 0) {
              p(HTML(paste0(
                icon("exclamation-triangle"), " ",
                "The current price exceeds the value-based maximum by ", cfmt((P_curr - p_max) * N),
                " per patient (across ", N, " units). A price reduction of ",
                strong(paste0(round((1 - p_max/P_curr) * 100, 1), "%")),
                " would be needed."
              )))
            }
        ),
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas", style = "margin-top:0;"),
            p("$$C_{max} = (\\Delta E \\times WTP) + C_{comparator}$$"),
            p("$$P_{max} = \\frac{C_{max} - C_{associated}}{N}$$"),
            p("$$WTP_{breakeven} = \\frac{(P_{current} \\times N) + C_{associated} - C_{comparator}}{\\Delta E}$$")
        ),
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Cosh E, et al. The value of 'innovation headroom'. <em>Value in Health</em>. 2007;10(4):312-315.")),
              tags$li(HTML("Chapman AM, et al. Early value assessment using headroom analysis. <em>Med Decis Making</em>. 2017;37(7):717-728."))
            )
        ),
        mathjax_trigger
      ))

      add_to_log(input$label, "Value-Based Pricing",
                 paste0("dE=", dE, ", WTP=", WTP, ", CurrPrice=", P_curr),
                 paste0("VBP=", round(p_max, 2), ", Breakeven WTP=", round(wtp_breakeven, 2)),
                 "Headroom Method")

      vbp_res(list(dE=dE, Cc=Cc, Ca=Ca, N=N, P_curr=P_curr, WTP=WTP, P_max=p_max, WTP_break=wtp_breakeven))
    })

    # --- PLOT 1: Price Map ---
    output$plot_price_map <- renderPlotly({
      req(vbp_res())
      d <- vbp_res()
      cs <- isolate(currency$symbol)

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
        layout(
          title = "Pricing & Reimbursement Map",
          xaxis = list(title = "Willingness-to-Pay (Threshold)"),
          yaxis = list(title = paste0("Unit Price (", cs, ")")),
          legend = list(orientation = "h", x = 0.1, y = -0.2)
        )

      if(!is.na(d$WTP_break)) {
        p <- p %>% add_markers(x = d$WTP_break, y = d$P_curr,
                               marker = list(size = 12, color = 'orange', symbol = 'diamond'),
                               name = "Breakeven Point",
                               hoverinfo = "text",
                               text = paste0("<b>Breakeven</b><br>WTP: ", format(round(d$WTP_break,0), big.mark=",")))
      }
      p
    })

    # --- PLOT 2: Waterfall ---
    output$plot_waterfall <- renderPlot({
      req(vbp_res())
      d <- vbp_res()
      cs <- isolate(currency$symbol)

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
        labs(title = "Headroom Analysis (Budget Breakdown)",
             y = paste0("Monetary Value (", cs, ")"), x="",
             subtitle = paste0("At WTP = ", cs, " ", format(d$WTP, big.mark=","))) +
        theme(axis.text.x = element_text(angle = 15, hjust = 1))
    })
  })
}
