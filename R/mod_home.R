#' @import shiny
#' @importFrom DiagrammeR grVizOutput renderGrViz
mod_home_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(
      column(12,
             div(class = "about-header",
                 h1("ParCC v1.2", style = "font-weight: 700;"),
                 p("Parameter Converter & Calculator for Health Economic Evaluation", style = "font-size: 1.2em; opacity: 0.9;"),
                 p(style="font-size: 0.9em; margin-top: 10px;", "R Package Edition")
             )
      )
    ),
    fluidRow(
      column(10, offset = 1,
             div(class = "about-card", style = "min-height: 600px;",
                 h4(icon("sitemap"), " Tool Overview", style = "color: #003366; text-align: center; margin-bottom: 20px;"),
                 div(style = "border: 1px solid #eee; border-radius: 4px; padding: 10px; background: #fff;",
                     grVizOutput(ns("tool_map"), height = "500px")
                 ),
                 br(),
                 div(style = "text-align: center; background-color: #e9ecef; padding: 20px; border-radius: 8px; border-top: 4px solid #17a2b8;",
                     h4("Start Your Analysis"),
                     p("Navigate to the Converters or Pricing tabs."),
                     actionButton(ns("go_converters"), "Go to Converters", class = "btn-primary btn-lg", icon = icon("arrow-right"))
                 )
             )
      )
    )
  )
}

mod_home_server <- function(id, parent_session) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$go_converters, {
      updateNavbarPage(parent_session, "main_nav", selected = "Converters")
    })
    
    output$tool_map <- renderGrViz({
      DiagrammeR::grViz("
        digraph parcc_map {
          graph [layout = dot, rankdir = TB, overlap = false]
          node [shape = box, style = filled, fontname = 'Helvetica', fontsize = 12]
          
          node [fillcolor = '#003366', fontcolor = 'white', fontsize=14]
          Root [label = 'ParCC Tools']
          
          node [fillcolor = '#17a2b8', fontcolor = 'white']
          Prob [label = 'Probabilities']; Surv [label = 'Survival']; 
          Mort [label = 'Bg Mortality']; Res [label = 'Results & Pricing']; 
          
          node [fillcolor = '#f0f7ff', fontcolor = '#003366', shape=ellipse]
          T1 [label = 'Rate ↔ Prob']; T2 [label = 'Odds ↔ Prob']; 
          T3 [label = 'Weibull / Exp']; T4 [label = 'SMR Adjust']; 
          T5 [label = 'ICER / NMB']; T6 [label = 'Headroom / VBP'];
          
          Root -> {Prob Surv Mort Res}
          Prob -> {T1 T2}
          Surv -> T3
          Mort -> T4
          Res -> {T5 T6}
        }
      ")
    })
  })
}