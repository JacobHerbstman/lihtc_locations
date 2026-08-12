# Audit LIHTC Geocoding Query Crosswalk

This independent audit reconstructs the compound-address component partition,
range decisions, component eligibility, and development-scoped query groups
from the pre-application site table and committed reviews. It verifies source
lineage, one-to-many cardinality, exact two-read application, absence of range
expansion, complete query mappings, retained downstream unit flags, and the
fact that every query remains unapproved.

The audit contains one row per named check. All checks must pass before the
query crosswalk can be described as locally ready for a separately approved
geocoding pilot.
