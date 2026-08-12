# Prepare LIHTC Compound-Address Review

This task prepares every final site whose source street cell appears to contain
more than one address. It is local and read-only: no address is transmitted,
no source site is changed, and no parse proposal is approved for geocoding.

The strict parser proposes components only when the entire cell follows one of
two narrow forms: a list of full civic-number tokens followed by one shared
street tail, or semicolon-delimited components that each begin with a civic
number and their own street text. Number fragments must have equal digit
length, so strings such as `801,3,5,7 LINCOLN` do not pass. Fractions, broken
digit strings, nested address lists, and strings that require inferred street
text remain manual-review questions.

The question Parquet freezes one row per source site and the proposal Parquet
freezes zero or more parser-proposed components. Collisions with another
proposal or an existing site in the same development are flagged rather than
silently deduplicated. A separate committed review task decides whether any
proposal is operative.
