# Apply LIHTC Name-Variant Linkage Review

This task applies the second committed linkage ledger to the current physical-development, project-episode, and development-site tables.

Merged blocks receive one development ID and retain every HUD row as a project episode. Retained blocks keep their current development IDs. Sites belonging to reviewed developments are rebuilt from the HUD property addresses and full multi-address file after reassignment, so sites shared across newly merged episodes collapse without losing source address or BIN coverage. Site rows outside the review are preserved unchanged.

Final development-level unit counts remain missing for every merged multi-episode development. The task records candidate rules separately, including exact duplicate records used once and the two Ten Fifty B financing components summed only as a review candidate.

Run from `code/`:

```sh
make
```
