# ==============================================================================
# MODULE: PPP CURRENCY CONVERTER WITH WTP THRESHOLDS
# ==============================================================================

# -- Static World Bank data (2022 ICP round, latest available) -----------------
# PPP conversion factor (LCU per international $), GDP per capita (current US$),
# and market exchange rate (LCU per US$).
# Source: World Bank Open Data, International Comparison Program.
# Users can override any value manually.

.ppp_data <- data.frame(
  country = c(
    "India", "United States", "United Kingdom", "Germany", "France",
    "Japan", "China", "Brazil", "Australia", "Canada",
    "South Korea", "Thailand", "Mexico", "South Africa", "Turkey",
    "Indonesia", "Nigeria", "Egypt", "Poland", "Sweden",
    "Norway", "Switzerland", "Italy", "Spain", "Netherlands",
    "Belgium", "Ireland", "New Zealand", "Malaysia", "Philippines"
  ),
  iso3 = c(
    "IND", "USA", "GBR", "DEU", "FRA",
    "JPN", "CHN", "BRA", "AUS", "CAN",
    "KOR", "THA", "MEX", "ZAF", "TUR",
    "IDN", "NGA", "EGY", "POL", "SWE",
    "NOR", "CHE", "ITA", "ESP", "NLD",
    "BEL", "IRL", "NZL", "MYS", "PHL"
  ),
  currency_code = c(
    "INR", "USD", "GBP", "EUR", "EUR",
    "JPY", "CNY", "BRL", "AUD", "CAD",
    "KRW", "THB", "MXN", "ZAR", "TRY",
    "IDR", "NGN", "EGP", "PLN", "SEK",
    "NOK", "CHF", "EUR", "EUR", "EUR",
    "EUR", "EUR", "NZD", "MYR", "PHP"
  ),
  currency_symbol = c(
    "\u20b9", "$", "\u00a3", "\u20ac", "\u20ac",
    "\u00a5", "\u00a5", "R$", "A$", "C$",
    "\u20a9", "\u0e3f", "Mex$", "R", "\u20ba",
    "Rp", "\u20a6", "E\u00a3", "z\u0142", "kr",
    "kr", "CHF", "\u20ac", "\u20ac", "\u20ac",
    "\u20ac", "\u20ac", "NZ$", "RM", "\u20b1"
  ),
  # PPP conversion factor (LCU per international dollar, 2022)
  ppp_factor = c(
    23.2, 1.00, 0.69, 0.74, 0.73,
    97.7, 4.19, 2.55, 1.46, 1.24,
    855, 12.0, 9.70, 6.90, 4.52,
    5207, 187, 5.09, 2.03, 8.82,
    10.8, 1.18, 0.67, 0.61, 0.79,
    0.76, 0.80, 1.44, 1.64, 19.2
  ),
  # Market exchange rate (LCU per US$, 2022 annual average)
  mkt_fx = c(
    78.6, 1.00, 0.81, 0.95, 0.95,
    131.5, 6.73, 5.17, 1.51, 1.30,
    1292, 35.1, 20.1, 16.4, 16.6,
    14850, 426, 19.2, 4.46, 10.1,
    9.61, 0.96, 0.95, 0.95, 0.95,
    0.95, 0.95, 1.58, 4.40, 54.5
  ),
  # GDP per capita (current US$, 2022)
  gdp_pc_usd = c(
    2389, 76330, 46125, 48718, 40886,
    33815, 12720, 8918, 65100, 55036,
    32423, 6910, 11091, 6776, 10674,
    4788, 2184, 3699, 17820, 56362,
    106149, 93260, 34776, 29674, 57026,
    49582, 103684, 47223, 12448, 3623
  ),
  stringsAsFactors = FALSE
)

