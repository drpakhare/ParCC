mod_report_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    column(10, offset = 1,
           div(class = "about-card",
               h3(icon("clipboard-list"), " Session Report (Lab Notebook)"),
               p("Review your parameters before exporting. The report automatically adapts to the tools used."),
               
               div(style="margin-bottom: 15px;",
                   downloadButton(ns("download_html"), "Download HTML Report", class="btn-primary"),
                   downloadButton(ns("download_csv"), "Download CSV Log", class="btn-default"),
                   actionButton(ns("clear_log"), "Clear Log", icon=icon("trash"), class="btn-danger pull-right")
               ),
               
               DT::dataTableOutput(ns("log_table"))
           )
    )
  )
}

mod_report_server <- function(id, logger) {
  moduleServer(id, function(input, output, session) {
    
    # 1. Render Table
    output$log_table <- DT::renderDataTable({
      req(nrow(logger$entries) > 0)
      DT::datatable(logger$entries, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
    })
    
    # 2. Clear Log
    observeEvent(input$clear_log, {
      logger$entries <- data.frame(
        Time = character(), Label = character(), Module = character(), 
        Input = character(), Result = character(), Notes = character(),
        stringsAsFactors = FALSE
      )
      showNotification("Log Cleared", type = "warning")
    })
    
    # 3. CSV Download
    output$download_csv <- downloadHandler(
      filename = function() { paste0("ParCC_Log_", Sys.Date(), ".csv") },
      content = function(file) { write.csv(logger$entries, file, row.names = FALSE) }
    )
    
    # 4. HTML Report (ROBUST VERSION)
    output$download_html <- downloadHandler(
      filename = function() { paste0("ParCC_Report_", Sys.Date(), ".html") },
      content = function(file) {
        
        # --- STEP A: Pre-Calculate Methodology Text in R ---
        # This avoids complex logic inside the Rmd file, preventing Error 64
        
        mods <- unique(logger$entries$Module)
        notes <- unique(logger$entries$Notes)
        meth_text <- "" # Accumulator
        
        add_sect <- function(title, content) {
          paste0("\n\n### ", title, "\n\n", content, "\n\n---\n")
        }
        
        if (any(grepl("Rate->Prob|Prob->Rate", mods))) {
          meth_text <- paste0(meth_text, add_sect("Rate and Probability Conversions", 
                                                  "Transition probabilities ($p$) were derived from instantaneous rates ($r$) over time ($t$) using the exponential formula:\n\n$$p = 1 - e^{-rt}$$\n\n> **Reference:** Sonnenberg FA, Beck JR. *Med Decis Making*. 1993."))
        }
        
        if (any(grepl("Odds->Prob|Prob->Odds", mods))) {
          meth_text <- paste0(meth_text, add_sect("Odds and Probabilities", 
                                                  "Probabilities were derived from Odds ratios using the standard logistic transformation:\n\n$$p = \\frac{Odds}{1 + Odds}$$\n\n> **Reference:** Briggs A, et al. 2006."))
        }
        
        if (any(grepl("Time Rescale", mods))) {
          meth_text <- paste0(meth_text, add_sect("Time Rescaling", 
                                                  "Probabilities were adjusted from an original time ($t_{old}$) to a new cycle ($t_{new}$) assuming constant hazards:\n\n$$p_{new} = 1 - (1 - p_{old})^{\\frac{t_{new}}{t_{old}}}$$\n\n> **Reference:** Fleurence RL, et al. 2007."))
        }
        
        if (any(grepl("Survival", mods))) {
          meth_text <- paste0(meth_text, add_sect("Parametric Survival Analysis", 
                                                  "**Exponential:** Rate $\\lambda$ derived from median survival ($M$): $\\lambda = \\ln(2)/M$.\n\n**Weibull:** Shape ($\\gamma$) and Scale ($\\lambda$) estimated via linear regression of log-log transformation:\n\n$$\\ln(-\\ln(S(t))) = \\ln(\\lambda) + \\gamma \\ln(t)$$\n\n> **Reference:** Collett D. 2015."))
        }
        
        if (any(grepl("PSA", mods))) {
          extra_note <- if(any(grepl("Rule of 4", notes))) "(SE approximated via Rule of 4 where missing)" else ""
          meth_text <- paste0(meth_text, add_sect("Probabilistic Sensitivity Analysis", 
                                                  paste0("Distribution parameters fitted using **Method of Moments** ", extra_note, ".\n\n* **Beta:** $\\alpha = \\mu [(\\mu(1-\\mu)/SE^2) - 1]$\n* **Gamma:** $k = \\mu^2/SE^2, \\theta = SE^2/\\mu$\n\n> **Reference:** Briggs A, et al. 2006.")))
        }
        
        if (any(grepl("Bg Mortality|DEALE", mods))) {
          meth_text <- paste0(meth_text, add_sect("Mortality Adjustments", 
                                                  "Adjustments included **SMR application** ($r_{adj} = r_{pop} \\times SMR$), **Gompertz fitting**, or **DEALE** (Excess Rate = $1/LE_{obs} - 1/LE_{bg}$).\n\n> **Reference:** Beck JR, et al. 1982."))
        }
        
        if (any(grepl("ICER|Value-Based Pricing", mods))) {
          meth_text <- paste0(meth_text, add_sect("Economic Results", 
                                                  "**iNMB:** $(\\Delta E \\times WTP) - \\Delta C$. Cost-Effective if $>0$.\n\n**Value-Based Price ($P_{max}$):** Calculated via Headroom method:\n\n$$P_{max} = \\frac{(\\Delta E \\times WTP) + C_{comparator} - C_a}{N}$$\n\n> **Reference:** Cosh E, et al. 2007."))
        }
        
        if (meth_text == "") meth_text <- "No specific methodology modules recorded."
        
        # --- STEP B: Write Simple Rmd Container ---
        # This Rmd does NO calculation. It just prints the strings we prepared above.
        
        tempReport <- file.path(tempdir(), "report.Rmd")
        
        rmd_header <- paste0(
          "---\n",
          "title: 'ParCC Analysis Report'\n",
          "date: '", format(Sys.time(), "%d %B %Y"), "'\n",
          "params:\n",
          "  table_data: NA\n",
          "  method_text: NA\n",
          "output: \n",
          "  html_document:\n",
          "    theme: flatly\n",
          "    highlight: tango\n",
          "---\n"
        )
        
        rmd_body <- "
# 1. Calculation Log

```{r, echo=FALSE}
library(knitr)
kable(params$table_data, format = 'html', table.attr = 'class=\"table table-striped\"', row.names=FALSE)
```

# 2. Applied Methodology

```{r, echo=FALSE, results='asis'}
cat(params$method_text)
```

<br><hr>
<center><small>Generated by ParCC (RRC-HTA, AIIMS Bhopal)</small></center>
"
        # Write file
        writeLines(paste0(rmd_header, rmd_body), tempReport, useBytes = TRUE)
        
        # --- STEP C: Render ---
        # Pass the pre-calculated text string into the params
        rmarkdown::render(tempReport, output_file = file,
                          params = list(
                            table_data = logger$entries,
                            method_text = meth_text
                          ),
                          envir = new.env(parent = globalenv()))
      }
    )
  })
}