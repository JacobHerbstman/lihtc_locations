# Apply LIHTC Single-Address Review

This task applies the committed two-read partition of 1,149 shared
single-address questions to the current physical-development,
project-episode, and development-site tables.

The member ledger is the complete identity mapping for the reviewed records.
The application does not rerun a matcher or infer links from names or
addresses. It preserves every HUD project episode and every distinct mapped
development/address key. Site keys that become exact duplicates inside one
reviewed physical development collapse to one site record with all
contributing HUD identifiers retained.

Newly merged development-level unit totals remain missing until unit scope is
reviewed. No source address is changed and no geocoding query is approved.
The `audits/audit_lihtc_single_address_adjudicated` task independently
reconciles the application against the inputs and committed mapping.

Run `make` from `code/`.
