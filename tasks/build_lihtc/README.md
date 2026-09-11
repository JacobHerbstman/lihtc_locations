# First new-construction locations

Read original-source project records and Census address matches. There is no
physical-development reconstruction or external adjudication prerequisite.

`project_records.csv` preserves every original new-construction HUD record with
its selection and location result. `projects.csv` selects the first dated new
construction per standardized primary address. Unique records remain even with
missing years or hedonics. Repeated addresses with missing dates or conflicting
first-year ties remain unresolved in the record table and review.csv. Exact ties
can use the smallest HUD ID only if name, date, units, bedroom counts, credit,
and scattered status agree and name/total units are known. Later records are
preserved, not called source errors: some are real later phases. All repeated
addresses require review before treating the first-address rule as verified.

This is first *new construction*, not first LIHTC financing; rehabilitation
records are irrelevant to the initial filter. There are no parcel IDs. Address
standardization does not resolve aliases, nearby buildings, or changing lots.

Census matches in the reported state are checked against HUD coordinates.
A non-exact string match can be accepted when HUD agrees within the threshold;
without a HUD comparison, an exact Census match is required.
A distance above the 500-meter review threshold is a flag, not a proven error.
Census range-interpolated points are not rooftop validation. If Census does not
match, existing plausible HUD coordinates remain explicitly unconfirmed.
Scattered projects keep a primary point with incomplete-site status. The
`usable_location` flag requires selection, checked location, and no known
repeat-address/resyndication question; it does not require units or bedrooms.
Source and Census coordinates remain in project_records.csv for comparison.
Census coordinates are used when a match agrees with the reported state; where
sources disagree, that choice is provisional and usable_location is false.

`review.csv` is the bounded list of repeated-address and location questions,
including all members of repeated groups. No new construction is reclassified
without evidence. Missing or inconsistent hedonics remain separate field-level
issues. Run root make for complete freshness, or make here on prepared inputs.
