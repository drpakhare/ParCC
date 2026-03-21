mod_diagnostic_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Bayes' Theorem"),
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

    observeEvent(input$calc, {
      se <- input$sens/100; sp <- input$spec/100; p <- input$prev/100

      ppv <- (se * p) / (se * p + (1 - sp) * (1 - p))
      npv <- (sp * (1 - p)) / (sp * (1 - p) + (1 - se) * p)

      # Pre-test odds and likelihood ratios
      lr_pos <- se / (1 - sp)
      lr_neg <- (1 - se) / sp
      pre_odds <- p / (1 - p)
      post_odds_pos <- pre_odds * lr_pos

      output$res <- renderUI(tagList(
        # Result
        div(class = "result-box", HTML(paste0(
          "<span class='result-label'>Predictive Values</span><br>",
          "<span class='result-value'>PPV = ", round(ppv * 100, 1), "%</span>",
          "<span class='result-value'>NPV = ", round(npv * 100, 1), "%</span>",
          "<br><small>LR+ = ", round(lr_pos, 2), " | LR- = ", round(lr_neg, 3), "</small>"
        ))),
        # Explanation
        div(style = "background:#f8f9fa; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
            p(HTML(paste0(
              "With Sensitivity = ", strong(paste0(input$sens, "%")),
              ", Specificity = ", strong(paste0(input$spec, "%")),
              ", and Prevalence = ", strong(paste0(input$prev, "%")), ":"
            ))),
            tags$ul(
              tags$li(HTML(paste0(
                strong("PPV (", round(ppv * 100, 1), "%):"),
                " If this test is positive, there is a ", round(ppv * 100, 1),
                "% chance the patient truly has the condition. ",
                "Out of every 1,000 people tested, approximately ",
                round(se * p * 1000), " true positives and ",
                round((1 - sp) * (1 - p) * 1000), " false positives are expected."
              ))),
              tags$li(HTML(paste0(
                strong("NPV (", round(npv * 100, 1), "%):"),
                " If this test is negative, there is a ", round(npv * 100, 1),
                "% chance the patient is truly disease-free."
              )))
            ),
            p(HTML(paste0(
              icon("info-circle"), " ",
              "The plot below shows that PPV changes dramatically with prevalence. ",
              "At low prevalence (e.g., screening), even a highly specific test produces many false positives. ",
              "At the current prevalence of ", input$prev, "%, the pre-test odds are ",
              round(pre_odds, 3), " and the post-test odds (if positive) are ", round(post_odds_pos, 3), "."
            )))
        ),
        # Formula
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
            h5(icon("square-root-alt"), " Formulas (Bayes' Theorem)", style = "margin-top:0;"),
            p("$$PPV = \\frac{Se \\times Prev}{Se \\times Prev + (1 - Sp) \\times (1 - Prev)}$$"),
            p("$$NPV = \\frac{Sp \\times (1 - Prev)}{Sp \\times (1 - Prev) + (1 - Se) \\times Prev}$$"),
            p("$$LR+ = \\frac{Se}{1 - Sp} \\qquad LR- = \\frac{1 - Se}{Sp}$$"),
            p(style = "font-size:0.85em; color:#666;",
              "Se = Sensitivity, Sp = Specificity, Prev = Prevalence. ",
              "PPV and NPV depend on prevalence; Sensitivity and Specificity do not.")
        ),
        # Citation
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
            h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
            tags$ol(style = "font-size:0.85em; margin-bottom:0;",
              tags$li(HTML("Altman DG, Bland JM. Diagnostic tests 2: Predictive values. <em>BMJ</em>. 1994;309(6947):102.")),
              tags$li(HTML("Deeks JJ, Altman DG. Diagnostic tests 4: likelihood ratios. <em>BMJ</em>. 2004;329(7458):168-169.")),
              tags$li(HTML("Drummond MF, et al. <em>Methods for the Economic Evaluation of Health Care Programmes</em>. 4th ed. OUP; 2015."))
            )
        ),
        mathjax_trigger
      ))

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
