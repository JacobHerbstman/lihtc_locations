# Single-Address Review Protocol

## Scope

The queue contains 1,149 shared-address questions covering 2,463 current
development records in the 50 states and District of Columbia. Every member
has one development site and a singular street address under the local address
audit. A common address creates a review question; it does not establish
common physical-development identity.

## First read: internal records

The internal read considers the published and normalized names, HUD and state
identifiers, allocation and placed-in-service years, development and
low-income unit counts, and the complete source address. No field is assumed
correct merely because it is labeled as an identifier, unit count, or project
name.

Distinct phase, building, and component labels remain separate unless the
record pair is a duplicate representation of the same component or a direct
source documents one physical building or development. A later record with
the same unit count is linked only when the names or a public record also
support continuity. Equal units by themselves are not a merge rule.

## Second read: public records

Every question has at least one retained direct public source. Thirty-two
questions required a focused web search. The remaining questions were located
through the public sitemaps for Section 8 Search and Affordable Housing Hub,
and the selected direct pages were read rather than inferred from the sitemap
text alone.

Allocating-agency, municipal, housing-authority, owner, manager, and other
direct property records can resolve identity. Public housing directories are
corroborating records: they can confirm that a listed name and address coexist,
but they are not treated as independent proof that HUD's underlying record is
correct. The ledger records direct-source URLs, source coverage, and whether
the outside read resolves identity or only corroborates the listed address.

## Decisions

- `merge_all` assigns all members of a question to one physical development.
- `retain_each` keeps every member as its own physical development.
- `partition` records a mixed member-level result, such as duplicate records
  within Phase I while Phase II remains separate.

The member ledger, not the question label or any executable matching rule,
defines the final partition. The anchor for each cluster is deterministic:
earliest placed-in-service year, then HUD anchor ID, then development ID.

All HUD rows remain available as project episodes and all source addresses
remain evidence. This review does not aggregate unit counts across records.

## Separation from geocoding

Physical-development identity is not a coordinate decision. Separate
developments may share an address, and one physical development may eventually
require more than one query. Every query remains `not_approved`, and this task
makes no network geocoding request.
