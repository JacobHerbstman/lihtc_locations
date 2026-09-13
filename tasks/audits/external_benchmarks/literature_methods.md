# LIHTC papers: missing locations and sample construction

Read September 12, 2026. This note compares documented methods with our current
rules; it introduces no production source, manual correction, or sample change.

All 570 source new-construction records with neither valid HUD coordinates nor
queryable addresses already have `location_available=FALSE` and
`confident_first=FALSE`. They remain in `project_records.csv`. Excluding them
from a location sample is our methodological judgment; the readings below are
precedents and qualifications, not a universal requirement imposed by the literature.

## Papers and exact passages to consult

**Baum-Snow and Marion, Journal of Public Economics (2009), “The Effects of Low
Income Housing Tax Credit Developments on Neighborhoods.”** Read the
[December 2008 author version](https://drive.google.com/file/d/1guHcDX32kXCRvWDUlL50zQ1EltkQZJkd/view),
Section 4, printed pp. 13–14. Their 24,504-project HUD file has 9.5% missing
locations and 4.9% missing unit counts. They discuss missingness relative to their
regression-discontinuity threshold, use metropolitan projects allocated from
1994 and placed in service by 1999, and do not describe recovering each missing
address. This supports explicitly acknowledging incomplete location coverage;
their identifying assumption does not establish that our state losses are random.

**Diamond and McQuade, Journal of Political Economy (2019), “Who Wants Affordable
Housing in Their Backyard?”** Read the
[December 2017 author version with appendices](https://www.rebecca-diamond.com/files/affordable-housing.pdf),
Appendix A.2.3, printed pp. 40–41; Section 4.2, p. 14; Table 1 and Table A2.
They use HUD, note missing geocodes, and explicitly exclude missing allocation
years. Their price-effect treatment date is allocation, and the sample includes
rehabilitation as well as new construction. The appendix does not specify a
missing-geocode recovery procedure or our first-address rule. The publisher's
separate appendix and data archive are linked on the
[journal page](https://www.journals.uchicago.edu/doi/10.1086/701354), but downloads
returned HTTP 403; replication code was not inspected.

**Wilson, Hankinson, Magazinnik, and Sands, Urban Affairs Review (2024),
“Inaccuracies in Low Income Housing Geocodes: When and Why They Matter.”** Read
the [March 18, 2023 author version](https://www.mhankinson.com/documents/lihtc_geocodes.pdf),
printed p. 3, pp. 11–13, and notes 5–6 on p. 15. It recognizes that exhaustive
manual auditing is often infeasible, recommends automated Google geocoding for
local analyses, and allows that HUD points may be preferable for larger-area
aggregation. It also recommends targeted visual checks where feasible. Note 5
excludes 17 missing-HUD-coordinate cases from accuracy comparisons; that is not
a construction-sample exclusion rule. Note 6 excludes scattered sites and treats
separate phases as separate parcels.

## Implications for this dataset

Keep the automatic exclusion of unlocatable records and the existing state/year
accounting. No building-by-building Google searches are added. A usable HUD point
can retain a project whose address text is incomplete. Missing hedonics remain
permissible for a location observation.

No exact first-address procedure was found in these readings. It remains our
explicit definition of the first recorded new-construction siting at a standardized
primary address. It can omit later phases; these papers do not establish that
all such phases are duplicates. No change to that settled rule is made here.

Accepting HUD points does not verify building footprints. Before a future study
uses very small distance bands, its required location precision should be considered
separately. That does not make manual adjudication a prerequisite for the present
national project-location dataset.

## Reading and verification limits

Papers were read from the linked author versions, not assumed identical in every
detail to the final journal versions. Public PDFs were downloaded only into
temporary storage. Docling was unavailable; the PDF-reading tool fell back to
`pdftotext -layout`, whose output has some degraded typography. Relevant prose
was inspected in context. No effect estimates were extracted or reproduced, no
new exploratory plots were generated, and no production data were changed.

## September 12 implementation update

The simplified production dataset now uses HUD coordinates only, retains the
previously agreed first-address counting rule, and keeps missing dates/hedonics
and scope flags in one main file. Census fallback and extra confidence filters
are removed. Partial valid bedroom counts remain; tables report marginal and
joint Ns. This adopts transparent source-based selection and analysis-specific
missingness handling. The first-address rule remains our research definition,
not a cleaning recipe established by the papers above. Later construction phases
and repeated financing motivate the all-HUD-ID comparison in the state/year audit.

## September 12 reassessment: first address is too restrictive for project construction

At revision `ace2cc0`, Jacob asked whether first-address counting is actually the
right definition. The recommendation from this review is to use HUD project IDs
for the main new-construction dataset and retain first-address counts as a
sensitivity comparison. This is a recommendation, not a production change in
this review.

HUD's [Updating the LIHTC Database: Projects Placed in Service Through 2006](https://www.huduser.gov/datasets/lihtc/report9506.pdf),
printed pp. 68–69 (PDF pages 77–78), explains that its file is project-level:
separate phases and sets of buildings receiving different allocations can share
one representative address while appearing as different records. That is direct
source documentation against interpreting every repeated address as a duplicate.
The report concerns an older release, but identifies the relevant distinction
between project records and representative addresses. It does not establish that
every repeat in the current release is a separate construction event.

The current first-address rule removes 1,246 of the 28,456 TYPE=1 records with HUD
coordinates: 617 later-year records, 550 additional earliest-year ties and 79
records whose repeated-address ordering is unresolved. Among the 617 later-year
records, 122 contain the literal word PHASE in their names and 522 are dated
within five years of the first record. These indicators make later construction
plausible; they do not independently verify phases or incremental unit totals.

For example, the unchanged HUD source lists Weeks Field Estates Phase I
(AKA20090010) at 1301 Kellum Street with 74 units and a 2009 placed-in-service
year, and Phase II (AKA20110020) at the same address with 56 units and a 2011
year. Both are TYPE=1 and have HUD coordinates. First-address selection drops
Phase II solely because the address appeared earlier. No external building
investigation or override was used for this example.

The existing filter answers when an address first appears with new construction.
The user's stated objective instead calls for each HUD-reported new-construction
project and its date/characteristics. The proposed rule keeps each unique HUD ID
with TYPE=1 and HUD coordinates, flags shared addresses and resyndication, and
uses first-address counting only as a comparison. A shared address alone would
not remove a project or force its hedonics to agree with a separate HUD record.
Exact duplicate HUD IDs remain a key check; all IDs in the pinned source are
already unique. Residual source classification and repeated-financing uncertainty
remain explicit.

Reproduce the exclusion counts from `project_records.csv` by restricting to
`hud_coordinates_present == TRUE & selected == FALSE` and tabulating
`exclusion_reason`. For the 617 later-year records, the phase-name count uses
`grepl("PHASE", project_name, ignore.case = TRUE)`; timing uses
`pis_year - first_year <= 5`. Production code and data are unchanged by this review.
