# Run the ParCC Application

Launches the ParCC Shiny application in the default web browser. The
application provides interactive tools for Health Technology Assessment
parameter conversions, survival extrapolation, PSA distribution fitting,
economic evaluation, and more.

## Usage

``` r
run_app()
```

## Value

A Shiny application object (invisibly). Called for its side effect of
launching the application.

## Examples

``` r
if (interactive()) {
  run_app()
}
```
