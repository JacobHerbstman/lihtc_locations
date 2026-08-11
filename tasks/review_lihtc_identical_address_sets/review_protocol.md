# Identical Address-Set Review Protocol

## Scope

The review universe is the 98 unresolved groups in the identical-address-set
audit after excluding `IAS0670` and `IAS0687`. Those two excluded groups are
the already diagnosed Massachusetts eight-address and Baltimore 53-address
portfolio cross-listings.

Each review question asks whether the development records carrying one exact
complete address set describe one physical development or distinct physical
developments. The decision is not an instruction to add, remove, or geocode an
address.

## Two reads

The internal read compares the original and normalized names, state, city,
allocation and placed-in-service timing, development-level unit counts, episode
counts, and every address in the complete set. No labeled field is assumed to
be correct merely because it is populated.

The outside read retains a reproducible search URL and a direct public source.
Allocating-agency, housing-authority, municipal, county, developer, owner, and
other official records are preferred. Housing-sector compilations and public
property directories are used as corroboration and are not treated as proof
that every HUD address is correct.

## Decisions

- `merge_all` proposes one physical-development identifier for every member of
  the group. All source rows remain separate project episodes and all source
  addresses remain evidence.
- `retain_each` preserves every member as a distinct physical development.

The address-set assessment is separate from the identity decision. A pair of
duplicate name variants can be one development while their shared address set
still contains an unrelated address. Conversely, distinct phases can share a
valid campus address set.

No unit count is summed or selected by this task. Conflicting unit scopes stay
visible for later project-episode adjudication.

## Geocoding boundary

Every row remains `not_approved` for geocoding. Known copied, administrative,
or contaminated address sets must be repaired in a later site-level task. No
address is sent to an outside service here.
