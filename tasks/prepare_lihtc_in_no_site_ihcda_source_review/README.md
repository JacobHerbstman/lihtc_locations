# Prepare Indiana No-Site IHCDA Source Review

This preparation-only task records the 40 Indiana developments in the final
no-retained-site queue and the availability of IHCDA's official existing-LIHTC
property source. The frozen state page links the workbook
`Existing-Properties-Report-2026.05.11-v2.xlsx`, described by IHCDA as its
listing of existing LIHTC properties. The workbook bytes are not frozen, so
the task stops at a source-access blocker and performs no property screen.

Every row remains `not_adjudicated` and `not_approved`. The task creates no
candidate identity, site, address, geocoding query, or data correction. A
later task may screen Indiana only after the linked workbook is frozen with
byte-level provenance.

Run `make` from `code/`.
