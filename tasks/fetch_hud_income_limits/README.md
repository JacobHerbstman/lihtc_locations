# Fetch HUD income limits

This separate task owns the official revised FY2024 MTSP workbook. Its actual root
target is `data_raw/hud_income_limits/2024/MTSP-Data-FY24.xlsx`. The workbook endpoint
currently returns HTTP 202 with an AWS WAF challenge and zero bytes. The producing
script fails before publishing a source; it has not produced or validated a workbook.
This blocked source is separate from the working Census demographic build.

Once access works, the workbook must be inspected before writing the area/household-
size cleaning and join. Use official HUD area geography, including New England towns;
do not multiply tract ACS median household income by HUD ceiling percentages. Initial
results will be area benchmarks, not observed rents or exact project legal limits.

The source and remaining work are recorded in [the Census methods](../../CENSUS_PLAN.md).
