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
        
        if (any(grepl("HR Conversion", mods))) {
          meth_text <- paste0(meth_text, add_sect("Hazard Ratio-Based Probability Conversion",
                                                  "Intervention probabilities were derived from control group probabilities using published Hazard Ratios under the proportional hazards assumption:\n\n1. $r_{control} = -\\ln(1 - p_{control}) / t$\n2. $r_{intervention} = r_{control} \\times HR$\n3. $p_{intervention} = 1 - e^{-r_{intervention} \\times t_{cycle}}$\n\n> **References:** Sonnenberg FA, Beck JR. *Med Decis Making*. 1993; Briggs A, et al. OUP. 2006; NICE DSU TSD 14. 2013."))
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

        if (any(grepl("Diagnostics", mods))) {
          meth_text <- paste0(meth_text, add_sect("Diagnostic Test Accuracy",
                                                  "Predictive values were calculated using **Bayes' Theorem**:\n\n$$PPV = \\frac{Se \\times Prev}{Se \\times Prev + (1-Sp)(1-Prev)}$$\n\n$$NPV = \\frac{Sp \\times (1-Prev)}{Sp(1-Prev) + (1-Se) \\times Prev}$$\n\nLikelihood ratios: $LR+ = Se/(1-Sp)$, $LR- = (1-Se)/Sp$.\n\n> **References:** Altman DG, Bland JM. *BMJ*. 1994; Deeks JJ, Altman DG. *BMJ*. 2004."))
        }

        if (any(grepl("Inflation", mods))) {
          meth_text <- paste0(meth_text, add_sect("Cost Inflation",
                                                  "Costs were inflated to a common price year using either:\n\n* **Compound rate:** $Cost_{target} = Cost_{base} \\times (1+r)^n$\n* **CPI ratio:** $Cost_{target} = Cost_{base} \\times CPI_{target}/CPI_{base}$\n\n> **Reference:** Drummond MF, et al. *Methods for the Economic Evaluation of Health Care Programmes*. 4th ed. OUP; 2015."))
        }

        if (any(grepl("Discounting|Annuity", mods))) {
          meth_text <- paste0(meth_text, add_sect("Discounting",
                                                  "Future values were discounted to present value:\n\n$$PV = \\frac{FV}{(1+r)^t}$$\n\nFor recurring costs, the **annuity formula** was applied: $PV = C \\times [1-(1+r)^{-n}]/r$.\n\n> **Reference:** Drummond MF, et al. OUP; 2015."))
        }

        if (any(grepl("OR->RR|RR->OR", mods))) {
          meth_text <- paste0(meth_text, add_sect("OR-RR Conversion",
                                                  "Odds Ratios and Relative Risks were converted using the Zhang & Yu method:\n\n$$RR = \\frac{OR}{1 - p_0 + p_0 \\times OR}$$\n\nwhere $p_0$ is the baseline risk in the control group.\n\n> **Reference:** Zhang J, Yu KF. *JAMA*. 1998;280(19):1690-1691."))
        }

        if (any(grepl("SMD->logOR|logOR->SMD|logOR->logRR", mods))) {
          meth_text <- paste0(meth_text, add_sect("Effect Size Conversions",
                                                  "Standardised Mean Differences were converted to log Odds Ratios using the Chinn formula:\n\n$$\\ln(OR) = SMD \\times \\frac{\\pi}{\\sqrt{3}}$$\n\n> **Reference:** Chinn S. *Stat Med*. 2000;19(22):3127-3131."))
        }

        if (any(grepl("NNT|NNH", mods))) {
          meth_text <- paste0(meth_text, add_sect("Number Needed to Treat",
                                                  "NNT was calculated as the ceiling of $1/ARR$, where $ARR = p_{control} - p_{intervention}$.\n\n> **Reference:** Laupacis A, et al. *NEJM*. 1988;318(26):1728-1733."))
        }

        if (any(grepl("Log-rank", mods))) {
          meth_text <- paste0(meth_text, add_sect("Log-rank to Hazard Ratio",
                                                  "Hazard Ratios were estimated from log-rank statistics using the Peto approximation:\n\n$$\\ln(HR) = \\pm \\frac{\\sqrt{\\chi^2}}{\\sqrt{E/4}}$$\n\nwhere $E$ = total events across both arms.\n\n> **Reference:** Tierney JF, et al. *Trials*. 2007;8:16."))
        }

        if (any(grepl("Budget Impact", mods))) {
          meth_text <- paste0(meth_text, add_sect("Budget Impact Analysis",
                                                  "Budget impact was estimated using the ISPOR framework:\n\n$$BI_t = N_{target} \\times Uptake_t \\times (C_{new} - C_{current}) \\times \\frac{1}{(1+r)^t}$$\n\n> **Reference:** Sullivan SD, et al. *Value Health*. 2014;17(1):5-14."))
        }

        if (any(grepl("PPP Converter", mods))) {
          meth_text <- paste0(meth_text, add_sect("PPP Currency Conversion",
                                                  "Costs were converted between countries using Purchasing Power Parity factors:\n\n$$Cost_{target} = Cost_{source} \\times PPP_{target} / PPP_{source}$$\n\nPPP factors from the World Bank International Comparison Program (ICP) 2022.\n\n> **Reference:** World Bank ICP 2022; WHO-CHOICE cost-effectiveness thresholds."))
        }

        if (any(grepl("Dirichlet", mods))) {
          meth_text <- paste0(meth_text, add_sect("Dirichlet Distribution",
                                                  "Multinomial transition probabilities were fitted using the **Dirichlet distribution** with $\\alpha_i$ = observed counts. Sampling via Gamma decomposition ensures row sums equal 1.\n\n> **Reference:** Briggs A, et al. OUP; 2006."))
        }

        if (meth_text == "") meth_text <- "No specific methodology modules recorded."
        
        # --- STEP B: Write Simple Rmd Container ---
        # This Rmd does NO calculation. It just prints the strings we prepared above.

        tempReport <- file.path(tempdir(), "report.Rmd")

        # Get package version for report stamp
        pkg_version <- tryCatch(
          as.character(utils::packageVersion("ParCC")),
          error = function(e) "1.4.0"
        )

        rmd_header <- paste0(
          "---\n",
          "title: 'ParCC v", pkg_version, " Analysis Report'\n",
          "date: '", format(Sys.time(), "%d %B %Y"), "'\n",
          "params:\n",
          "  table_data: NA\n",
          "  method_text: NA\n",
          "  pkg_version: NA\n",
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
<center><small>Generated by ParCC v`r params$pkg_version` (RRC-HTA, AIIMS Bhopal)</small></center>
"
        # Write file
        writeLines(paste0(rmd_header, rmd_body), tempReport, useBytes = TRUE)
        
        # --- STEP C: Render ---
        # Pass the pre-calculated text string into the params
        rmarkdown::render(tempReport, output_file = file,
                          params = list(
                            table_data = logger$entries,
                            method_text = meth_text,
                            pkg_version = pkg_version
                          ),
                          envir = new.env(parent = globalenv()))
      }
    )
  })
}