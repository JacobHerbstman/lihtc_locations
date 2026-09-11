# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/build_lihtc/code")
# distance_review_meters <- 500
library(data.table)
if (!interactive()) {
  args <- commandArgs(trailingOnly=TRUE)
  stopifnot(length(args)==1L)
  distance_review_meters <- as.numeric(args[1])
}
stopifnot(is.finite(distance_review_meters),distance_review_meters>0)
x <- fread("../input/projects.csv",na.strings="",colClasses=c(hud_id="character",zip="character",zip_raw="character",state_project_id="character"))
g <- fread("../input/geocodes.csv",na.strings="",colClasses="character")
stopifnot(!anyDuplicated(x$hud_id),!anyDuplicated(g$hud_id),setequal(g$hud_id,x[address_queryable==TRUE,hud_id]))
g[,`:=`(census_latitude=as.numeric(census_latitude),census_longitude=as.numeric(census_longitude))]
x <- merge(x,g,by="hud_id",all.x=TRUE,sort=FALSE)
stopifnot(nrow(x)==29453L,!anyDuplicated(x$hud_id))
# State FIPS follows R's alphabetical state.abb order, with DC appended.
state_codes <- data.table(state=c(state.abb,"DC"),expected_state=sprintf("%02d",c(1,2,4,5,6,8,9,10,12,13,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56,11)))
stopifnot(!anyDuplicated(state_codes$state))
x <- merge(x,state_codes,by="state",all.x=TRUE,sort=FALSE)
x[, census_match := !is.na(match_status) & match_status=="Match"]
x[, state_agrees := census_match & !is.na(census_state) & census_state==expected_state]
x[, hud_census_distance_m := NA_real_]
x[census_match & hud_coordinates_present, hud_census_distance_m := {
  a <- sin((census_latitude-hud_latitude)*pi/360)^2 + cos(hud_latitude*pi/180)*cos(census_latitude*pi/180)*sin((census_longitude-hud_longitude)*pi/360)^2
  6371008.8*2*asin(sqrt(pmin(1,pmax(0,a))))
}]
# Retain source coordinates when Census supplies no corroboration; label them honestly.
x[, `:=`(longitude=fifelse(hud_coordinates_present,hud_longitude,NA_real_),latitude=fifelse(hud_coordinates_present,hud_latitude,NA_real_),location_source=fifelse(hud_coordinates_present,"HUD","missing"))]
x[state_agrees==TRUE,`:=`(longitude=census_longitude,latitude=census_latitude,location_source="Census ACS2025")]
x[, location_status := fcase(
  census_match & !state_agrees,"state_disagreement",
  state_agrees & !is.na(hud_census_distance_m) & hud_census_distance_m>distance_review_meters,"coordinate_disagreement",
  state_agrees & hud_coordinates_present,"census_hud_agree",
  state_agrees & match_type!="Exact","inexact_census_match",
  state_agrees & match_type=="Exact","census_exact_no_hud_comparison",
  hud_coordinates_present,"hud_only_unconfirmed",
  default="no_location")]
x[, location_checked := location_status %in% c("census_hud_agree","census_exact_no_hud_comparison")]
# Scattered-site projects retain their reported primary point, not a full site inventory.
x[scattered_site==1 & location_checked,location_status:="scattered_primary_point_only"]
x[, location_checked := location_checked & (is.na(scattered_site) | scattered_site!=1)]

# The requested first-location rule is based only on NEW-CONSTRUCTION records.
# Earlier rehabilitation does not disqualify a construction project.
setorder(x,address_key,pis_year,hud_id,na.last=TRUE)
x[, `:=`(records_at_address=.N,first_year=if(all(is.na(pis_year))) NA_integer_ else min(pis_year,na.rm=TRUE)),by=address_key]
x[, keep_first := records_at_address==1L]
x[, selection_status := "single_new_construction_record"]
x[records_at_address>1,`:=`(keep_first=NA,selection_status="repeat_address_missing_year")]
# A date tie is collapsed only when substantive fields agree and name/units are known.
for (key in unique(x[records_at_address>1,address_key])) {
  rows <- which(x$address_key==key)
  if (anyNA(x$pis_year[rows])) next
  first <- rows[x$pis_year[rows]==min(x$pis_year[rows])]
  x[rows,`:=`(keep_first=FALSE,selection_status="later_new_construction_at_address")]
  if (length(first)==1L) {
    x[first,`:=`(keep_first=TRUE,selection_status="earliest_at_repeated_address")]
  } else {
    fields <- c("name_key","pis_year","total_units","low_income_units","bedrooms_0","bedrooms_1","bedrooms_2","bedrooms_3","bedrooms_4plus","scattered_site","credit_type")
    identical_records <- nrow(unique(x[first,..fields]))==1L && !is.na(x$name_key[first[1]]) && nzchar(x$name_key[first[1]]) && !is.na(x$total_units[first[1]])
    if (identical_records) {
      # Stable HUD ID chooses a representative only after all listed attributes agree.
      x[first,selection_status:="identical_first_record_copy"]
      x[first[1],`:=`(keep_first=TRUE,selection_status="first_of_identical_records")]
    } else x[first,`:=`(keep_first=NA,selection_status="conflicting_first_year_tie")]
  }
}
x[, repeat_address_review := records_at_address>1L]
x[, construction_review := (!is.na(resyndicated) & resyndicated==1)]
x[, review_needed := repeat_address_review | construction_review | !location_checked]
x[, usable_location := keep_first %in% TRUE & location_checked & !repeat_address_review & !construction_review]
# Every raw new-construction record remains here, including later and unresolved records.
stopifnot(nrow(x)==29453L,!anyDuplicated(x$hud_id))
stopifnot(x[keep_first %in% TRUE,all(!duplicated(address_key))])
setorder(x,hud_id)
fwrite(x,"../output/project_records.csv",na="")
