# Survival Extrapolation from Published Curves

## The Problem

Clinical trials typically follow patients for 2-5 years, but health
economic models often require lifetime projections (20-40 years). When
Individual Patient Data (IPD) is unavailable, you must extract
information from published Kaplan-Meier curves and fit parametric
distributions.

## Method 1: Exponential (From Median Survival)

### When to Use

The exponential distribution assumes a **constant hazard** — the risk of
the event is the same at every time point. This is rarely true
biologically, but can be a reasonable approximation when:

- You only have median survival reported
- The Kaplan-Meier curve appears roughly linear on a log scale

### The Scenario — Metastatic Colorectal Cancer

A Phase III trial of Bevacizumab + FOLFOX reports median Overall
Survival of **21.3 months** in the control arm (Hurwitz et al., NEJM
2004).

### Worked Example

``` r
median_os <- 21.3  # months

# Hazard rate from median
lambda <- log(2) / median_os
cat("Hazard rate (lambda):", round(lambda, 5), "per month\n")
#> Hazard rate (lambda): 0.03254 per month

# Survival function: S(t) = exp(-lambda * t)
t_seq <- c(6, 12, 24, 36, 60)
surv <- exp(-lambda * t_seq)

data.frame(
  Month = t_seq,
  Survival = round(surv, 3),
  Event_Prob = round(1 - surv, 3)
)
#>   Month Survival Event_Prob
#> 1     6    0.823      0.177
#> 2    12    0.677      0.323
#> 3    24    0.458      0.542
#> 4    36    0.310      0.690
#> 5    60    0.142      0.858
```

## Method 2: Weibull (From Two KM Points)

### When to Use

The Weibull distribution allows the hazard to increase or decrease over
time (monotonically). This is more flexible than exponential and is
frequently used in oncology HTA.

### The Scenario — NSCLC (CheckMate 017)

A published Kaplan-Meier curve for nivolumab in squamous NSCLC shows:

- At 12 months, survival is approximately **42%**
- At 24 months, survival is approximately **23%**

### The Formula

The Weibull survival function is:

$$S(t) = e^{- \lambda t^{\gamma}}$$

Using the log-log transformation:

$$\ln\left( - \ln\left( S(t) \right) \right) = \ln(\lambda) + \gamma\ln(t)$$

With two points, we solve a system of two linear equations.

### Worked Example

``` r
# Two points from the KM curve
t1 <- 12; s1 <- 0.42
t2 <- 24; s2 <- 0.23

# Log-log transformation
y1 <- log(-log(s1)); x1 <- log(t1)
y2 <- log(-log(s2)); x2 <- log(t2)

# Solve for shape (gamma) and scale (lambda)
gamma <- (y2 - y1) / (x2 - x1)
lambda <- exp(y1 - gamma * x1)

cat("Weibull Shape (gamma):", round(gamma, 4), "\n")
#> Weibull Shape (gamma): 0.7606
cat("Weibull Scale (lambda):", format(lambda, scientific = TRUE, digits = 4), "\n")
#> Weibull Scale (lambda): 1.311e-01

# Generate survival table
t_seq <- seq(0, 60, by = 6)
surv <- exp(-lambda * t_seq^gamma)

# Transition probabilities (monthly)
t_monthly <- 0:60
s_monthly <- exp(-lambda * t_monthly^gamma)
tp <- c(1, s_monthly[-1] / s_monthly[-length(s_monthly)])

cat("\nSurvival projections:\n")
#> 
#> Survival projections:
data.frame(
  Month = seq(0, 60, by = 6),
  Survival = round(exp(-lambda * seq(0, 60, by = 6)^gamma), 3)
)
#>    Month Survival
#> 1      0    1.000
#> 2      6    0.599
#> 3     12    0.420
#> 4     18    0.307
#> 5     24    0.230
#> 6     30    0.175
#> 7     36    0.135
#> 8     42    0.105
#> 9     48    0.083
#> 10    54    0.066
#> 11    60    0.052
```

### Interpretation

- If $\gamma > 1$: hazard is increasing over time (common in cancer)
- If $\gamma = 1$: constant hazard (reduces to exponential)
- If $\gamma < 1$: hazard is decreasing over time (common post-surgery)

## Generating Markov Trace

Both methods produce cycle-specific transition probabilities for your
Markov model:

``` r
# Generate annual transition probabilities from Weibull
cycles <- 0:10
s_t <- exp(-lambda * (cycles * 12)^gamma)  # Convert years to months for calculation
tp <- c(1, s_t[-1] / s_t[-length(s_t)])

trace <- data.frame(
  Year = cycles,
  Survival = round(s_t, 4),
  Annual_TP = round(tp, 4),
  Cumulative_Death = round(1 - s_t, 4)
)
print(trace)
#>    Year Survival Annual_TP Cumulative_Death
#> 1     0   1.0000    1.0000           0.0000
#> 2     1   0.4200    0.4200           0.5800
#> 3     2   0.2300    0.5476           0.7700
#> 4     3   0.1353    0.5881           0.8647
#> 5     4   0.0829    0.6131           0.9171
#> 6     5   0.0523    0.6309           0.9477
#> 7     6   0.0337    0.6448           0.9663
#> 8     7   0.0221    0.6560           0.9779
#> 9     8   0.0147    0.6654           0.9853
#> 10    9   0.0099    0.6735           0.9901
#> 11   10   0.0067    0.6805           0.9933
```

## References

- Collett D. *Modelling Survival Data in Medical Research*. 3rd
  ed. Chapman and Hall/CRC; 2015.
- Latimer NR. Survival analysis for economic evaluations alongside
  clinical trials. *Med Decis Making*. 2013;33(6):743-754.
- NICE Decision Support Unit. TSD 14: Survival analysis for economic
  evaluations. 2013.
