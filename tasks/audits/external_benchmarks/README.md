# External checks of the simple LIHTC dataset

## September 12: project summaries and feasible external benchmarks

The current HUD-ID sample has 28,456 projects. Mean reported size is 67.2 units
(N=28,342), versus a median of 48 and an interquartile range of 27–82.
Mean low-income units are 60.4 (N=27,938). These means have different denominators;
their ratio is not the average low-income share. The distribution figure in the
state diagnostics uses 21,153 complete, consistent bedroom breakdowns for its
unit-weighted bedroom shares. No project selection or source values changed.

**Rent availability.** All 80 columns and the dictionary inside the pinned 2024
archive were checked. There is no actual dollar rent variable. INC_CEIL is the
elected income/rent ceiling, LOW_CEIL indicates a lower set-aside, CEILUNIT counts
such units, and rental-assistance fields describe program participation.
None can be used as observed rent. HUD's separate
[tenant tables](https://www.huduser.gov/portal/datasets/lihtc/tenant.html) publish
rent burdens and assistance. The
[November 2025 documentation](https://www.huduser.gov/portal/Datasets/lihtc/LIHTC-TenantDataDocumentation.pdf),
pp. 2–3 and 6, describes coverage limitations and distinguishes actual rents from
program rent limits. The public 2022 property-tabulation ZIP returned an empty
HTTP 202 response with an AWS WAF challenge on September 12; its contents could
not be inspected. No dollar-rent availability or merge coverage is claimed for
that file. A future tenant-data merge would measure rents at its observation
date, not historical rent when a project entered service.

**Checks performed.** The
[HUD 2024 published table](https://www.huduser.gov/portal/Datasets/lihtc/LIHTC-2024-Tables.pdf)
matches the raw workbook's 55,345 projects and 3,860,546 adjusted units, including
all ten annual project counts and adjusted-unit totals for 2015–2024.
The extended compare_hud.R calculation finds 29,641 TYPE=1 records among 48,251
records with known construction type across all geographies: 61.43085%, versus
61.5% published. Annual 2015–2024 differences range from -0.33415 to +0.15473
percentage points. Their cause is unresolved. The classifications have not been
altered to force agreement. Published adjusted units (N_UNITSR) and all-type totals
are not targets for our narrower sample or its reported-unit field (N_UNITS).
These checks validate transcription and broad agreement with a separate
publication of the same source; they do not establish independent completeness.
The publication explicitly marks 2023–2024 incomplete. The annual figure now
shades those cohorts.

**A feasible independent comparison.** Use agency administrative lists with
construction type, completion year, agency project ID and units. Compare completed
new-construction projects for the same state and mature cohorts, initially
2010–2019, and report source counts/units, automatic match rates, unmatched counts,
and date/unit disagreements. Validate state-ID uniqueness before a join; a repeated
ID should be reported separately rather than generating a many-to-many match.
Keep this as an audit with no individual overrides or automatic production drops.
It has not yet been run.

The [NCSHA Factbook guide](https://www.ncsha.org/hfa-factbook-online-data-visualization-and-reports-user-guide/)
identifies separate 9% and 4% tables with new-construction breakouts from an
agency survey. Those tables concern allocations, not completed projects.
They can check allocation-cohort scale and geographic patterns, allowing for
awards that do not become completed projects. They cannot be equated to our
placed-in-service totals. Full reports require member or purchased access.
The [California 2024 annual report](https://www.treasurer.ca.gov/sites/default/files/2025-12/2024-TCAC.pdf)
also publishes new-construction award trends, but has the same timing mismatch.
Neither source has been merged here, and neither is an excuse for individual
building searches. Housing agencies also supply HUD, so a separate administrative
list is not wholly independent of the underlying reporting system.

## Earlier research record

For the September 12 review of papers' data methods, see
[LIHTC papers: missing locations and sample construction](literature_methods.md).
It documents the justification and limits of automatic location exclusions;
no individual building searches or new production corrections were added.

September 12 update: the findings below describe the September 11 baseline. Current
sample comparisons are in `../state_diagnostics/output/diagnostics.html`. The
current automatic rules preserve locations with conflicting hedonics and record
all exclusions by state and year. Earlier suggestions for individual corrections
or reviews have not been adopted; no building-specific override enters production.
The three originally sampled HUD IDs remain fixed in the benchmark script.

September 11, 2026. Baseline: reset revision `36228a3`. These are checks and
recommendations, not changes to project selection or source values.

The original file agrees with HUD's published totals. The selected dataset is a
useful starting sample, but matching totals cannot establish completeness or
validate individual classifications. Three exploratory project checks found one
clear construction-type conflict and one unit-count discrepancy.

## Published totals and sample size

[HUD's 2024 summary](https://www.huduser.gov/portal/Datasets/lihtc/LIHTC-2024-Tables.pdf)
reports 55,345 records and 3,860,546 units using `n_unitsr`. Our original workbook
matches both exactly, and matches every published annual count of properties and
adjusted units for 2015–2024. This checks the source vintage and reading of the
file. These totals include rehabilitation and territories. They are not a target
for our new-construction-only sample, which uses reported rather than adjusted
unit counts.

| 50 states and DC | Records | Reported total units |
| --- | ---: | ---: |
| HUD new-construction records | 29,453 | 1,949,494 |
| Selected first-address records | 27,708 | 1,851,152 |

Selection reduces records by 5.9% and reported units by 5.0%. Missing units are
excluded from sums; these are not complete unit totals. The selected mean is
67.1 units among 27,595 records with known units; the median is 48.
This is an internal selection comparison, not an external validation of the rule.
New Jersey loses 17.6% of records and 18.5% of units; North Carolina loses 15.2%
of records but 4.9% of units. Later phases and unresolved ties are not proven
duplicates. Full state and year comparisons are in [the current diagnostics](../state_diagnostics/output/diagnostics.html).

## What external project records show

Three records were sampled from `usable_location == TRUE` with placed-in-service
years 2010–2020, using R seed 20260911. This tiny exploratory sample does not
estimate an error rate. `usable_location` has not included external construction
verification.

- **Oconee Park, Dublin, GA — GAA20100035.** HUD says new construction, 2010,
  117 units, formerly Riverview Heights. [GAO's May 2010 report, Georgia appendix,
  Table 2](https://www.gao.gov/assets/a204076.html) identifies the same project by
  both names, with 117 units and rehabilitation financed through TCAP. GAO also
  describes its renovation. Recommendation: exclude this financing episode from
  new construction through a documented correction; do not infer an original
  construction year from 2010.
- **Sequoia Villas, Lindsay, CA — CAA20120846 / CA-12-168.** HUD reports 18 total
  units and 18 low-income units, but its bedroom counts sum to 19. [California's
  2012 allocation report, Table A-5](https://www.treasurer.ca.gov/ctcac/2012/annualreport.pdf)
  labels the project new construction and distinguishes 19 total from 18
  low-income units. The [Tulare housing authority's property
  page](https://www.hatc.net/family-housing.php?nbl=RP&project=family-sv) also says
  19 units. Recommendation: resolve total units; retain the location. The
  allocation report does not verify the recorded 2012 placed-in-service year.
- **Willoughbeach Terrace, Willowick, OH — OHA20160031.** HUD reports 50 units.
  [OHFA's property description](https://ohiohome.org/ppd/featured/willoughbeachterrace.aspx)
  agrees, its [2014 awards](https://ohiohome.org/ppd/documents/2014HTC-recipients.pdf)
  classify the proposal as new units, and the [operator's
  address](https://willoughbeachterrace.wodagroup.com/contactus) matches 30707 Lake
  Shore Boulevard. These checks support location, size, and construction type;
  they do not independently establish the exact opening year.

## Coverage requires a separate check

Construction type is blank for 1,052 of 1,353 Indiana records (77.8%), compared
with 3.1% in California. Unknown does not mean rehabilitation. The simple TYPE=1
filter will miss construction among those records, so state counts are not yet
comparable measures of all construction.

A targeted example is **River Pointe, Tell City — INA20157173**, with missing
HUD construction type, 2015 placed-in-service year, and 40 units. [Indiana's
project description](https://www.in.gov/ibc/legacyprojects/3457.htm) describes a
new building with 40 senior units plus 10 unrestricted units; the [developer
reports opening it in 2015](https://flco.com/ahf-top-50-affordable-housing-developers-fc-ranks-39/).
This is evidence to investigate inclusion and project scope, not justification
to call every missing-type record new construction or substitute 50 units.

Published comparisons also require aligned definitions. [Urban Institute's 2026
state totals](https://www.urban.org/research/publication/lihtc-40-how-much-affordable-housing-has-been-built-your-state)
explicitly include rehabilitation. [Soltas's Table 1](https://evansoltas.com/papers/SoltasJMP.pdf)
describes 9% applications, including rehabilitation and unsuccessful proposals.
Neither is a direct count benchmark for completed new-construction projects.
[HUD documents additions to earlier years at each
release](https://www.huduser.gov/portal/datasets/lihtc/property.html), so recent
years should not be treated as fully reported construction totals.

The next bounded work is to document the identified exceptions, inspect the
repeated addresses that drive the largest state changes, and assess missing-type
coverage by state and year. The default remains to accept HUD new construction
unless there is specific conflicting evidence.

## Reproduction

Run root `make`, or `make` in this task's `code/` on prepared inputs. The single
linear R script reads the original workbook and the preserved project records,
checks the published totals, and writes the calculation report. Published
benchmark values are transcribed in the script with their URL. Web sources were
read on September 11, 2026; this audit does not download or update production
data. All individual findings above remain recommendations outside the dataset.

The executable benchmark calculation is now `output/checks.txt`, declared as a
substantive audit output in this task Makefile. Dataset metadata reports elsewhere
are side effects of SaveData. The current location sample uses HUD coordinates by
default; the earlier counts and recommendations above are historical.
