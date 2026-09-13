# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/fetch_census/code")
# selection = "tables"
if (!interactive()) selection <- commandArgs(trailingOnly = TRUE)[[1L]]
suppressPackageStartupMessages({library(curl); library(jsonlite)})
stopifnot(selection %in% c("tables", paste0("tracts_", c(1980,1990,2000,2010,2020,2024)), "places_2024"))

# 1. Submit the explicit, versioned selection. Keys stay in the private R environment.
specification <- paste(readLines(paste0("nhgis_", selection, ".json")), collapse = "\n")
stopifnot(nzchar(Sys.getenv("IPUMS_API_KEY")))
h <- new_handle(timeout = 180)
handle_setheaders(h, Authorization = Sys.getenv("IPUMS_API_KEY"), "Content-Type" = "application/json")
handle_setopt(h, postfields = specification)
response <- tryCatch(suppressWarnings(curl_fetch_memory(
  "https://api.ipums.org/extracts/?collection=nhgis&version=2", h)),
  error = function(e) stop("NHGIS submission failed; no source was published.", call. = FALSE))
stopifnot(response$status_code %in% c(200L, 201L, 202L))
extract <- fromJSON(rawToChar(response$content))
writeLines(c(paste("Extract:", extract$number), specification),
           paste0("../report/nhgis_", selection, "_request.txt"))
cat("NHGIS", selection, "extract", extract$number, "submitted\n")

# 2. Wait for this extract, without submitting another job on a transient status.
h <- new_handle(timeout = 180)
handle_setheaders(h, Authorization = Sys.getenv("IPUMS_API_KEY"))
for (attempt in seq_len(240L)) {
  response <- tryCatch(suppressWarnings(curl_fetch_memory(sprintf(
    "https://api.ipums.org/extracts/%s?collection=nhgis&version=2", extract$number), h)),
    error = function(e) stop("NHGIS status request failed.", call. = FALSE))
  stopifnot(response$status_code == 200L)
  extract <- fromJSON(rawToChar(response$content))
  if (extract$status == "completed") break
  if (extract$status %in% c("failed", "canceled")) stop("NHGIS extract failed.")
  Sys.sleep(15)
}
stopifnot(extract$status == "completed")

# 3. Preserve the delivered ZIP, including its codebook, unchanged.
link <- if (selection == "tables") extract$downloadLinks$tableData else extract$downloadLinks$gisData
temporary <- paste0("../temp/nhgis_", selection, ".zip")
response <- tryCatch(suppressWarnings(curl_fetch_disk(link$url, temporary, h)),
  error = function(e) stop("NHGIS transfer failed; no source was published.", call. = FALSE))
stopifnot(response$status_code == 200L, nrow(unzip(temporary, list = TRUE)) > 0L)
dir.create("../../../data_raw/nhgis/2026-09-13", recursive = TRUE, showWarnings = FALSE)
destination <- paste0("../../../data_raw/nhgis/2026-09-13/", selection, ".zip")
stopifnot(file.rename(temporary, destination))
writeLines(c(paste("Extract:", extract$number), paste("Saved ZIP MD5:", tools::md5sum(destination)),
             paste("Bytes:", file.info(destination)$size)), paste0("../report/nhgis_", selection, ".txt"))
cat("NHGIS", selection, "saved\n")
