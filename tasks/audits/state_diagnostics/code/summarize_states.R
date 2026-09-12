# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(readxl)
hud <- as.data.table(read_excel("../input/LIHTCPUB.xlsx",sheet="Data",col_types="text"))
x <- fread("../input/project_records.csv",na.strings="",colClasses=c(hud_id="character"))
p <- fread("../input/projects.csv",na.strings="",colClasses=c(hud_id="character"))
stopifnot(!anyDuplicated(hud$hud_id),!anyDuplicated(x$hud_id),!anyDuplicated(p$hud_id))
hud <- hud[proj_st %in% c(state.abb,"DC")]
hud[,year:=fcase(yr_pis %in% as.character(1987:2024),yr_pis,
  yr_pis %in% as.character(2025:2027),"after_2024",default="unknown")]
stopifnot(all(x$hud_id %in% hud$hud_id),all(p$hud_id %in% x$hud_id))
x[,year:=hud$year[match(hud_id,hud$hud_id)]]
p[,year:=hud$year[match(hud_id,hud$hud_id)]]

coverage <- hud[,.(hud_records=.N,type_unknown=sum(is.na(type)),type_known=sum(!is.na(type))),by=.(state=proj_st,year)]
records <- x[,.(new_records=.N,new_units=sum(total_units,na.rm=TRUE),new_units_known=sum(!is.na(total_units)),
  screened_new_records=sum(record_confident),screened_new_units=sum(total_units[record_confident],na.rm=TRUE),
  later_records=sum(selection_status=="later_new_construction_at_address"),
  same_year_records=sum(selection_status=="same_year_record_at_address"),
  uncertain_order_records=sum(is.na(keep_first))),by=.(state,year)]
first <- p[,.(first_records=.N,first_units=sum(total_units,na.rm=TRUE),first_units_known=sum(!is.na(total_units)),
  confident_records=sum(confident_first),confident_units=sum(total_units[confident_first],na.rm=TRUE),
  confident_units_known=sum(confident_first & !is.na(total_units)),
  confident_bedrooms_known=sum(confident_first & bedrooms_consistent),
  first_tied_records=sum(first_record_count>1),
  address_missing_count=sum(exclusion_reason=="unresolved_address" & (is.na(street)|street=="")),
  address_multiple_count=sum(exclusion_reason=="unresolved_address" & grepl("MULTIPLE|SCATTERED|VARIOUS|[;&]",street)),
  drop_address=sum(exclusion_reason=="unresolved_address"),drop_year=sum(exclusion_reason=="missing_year"),
  drop_resyndication=sum(exclusion_reason=="resyndication_flag"),drop_scattered=sum(exclusion_reason=="scattered_site"),
  drop_hud_only=sum(exclusion_reason=="hud_only_unconfirmed"),
  drop_coordinates=sum(exclusion_reason %in% c("coordinate_disagreement","tied_coordinates_disagree","state_disagreement")),
  drop_other_location=sum(exclusion_reason %in% c("no_location","inexact_census_match","other_tied_record_location_uncertain"))),by=.(state,year)]
stopifnot(!anyDuplicated(coverage[,.(state,year)]),!anyDuplicated(records[,.(state,year)]),!anyDuplicated(first[,.(state,year)]))
out <- merge(CJ(state=c(state.abb,"DC"),year=c(as.character(1987:2024),"after_2024","unknown")),coverage,by=c("state","year"),all.x=TRUE)
out <- merge(out,records,by=c("state","year"),all.x=TRUE)
out <- merge(out,first,by=c("state","year"),all.x=TRUE)
for (field in setdiff(names(out),c("state","year"))) set(out,which(is.na(out[[field]])),field,0)
stopifnot(nrow(out)==51L*40L,sum(out$new_records)==nrow(x),sum(out$first_records)==nrow(p),
  all(out$first_records+out$later_records+out$same_year_records+out$uncertain_order_records==out$new_records),
  all(out$first_records-out$confident_records==rowSums(out[,grep("^drop_",names(out)),with=FALSE])))
fwrite(out,"../output/state_year_counts.csv",na="")
