# Audit LIHTC Cross-Development Addresses After Round 2

This task verifies the applied member partition against the complete set of
addresses that were shared before round two.

The audit separately checks two populations:

- all 587 name/timing and phase/component candidate edges prepared for round
  two, each of which must end either inside one physical-development cluster or
  between two explicitly reviewed distinct clusters; and
- every address and development pair that remains shared after remapping,
  including lower-priority overlaps that were outside the round-two queue.

The residual files preserve review status and local address, source, and HUD
coordinate problem flags. They do not approve a common coordinate query, edit
a source row, or call a geocoder.

Run from `code/`:

```sh
make
```
