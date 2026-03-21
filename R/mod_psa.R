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

      # 3. Range Input
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

    # MathJax retrigger
    mathjax_trigger <- tags$script("if(window.MathJax){MathJax.Hub.Queue(['Typeset', MathJax.Hub]);}")

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
        se <- (input$rng_high - input$rng_low) / 4
        input_log_str <- paste0("Mean=", mu, ", Range[", input$rng_low, "-", input$rng_high, "]")
        method_note <- "MoM (Rule of 4 Estimation)"

        if (se <= 0) {
          output$res <- renderUI(div(class="result-box", style="color:red", "Error: High bound must be greater than Low bound."))
          return()
        }
      }

      v <- se^2

      # ==============================================================
      # BETA DISTRIBUTION
      # ==============================================================
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

          output$res <- renderUI(tagList(
            div(class="result-box", HTML(paste0(
              "<span class='result-label'>Beta Distribution Parameters</span><br>",
              "<span class='result-value'>", res_str, "</span>",
              "<br><small>Derived SE = ", round(se, 4), "</small>"
            ))),
            # Explanation
            div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
                p(HTML(paste0(
                  "The Beta distribution is appropriate for probabilities and utilities (bounded 0-1). ",
                  "Using the Method of Moments with Mean = ", strong(mu), " and SE = ", strong(round(se, 4)),
                  ", the shape parameters were derived: \u03b1 = ", strong(round(a, 3)),
                  " and \u03b2 = ", strong(round(b, 3)), "."
                ))),
                p(HTML(paste0(
                  icon("info-circle"), " ",
                  "Use ", tags$code(paste0("rbeta(n, ", round(a, 3), ", ", round(b, 3), ")")),
                  " in R to sample from this distribution in your PSA loop."
                )))
            ),
            # Formula
            div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
                h5(icon("square-root-alt"), " Formulas (Method of Moments)", style = "margin-top:0;"),
                p("$$\\alpha = \\mu \\left( \\frac{\\mu(1-\\mu)}{SE^2} - 1 \\right)$$"),
                p("$$\\beta = (1-\\mu) \\left( \\frac{\\mu(1-\\mu)}{SE^2} - 1 \\right)$$"),
                p(style = "font-size:0.85em; color:#666;",
                  "Requires SE\u00b2 < \u03bc(1-\u03bc) for valid parameters.")
            ),
            # Citation
            div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
                tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                  tags$li(HTML("Briggs A, Claxton K, Sculpher M. <em>Decision Modelling for Health Economic Evaluation</em>. Oxford University Press; 2006. Chapter 4.")),
                  tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015."))
                )
            ),
            mathjax_trigger
          ))

          add_to_log(input$label, "PSA (Beta)", input_log_str, res_str, method_note)
        }

      # ==============================================================
      # GAMMA DISTRIBUTION
      # ==============================================================
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

          output$res <- renderUI(tagList(
            div(class="result-box", HTML(paste0(
              "<span class='result-label'>Gamma Distribution Parameters</span><br>",
              "<span class='result-value'>", res_str, "</span>",
              "<br><small>Derived SE = ", round(se, 4), "</small>"
            ))),
            # Explanation
            div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
                p(HTML(paste0(
                  "The Gamma distribution is the standard choice for costs and resource use because it is ",
                  "non-negative and right-skewed. ",
                  "Using Mean = ", strong(mu), " and SE = ", strong(round(se, 4)),
                  ", the parameters were derived: Shape (k) = ", strong(round(k, 3)),
                  " and Scale (\u03b8) = ", strong(round(theta, 3)), "."
                ))),
                p(HTML(paste0(
                  icon("info-circle"), " ",
                  "Use ", tags$code(paste0("rgamma(n, shape=", round(k, 3), ", scale=", round(theta, 3), ")")),
                  " in R to sample from this distribution. All values will be positive."
                )))
            ),
            # Formula
            div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
                h5(icon("square-root-alt"), " Formulas (Method of Moments)", style = "margin-top:0;"),
                p("$$k = \\frac{\\mu^2}{SE^2}$$"),
                p("$$\\theta = \\frac{SE^2}{\\mu}$$"),
                p(style = "font-size:0.85em; color:#666;",
                  "where k is the shape and \u03b8 is the scale parameter.")
            ),
            # Citation
            div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
                tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                  tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. OUP; 2006. Chapter 4.")),
                  tags$li(HTML("Nixon RM, Thompson SG. Parametric modelling of cost data. <em>Health Econ</em>. 2004;13(10):1015-1026."))
                )
            ),
            mathjax_trigger
          ))

          add_to_log(input$label, "PSA (Gamma)", input_log_str, res_str, method_note)
        }

      # ==============================================================
      # LOGNORMAL DISTRIBUTION
      # ==============================================================
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

          output$res <- renderUI(tagList(
            div(class="result-box", HTML(paste0(
              "<span class='result-label'>LogNormal Distribution Parameters</span><br>",
              "<span class='result-value'>", res_str, "</span>",
              "<br><small>Derived SE = ", round(se, 4), "</small>"
            ))),
            # Explanation
            div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
                p(HTML(paste0(
                  "The LogNormal distribution is the standard choice for relative risks, hazard ratios, and odds ratios ",
                  "because it is non-negative and multiplicative (symmetric on the log scale). ",
                  "Using Mean = ", strong(mu), " and SE = ", strong(round(se, 4)),
                  ", the log-scale parameters were derived: \u03bc<sub>log</sub> = ", strong(round(m, 3)),
                  " and \u03c3<sub>log</sub> = ", strong(round(s, 3)), "."
                ))),
                p(HTML(paste0(
                  icon("info-circle"), " ",
                  "Use ", tags$code(paste0("rlnorm(n, meanlog=", round(m, 3), ", sdlog=", round(s, 3), ")")),
                  " in R. Median of this distribution = e<sup>", round(m, 3), "</sup> = ", strong(round(exp(m), 4)), "."
                )))
            ),
            # Formula
            div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
                h5(icon("square-root-alt"), " Formulas (Method of Moments)", style = "margin-top:0;"),
                p("$$\\sigma^2_{log} = \\ln\\left(1 + \\frac{SE^2}{\\mu^2}\\right)$$"),
                p("$$\\mu_{log} = \\ln(\\mu) - \\frac{\\sigma^2_{log}}{2}$$"),
                p(style = "font-size:0.85em; color:#666;",
                  "These are the parameters of the underlying Normal distribution on the log scale.")
            ),
            # Citation
            div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
                h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
                tags$ol(style = "font-size:0.85em; margin-bottom:0;",
                  tags$li(HTML("Briggs A, et al. <em>Decision Modelling for Health Economic Evaluation</em>. OUP; 2006. Chapter 4.")),
                  tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015."))
                )
            ),
            mathjax_trigger
          ))

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
