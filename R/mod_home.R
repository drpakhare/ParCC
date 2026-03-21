#' @import shiny
mod_home_ui <- function(id) {
  ns <- NS(id)

  # -- Accordion CSS & JS ------------------------------------------------------
  accordion_assets <- tags$head(tags$style(HTML("
    .tool-accordion { max-width: 800px; margin: 0 auto; }
    .tool-section {
      border: 1px solid #dee2e6; border-radius: 6px; margin-bottom: 8px;
      overflow: hidden; background: #fff; transition: box-shadow 0.2s;
    }
    .tool-section:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    .tool-section-header {
      display: flex; align-items: center; justify-content: space-between;
      padding: 12px 18px; cursor: pointer; user-select: none;
      background: linear-gradient(135deg, #003366 0%, #004d99 100%);
      color: #fff; font-weight: 600; font-size: 1.05em;
    }
    .tool-section-header:hover { background: linear-gradient(135deg, #004080 0%, #0059b3 100%); }
    .tool-section-header .section-icon { margin-right: 10px; width: 20px; text-align: center; }
    .tool-section-header .tool-count {
      background: rgba(255,255,255,0.2); padding: 2px 10px; border-radius: 12px;
      font-size: 0.8em; font-weight: 400;
    }
    .tool-section-header .chevron {
      transition: transform 0.25s ease; font-size: 0.85em; margin-left: 12px;
    }
    .tool-section.open .chevron { transform: rotate(90deg); }
    .tool-section-body {
      max-height: 0; overflow: hidden; transition: max-height 0.3s ease;
      padding: 0 18px;
    }
    .tool-section.open .tool-section-body { max-height: 800px; padding: 12px 18px 16px; }
    .tool-item {
      display: flex; align-items: baseline; padding: 7px 4px;
      border-bottom: 1px solid #f0f0f0; font-size: 0.95em;
      cursor: pointer; border-radius: 4px; transition: background 0.15s;
    }
    .tool-item:hover { background: #e8f4fd; }
    .tool-item:last-child { border-bottom: none; }
    .tool-item .tool-name { font-weight: 600; color: #0056b3; min-width: 180px; }
    .tool-item .tool-desc { color: #666; font-size: 0.9em; flex: 1; }
    .tool-item .tool-go {
      color: #0056b3; font-size: 0.8em; opacity: 0; transition: opacity 0.15s;
      margin-left: 8px; white-space: nowrap;
    }
    .tool-item:hover .tool-go { opacity: 1; }
    .tool-item .badge-new {
      background: #28a745; color: #fff; font-size: 0.7em; padding: 1px 6px;
      border-radius: 3px; margin-left: 6px; font-weight: 700; vertical-align: middle;
    }
  ")),
  tags$script(HTML(paste0("
    $(document).on('click', '.tool-section-header', function() {
      $(this).closest('.tool-section').toggleClass('open');
    });
    $(document).on('click', '.tool-item[data-tab]', function() {
      var tab = $(this).data('tab');
      if (tab) {
        Shiny.setInputValue('", ns("nav_to"), "', tab, {priority: 'event'});
      }
    });
  "))))

  # -- Helper to build one accordion section ----------------------------------
  # tab = navbar tab name to navigate to on click (NULL = no navigation)
  make_section <- function(title, icon_name, tools) {
    n <- length(tools)
    tool_items <- lapply(tools, function(t) {
      badge <- if (!is.null(t$new) && t$new) span(class = "badge-new", "NEW") else NULL
      go_arrow <- if (!is.null(t$tab)) span(class = "tool-go", icon("arrow-right"), " Open") else NULL
      div(class = "tool-item",
        `data-tab` = if (!is.null(t$tab)) t$tab else NULL,
        span(class = "tool-name", t$name, badge),
        span(class = "tool-desc", t$desc),
        go_arrow
      )
    })
    div(class = "tool-section",
      div(class = "tool-section-header",
        span(span(class = "section-icon", icon(icon_name)), title),
        span(span(class = "tool-count", paste0(n, " tool", if(n != 1) "s")),
             span(class = "chevron", icon("chevron-right")))
      ),
      div(class = "tool-section-body", tool_items)
    )
  }

  # -- Tool data with navigation targets --------------------------------------
  # tab values must match the tabPanel titles in app_ui.R exactly
  sec_convert <- make_section("Convert", "exchange-alt", list(
    list(name = "Rate \u2194 Probability",    desc = "Instantaneous rate to/from time-bound probability",          tab = "Rate \u2194 Probability"),
    list(name = "Odds \u2194 Probability",    desc = "Odds to/from probability",                                    tab = "Rate \u2194 Probability"),
    list(name = "Time Rescaling",              desc = "Rescale probability from one time horizon to another",        tab = "Rate \u2194 Probability"),
    list(name = "OR \u2194 RR",               desc = "Odds Ratio to Relative Risk via baseline risk (Zhang & Yu)",  tab = "Rate \u2194 Probability", new = TRUE),
    list(name = "Effect Size Conversions",     desc = "SMD \u2194 log(OR) \u2194 log(RR) for NMA (Chinn 2000)",     tab = "Rate \u2194 Probability", new = TRUE),
    list(name = "HR \u2192 Probability",       desc = "Apply Hazard Ratio to control probability for model input",  tab = "HR \u2192 Probability & NNT"),
    list(name = "Multi-HR Comparison",         desc = "Compare multiple interventions side-by-side via HRs",        tab = "HR \u2192 Probability & NNT"),
    list(name = "NNT / NNH Calculator",        desc = "Number Needed to Treat from ARR, RR, or OR + baseline",     tab = "HR \u2192 Probability & NNT", new = TRUE),
    list(name = "Log-rank \u2192 HR",          desc = "Estimate HR from chi\u00b2 or p-value + events (Peto)",      tab = "HR \u2192 Probability & NNT", new = TRUE),
    list(name = "Bulk CSV Upload",             desc = "Batch convert rates, odds, or HRs from uploaded CSV",        tab = "Bulk CSV Upload")
  ))

  sec_survival <- make_section("Survival Curves", "heartbeat", list(
    list(name = "Exponential",           desc = "Constant hazard model from median survival",                      tab = "Fit Survival Curve"),
    list(name = "Weibull",               desc = "Monotonic hazard model from two KM time-points",                  tab = "Fit Survival Curve"),
    list(name = "Log-Logistic",          desc = "Non-monotonic (hump-shaped) hazard from two KM time-points",      tab = "Fit Survival Curve", new = TRUE),
    list(name = "SMR Adjustment",        desc = "Apply Standardised Mortality Ratio to census life table",         tab = "Adjust Background Mortality"),
    list(name = "Linear Interpolation",  desc = "Interpolate between published age-specific rates",                tab = "Adjust Background Mortality"),
    list(name = "Gompertz Fit",          desc = "Exponential-growth mortality model from two age-rate pairs",      tab = "Adjust Background Mortality"),
    list(name = "DEALE",                 desc = "Declining Exponential Approximation of Life Expectancy",          tab = "Adjust Background Mortality")
  ))

  sec_psa <- make_section("Uncertainty (PSA)", "chart-area", list(
    list(name = "Beta Distribution",      desc = "For probabilities and utilities (bounded 0\u20131)",             tab = "Uncertainty (PSA)"),
    list(name = "Gamma Distribution",     desc = "For costs and resource use (positive, right-skewed)",            tab = "Uncertainty (PSA)"),
    list(name = "LogNormal Distribution", desc = "For hazard ratios and relative risks",                           tab = "Uncertainty (PSA)"),
    list(name = "Dirichlet Distribution", desc = "For multinomial transition probabilities (row-sum = 1)",         tab = "Uncertainty (PSA)", new = TRUE)
  ))

  sec_costs <- make_section("Costs & Outcomes", "calculator", list(
    list(name = "Inflate & Discount Costs", desc = "CPI-based inflation adjustment and present-value discounting", tab = "Inflate & Discount Costs"),
    list(name = "Annuity / PV Stream",      desc = "Present value of recurring annual costs (ordinary & due)",     tab = "Inflate & Discount Costs", new = TRUE),
    list(name = "Calculate ICER & NMB",     desc = "Incremental cost-effectiveness ratio and net monetary benefit",tab = "Calculate ICER & NMB"),
    list(name = "Value-Based Pricing",      desc = "Maximum justifiable price via innovation headroom method",     tab = "Value-Based Pricing"),
    list(name = "Budget Impact Analysis",   desc = "5-year BIA with population uptake curves (ISPOR framework)",   tab = "Budget Impact Analysis", new = TRUE)
  ))

  sec_ppp <- make_section("PPP Converter", "globe-americas", list(
    list(name = "PPP Currency Conversion",  desc = "Convert costs across 30 countries using World Bank PPP factors", tab = "PPP Converter", new = TRUE),
    list(name = "Market FX Comparison",     desc = "Side-by-side PPP vs market exchange rate",                       tab = "PPP Converter", new = TRUE),
    list(name = "WTP Threshold Assessment", desc = "Auto-assess against 1\u00d7 and 3\u00d7 GDP/capita (WHO-CHOICE)",tab = "PPP Converter", new = TRUE)
  ))

  sec_diag <- make_section("Diagnostics", "microscope", list(
    list(name = "PPV / NPV Calculator",  desc = "Positive & negative predictive values from Se, Sp, prevalence",  tab = "Diagnostics")
  ))

  sec_notebook <- make_section("Lab Notebook", "clipboard", list(
    list(name = "Session Log",       desc = "Every calculation is timestamped and logged automatically",          tab = "Lab Notebook"),
    list(name = "HTML Report Export", desc = "Download your full session as a reproducibility appendix",           tab = "Lab Notebook")
  ))

  # -- Page layout ------------------------------------------------------------
  fluidPage(
    accordion_assets,
    fluidRow(
      column(12,
             div(class = "about-header",
                 h1("ParCC v1.4", style = "font-weight: 700;"),
                 p("Parameter Converter & Calculator for Health Economic Evaluation", style = "font-size: 1.2em; opacity: 0.9;"),
                 p(style="font-size: 0.9em; margin-top: 10px;", "R Package Edition | RRC-HTA, AIIMS Bhopal")
             )
      )
    ),
    fluidRow(
      column(10, offset = 1,

             # Tool Overview (Accordion) - FIRST
             div(class = "about-card",
                 h4(icon("sitemap"), " Tool Overview", style = "color: #003366; text-align: center; margin-bottom: 5px;"),
                 p(style = "text-align: center; color: #888; font-size: 0.9em; margin-bottom: 15px;",
                   "Click any section to expand, then click a tool to open it. ",
                   span(style = "background: #28a745; color: #fff; font-size: 0.75em; padding: 1px 5px; border-radius: 3px;", "NEW"),
                   " = added in v1.4."),
                 div(class = "tool-accordion",
                   sec_convert,
                   sec_survival,
                   sec_psa,
                   sec_costs,
                   sec_ppp,
                   sec_diag,
                   sec_notebook
                 )
             ),

             # What's New - SECOND
             div(class = "about-card", style = "border-top: 4px solid #28a745;",
                 h4(icon("star"), " What's New in v1.4", style = "color: #155724;"),
                 tags$ul(
                   tags$li(HTML(paste0(strong("Global Currency Selector"), " \u2014 Switch between INR, USD, EUR, GBP, and other currencies. All economic modules update automatically."))),
                   tags$li(HTML(paste0(strong("OR \u2194 RR Converter"), " \u2014 Convert between Odds Ratios and Relative Risks using baseline risk (Zhang & Yu method)."))),
                   tags$li(HTML(paste0(strong("Effect Size Conversions"), " \u2014 Convert between SMD, log(OR), and log(RR) for network meta-analysis."))),
                   tags$li(HTML(paste0(strong("Standalone NNT/NNH"), " \u2014 Calculate Number Needed to Treat from ARR, RR, or OR with baseline risk."))),
                   tags$li(HTML(paste0(strong("Log-rank \u2192 HR"), " \u2014 Estimate Hazard Ratios from published log-rank statistics (Peto method)."))),
                   tags$li(HTML(paste0(strong("Dirichlet Distribution"), " \u2014 Fit Dirichlet parameters for multinomial transition probabilities in PSA."))),
                   tags$li(HTML(paste0(strong("Log-Logistic Survival"), " \u2014 Third survival distribution with non-monotonic hazard support."))),
                   tags$li(HTML(paste0(strong("Annuity / PV Stream"), " \u2014 Present value of recurring annual costs (ordinary annuity and annuity due)."))),
                   tags$li(HTML(paste0(strong("Budget Impact Analysis"), " \u2014 5-year BIA framework with population uptake curves and discounting."))),
                   tags$li(HTML(paste0(strong("PPP Currency Converter"), " \u2014 Purchasing Power Parity conversion across 30 countries with WHO-CHOICE WTP threshold assessment.")))
                 )
             ),

             # Quick Start
             div(style = "text-align: center; background-color: #e9ecef; padding: 20px; border-radius: 8px; border-top: 4px solid #17a2b8; margin-bottom: 30px;",
                 h4("Start Your Analysis"),
                 p("Click any tool above, or jump straight in:"),
                 actionButton(ns("go_converters"), "Go to Convert", class = "btn-primary btn-lg", icon = icon("arrow-right"))
             )
      )
    )
  )
}

mod_home_server <- function(id, parent_session) {
  moduleServer(id, function(input, output, session) {
    # Quick start button
    observeEvent(input$go_converters, {
      updateNavbarPage(parent_session, "main_nav", selected = "Rate \u2194 Probability")
    })

    # Accordion tool item click -> navigate to tab
    observeEvent(input$nav_to, {
      updateNavbarPage(parent_session, "main_nav", selected = input$nav_to)
    })
  })
}
