# LIHTC Location: Preliminary Literature Map

## Bottom line

LIHTC project locations are public. HUD's current property database covers
55,345 projects and 3.9 million units placed in service from 1987 through 2024.
It includes addresses, latitude and longitude, units, allocation and
placed-in-service years, construction type, and credit characteristics. The
archive is a rolling release, and nearly every variable has some missingness.

There is already a substantial literature on the neighborhoods and
municipalities that receive LIHTC housing. The historical descriptive evidence
is consistent with the proposed fact: LIHTC developments tend to be in poorer,
lower-homeownership neighborhoods. The narrower question still looks useful:

> Among feasible neighborhoods within the same municipality, are new LIHTC
> developments disproportionately allocated to places with lower baseline
> homeownership and income?

The contribution would not be documenting that LIHTC neighborhoods are
disadvantaged. It would be separating within-municipality sorting from
cross-municipality exclusion, using neighborhood conditions measured before
the siting decision, and defining the set of plausible alternative locations.
This is a preliminary search, not a systematic review, so the novelty claim
should remain provisional.

## Closest work

| Source | Setting and method | Main result | Relationship to this project |
| --- | --- | --- | --- |
| [Freeman (2004)](https://www.brookings.edu/wp-content/uploads/2016/06/20040405_Freeman.pdf) | National HUD LIHTC data for projects built in the 1990s, linked to 1990 and 2000 tract characteristics | LIHTC neighborhoods were poorer and had fewer homeowners than metropolitan neighborhoods overall. In 2000, their unit-weighted homeownership rate was 45.7%, compared with 63.4% across metropolitan neighborhoods. | Directly establishes the broad descriptive pattern, including homeownership, but does not isolate comparisons among neighborhoods in the same municipality or model the siting opportunity set. |
| [Oakley (2008)](https://doi.org/10.1177/1078087407309432) | Sociospatial analysis of LIHTC developments in four metropolitan areas | LIHTC projects reached less disadvantaged neighborhoods than older subsidized programs but remained spatially clustered; an existing project predicted nearby development. | Shows why spatial clustering and prior subsidized-housing locations must be handled explicitly. |
| [Lang (2012)](https://doi.org/10.1016/j.jhe.2012.04.002) | Tract-level analysis of market rents, QCT status, and LIHTC development | Projects are more likely in lower-rent places, consistent with a lower opportunity cost of rent restrictions; QCT incentives are not the only explanation. | Provides a developer-cost mechanism that is correlated with both poverty and homeownership. |
| [Ellen, Horn, and O'Regan (2016)](https://www.prrac.org/pdf/EllenHornORegan_JHE2016_LIHTCPovConc.pdf) | National project data plus tenant data from 12 states and funded/unfunded proposals from five states | Finds little evidence that LIHTC increases metropolitan poverty concentration and some evidence of declining poverty in high-poverty receiving tracts. | Shows the siting-versus-tenant-composition distinction and the value of applicant data. It studies poverty, not the within-city homeownership gradient. |
| [Ellen and Horn (2018)](https://nlihc.org/sites/default/files/Points-for-Place.pdf) | Changes in Qualified Allocation Plans across 20 states, comparing 2003–2005 with 2011–2013 allocations | QAP changes prioritizing opportunity were associated with more credits in lower-poverty and less heavily minority neighborhoods. The paper explicitly identifies land cost, zoning, site availability, and community opposition as constraints. | Closest policy paper. It hypothesizes stronger opposition in homeowner-heavy areas but does not test homeownership as the siting outcome of interest. |
| [Schwartz and McClure (2023)](https://doi.org/10.1080/10511482.2023.2171740) | National municipality-level analysis of LIHTC presence | Seventy-two percent of municipalities had no LIHTC housing. Excluding municipalities were generally smaller, wealthier, whiter, and had less rental and multifamily housing. | Establishes cross-municipality exclusion. The proposed project asks where projects go conditional on being inside a municipality. |
| [Cook, Li, and Binder (2026)](https://www.iza.org/publications/dp/18711/where-to-build-affordable-housing-evaluating-the-tradeoffs-of-location) | Administrative tenant data and a structural location-choice model | Higher-opportunity locations cost more and reduce segregation, but they attract and house a different applicant pool. | Clarifies why location is itself a distributional policy choice; it does not estimate the homeowner gradient in observed project siting. |

## Political mechanism literature

[Scally and Tighe (2015)](https://doi.org/10.1080/02673037.2015.1013093)
survey affordable-housing developers and conclude that community opposition can
redirect projects toward less-contested locations. [Marble and Nall
(2021)](https://doi.org/10.1086/711717) show that homeowners, including liberal
homeowners, are especially likely to oppose dense and affordable housing.
[Fang, Stewart, and Tyndall (2023)](https://doi.org/10.1016/j.jue.2023.103608)
link higher ward homeownership in Toronto to councillor opposition to local
housing projects. These papers support a political channel but do not establish
that it causes the national LIHTC location pattern.

[Hankinson, Magazinnik, and Sands
(2026)](https://doi.org/10.1111/ajps.70022) use California LIHTC construction to
study subsequent voting on affordable-housing bonds. Their block-level design
and homeowner-versus-renter heterogeneity are methodologically relevant, but
project siting is the treatment rather than the outcome.

## Empirical object

The clean first-stage object is a tract-by-allocation-year panel. Placed-in-
service year is useful for dating completion, but allocation year is closer to
the location decision. For each project, the candidate choice set is the set of
tracts in the same municipality at the time of allocation.

Primary outcomes should be reported separately:

- whether a tract receives a new-construction project;
- the number of new-construction projects;
- total and low-income units allocated to the tract;
- acquisition or rehabilitation projects, which inherit the geography of
  existing buildings and answer a different question.

The central exposure is baseline owner-occupied share among occupied housing
units. Poverty, median household income, gross rent, rental share, multifamily
share, vacancy, density, race and ethnicity, and existing subsidized housing
are competing explanations or confounders. Baseline ACS measures should end
before allocation. QCT and DDA status must be matched to the allocation year.

## The denominator decision

"Disproportionately" has no unique meaning. At least three comparisons answer
different questions:

1. **Per tract:** Where on the municipal map do projects go?
2. **Per existing rental or multifamily unit:** Are projects concentrated
   beyond the existing geography of rental housing?
3. **Per feasible development site or zoned capacity:** Are projects sorted
   after accounting for where multifamily construction could plausibly occur?

The third comparison is closest to a political-siting interpretation, but no
clean national historical zoning panel exists. The first paper-quality result
should therefore show the raw tract gradient, a rental-stock denominator, and
a multifamily-stock denominator. It should describe the residual association
as political only after stronger evidence is available.

## Proposed first pass

1. Restrict the main sample to new construction with usable coordinates and
   allocation or placed-in-service years. Keep rehab as a separate result.
2. Assign projects to Census tracts and legal places using explicit boundary
   vintages rather than HUD city strings.
3. Construct lagged ACS tract measures and annual QCT/DDA status.
4. Within each municipality, rank tracts by baseline homeownership and poverty.
5. Plot project counts and units across municipal deciles using each of the
   three denominators above.
6. Estimate tract-year Poisson models with municipality-by-year fixed effects.
   Add housing-stock and rent controls before demographic controls; show QCT
   both as a mechanism and as a control.
7. Audit geocoding failures, boundary cases, projects spanning multiple
   addresses, and municipality-years with no meaningful within-place choice.

This sequence produces a transparent descriptive fact before asking for a
causal interpretation. A political mechanism would need additional variation,
such as changes in local-approval rules, QAP provisions, zoning, or political
boundaries.

## Acquisition status

HUD's [official property-data
page](https://www.huduser.gov/portal/datasets/lihtc/property.html) documents a
downloadable rolling ZIP. HTTP/2 command-line requests receive a web-
application-firewall challenge, but a normal HTTP/1.1 request succeeds. The
`fetch_lihtc_property` task pins the official 2024 archive by checksum and
validates 55,345 project rows and 80 columns in `LIHTCPUB.xlsx`. HUD does not
publish a year-specific URL, so long-run replication still requires depositing
the exact archive in a versioned research repository before the rolling file is
replaced.
