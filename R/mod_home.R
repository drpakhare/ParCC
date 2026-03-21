#' @import shiny
#' @importFrom DiagrammeR grVizOutput renderGrViz
mod_home_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(
      column(12,
             div(class = "about-header",
                 h1("ParCC v1.3", style = "font-weight: 700;"),
                 p("Parameter Converter & Calculator for Health Economic Evaluation", style = "font-size: 1.2em; opacity: 0.9;"),
                 p(style="font-size: 0.9em; margin-top: 10px;", "R Package Edition | RRC-HTA, AIIMS Bhopal")
             )
      )
    ),
    fluidRow(
      column(10, offset = 1,

             # What's New
             div(class = "about-card", style = "border-top: 4px solid #28a745;",
                 h4(icon("star"), " What's New in v1.3", style = "color: #155724;"),
                 tags$ul(
                   tags$li(HTML(paste0(strong("HR-Based Probability Converter"), " \u2014 Convert control group probabilities to intervention group using hazard ratios from clinical trials (single + multi-HR comparison)."))),
                   tags$li(HTML(paste0(strong("Enhanced Output Panels"), " \u2014 Every calculation module now displays step-by-step explanation, rendered formula, and literature citations alongside results."))),
                   tags$li(HTML(paste0(strong("Batch HR Conversion"), " \u2014 Bulk convert multiple endpoints using hazard ratios (e.g., all PLATO trial endpoints at once)."))),
                   tags$li(HTML(paste0(strong("Comprehensive Vignettes"), " \u2014 Eight worked-example tutorials covering core conversions, survival, PSA distributions, economic evaluation, and more.")))
                 )
             ),

             # Tool Map
             div(class = "about-card", style = "min-height: 600px;",
                 h4(icon("sitemap"), " Tool Overview", style = "color: #003366; text-align: center; margin-bottom: 20px;"),
                 div(style = "border: 1px solid #eee; border-radius: 4px; padding: 10px; background: #fff;",
                     grVizOutput(ns("tool_map"), height = "550px")
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
          graph [layout = dot, rankdir = TB, overlap = false, nodesep = 0.4, ranksep = 0.6]
          node [shape = box, style = filled, fontname = 'Helvetica', fontsize = 11]

          /* Root */
          node [fillcolor = '#003366', fontcolor = 'white', fontsize = 14]
          Root [label = 'ParCC v1.3']

          /* Category nodes */
          node [fillcolor = '#17a2b8', fontcolor = 'white', fontsize = 12]
          Prob   [label = 'Probabilities']
          Surv   [label = 'Survival']
          Mort   [label = 'Bg Mortality']
          PSA    [label = 'PSA Distributions']
          Fin    [label = 'Financial']
          Diag   [label = 'Diagnostics']
          Res    [label = 'Results & Pricing']
          Batch  [label = 'Batch Processing']

          /* Leaf tool nodes */
          node [fillcolor = '#f0f7ff', fontcolor = '#003366', shape = ellipse, fontsize = 10]
          T1  [label = 'Rate <-> Prob']
          T2  [label = 'Odds <-> Prob']
          T3  [label = 'Time Rescaling']
          T4  [label = 'HR Converter']
          T5  [label = 'Weibull / Exp']
          T6  [label = 'SMR Adjust']
          T7  [label = 'Linear Interp.']
          T8  [label = 'Gompertz Fit']
          T9  [label = 'DEALE']
          T10 [label = 'Beta / Gamma / LogN']
          T11 [label = 'Inflation']
          T12 [label = 'Discounting']
          T13 [label = 'Sensitivity / PPV']
          T14 [label = 'ICER / NMB']
          T15 [label = 'Headroom / VBP']
          T16 [label = 'Bulk Convert']
          T17 [label = 'Bulk HR Convert']

          /* New feature highlight */
          node [fillcolor = '#d4edda', fontcolor = '#155724', shape = ellipse, fontsize = 10]
          T4  [label = 'HR Converter (NEW)']
          T17 [label = 'Bulk HR Convert (NEW)']

          /* Edges */
          Root -> {Prob Surv Mort PSA Fin Diag Res Batch}
          Prob -> {T1 T2 T3 T4}
          Surv -> T5
          Mort -> {T6 T7 T8 T9}
          PSA -> T10
          Fin -> {T11 T12}
          Diag -> T13
          Res -> {T14 T15}
          Batch -> {T16 T17}
        }
      ")
    })
  })
}
