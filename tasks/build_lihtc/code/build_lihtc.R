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

# First-address selection uses dates, never the availability of hedonics.
setorder(x,address_key,pis_year,hud_id,na.last=TRUE)
x[, `:=`(records_at_address=.N,first_year=if(all(is.na(pis_year))) NA_integer_ else min(pis_year,na.rm=TRUE)),by=address_key]
x[, address_years_complete := all(!is.na(pis_year)),by=address_key]
x[, first_record := records_at_address==1L | (address_years_complete & !is.na(pis_year) & pis_year==first_year)]
x[, representative_hud_id := if(any(first_record)) min(hud_id[first_record]) else NA_character_,by=address_key]
x[, first_record_count := sum(first_record),by=address_key]
x[, keep_first := fifelse(is.na(representative_hud_id),NA,hud_id==representative_hud_id)]
x[, selection_status := fcase(
  records_at_address==1L,"single_new_construction_record",
  !address_years_complete,"repeat_address_missing_year",
  !first_record,"later_new_construction_at_address",
  keep_first & first_record_count>1L,"first_of_tied_records",
  keep_first,"earliest_at_repeated_address",
  default="same_year_record_at_address")]
x[, repeat_address_review := records_at_address>1L]
x[, construction_review := (!is.na(resyndicated) & resyndicated==1)]
x[, address_resolved := !grepl("^UNRESOLVED:",address_key)]
# Apply the same individual-record screens before comparing all records with first addresses.
x[, record_confident := address_resolved & !is.na(pis_year) & location_checked & !construction_review]
x[, `:=`(first_location_checked=any(first_record) & all(location_checked[first_record]),
  first_coordinates_agree=any(first_record) & uniqueN(paste(longitude[first_record],latitude[first_record]))==1L,
  first_resyndicated=any(construction_review[first_record]),
  first_scattered=any(scattered_site[first_record]==1,na.rm=TRUE)),by=address_key]
# A repeated address alone is not an extra exclusion after applying the chosen first-address rule.
x[, usable_location := keep_first %in% TRUE & address_resolved & first_location_checked & first_coordinates_agree & !first_resyndicated & !first_scattered]
x[, confident_first := usable_location & !is.na(pis_year)]
x[, exclusion_reason := fcase(
  is.na(keep_first),"repeated_address_missing_year",
  !keep_first,selection_status,
  !address_resolved,"unresolved_address",
  is.na(pis_year),"missing_year",
  first_resyndicated,"resyndication_flag",
  first_scattered,"scattered_site",
  !first_coordinates_agree,"tied_coordinates_disagree",
  !first_location_checked & location_checked,"other_tied_record_location_uncertain",
  !first_location_checked,location_status,
  default="retained")]
x[, review_needed := exclusion_reason!="retained"]
# Every raw new-construction record remains here, including later and unresolved records.
stopifnot(nrow(x)==29453L,!anyDuplicated(x$hud_id))
stopifnot(x[keep_first %in% TRUE,all(!duplicated(address_key))])
stopifnot(all(x$confident_first==(x$exclusion_reason=="retained")))
setorder(x,hud_id)
fwrite(x,"../output/project_records.csv",na="")
