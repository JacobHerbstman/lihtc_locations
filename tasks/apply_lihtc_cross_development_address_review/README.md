# Apply LIHTC Cross-Development Address Review

This task applies the committed shared-address identity review to the current
physical-development, project-episode, and development-site tables.

Only the 113 `merge` decisions change a physical-development identifier. Every
HUD row remains a project episode. Sites are rebuilt from the HUD property and
multi-address source rows only for developments that merge, so identical sites
collapse within the newly adjudicated development without discarding distinct
addresses. The 24 `retain_separate` questions keep all 53 current development
identifiers.

The task does not edit a source address, choose a unit total for a merged
development, approve a shared geocoding query, or call a geocoder.

Run from `code/`:

```sh
make
```
