## Resubmission

This is a resubmission. In this version I have:

* Expanded all acronyms in the Description field (HR, PSA, ICERs, NMB, OR, RR)
* Added a testthat test suite (39 tests across 6 files) covering the
  core mathematical functions, as suggested by the reviewer

## Test environments

* Local: macOS (aarch64-apple-darwin), R 4.4.x
* win-builder: R-devel (2026-03-25 r89703 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

* POSSIBLY MISSPELLED WORDS in DESCRIPTION:
  Chinn, Dirichlet, HTA, ICERs, LogNormal, NMB, PPP, PSA, Yu, Zhang

  These are all domain-specific terms from health technology assessment
  (HTA, ICERs, NMB, PPP, PSA), statistical distributions (Dirichlet,
  LogNormal), or author surnames cited in the Description (Chinn, Yu,
  Zhang).