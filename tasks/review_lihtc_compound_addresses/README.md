# Review LIHTC Compound Addresses

This task validates two independent local reads of all 5,114 compound-address
questions. The reads agreed on 3,309 strict splits and 37 single fractional
civic addresses. The remaining 1,768 cells stay unresolved, including every
disagreement, incomplete fragment, collision concern, intersection, range,
and expression that needs inferred street text.

The committed question ledger preserves both reads and the conservative final
decision. The component ledger explicitly lists all 9,091 reviewed address
components; no parser proposal becomes operative by default. The validator
requires exact question coverage, agreement for every applied split, exact
equality to the frozen parser components, and `not_approved` submission status
throughout.
