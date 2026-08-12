# Audit LIHTC Cross-Development Addresses

This local audit examines every standardized street, city, and state combination that appears in more than one final LIHTC development. It does not merge developments, alter site addresses, approve geocoding queries, call a geocoder, or transmit an address.

The outputs separate three units of review:

- one row per shared address;
- one row per development represented at that address; and
- one row per unique pair of developments sharing at least one address.

The pair table prevents a repeated portfolio address set from being mistaken for many independent identity signals. It records exact and fuzzy name evidence, state-ID overlap, primary-address overlap, complete-address-set equality, project timing and units, coordinate overlap, address-form problems, and the fraction of each development's sites shared by the pair. Review strata prioritize cases; they are not merge or geocoding decisions. Every development and site remains unchanged and every substantive disposition remains `unresolved`.

The canonical output is `output/lihtc_cross_development_pairs.parquet`. The address-group and member Parquets, manual-review sample, and audit summary are supporting outputs from the same run.

Run from `code/`:

```sh
make
```
