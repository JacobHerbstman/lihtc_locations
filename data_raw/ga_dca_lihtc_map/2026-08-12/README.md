# Georgia DCA LIHTC Placed-in-Service Map Freeze

Georgia Department of Community Affairs (DCA) identifies its **Low-Income
Housing Tax Credit Placed-In-Service Map** as a way to locate LIHTC properties
and says that it highlights unit count, tenancy type, and location:
<https://dca.georgia.gov/affordable-housing/housing-development>.

On 2026-08-12 this directory's official ArcGIS Experience configuration, its
Georgia-DCA-hosted web-map configuration, and the referenced feature-layer
schema were retrieved and frozen. `manifest.csv` gives the exact retrieval
URL, byte count, and SHA-256 digest for each file. The web map identifies the
layer as `PIS_LIHTC_Properties_(Monitored)` and its schema includes property
name, city, units, low-income units, ZIP, and full address.

The feature service advertises `Query` capability, but this freeze contains no
feature rows. Therefore this directory is a documented source-access blocker,
not a usable property screen: it must not be used to infer candidate identities,
sites, addresses, or geography. A future retrieval must freeze the complete
query response and its manifest before screening can begin.
