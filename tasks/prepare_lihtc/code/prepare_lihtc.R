# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc/code")
library(data.table)
library(readxl)
source("../../shared/code/save_data.R")

# 1. Read the pinned workbook; retain HUD new construction in the 50 states and DC.
hud <- as.data.table(read_excel(
  "../temp/LIHTCPUB.xlsx", sheet = "Data", col_types = "text",
  na = "", trim_ws = FALSE
))
stopifnot(
  nrow(hud) == 55345L, ncol(hud) == 80L,
  !anyNA(hud$hud_id), !anyDuplicated(hud$hud_id)
)
x <- hud[type == "1" & proj_st %in% c(state.abb, "DC"), .(
  hud_id, project_name = trimws(project), state_project_id = trimws(state_id),
  street_raw = proj_add, city_raw = proj_cty, state = proj_st, zip_raw = proj_zip,
  pis_year_raw = yr_pis, allocation_year_raw = yr_alloc, construction_type = type,
  total_units_raw = n_units, low_income_units_raw = li_units,
  hud_adjusted_total_units = n_unitsr, hud_adjusted_low_income_units = li_unitr,
  bedrooms_0 = n_0br, bedrooms_1 = n_1br, bedrooms_2 = n_2br,
  bedrooms_3 = n_3br, bedrooms_4 = n_4br,
  credit_type = credit, target_family = trgt_fam,
  target_elderly = trgt_eld, target_disabled = trgt_dis,
  scattered_site = scattered_site_cd, resyndicated = resyndication_cd,
  hud_latitude = latitude, hud_longitude = longitude, source_note = datanote
)]
stopifnot(nrow(x) == 29453L)

# 2. Derive dates and unit counts, preserving the original fields above.
# 8888/9999 and years outside this release's 1987–2024 window become missing.
for (field in c("pis_year_raw", "allocation_year_raw")) {
  value <- suppressWarnings(as.integer(x[[field]]))
  value[is.na(value) | value < 1987L | value > 2024L] <- NA_integer_
  set(x, j = sub("_raw$", "", field), value = value)
}
for (field in c("total_units_raw", "low_income_units_raw")) {
  value <- suppressWarnings(as.numeric(x[[field]]))
  value[is.na(value) | value < 0 | value != floor(value)] <- NA_real_
  set(x, j = sub("_raw$", "", field), value = value)
}
x[total_units == 0, total_units := NA_real_]
x[, units_conflict := !is.na(total_units) & !is.na(low_income_units) &
    low_income_units > total_units]
x[units_conflict == TRUE, low_income_units := NA_real_]

# HUD's N_4BR is labeled "4-bedroom units" in the pinned source dictionary.
for (field in c("bedrooms_0", "bedrooms_1", "bedrooms_2", "bedrooms_3",
                "bedrooms_4", "hud_latitude", "hud_longitude")) {
  set(x, j = field, value = suppressWarnings(as.numeric(x[[field]])))
}
x[, bedrooms_consistent := !is.na(total_units) &
    !is.na(bedrooms_0 + bedrooms_1 + bedrooms_2 + bedrooms_3 + bedrooms_4) &
    bedrooms_0 + bedrooms_1 + bedrooms_2 + bedrooms_3 + bedrooms_4 == total_units &
    bedrooms_0 >= 0 & bedrooms_1 >= 0 & bedrooms_2 >= 0 &
    bedrooms_3 >= 0 & bedrooms_4 >= 0]

# 3. Standardize address text. Keep house-number ranges and unit/suite text.
x[, `:=`(
  street = toupper(trimws(street_raw)),
  city = toupper(trimws(city_raw)),
  zip = sub("^([0-9]{5}).*$", "\\1", trimws(zip_raw))
)]
x[is.na(zip) | !grepl("^[0-9]{5}$", zip), zip := NA_character_]
x[, street := gsub("[.,]", "", street)]
x[, street := gsub("\\s+", " ", street)]
x[, city := gsub("\\s+", " ", city)]
replacements <- c(
  STREET = "ST", AVENUE = "AVE", ROAD = "RD", BOULEVARD = "BLVD",
  DRIVE = "DR", LANE = "LN", COURT = "CT", PLACE = "PL", PARKWAY = "PKWY",
  HIGHWAY = "HWY", NORTH = "N", SOUTH = "S", EAST = "E", WEST = "W"
)
for (word in names(replacements)) {
  x[, street := gsub(paste0("\\b", word, "\\b"), replacements[[word]], street)]
}

# A numbered street is required for an address query, not for using a HUD point.
x[, address_queryable := !is.na(street) & grepl("^[0-9]+", street) &
    !grepl("\\b(P ?O BOX|POST OFFICE|SCATTERED|VARIOUS)\\b|[;&]", street) &
    ((!is.na(city) & nzchar(city)) | !is.na(zip))]
x[, address_key := paste(state, city, street, sep = "|")]
x[address_queryable == FALSE | is.na(city) | city == "",
  address_key := paste0("UNRESOLVED:", hud_id)]
x[, name_key := gsub("[^A-Z0-9]", "", toupper(project_name))]

# 4. Recognize available HUD points using the existing broad numerical bounds.
# This is not a state-boundary test or building-footprint validation.
x[, hud_coordinates_present := !is.na(hud_latitude) & !is.na(hud_longitude) &
    hud_latitude >= 18 & hud_latitude <= 72 &
    hud_longitude >= -180 & hud_longitude <= 180 & hud_longitude != 0]

setorder(x, hud_id)
SaveData(x, "../output/projects.csv", "../report/projects.txt", "hud_id")
