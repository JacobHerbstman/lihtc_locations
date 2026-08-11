# Mixed-Site Identity Review Protocol

## Scope

The queue contains 87 questions covering 195 current development records in
the 50 states and District of Columbia. A shared address creates a review
question; it does not establish common physical-development identity.

## First read: internal records

The internal read considers published and normalized names, HUD and state
identifiers, allocation and placed-in-service years, source-reported unit
counts, every financing episode, and each member's complete site set. No field
is assumed correct because it is labeled as an identifier, unit count, or
address.

Distinct physical buildings and named phases remain separate unless the pair
is a duplicate representation of the same component or a direct source shows
one physical property. Equal unit counts do not establish identity. A longer
site list is not assigned to a shorter member merely because the two lists
overlap.

## Second read: public records

Every question retains at least one direct public source. Allocating-agency,
municipal, housing-authority, owner, and manager records can resolve identity.
Public housing directories are corroborating records: they can confirm that a
published name, address, year, and unit count coexist, but do not override
contrary official evidence.

## Decisions

- `merge_all` assigns all members to one reviewed cluster.
- `retain_each` keeps every member in its own reviewed cluster.
- `partition` records a mixed result, such as duplicate records within Phase II
  while Phase I remains separate.

The member ledger, not the question label or an executable matching rule,
defines the final partition. The anchor for each physical cluster is the
earliest placed-in-service year, then HUD anchor ID, then development ID.

Financing episodes remain distinct and source-reported unit counts are not
summed. The Ciena duplicate is linked to Ciena, Hobbs Court remains separate,
and the combined 340-unit Hobbs/Ciena record is held as a nonphysical umbrella
episode until an episode-to-property bridge is reviewed.

## Separation from geocoding

Physical-development identity is not a coordinate decision. Separate
developments may share an address, and one physical development may require
more than one query. Every query remains `not_approved`.
