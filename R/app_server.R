#' @import shiny
#' @import ggplot2
#' @importFrom plotly renderPlotly
#' @importFrom DT renderDataTable
#' @importFrom DiagrammeR renderGrViz
#' @importFrom magrittr %>%
app_server <- function(input, output, session) {
  
  # Global Logging State
  global_logger <- reactiveValues(
    entries = data.frame(
      Time = character(), 
      Label = character(), 
      Module = character(), 
      Input = character(), 
      Result = character(), 
      Notes = character(),
      stringsAsFactors = FALSE
    )
  )
  
  # Call Modules
  mod_home_server("home_1", parent_session = session)
  
  # Parameter Estimation Modules
  mod_core_conv_server("core_1", logger = global_logger)
  mod_batch_server("batch_1") 
  mod_survival_server("surv_1", logger = global_logger)
  mod_lifetable_server("life_1", logger = global_logger)
  mod_psa_server("psa_1", logger = global_logger)
  mod_financial_server("fin_1", logger = global_logger)
  mod_diagnostic_server("diag_1", logger = global_logger)
  
  # Results & Pricing Modules
  mod_icer_server("icer_1", logger = global_logger)
  mod_vbp_server("vbp_1", logger = global_logger)
  
  # Reporting Module
  mod_report_server("rep_1", logger = global_logger)
}
