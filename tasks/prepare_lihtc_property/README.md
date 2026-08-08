# Prepare HUD LIHTC Property Data

This task converts HUD's published Excel property table to a columnar analytical input without changing its contents. It imports every cell as text so that Excel type inference cannot strip leading zeros or silently choose numeric, date, or logical meanings. The output is `output/lihtc_property_2024_raw_text.parquet`.

The Parquet file is a faithful access layer, not cleaned data. It has the same 55,345 rows, 80 columns, names, order, missing cells, and raw nonmissing values as the published `Data` worksheet. Downstream audit and construction tasks must make any type conversion or value correction explicitly.

Run from `code/`:

```sh
make
```