# -- UI ------------------------------------------------------------------------
mod_ppp_ui <- function(id) {
  ns <- NS(id)

  country_choices <- setNames(.ppp_data$country, paste0(.ppp_data$country, " (", .ppp_data$currency_code, ")"))

  sidebarLayout(
    sidebarPanel(
      h4(icon("globe-americas"), " PPP Currency Converter"),
      p(class = "text-muted", "Convert costs between countries using Purchasing Power Parity and assess cost-effectiveness thresholds."),
      textInput(ns("label"), "Label:", placeholder = "e.g., Drug X price comparison"),
      hr(),

      h5("1. Source Cost"),
      selectInput(ns("source_country"), "Source Country:",
                  choices = country_choices, selected = "United States"),
      numericInput(ns("cost_input"), "Cost in Source Currency:", value = 50000, min = 0),
      helpText("Enter the cost in the source country's local currency."),

      hr(),
      h5("2. Target Country"),
      selectInput(ns("target_country"), "Target Country:",
                  choices = country_choices, selected = "India"),

      hr(),
      h5("3. Override Values (Optional)"),
      helpText("Leave blank to use World Bank 2022 defaults. Enter custom values if you have more recent data."),
      numericInput(ns("override_ppp_source"), "Source PPP Factor (LCU/Intl$):", value = NA, min = 0, step = 0.01),
      numericInput(ns("override_ppp_target"), "Target PPP Factor (LCU/Intl$):", value = NA, min = 0, step = 0.01),
      numericInput(ns("override_fx_source"), "Source Market FX (LCU/US$):", value = NA, min = 0, step = 0.01),
      numericInput(ns("override_fx_target"), "Target Market FX (LCU/US$):", value = NA, min = 0, step = 0.01),
      numericInput(ns("override_gdp_target"), "Target GDP/capita (US$):", value = NA, min = 0, step = 1),

      br(),
      actionButton(ns("calc"), "Convert & Assess", class = "btn-primary", width = "100%")
    ),
    mainPanel(
      uiOutput(ns("res_ppp")),
      br(),
      div(class = "plot-container", plotOutput(ns("plot_ppp"), height = "350px")),
      br(),
      DT::dataTableOutput(ns("tbl_ppp"))
    )
  )
}

