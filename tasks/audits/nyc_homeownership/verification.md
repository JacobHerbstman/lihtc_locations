# Verification: September 13, 2026

Root `make -j3` built the new audit from previously absent outputs using the
existing national sources. Root and paper builds passed and subsequent root/task
builds were idle. No source acquisition, national cleaning, or national assignment
ran. Data reports show complete, unique project and tract/year keys.

Independent checks retained every native NYC tract in each of the 36 study years,
verified that its observation ends before the placement year, and reconciled 824
dated placements to the 851 NYC master rows. The analytic sample has 822 projects
and 77,409 tract-years, including 76,714 with no project. The two exclusions for
prior context are later projects whose prior tracts have zero housing and an
undefined homeowner share.

All eight estimated homeowner slopes (two periods, two samples, two adjustments)
were independently reproduced to within 0.00001 by profiling out the Poisson
stratum intercepts and optimizing the conditional likelihood. This checks the
reported point estimates separately from the GLM implementation. It does not
validate the causal or spatial assumptions behind the model.

A disposable task checkout with empty input/output/report directories and links
to the recorded prepared national data reproduced all six CSVs, four figures,
the HTML report, and generated TeX exactly. Its data reports were generated.
Deleting its actual model CSV and report regenerated both through the HTML target
with the same model-data hash. Changing the main end year to 2021 in that checkout
propagated to the panel, coverage, models and report; the later period became
19 years. Production data and specifications were not changed by these checks.

All four figures and the rendered logbook entry were inspected. The annual plot
has no project-location mean for 1987–1989 because there are no retained placements
in those years; this is documented rather than replaced with a zero homeowner
share. `git diff --check` passed.
