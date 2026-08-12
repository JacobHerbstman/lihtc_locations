# Build LIHTC Geocoding Query Crosswalk

This task builds the final local site-component-to-query crosswalk after the
compound and range reviews. It preserves the unchanged 131,473 source sites
through 137,255 address components.

Previously ready sites retain the final readiness audit's street and ZIP
format proposals. Newly reviewed compound components, fractional civic
addresses, literal ranges, and ordinal-street corrections enter the query
table only when no other source, locality, suffix, collision, shared-address,
or malformed-text blocker remains. Cross-development addresses are not grouped
together. The development-scoped key uses the uppercase, whitespace-squished
literal address, so it also does not silently collapse abbreviation variants.

The query table is ready for a separately approved local geocoding pilot, but
every row remains `not_approved`. This task does not call a geocoder, transmit
an address, or assert that a query is a separate building or parcel.
