#' @import shiny
#' @import shinythemes
#' @importFrom plotly plotlyOutput
app_ui <- function() {

  # Custom CSS
  custom_css <- tags$head(
    tags$style(HTML("
      body { background-color: #f4f6f9; }
      .navbar-default { background-color: #003366 !important; border: none; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
      .navbar-default .navbar-brand { color: #fff !important; font-weight: 700; font-size: 1.3em; }
      .navbar-default .navbar-nav > li > a { color: #e0e0e0 !important; }
      .navbar-default .navbar-nav > .active > a { background-color: #004080 !important; color: #fff !important; border-bottom: 3px solid #00d2d3; }
      .navbar-default .navbar-nav > .open > a { background-color: #004080 !important; color: #fff !important; }
      .dropdown-menu { background-color: #003d73; border: none; box-shadow: 0 4px 12px rgba(0,0,0,0.2); }
      .dropdown-menu > li > a { color: #e0e0e0 !important; padding: 8px 20px; }
      .dropdown-menu > li > a:hover { background-color: #00509e !important; color: #fff !important; }
      .dropdown-menu > .active > a { background-color: #004080 !important; color: #fff !important; }
      .about-header { background: linear-gradient(135deg, #003366 0%, #0056b3 100%); color: white; padding: 40px; border-radius: 8px; margin-bottom: 30px; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
      .about-card { background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); margin-bottom: 20px; border-top: 4px solid #003366; }
      .result-box { background-color: #fff; border-left: 5px solid #0056b3; padding: 20px; margin-top: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.05); border-radius: 0 4px 4px 0; }
      .result-value { color: #2c3e50; font-size: 1.4em; font-weight: 700; display: block; margin-top: 5px; }
      .result-label { color: #7f8c8d; font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; }
      .plot-container { border: 1px solid #ddd; background: #fff; padding: 10px; margin-top: 20px; border-radius: 4px; }
      .use-case-box { border-left: 4px solid #28a745; background-color: #f1f8f3; padding: 15px; margin-bottom: 15px; border-radius: 0 4px 4px 0; }
      .use-case-title { font-weight: bold; color: #155724; display: block; margin-bottom: 5px; }
      .btn-primary { background-color: #0056b3; border-color: #004494; }
      .btn-primary:hover { background-color: #004494; }
      .settings-currency { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; max-width: 400px; }
      .settings-currency .form-group { margin-bottom: 8px; }
    "))
  )

  navbarPage(
    title = "ParCC v1.4",
    theme = shinytheme("flatly"),
    id = "main_nav",
    header = list(custom_css, withMathJax()),

    # 1 -- Home ------------------------------------------------
    tabPanel("Home", mod_home_ui("home_1"), icon = icon("home")),

    # 2 -- Convert ---------------------------------------------
    navbarMenu("Convert",
      icon = icon("exchange-alt"),
      tabPanel("Rate \u2194 Probability", mod_core_conv_ui("core_1")),
      tabPanel("HR \u2192 Probability & NNT", mod_hr_converter_ui("hr_1")),
      tabPanel("Bulk CSV Upload", mod_batch_ui("batch_1"))
    ),

    # 3 -- Survival Curves -------------------------------------
    navbarMenu("Survival Curves",
      icon = icon("heartbeat"),
      tabPanel("Fit Survival Curve", mod_survival_ui("surv_1")),
      tabPanel("Adjust Background Mortality", mod_lifetable_ui("life_1"))
    ),

    # 4 -- Uncertainty (PSA) -----------------------------------
    tabPanel("Uncertainty (PSA)", mod_psa_ui("psa_1"), icon = icon("chart-area")),

    # 5 -- Costs & Outcomes ------------------------------------
    navbarMenu("Costs & Outcomes",
      icon = icon("calculator"),
      tabPanel("Inflate & Discount Costs", mod_financial_ui("fin_1")),
      tabPanel("Calculate ICER & NMB", mod_icer_ui("icer_1")),
      tabPanel("Value-Based Pricing", mod_vbp_ui("vbp_1")),
      tabPanel("Budget Impact Analysis", mod_bia_ui("bia_1"))
    ),

    # 6 -- PPP Currency Converter -----------------------------
    tabPanel("PPP Converter", mod_ppp_ui("ppp_1"), icon = icon("globe-americas")),

    # 7 -- Diagnostics -----------------------------------------
    tabPanel("Diagnostics", mod_diagnostic_ui("diag_1"), icon = icon("microscope")),

    # 8 -- Lab Notebook ----------------------------------------
    tabPanel("Lab Notebook", mod_report_ui("rep_1"), icon = icon("clipboard")),

    # 9 -- Learn -----------------------------------------------
    navbarMenu("Learn",
      icon = icon("graduation-cap"),
      tabPanel("Tutorials", mod_howtouse_ui("help_1")),
      tabPanel("Formula Reference", mod_formulae_ui("form_1"))
    ),

    # 10 -- Settings (gear icon) -------------------------------
    tabPanel(
      title = span(icon("cog")),
      value = "settings_tab",
      fluidPage(
        column(8, offset = 2,
          div(class = "about-header", style = "padding: 20px;",
              h2(icon("cog"), " Settings"),
              p("Configure ParCC preferences")
          ),
          div(class = "about-card",
            h4(icon("globe"), " Currency"),
            p("Select the currency symbol used across Financial, ICER, VBP, and Budget Impact modules."),
            div(class = "settings-currency",
              selectInput("global_currency", label = "Display Currency", width = "200px",
                          choices = c("\u20b9 INR (Indian Rupee)" = "INR",
                                      "$ USD (US Dollar)" = "USD",
                                      "\u20ac EUR (Euro)" = "EUR",
                                      "\u00a3 GBP (British Pound)" = "GBP",
                                      "\u00a5 JPY (Japanese Yen)" = "JPY",
                                      "R$ BRL (Brazilian Real)" = "BRL",
                                      "\u0e3f THB (Thai Baht)" = "THB",
                                      "A$ AUD (Australian Dollar)" = "AUD",
                                      "C$ CAD (Canadian Dollar)" = "CAD",
                                      "Custom" = "CUSTOM"),
                          selected = "INR"),
              conditionalPanel(condition = "input.global_currency == 'CUSTOM'",
                textInput("custom_currency_symbol", label = "Custom Symbol", value = "", placeholder = "e.g. CHF", width = "120px")
              )
            ),
            p(class = "text-muted", style = "margin-top: 10px; font-size: 0.85em;",
              icon("info-circle"), " Currency affects display only. No exchange rate conversion is applied.")
          ),
          div(class = "about-card",
            h4(icon("info-circle"), " About ParCC"),
            mod_about_ui("about_1")
          )
        )
      )
    )
  )
}
