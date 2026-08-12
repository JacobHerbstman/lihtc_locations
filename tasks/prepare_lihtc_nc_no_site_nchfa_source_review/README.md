# Prepare North Carolina No-Site NCHFA Source Review

This task screens the 55 North Carolina developments in the final no-retained-site
queue against a frozen copy of NCHFA's official **Find Awarded Projects**
directory. NCHFA administers North Carolina's Housing Credit Program. The
directory is an official statewide award/property source with project name,
city, county, total units, type, owner, bond-deal indicator, and award year.

The frozen directory has no street-address field, geographic coordinates, or
stable project identifier. It is therefore suitable only for identity-candidate
screening. It cannot identify, verify, create, or delimit a physical site, and
it cannot establish complete physical-site scope. In particular, an award row
can be a financing record or a current project label rather than a complete
physical-property inventory.

The task records two deliberately conservative ledgers:

- exact normalized-name matches only when that name occurs once in both the
  question set and source directory; and
- non-exact matches only where the North Carolina state, normalized city, and
  total units agree and Levenshtein distance is at most 0.25 of the longer
  normalized name.

This is preparation only. All rows remain `not_adjudicated` and `not_approved`.
It does not create a site, approve a geocoding query, use an address, change
final LIHTC data, or authorize geography work. A later row-level review with
independent physical-property evidence is required before any candidate can be
used.

The exact URLs, retrieved-byte SHA-256 digests, and page names are in
`data_raw/nchfa_funded_rental_projects/2026-08-12/source_manifest.csv`; the
source README documents the source and freeze. Run `make` from `code/`.
