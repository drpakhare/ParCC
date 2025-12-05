#' @import shiny
#' @import shinythemes
#' @importFrom plotly plotlyOutput
#' @importFrom DT dataTableOutput
#' @importFrom DiagrammeR grVizOutput
app_ui <- function() {
  
  # Custom CSS
  custom_css <- tags$head(
    tags$style(HTML("
      body { background-color: #f4f6f9; }
      .navbar-default { background-color: #003366 !important; border: none; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
      .navbar-default .navbar-brand { color: #fff !important; font-weight: 700; }
      .navbar-default .navbar-nav > li > a { color: #e0e0e0 !important; }
      .navbar-default .navbar-nav > .active > a { background-color: #004080 !important; color: #fff !important; border-bottom: 3px solid #00d2d3; }
      .about-header { background: linear-gradient(135deg, #003366 0%, #0056b3 100%); color: white; padding: 40px; border-radius: 8px; margin-bottom: 30px; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
      .about-card { background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); margin-bottom: 20px; border-top: 4px solid #003366; }
      .result-box { background-color: #fff; border-left: 5px solid #0056b3; padding: 20px; margin-top: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
      .result-value { color: #2c3e50; font-size: 1.4em; font-weight: 700; display: block; margin-top: 5px; }
      .result-label { color: #7f8c8d; font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; }
      .plot-container { border: 1px solid #ddd; background: #fff; padding: 10px; margin-top: 20px; border-radius: 4px; }
      .use-case-box { border-left: 4px solid #28a745; background-color: #f1f8f3; padding: 15px; margin-bottom: 15px; border-radius: 0 4px 4px 0; }
      .use-case-title { font-weight: bold; color: #155724; display: block; margin-bottom: 5px; }
      .btn-primary { background-color: #0056b3; border-color: #004494; }
    "))
  )
  
  navbarPage(
    title = "ParCC v1.2",
    theme = shinytheme("flatly"),
    id = "main_nav",
    header = list(custom_css, withMathJax()),
    
    tabPanel("Home", mod_home_ui("home_1")),
    tabPanel("How to Use", mod_howtouse_ui("help_1")),
    
    # Calculation Tools
    tabPanel("Converters", mod_core_conv_ui("core_1")),
    tabPanel("Bulk Conversion", mod_batch_ui("batch_1")),
    tabPanel("Survival", mod_survival_ui("surv_1")),
    tabPanel("Bg Mortality", mod_lifetable_ui("life_1")),
    tabPanel("PSA", mod_psa_ui("psa_1")),
    tabPanel("Financial", mod_financial_ui("fin_1")),
    tabPanel("Diagnostics", mod_diagnostic_ui("diag_1")),
    
    # Results & Pricing
    tabPanel("ICER & NMB", mod_icer_ui("icer_1")),
    tabPanel("Value-Based Pricing", mod_vbp_ui("vbp_1")),
    
    # Documentation
    tabPanel("Report", mod_report_ui("rep_1")),
    tabPanel("Formulae", mod_formulae_ui("form_1")),
    tabPanel("About", mod_about_ui("about_1"))
  )
}