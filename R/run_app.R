#' Run the ParCC Application
#'
#' Launches the ParCC Shiny application in the default web browser.
#' The application provides interactive tools for Health Technology Assessment
#' parameter conversions, survival extrapolation, PSA distribution fitting,
#' economic evaluation, and more.
#'
#' @return A Shiny application object (invisibly). Called for its side effect
#'   of launching the application.
#'
#' @examples
#' if (interactive()) {
#'   run_app()
#' }
#'
#' @export
run_app <- function() {
  shiny::shinyApp(ui = app_ui, server = app_server)
}