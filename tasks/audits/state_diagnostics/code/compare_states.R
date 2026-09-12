# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
source("../../../shared/code/save_data.R")
x <- fread("../output/state_year_counts.csv")
stopifnot(!anyDuplicated(x[,.(state,year)]))
# Expected retained count uses national retention within each cohort and each state's own year mix.
national <- x[,.(first_records=sum(first_records),confident_records=sum(confident_records)),by=year]
national[,national_retention:=fifelse(first_records>0,confident_records/first_records,0)]
stopifnot(!anyDuplicated(national$year))
x[national,on="year",expected_confident:=first_records*i.national_retention]
counts <- setdiff(names(x),c("state","year"))
states <- x[,lapply(.SD,sum),by=state,.SDcols=counts]
states[,state_name:=c(state.name,"District of Columbia")[match(state,c(state.abb,"DC"))]]
states[,`:=`(type_missing_pct=100*type_unknown/hud_records,
  first_reduction_pct=100*(1-first_records/new_records),confidence_loss_pct=100*(1-confident_records/first_records),
  total_reduction_pct=100*(1-confident_records/new_records),
  excess_confidence_loss_pp=100*(expected_confident-confident_records)/first_records,
  new_share_pct=100*new_records/sum(new_records),confident_share_pct=100*confident_records/sum(confident_records),
  first_units_missing_pct=100*(1-first_units_known/first_records),
  confident_units_missing_pct=100*(1-confident_units_known/confident_records))]
states[,state_share_change_pp:=confident_share_pct-new_share_pct]
recent <- x[year %in% as.character(2010:2024),.(recent_hud_records=sum(hud_records),recent_type_unknown=sum(type_unknown),
  recent_first=sum(first_records),recent_confident=sum(confident_records)),by=state]
stopifnot(!anyDuplicated(states$state),!anyDuplicated(recent$state))
states <- merge(states,recent,by="state",all.x=TRUE)
states[,`:=`(recent_type_missing_pct=100*recent_type_unknown/recent_hud_records,
  recent_confidence_loss_pct=fifelse(recent_first>0,100*(1-recent_confident/recent_first),NA_real_))]
stopifnot(nrow(states)==51L,!anyDuplicated(states$state))
SaveData(states[order(state)],"../output/state_summary.csv","../report/state_summary.txt","state")
