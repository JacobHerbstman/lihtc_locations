# Prepare HUD LIHTC Multi-Address Data

This task converts HUD's `LIHTCPUB_BIN.xlsx` workbook to raw-text Parquet without changing its contents. The workbook is the supplementary multi-address file bundled with the committed 2024 LIHTC archive. Its rows are address records nested within HUD projects; they are not a complete national building inventory, and `bin` is not a nationally unique building key.

The output is `output/lihtc_multisite_2024_raw_text.parquet`. It preserves all 161,715 published rows, eight columns, missing cells, and nonmissing text values. Downstream tasks must make normalization, deduplication, and interpretation explicit.

Run from `code/`:

```sh
make
```
