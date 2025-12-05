#' Run the ParCC Application
#'
#' Launches the ParCC Shiny application in the default web browser.
#'
#' @export
run_app <- function() {
  shiny::shinyApp(ui = app_ui, server = app_server)
}