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
  bedrooms_0_raw = n_0br, bedrooms_1_raw = n_1br, bedrooms_2_raw = n_2br,
  bedrooms_3_raw = n_3br, bedrooms_4_raw = n_4br,
  income_ceiling_raw = inc_ceil, lower_income_ceiling_raw = low_ceil,
  lower_ceiling_units_raw = ceilunit,
  hud_tract_1990 = fips1990, hud_tract_2000 = fips2000,
  hud_tract_2010 = fips2010, hud_tract_2020 = fips2020,
  hud_place_1990 = place1990, hud_place_2000 = place2000,
  hud_place_2010 = place2010, hud_place_2020 = place2020,
  credit_type = credit, target_family_raw = trgt_fam,
  target_elderly_raw = trgt_eld, target_disabled_raw = trgt_dis,
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

# HUD's elected ceiling is categorical; income averaging does not identify unit-level limits.
x[, income_ceiling_type := fcase(income_ceiling_raw == "1", "50_pct_ami",
  income_ceiling_raw == "2", "60_pct_ami", income_ceiling_raw == "3", "income_averaging",
  default = NA_character_)]
x[, lower_income_ceiling := fcase(lower_income_ceiling_raw == "1", 1L,
  lower_income_ceiling_raw == "2", 0L, default = NA_integer_)]
x[, lower_ceiling_units := suppressWarnings(as.numeric(lower_ceiling_units_raw))]
x[, lower_ceiling_units_conflict := !is.na(lower_ceiling_units) &
  (lower_ceiling_units < 0 | lower_ceiling_units != floor(lower_ceiling_units) |
   (!is.na(total_units) & lower_ceiling_units > total_units))]
x[lower_ceiling_units_conflict == TRUE, lower_ceiling_units := NA_real_]
x[, lower_ceiling_indicator_conflict := !is.na(lower_income_ceiling) & !is.na(lower_ceiling_units) &
  ((lower_income_ceiling == 0L & lower_ceiling_units > 0) |
   (lower_income_ceiling == 1L & lower_ceiling_units == 0))]
x[, low_income_share := low_income_units / total_units]

# Keep valid partial bedroom counts. Blank a breakdown only when it contradicts
# total units; unavailable categories alone do not invalidate observed categories.
# HUD labels N_4BR as "4-bedroom units", not "4 or more".
bedrooms <- c("bedrooms_0", "bedrooms_1", "bedrooms_2", "bedrooms_3", "bedrooms_4")
for (field in bedrooms) {
  value <- suppressWarnings(as.numeric(x[[paste0(field, "_raw")]]))
  value[!is.finite(value) | value < 0 | value != floor(value)] <- NA_real_
  set(x, j = field, value = value)
}
x[, bedrooms_conflict := !is.na(total_units) &
    (rowSums(.SD, na.rm = TRUE) > total_units |
     (rowSums(is.na(.SD)) == 0 & rowSums(.SD, na.rm = TRUE) != total_units)),
  .SDcols = bedrooms]
x[bedrooms_conflict == TRUE, (bedrooms) := NA_real_]
x[, bedrooms_consistent := !is.na(total_units) & rowSums(is.na(.SD)) == 0 &
    rowSums(.SD, na.rm = TRUE) == total_units, .SDcols = bedrooms]

# Targeting indicators: HUD 1=yes, 2=no, 0/blank=not indicated.
# Derived indicators use 1=yes, 0=no, NA=unknown; source codes remain above.
for (field in c("target_family", "target_elderly", "target_disabled")) {
  value <- x[[paste0(field, "_raw")]]
  set(x, j = field, value = fcase(value == "1", 1L, value == "2", 0L,
                                 default = NA_integer_))
}
for (field in c("hud_latitude", "hud_longitude")) {
  set(x, j = field, value = suppressWarnings(as.numeric(x[[field]])))
}

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

# 4. Recognize available HUD points using the existing broad numerical bounds.
# This is not a state-boundary test or building-footprint validation.
x[, hud_coordinates_present := !is.na(hud_latitude) & !is.na(hud_longitude) &
    hud_latitude >= 18 & hud_latitude <= 72 &
    hud_longitude >= -180 & hud_longitude <= 180 & hud_longitude != 0]

setorder(x, hud_id)
SaveData(x, "../output/projects.csv", "../report/projects.txt", "hud_id")
