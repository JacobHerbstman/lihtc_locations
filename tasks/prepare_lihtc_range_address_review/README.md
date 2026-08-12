# Prepare LIHTC Range-Address Review

This task screens ranges only after the compound-address review has created the
address-component layer. It selects 8,815 apparent leading ranges and never
expands an endpoint sequence.

The parser separates 383 likely ordinal-street false positives, 53 unresolved
compound expressions containing ranges, 38 `TO` intervals, 922 spaced-hyphen
forms, and 7,419 ambiguous tight-hyphen forms. The latter may be true ranges or
local civic-number conventions, so syntax alone does not change them.

The output freezes parsed endpoints, literal delimiters, locality and upstream
review flags, and a format-only proposal for the apparent ordinal-street cases.
A separate two-read review decides whether to retain a literal query, accept a
single-address normalization, or keep the component blocked. No query is
approved or transmitted here.
