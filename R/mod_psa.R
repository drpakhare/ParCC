mod_psa_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Distribution Fitting"),
      textInput(ns("label"), "Parameter Name:", placeholder = "e.g., Utility of Stable State"),
      hr(),
      
      selectInput(ns("dist"), "Distribution:", 
                  choices = c("Beta (Proportions)" = "beta",
                              "Gamma (Costs/Rates)" = "gamma",
                              "LogNormal (RR)" = "lnorm")),
      
      # UPDATED: 3 Options now
      radioButtons(ns("source_type"), "Input Data Format:",
                   choices = c("Mean & Standard Error" = "se",
                               "Mean & 95% CI" = "ci",
                               "Mean & Range (Low/High)" = "range")),
      
      numericInput(ns("mean"), "Mean:", value = 0.5),
      
      # 1. Standard Error Input
      conditionalPanel(condition = sprintf("input['%s'] == 'se'", ns("source_type")),
                       numericInput(ns("se"), "Standard Error (SE):", value = 0.05)
      ),
      
      # 2. Confidence Interval Input
      conditionalPanel(condition = sprintf("input['%s'] == 'ci'", ns("source_type")),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("ci_low"), "Lower 95%:", value = 0.4),
                           numericInput(ns("ci_high"), "Upper 95%:", value = 0.6)
                       ),
                       helpText(class="text-info", "SE calculated as (Upper - Lower) / 3.92")
      ),
      
      # 3. NEW: Range Input
      conditionalPanel(condition = sprintf("input['%s'] == 'range'", ns("source_type")),
                       div(style="display:flex; gap:5px;",
                           numericInput(ns("rng_low"), "Low Bound:", value = 0.4),
                           numericInput(ns("rng_high"), "High Bound:", value = 0.6)
                       ),
                       helpText(class="text-info", "SE estimated via 'Rule of 4': (High - Low) / 4")
      ),
      
      br(),
      actionButton(ns("calc"), "Calculate & Log", class = "btn-primary", width = "100%")
    ),
    mainPanel(
      uiOutput(ns("res")),
      div(class="plot-container", plotOutput(ns("plot")))
    )
  )
}

mod_psa_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {
    
    psa_data <- reactiveVal(NULL)
    
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
      mu <- input$mean
      se <- 0
      input_log_str <- ""
      method_note <- ""
      
      # 1. Determine SE based on Source Type
      if (input$source_type == "se") {
        se <- input$se
        input_log_str <- paste0("Mean=", mu, ", SE=", se)
        method_note <- "Method of Moments"
        
      } else if (input$source_type == "ci") {
        se <- (input$ci_high - input$ci_low) / 3.92
        input_log_str <- paste0("Mean=", mu, ", 95% CI[", input$ci_low, "-", input$ci_high, "]")
        method_note <- "MoM (Derived from 95% CI)"
        
        if (se <= 0) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: Upper bound must be greater than Lower bound."))
          return()
        }
        
      } else { 
        # NEW: Range Logic (Rule of 4)
        se <- (input$rng_high - input$rng_low) / 4
        input_log_str <- paste0("Mean=", mu, ", Range[", input$rng_low, "-", input$rng_high, "]")
        method_note <- "MoM (Rule of 4 Estimation)"
        
        if (se <= 0) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: High bound must be greater than Low bound."))
          return()
        }
      }
      
      v <- se^2
      
      # 2. Distribution Fitting Logic
      if (input$dist == "beta") {
        if (mu<=0 || mu>=1 || v >= mu*(1-mu)) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: Impossible Beta variance (Range/SE too wide for Mean)."))
          psa_data(NULL)
        } else {
          term <- (mu * (1 - mu) / v) - 1
          a <- mu * term; b <- (1 - mu) * term
          x <- seq(0, 1, length.out=200); y <- dbeta(x, a, b)
          psa_data(data.frame(x=x, y=y))
          
          res_str <- paste0("Alpha=", round(a,3), " Beta=", round(b,3))
          output$res <- renderUI(div(class="result-box", HTML(paste0(
            "<span class='result-label'>Beta Params</span><br>",
            "<span class='result-value'>", res_str, "</span>",
            "<br><small>Derived SE = ", round(se, 4), "</small>"
          ))))
          
          add_to_log(input$label, "PSA (Beta)", input_log_str, res_str, method_note)
        }
      } else if (input$dist == "gamma") {
        if (mu <= 0) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: Mean must be positive."))
          psa_data(NULL)
        } else {
          k <- mu^2/v; theta <- v/mu
          x <- seq(0, qgamma(0.999, k, scale=theta), length.out=200)
          y <- dgamma(x, k, scale=theta)
          psa_data(data.frame(x=x, y=y))
          
          res_str <- paste0("Shape=", round(k,3), " Scale=", round(theta,3))
          output$res <- renderUI(div(class="result-box", HTML(paste0(
            "<span class='result-label'>Gamma Params</span><br>",
            "<span class='result-value'>", res_str, "</span>",
            "<br><small>Derived SE = ", round(se, 4), "</small>"
          ))))
          
          add_to_log(input$label, "PSA (Gamma)", input_log_str, res_str, method_note)
        }
      } else {
        if (mu <= 0) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: Mean must be positive."))
          psa_data(NULL)
        } else {
          s2 <- log(1 + v/mu^2); s <- sqrt(s2); m <- log(mu) - 0.5*s2
          x <- seq(0, qlnorm(0.99, m, s), length.out=200)
          y <- dlnorm(x, m, s)
          psa_data(data.frame(x=x, y=y))
          
          res_str <- paste0("Meanlog=", round(m,3), " Sdlog=", round(s,3))
          output$res <- renderUI(div(class="result-box", HTML(paste0(
            "<span class='result-label'>LogNormal Params</span><br>",
            "<span class='result-value'>", res_str, "</span>",
            "<br><small>Derived SE = ", round(se, 4), "</small>"
          ))))
          
          add_to_log(input$label, "PSA (LNorm)", input_log_str, res_str, method_note)
        }
      }
    })
    
    output$plot <- renderPlot({
      req(psa_data())
      ggplot(psa_data(), aes(x, y)) + 
        geom_line(color = "#E74C3C", size = 1.2) +
        geom_area(fill = "#E74C3C", alpha = 0.2) +
        geom_vline(xintercept = input$mean, linetype="dashed") +
        theme_minimal() + labs(y="Density", x="Value")
    })
  })
}