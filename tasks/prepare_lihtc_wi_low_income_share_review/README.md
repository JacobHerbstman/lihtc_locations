# Prepare Wisconsin Low-Income-Share Review

This task extracts WHEDA's monitored housing-tax-credit inventory and prepares
conservative candidate evidence for Wisconsin physical developments whose HUD
low-income-unit share is below 20 percent. It does not alter a LIHTC value.

The committed HTML source was downloaded from WHEDA's
[Monitored HTC Projects](https://www.wheda.com/developers-and-property-managers/tax-credits/multifamily-data-library/monitored-htc-projects)
on 2026-08-12. It reported an effective date of 2026-03-31 and 925 displayed
projects; 902 distinct WHEDA project IDs remain after removing repeated cards.
Its SHA-256 is `ba00414cf334e76c060d65ca8bcbda9ef6b2f50b260b3bdfca58af9bff2da25c`.

Candidates require the same placed-in-service year and Jaro-Winkler normalized
name distance no greater than 0.15. The output states whether the total-unit
count also agrees. The next review task, rather than this preparation task,
decides whether an official low-income-unit value is usable.

Run from `code/` with `make`.
