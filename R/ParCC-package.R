#' @keywords internal
"_PACKAGE"

## Global variable bindings (suppress R CMD check NOTEs for ggplot2/plotly NSE)
## These are column names used inside aes() and plotly calls, not actual globals.
utils::globalVariables(c(

  # ggplot2 aes() variables
  "Time", "Survival", "Group", "Age", "Rate", "Probability",
  "Prev", "PPV", "Category", "Value", "Type",
  "State", "Proportion", "Year", "Method", "Fill",

  # plotly functions (called via pipe, not imported individually)
  "plot_ly", "add_lines", "add_markers", "add_segments", "layout"
))

#' @importFrom stats dbeta dgamma dlnorm qgamma qlnorm qnorm rgamma setNames
#' @importFrom utils read.csv write.csv
#' @importFrom plotly plot_ly add_lines add_markers add_segments layout
NULL
