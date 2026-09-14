# Verification, September 14, 2026

## Vacancy and density update

- All 111,983 prior panel rows and their existing fields match the saved pre-control panel exactly. Original standardization scales and all 24 baseline estimates are unchanged. The original pooled figure and TeX table also retain their SHA-256 fingerprints.
- Vacancy reconciles with vacant/all housing counts. Density reconciles with prior housing units divided by native mapped area in square kilometers. CSV rounding introduces at most `4.94e-15` relative arithmetic differences in density. Log density uses only positive density.
- The controls sample excludes exactly four original eligible NYC tract-years with missing polygon area, all with zero projects. There is no project loss and no eligible missing vacancy. Both before/after specifications have identical fitted rows and project counts within each city and geographic sample.
- Independently profiled out year intercepts and optimized the conditional Poisson likelihood jointly over all focal and housing-control coefficients, without using `glm`. All 24 controlled focal slopes, spanning separate/joint models and both geographic samples, agree within `9.37e-7` log-rate units. Every production model explicitly retains `factor(placement_year)`.
- A fresh disposable fixture using the affected root rules reproduced all 11 outputs and all six SaveData reports byte-for-byte. Deleting its `models.csv` and model report and requesting the root HTML target regenerated both. Changing only the fixture end year to 2021 propagated to the extended panel, coverage, scales, models and both added-control exhibits, with the report's date label following the change.
- Root `make -j3`, task-local `make`, and `make -C paper` complete under GNU Make 3.81. Unchanged root/task builds do no work. Inspected the saved reports, comparison figure, and rendered logbook pages 24–25; `git diff --check` passes. No national source files changed or new data were acquired.

Mapped tract area includes inland water; this analysis does not measure land-only or developable-area density. Before/after confidence intervals are not a hypothesis test that the coefficient change differs from zero.

## Pooled update

Jacob subsequently requested pooling 1987–2022 in both cities. The current models estimate one slope per characteristic within each city and retain year effects. All 24 output estimates have `comparison = pooled`; there are no time interactions. Coverage now has one row per city.

The same independent conditional-Poisson calculation reproduces all 12 pooled separate-model slopes, including the interior sensitivity. Project-to-panel context, common model Ns, latest-prior timing and the original NYC tract-year values reconcile. Samples and standardization scales remain unchanged. Root and task builds, `make -C paper`, unchanged-build checks, figure inspection and the new rendered logbook entry are checked for this update. The preceding split-period table and figure are preserved as dated logbook snapshots, so their historical interpretation is not paired with pooled estimates.

The checks below document the initial split-period build, before this update.

## Initial split-period build

- Root `make -j3`, task-local `make`, and `make -C paper` complete under GNU Make 3.81. The shared execution settings serialize recursive production. Unchanged second builds do no work.
- Independent checks compare all 79,523 NYC tract-year keys and the prior observation, boundary, homeowner, housing and project fields with the previous NYC audit. They match exactly, as does the original homeowner eligibility flag. National source and earlier audit files are unchanged.
- Project-to-panel joins reproduce each matched project's prior observation and all three characteristics. Coverage and analysis flags reconcile. NYC retains 819 common-sample projects and 76,449 eligible zero-project tract-years; Chicago retains 172 and 31,671. All three separate regressions and the joint model have identical fitted rows and project counts within each city/geographic sample.
- For every opening year, the baseline observation is the latest source ending strictly earlier. No interpolation or future substitution enters. Scales use all eligible tract-years, including zero-project years, and remain fixed for the interior sensitivity.
- An independent conditional-Poisson calculation profiles out year intercepts and optimizes each period slope without calling `glm`. All 24 separate-model slopes (both cities, periods, and geographic samples) agree with the production estimates to a maximum absolute log-slope difference of `5.46e-8`.
- A disposable fixture uses the affected root Makefile rules, task code and prepared links to the unchanged national sources. A fresh build reproduced all nine outputs and all six SaveData reports exactly. Updating the plot's year-label dependency also built successfully in the fixture.
- Deleting fixture `models.csv` and its report, then requesting the root HTML target, regenerated the data and report and reproduced the model fingerprint. No report recovery target is used.
- Changing only the fixture's final opening year from 2022 to 2021 propagated to the project sample, tract panel, coverage, scales, models, plot, HTML and TeX table. The HTML and plot date labels followed the change. The production specification remains 2022.
- Reviewed the saved data reports, plotted confidence intervals and both new rendered logbook pages (21–22). The HTML report contains the generated figure, common-scale and natural-scale results, geographic sensitivity, missingness and all model counts. `git diff --check` passes.

The verification does not establish causal identification, validate HUD coordinates against individual buildings, or harmonize native tract boundaries. It checks the stated descriptive calculation and build behavior. The interior sensitivity preserves the broad magnitude ordering in both cities; uncertainty about relative point-estimate ranks is not a formal cross-variable hypothesis test.
