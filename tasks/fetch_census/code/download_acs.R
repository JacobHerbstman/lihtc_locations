# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/fetch_census/code")
# year = 2024L
if (!interactive()) year <- as.integer(commandArgs(trailingOnly = TRUE)[[1L]])
suppressPackageStartupMessages({library(curl); library(jsonlite); library(data.table)})
stopifnot(year %in% 2010:2024, nzchar(Sys.getenv("CENSUS_API_KEY")))

# 1. The same detailed tables, estimates and MOEs are requested in each release.
variables <- fread("acs_variables.csv")
# B15003 starts in 2012. Earlier releases publish the same attainment categories by sex.
if (year <= 2011L) {
  variables <- variables[!grepl("^B15003", census_code)]
  variables <- rbind(variables, data.table(
    variable = c("population_25_plus", "male_bachelors", "male_masters", "male_professional",
                 "male_doctorate", "female_bachelors", "female_masters", "female_professional", "female_doctorate"),
    census_code = paste0("B15002_", c("001","015","016","017","018","032","033","034","035"))))
}
fields <- c("NAME", paste0(variables$census_code, "E"), paste0(variables$census_code, "M"),
            paste0(variables[grepl("^median_", variable), census_code], "EA"),
            if (year >= 2012L) paste0(variables[grepl("^median_", variable), census_code], "MA"))
stopifnot(length(fields) <= 50L)
states <- c("01","02","04","05","06","08","09","10","11","12","13","15",
            "16","17","18","19","20","21","22","23","24","25","26","27",
            "28","29","30","31","32","33","34","35","36","37","38","39",
            "40","41","42","44","45","46","47","48","49","50","51","53",
            "54","55","56")
folder <- paste0("../temp/acs5_", year)
dir.create(folder, showWarnings = FALSE)
base <- sprintf("https://api.census.gov/data/%d/acs/acs5", year)

# 2. Preserve each state response verbatim. No LIHTC filter enters these requests.
# Error messages deliberately omit the authenticated URL.
counts <- vector("list", length(states))
for (i in seq_along(states)) {
  state <- states[[i]]
  url <- paste0(base, "?get=", paste(fields, collapse = ","),
                "&for=tract:*&in=state:", state, "&key=", Sys.getenv("CENSUS_API_KEY"))
  response <- tryCatch(suppressWarnings(curl_fetch_memory(url, new_handle(timeout = 180))),
    error = function(e) stop(sprintf("Census transfer failed: year %d, state %s.", year, state), call. = FALSE))
  if (response$status_code != 200L) stop(sprintf("Census HTTP %d: year %d, state %s.", response$status_code, year, state))
  table <- fromJSON(rawToChar(response$content))
  stopifnot(is.matrix(table), nrow(table) > 1L, all(fields %in% table[1L, ]))
  data <- as.data.table(table[-1L, , drop = FALSE]); setnames(data, table[1L, ])
  stopifnot(all(data$state == state), all(nchar(data$tract) == 6L),
            !anyDuplicated(data[, .(state, county, tract)]))
  writeBin(response$content, paste0(folder, "/state_", state, ".json"))
  counts[[i]] <- data.table(state = state, tracts = nrow(data))
  cat("ACS", year, "state", state, ":", nrow(data), "tracts\n")
}

# 3. Record the release's metadata and public request definition with the responses.
response <- curl_fetch_memory(paste0(base, "/variables.json"), new_handle(timeout = 180))
stopifnot(response$status_code == 200L, all(paste0(variables$census_code, "E") %in% names(fromJSON(rawToChar(response$content))$variables)))
writeBin(response$content, paste0(folder, "/variables.json"))
writeLines(c(paste0(base, "?get=", paste(fields, collapse = ","), "&for=tract:*&in=state:SS"),
             "SS: all 50 states and DC; private key omitted. Retrieval: 2026-09-13."),
           paste0(folder, "/request.txt"))
archive <- paste0("../temp/acs5_", year, ".tar.gz")
stopifnot(system2("tar", c("-czf", archive, "-C", folder, ".")) == 0L)
dir.create("../../../data_raw/census_acs/2026-09-13", recursive = TRUE, showWarnings = FALSE)
destination <- paste0("../../../data_raw/census_acs/2026-09-13/acs5_", year, ".tar.gz")
stopifnot(file.rename(archive, destination))
writeLines(c(paste("National tracts:", sum(rbindlist(counts)$tracts)),
             paste("Archive MD5:", tools::md5sum(destination)),
             capture.output(print(rbindlist(counts), nrows = 51L))),
           paste0("../report/acs5_", year, ".txt"))
