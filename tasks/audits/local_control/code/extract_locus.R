# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
library(DBI)
library(duckdb)
source("../../../shared/code/save_data.R")

# 1. Check the existing public source bytes against their recorded publisher hashes.
hashes <- fread("source_hashes.csv")
stopifnot(nrow(hashes) == 8L, !anyDuplicated(hashes$source_file))
stopifnot(setequal(list.files("../input", pattern = "^train-.*[.]parquet$"), hashes$source_file))
for (i in seq_len(nrow(hashes))) {
  hash <- system2("shasum", c("-a", "256", paste0("../input/", hashes$source_file[i])), stdout = TRUE)
  stopifnot(length(hash) == 1L, is.null(attr(hash, "status")), substr(hash, 1, 64) == hashes$sha256[i])
}
keys <- fread("city_keys.csv", colClasses = "character")
cities <- fread("../input/cities.csv", colClasses = "character")
stopifnot(!anyDuplicated(keys$place_geoid), !anyDuplicated(keys[, .(locus_state, city_key)]),
  setequal(keys$place_geoid, cities$place_geoid), !anyDuplicated(cities$place_geoid))
keys <- merge(keys, cities, by = "place_geoid", all.x = TRUE)

# 2. Keep every raw city chunk, regardless of its automated topic or function label.
con <- dbConnect(duckdb())
dbWriteTable(con, "city_keys", as.data.frame(keys))
x <- as.data.table(dbGetQuery(con, "
  SELECT k.place_geoid, k.city_name,
    regexp_extract(r.filename, '[^/]+$') AS source_file,
    r.file_row_number + 1 AS source_row,
    r.header, r.content, r.is_substantive, r.function AS source_function,
    r.topic AS source_topic, r.source_jurisdiction_type, r.state, r.city, r.county,
    r.enforcement_discretion, r.opacity, r.paternalism, r.problem_salience
  FROM read_parquet('../input/train-*.parquet', filename = true, file_row_number = true) r
  INNER JOIN city_keys k ON r.state = k.locus_state
    AND regexp_replace(lower(r.city), '[^a-z0-9]', '', 'g') = k.city_key
  WHERE r.source_jurisdiction_type = 'cities'
"))
dbDisconnect(con, shutdown = TRUE)
x[, source_version_sha := "519c0cff5278609b18547bf0fa3b66e088ffb04e"]
x[, chunk_id := paste0(source_file, ":", source_row)]
stopifnot(!anyNA(x$header), !anyNA(x$content), !anyDuplicated(x$chunk_id))
setorder(x, place_geoid, source_file, source_row)
SaveData(x, "../output/locus_city_text.csv", "../report/locus_city_text.txt", "chunk_id")
