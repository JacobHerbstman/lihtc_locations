# Review Wisconsin Low-Income Shares

This task records the adjudication of 197 Wisconsin physical developments whose
HUD low-income-unit share is below 20 percent. The committed ledger has one row
per development. A direct WHEDA proposal requires a unique normalized-name and
placed-in-service-year match and identical total units. The validator checks
every proposed value against the immutable WHEDA HTML snapshot prepared
upstream.

The output is evidence only. It does not change the HUD-derived development,
episode, or site tables. Records with a total-unit-scope disagreement, multiple
candidates, or no candidate retain their HUD values until a separate scope
review resolves them.

Run from `code/` with `make`.
