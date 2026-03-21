# app.R - Entry point for Posit Connect Cloud deployment
# This file sources all package modules and launches the ParCC Shiny app.

library(shiny)
library(shinythemes)
library(ggplot2)
library(plotly)
library(DiagrammeR)
library(DT)
library(magrittr)

# Source all R files in the R/ directory
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in r_files) source(f, local = FALSE)

# Launch the application
shinyApp(ui = app_ui(), server = app_server)