# -- Server --------------------------------------------------------------------
mod_ppp_server <- function(id, logger, currency) {
  moduleServer(id, function(input, output, session) {

    add_to_log <- function(label, type, inputs, result, note) {
      new_entry <- data.frame(
        Time   = format(Sys.time(), "%H:%M:%S"),
        Label  = ifelse(label == "", "Unlabeled", label),
        Module = type,
        Input  = inputs,
        Result = result,
        Notes  = note,
        stringsAsFactors = FALSE
      )
      logger$entries <- rbind(logger$entries, new_entry)
      showNotification("Added to Report", type = "message")
    }

    mathjax_trigger <- tags$script("if(window.MathJax){MathJax.Hub.Queue(['Typeset', MathJax.Hub]);}")

    observeEvent(input$calc, {
      req(input$cost_input > 0)

      src <- .ppp_data[.ppp_data$country == input$source_country, ]
      tgt <- .ppp_data[.ppp_data$country == input$target_country, ]

      # Apply overrides if provided
      ppp_src <- if (!is.na(input$override_ppp_source)) input$override_ppp_source else src$ppp_factor
      ppp_tgt <- if (!is.na(input$override_ppp_target)) input$override_ppp_target else tgt$ppp_factor
      fx_src  <- if (!is.na(input$override_fx_source))  input$override_fx_source  else src$mkt_fx
      fx_tgt  <- if (!is.na(input$override_fx_target))  input$override_fx_target  else tgt$mkt_fx
      gdp_tgt <- if (!is.na(input$override_gdp_target)) input$override_gdp_target else tgt$gdp_pc_usd

      cost_lcu <- input$cost_input

      # -- Step 1: Convert source LCU to International Dollars --
      cost_intl <- cost_lcu / ppp_src

      # -- Step 2: Convert International Dollars to target LCU (PPP) --
      cost_ppp_target <- cost_intl * ppp_tgt

      # -- Step 3: Market exchange rate conversion (for comparison) --
      cost_usd <- cost_lcu / fx_src
      cost_fx_target <- cost_usd * fx_tgt

      # -- Step 4: WTP thresholds in target country --
      # Common HTA thresholds: 1x and 3x GDP per capita (WHO-CHOICE)
      wtp_1x <- gdp_tgt  # in US$, convert to target LCU
      wtp_3x <- 3 * gdp_tgt
      wtp_1x_lcu <- wtp_1x * fx_tgt
      wtp_3x_lcu <- wtp_3x * fx_tgt

      # PPP-adjusted GDP per capita in target LCU
      gdp_pc_ppp_tgt <- gdp_tgt * ppp_tgt  # International $ * PPP = LCU

      # -- Ratio for context --
      ppp_fx_ratio <- cost_ppp_target / cost_fx_target

      # Format helpers
      sfmt <- function(x, sym) paste0(sym, " ", format(round(x, 0), big.mark = ","))

      src_sym <- src$currency_symbol
      tgt_sym <- tgt$currency_symbol

      # -- Assessment --
      # Is the PPP-converted cost below 1x or 3x GDP/capita?
      assess_col <- if (cost_ppp_target <= wtp_1x_lcu) {
        "#27ae60"
      } else if (cost_ppp_target <= wtp_3x_lcu) {
        "#e67e22"
      } else {
        "#e74c3c"
      }

      assess_text <- if (cost_ppp_target <= wtp_1x_lcu) {
        "Below 1\u00d7 GDP/capita \u2014 Highly cost-effective by WHO-CHOICE criteria."
      } else if (cost_ppp_target <= wtp_3x_lcu) {
        "Between 1\u00d7 and 3\u00d7 GDP/capita \u2014 Cost-effective by WHO-CHOICE criteria."
      } else {
        "Above 3\u00d7 GDP/capita \u2014 Not cost-effective by WHO-CHOICE criteria."
      }

      # -- Output --
      output$res_ppp <- renderUI(tagList(
        div(class = "result-box", style = paste0("border-left-color:", assess_col),
          HTML(paste0(
            "<span class='result-label'>PPP-Adjusted Cost</span><br>",
            strong(input$source_country), ": ", sfmt(cost_lcu, src_sym), "<br>",
            "<span class='result-value'>", strong(input$target_country), ": ",
            sfmt(cost_ppp_target, tgt_sym), " (PPP)</span>",
            "<br><small>Market exchange rate: ", sfmt(cost_fx_target, tgt_sym),
            " | International $: ", sfmt(cost_intl, "$"), "</small>"
          ))
        ),

        # PPP vs FX comparison
        div(style = "background:#f8f9fa; border-left:4px solid #17a2b8; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
          h5(icon("balance-scale"), " PPP vs Market Exchange Rate", style = "color:#0c5460; margin-top:0;"),
          p(HTML(paste0(
            "PPP-adjusted cost is ", strong(round(abs(1 - ppp_fx_ratio) * 100, 1), "%"),
            if (ppp_fx_ratio > 1) " higher " else " lower ",
            "than the market FX conversion.",
            "<br><small>PPP ratio = ", round(ppp_fx_ratio, 3),
            ". A ratio > 1 means the target country is more expensive in PPP terms than the market rate suggests.</small>"
          )))
        ),

        # WTP threshold assessment
        div(style = paste0("background:#fff; border-left:4px solid ", assess_col, "; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;"),
          h5(icon("chart-line"), " Cost-Effectiveness Threshold Assessment", style = "margin-top:0;"),
          p(HTML(paste0(
            strong("Target country GDP per capita: "), sfmt(gdp_tgt, "$"), " (", sfmt(wtp_1x_lcu, tgt_sym), ")<br>",
            strong("1\u00d7 GDP/capita (highly CE): "), sfmt(wtp_1x_lcu, tgt_sym), "<br>",
            strong("3\u00d7 GDP/capita (CE): "), sfmt(wtp_3x_lcu, tgt_sym), "<br><br>",
            strong("PPP-adjusted cost: "), sfmt(cost_ppp_target, tgt_sym), "<br>",
            span(style = paste0("font-weight:bold; color:", assess_col, "; font-size:1.1em;"), assess_text)
          ))),
          p(style = "font-size:0.8em; color:#888;",
            "WHO-CHOICE thresholds are approximate guides. Many countries now use empirical thresholds (e.g., UK: \u00a320,000-30,000/QALY, India: 1\u00d7 GDP/capita per HTAIn).")
        ),

        # Explanation
        div(style = "background:#f1f8f3; border-left:4px solid #28a745; padding:15px; margin-top:15px; border-radius:0 4px 4px 0;",
          h5(icon("lightbulb"), " How This Was Calculated", style = "color:#155724; margin-top:0;"),
          tags$ol(
            tags$li(HTML(paste0(
              strong("Source to International $: "),
              sfmt(cost_lcu, src_sym), " \u00f7 ", ppp_src, " = ",
              sfmt(cost_intl, "$"), " (international dollars)"
            ))),
            tags$li(HTML(paste0(
              strong("International $ to Target (PPP): "),
              sfmt(cost_intl, "$"), " \u00d7 ", ppp_tgt, " = ",
              sfmt(cost_ppp_target, tgt_sym)
            ))),
            tags$li(HTML(paste0(
              strong("Market FX comparison: "),
              sfmt(cost_lcu, src_sym), " \u00f7 ", fx_src, " = ",
              sfmt(cost_usd, "$"), " \u00d7 ", fx_tgt, " = ",
              sfmt(cost_fx_target, tgt_sym)
            )))
          )
        ),

        # Formula
        div(style = "background:#fff; border:1px solid #ddd; padding:15px; margin-top:15px; border-radius:4px;",
          h5(icon("square-root-alt"), " Formula", style = "margin-top:0;"),
          p("$$C_{target}^{PPP} = \\frac{C_{source}}{PPP_{source}} \\times PPP_{target}$$"),
          p("$$C_{target}^{FX} = \\frac{C_{source}}{FX_{source}} \\times FX_{target}$$"),
          p(style = "font-size:0.85em; color:#666;",
            "PPP = Purchasing Power Parity factor (LCU per international dollar). FX = market exchange rate (LCU per US$).")
        ),

        # Citation
        div(style = "background:#eef6ff; border-left:4px solid #0056b3; padding:12px; margin-top:15px; border-radius:0 4px 4px 0;",
          h5(icon("book"), " References", style = "margin-top:0; color:#003366;"),
          tags$ol(style = "font-size:0.85em; margin-bottom:0;",
            tags$li(HTML("World Bank. International Comparison Program (ICP). PPP conversion factors. <em>World Development Indicators</em>. 2022.")),
            tags$li(HTML("WHO-CHOICE. Cost-effectiveness thresholds. <em>World Health Organization</em>. Choosing Interventions that are Cost-Effective.")),
            tags$li(HTML("Pichon-Riviere A, et al. Ethnicity and the need for local cost-effectiveness thresholds. <em>Value in Health Regional Issues</em>. 2019."))
          )
        ),

        mathjax_trigger
      ))

      # -- Plot: Waterfall comparison --
      output$plot_ppp <- renderPlot({
        plot_df <- data.frame(
          Method = factor(c(
            paste0("Source\n(", src$currency_code, ")"),
            "International $",
            paste0("PPP\n(", tgt$currency_code, ")"),
            paste0("Market FX\n(", tgt$currency_code, ")")
          ), levels = c(
            paste0("Source\n(", src$currency_code, ")"),
            "International $",
            paste0("PPP\n(", tgt$currency_code, ")"),
            paste0("Market FX\n(", tgt$currency_code, ")")
          )),
          Value = c(cost_lcu, cost_intl, cost_ppp_target, cost_fx_target),
          Fill = c("source", "intl", "ppp", "fx")
        )

        ggplot(plot_df, aes(x = Method, y = Value, fill = Fill)) +
          geom_col(width = 0.6, alpha = 0.85) +
          geom_text(aes(label = format(round(Value, 0), big.mark = ",")),
                    vjust = -0.5, size = 3.5, fontface = "bold") +
          geom_hline(yintercept = wtp_1x_lcu, linetype = "dashed", color = "#27ae60", linewidth = 0.8) +
          geom_hline(yintercept = wtp_3x_lcu, linetype = "dashed", color = "#e74c3c", linewidth = 0.8) +
          annotate("text", x = 3.5, y = wtp_1x_lcu, label = "1x GDP/cap",
                   vjust = -0.5, hjust = 1, color = "#27ae60", fontface = "bold", size = 3) +
          annotate("text", x = 3.5, y = wtp_3x_lcu, label = "3x GDP/cap",
                   vjust = -0.5, hjust = 1, color = "#e74c3c", fontface = "bold", size = 3) +
          scale_fill_manual(values = c(
            "source" = "#003366", "intl" = "#17a2b8",
            "ppp" = "#28a745", "fx" = "#95a5a6"
          )) +
          theme_minimal(base_size = 13) +
          labs(title = paste0("Cost Comparison: ", input$source_country, " \u2192 ", input$target_country),
               y = "Value", x = "") +
          theme(legend.position = "none",
                panel.grid.major.x = element_blank()) +
          scale_y_continuous(expand = expansion(mult = c(0, 0.15)))
      })

      # -- Comparison Table --
      output$tbl_ppp <- DT::renderDataTable({
        comp_df <- data.frame(
          Metric = c(
            "Cost (source LCU)",
            "Cost (international $)",
            "Cost (target LCU, PPP)",
            "Cost (target LCU, market FX)",
            "PPP / FX ratio",
            "Target GDP per capita (US$)",
            "1x GDP/capita threshold (target LCU)",
            "3x GDP/capita threshold (target LCU)"
          ),
          Value = c(
            sfmt(cost_lcu, src_sym),
            sfmt(cost_intl, "$"),
            sfmt(cost_ppp_target, tgt_sym),
            sfmt(cost_fx_target, tgt_sym),
            round(ppp_fx_ratio, 3),
            sfmt(gdp_tgt, "$"),
            sfmt(wtp_1x_lcu, tgt_sym),
            sfmt(wtp_3x_lcu, tgt_sym)
          ),
          stringsAsFactors = FALSE
        )
        DT::datatable(comp_df, options = list(dom = 'Bt', pageLength = 10,
                      buttons = list('copy', 'csv')),
                      extensions = 'Buttons', rownames = FALSE)
      })

      # -- Log --
      add_to_log(input$label, "PPP Converter",
                 paste0(input$source_country, " ", sfmt(cost_lcu, src_sym),
                        " -> ", input$target_country),
                 paste0("PPP: ", sfmt(cost_ppp_target, tgt_sym),
                        " | FX: ", sfmt(cost_fx_target, tgt_sym)),
                 paste0("WTP assessment: ", assess_text))
    })
  })
}
