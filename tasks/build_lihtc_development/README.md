# Build LIHTC Development Data

This task constructs three linked analytical tables from HUD's property and supplementary multi-address files:

- `lihtc_development_2024.parquet`: one provisional row per underlying physical development.
- `lihtc_project_episode_2024.parquet`: one row per published HUD ID, interpreted as a project or financing episode.
- `lihtc_development_site_2024.parquet`: one row per exact normalized address within a development.

The linkage is deliberately conservative. Two HUD IDs are assigned to the same provisional development only when their normalized project names agree and either their standardized informative primary addresses agree or their complete standardized informative multi-address sets agree. Street standardization covers common direction and street-type abbreviations. Shared BIN values, fuzzy names, and partial address overlap do not create links. Every linked development is marked for review.

Development-level unit counts are resolved only for singleton HUD records. Every linked development retains a candidate aggregation rule and candidate unit total, but its final development total remains missing until the linkage group is reviewed. The project-episode table always retains the published values.

Run from `code/`:

```sh
make
```
