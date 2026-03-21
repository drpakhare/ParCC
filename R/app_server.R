#' @import shiny
#' @import ggplot2
#' @importFrom plotly renderPlotly
#' @importFrom magrittr %>%
app_server <- function(input, output, session) {

  # -- Global Currency Reactive --------------------------------------
  currency_symbol_map <- c(
    INR = "\u20b9", USD = "$", EUR = "\u20ac", GBP = "\u00a3",
    JPY = "\u00a5", BRL = "R$", THB = "\u0e3f", AUD = "A$", CAD = "C$"
  )

  currency <- reactiveValues(code = "INR", symbol = "\u20b9")

  observeEvent(input$global_currency, {
    if (input$global_currency == "CUSTOM") {
      currency$code   <- "CUSTOM"
      currency$symbol <- if (nzchar(input$custom_currency_symbol)) input$custom_currency_symbol else ""
    } else {
      currency$code   <- input$global_currency
      currency$symbol <- currency_symbol_map[[input$global_currency]]
    }
  })

  observeEvent(input$custom_currency_symbol, {
    if (input$global_currency == "CUSTOM") {
      currency$symbol <- if (nzchar(input$custom_currency_symbol)) input$custom_currency_symbol else ""
    }
  })

  # -- Global Logging State ------------------------------------------
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

  # -- Call Modules --------------------------------------------------
  mod_home_server("home_1", parent_session = session)

  # Parameter Estimation Modules
  mod_core_conv_server("core_1", logger = global_logger)
  mod_hr_converter_server("hr_1", logger = global_logger)
  mod_batch_server("batch_1", logger = global_logger)
  mod_survival_server("surv_1", logger = global_logger)
  mod_lifetable_server("life_1", logger = global_logger)
  mod_psa_server("psa_1", logger = global_logger)
  mod_financial_server("fin_1", logger = global_logger, currency = currency)
  mod_diagnostic_server("diag_1", logger = global_logger)

  # Results & Pricing Modules
  mod_icer_server("icer_1", logger = global_logger, currency = currency)
  mod_vbp_server("vbp_1", logger = global_logger, currency = currency)
  mod_bia_server("bia_1", logger = global_logger, currency = currency)

  # PPP Currency Converter
  mod_ppp_server("ppp_1", logger = global_logger, currency = currency)

  # Reporting Module
  mod_report_server("rep_1", logger = global_logger)
}
