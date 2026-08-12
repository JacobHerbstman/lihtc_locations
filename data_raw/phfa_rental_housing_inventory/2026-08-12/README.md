# PHFA Rental Housing Inventory snapshot

Retrieved from the Pennsylvania Housing Finance Agency on 2026-08-12.

Source page: https://www.phfa.org/renters/#mfinventory

The source page says this inventory identifies properties funded at some point
by PHFA or properties for which PHFA is the Section 8 contract administrator.
It is not an assertion that each listed address exhausts a development's
physical site inventory. The files are therefore frozen as source evidence for
manual identity and location review, not as automatic address replacements.

`phfa_renters.html` is the retrieved source page. `manifest.sha256` freezes the
hash of every source byte used by the parser. The 66 `dv_*.pdf` files are
the valid PDF responses from its 67 county menu entries. The Northampton
endpoint returned an HTML error response rather than a PDF and is deliberately
absent. No PDF was transformed.

The SHA-256 of `manifest.sha256` is:

`126692549c9ff0605892c4deaec18cfa62e0cbeb8c83d1a22a41e07bf0813095`

The current snapshot must be treated as time-varying administrative evidence.
Historical projects, renamed properties, scattered-site developments, and
later management addresses require a genuinely independent source read before
an address is accepted.
