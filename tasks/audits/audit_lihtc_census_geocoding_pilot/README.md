# Census pilot audit

This independent audit reads the parsed pilot output and the frozen manifest. It verifies returned identifier coverage and uniqueness, state-FIPS agreement for matched results, match and exact-match rates, and Census-to-HUD coordinate distances where comparison coordinates exist.

It reports quality; it does not turn any pilot result into an approval for bulk submission or tract assignment.

The supporting review queue contains every unmatched, tied, or non-exact
result, plus exact matches more than one kilometer from the comparison HUD
coordinate. HUD coordinates are not treated as ground truth; the distance flag
only identifies cases that deserve a separate read.
