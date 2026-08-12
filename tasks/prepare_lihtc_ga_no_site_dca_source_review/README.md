# Prepare Georgia No-Site DCA Source Review

This task records the 41 Georgia developments in the final no-retained-site
queue and the current access status of Georgia DCA's official LIHTC
Placed-in-Service Map.

The frozen DCA ArcGIS configurations identify an official property layer with
property name, city, unit count, and address fields. However, no feature rows
were frozen. Accordingly, the task emits a source-access blocker for every
Georgia question. It emits no exact or fuzzy candidates. Four of the 41
questions also lack a city, so even a later name/city/unit screen will need an
explicit missing-city branch.

This is preparation only. Every row remains `not_adjudicated` and
`not_approved`; it does not identify or create a site, apply an address, approve
a geocoding query, or modify final LIHTC data. The blocker can be cleared only
by freezing a complete feature-query response with a byte-level manifest, then
building a separate conservative screen.
