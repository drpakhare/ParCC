# Batch Conversion Workflow

## When to Use Batch Conversion

When populating a Markov model, you may need to convert dozens of
parameters simultaneously. Rather than entering each one manually,
ParCC’s Bulk Conversion module lets you upload a CSV, select columns,
and convert them all at once.

## Supported Conversion Types

1.  **Rate to Probability** — for incidence rates from clinical trials
2.  **Odds to Probability** — for odds ratios from logistic regression
3.  **HR to Intervention Probability** — for applying hazard ratios to
    control arm probabilities

## Example: PLATO Trial Parameters

### Step 1: Prepare Your CSV

Create a CSV with at least these columns:

    Endpoint,Control_Prob,Hazard_Ratio,Time_Horizon
    CV Death,0.0525,0.79,1
    MI,0.0643,0.84,1
    Stroke,0.0138,1.01,1
    Major Bleeding,0.1143,1.04,1
    Dyspnea AE,0.0789,1.37,1
    All-cause Mortality,0.0595,0.78,1

### Step 2: Upload and Configure

1.  Navigate to **Bulk Conversion**
2.  Upload your CSV (or click “Load Sample Dataset” for a pre-built
    PLATO example)
3.  Select Conversion Type: **HR -\> Intervention Probability**
4.  Select Value Column: `Control_Prob`
5.  Select HR Column: `Hazard_Ratio`
6.  Time Source: Constant = `1` (or from column)

### Step 3: Run and Review

Click **Run Bulk Conversion**. The output table adds:

| Column            | Description                                         |
|-------------------|-----------------------------------------------------|
| Rate_Control      | Instantaneous rate derived from control probability |
| Rate_Intervention | Control rate multiplied by HR                       |
| Intervention_Prob | Converted probability for intervention arm          |
| ARR               | Absolute Risk Reduction (control - intervention)    |
| NNT               | Number Needed to Treat (for beneficial effects)     |

### Step 4: Download

Click **Download Results** to get a CSV you can paste directly into your
model spreadsheet.

### Example Output

``` r
# Simulate what ParCC produces
df <- data.frame(
  Endpoint = c("CV Death", "MI", "Stroke", "Major Bleeding", "Dyspnea AE", "All-cause Mortality"),
  Control_Prob = c(0.0525, 0.0643, 0.0138, 0.1143, 0.0789, 0.0595),
  HR = c(0.79, 0.84, 1.01, 1.04, 1.37, 0.78),
  stringsAsFactors = FALSE
)

t <- 1  # 1-year horizon

df$Rate_Ctrl <- -log(1 - df$Control_Prob) / t
df$Rate_Int <- df$Rate_Ctrl * df$HR
df$Interv_Prob <- round(1 - exp(-df$Rate_Int * t), 5)
df$ARR <- round(df$Control_Prob - df$Interv_Prob, 5)
df$NNT <- ifelse(df$ARR > 0, ceiling(1 / df$ARR), NA)

# Clean display
result <- df[, c("Endpoint", "Control_Prob", "HR", "Interv_Prob", "ARR", "NNT")]
print(result)
#>              Endpoint Control_Prob   HR Interv_Prob      ARR NNT
#> 1            CV Death       0.0525 0.79     0.04171  0.01079  93
#> 2                  MI       0.0643 0.84     0.05430  0.01000 100
#> 3              Stroke       0.0138 1.01     0.01394 -0.00014  NA
#> 4      Major Bleeding       0.1143 1.04     0.11859 -0.00429  NA
#> 5          Dyspnea AE       0.0789 1.37     0.10649 -0.02759  NA
#> 6 All-cause Mortality       0.0595 0.78     0.04672  0.01278  79
```

Notice that endpoints with HR \> 1 (Stroke, Major Bleeding, Dyspnea)
show negative ARR, meaning the intervention *increases* the event risk —
these rows correctly show `NA` for NNT.

## Tips

- **Column naming:** ParCC auto-detects columns containing “Rate”,
  “Odds”, “Prob”, “HR”, “Hazard”, or “Time” in their names.
- **Mixed conversions:** If you have a mix of rates and probabilities,
  split your CSV into two files and run them separately.
- **The sample dataset** is pre-loaded with realistic PLATO trial data —
  useful for learning the workflow.

## References

- Wallentin L, et al. Ticagrelor versus clopidogrel in patients with
  acute coronary syndromes. *N Engl J Med*. 2009;361(11):1045-1057.
- Briggs A, et al. *Decision Modelling for Health Economic Evaluation*.
  Oxford University Press; 2006.
