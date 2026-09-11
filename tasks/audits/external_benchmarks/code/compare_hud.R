# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/external_benchmarks/code")
library(data.table)
library(readxl)
hud <- as.data.table(read_excel("../input/LIHTCPUB.xlsx",sheet="Data",col_types="text"))
x <- fread("../input/project_records.csv",na.strings="",colClasses=c(hud_id="character"))
stopifnot(!anyDuplicated(hud$hud_id),!anyDuplicated(x$hud_id))

# Published all-type, all-geography counts, not a target for the selected sample.
# https://www.huduser.gov/portal/Datasets/lihtc/LIHTC-2024-Tables.pdf
published <- data.table(year=2015:2024,
  properties=c(1215,1271,1095,1124,1112,1193,1079,1020,929,787),
  units=c(93927,105002,96493,96186,102164,101986,96825,97048,81407,64269))
observed <- hud[yr_pis %in% as.character(2015:2024),
  .(properties=.N,units=sum(as.numeric(n_unitsr),na.rm=TRUE)),by=.(year=as.integer(yr_pis))][order(year)]
stopifnot(nrow(hud)==55345L,sum(as.numeric(hud$n_unitsr),na.rm=TRUE)==3860546,
  identical(observed$year,published$year),all(observed$properties==published$properties),all(observed$units==published$units))

report <- capture.output({
  cat("External benchmark calculations: HUD 2024 release; baseline revision 36228a3\n")
  cat("See ../README.md for external evidence and interpretation. No records are changed.\n\n")
  cat("HUD published all-type totals: 55,345 records and 3,860,546 adjusted units. Both match.\n")
  cat("All ten published annual property and adjusted-unit counts also match:\n")
  print(observed)
  cat("\nConstruction-type coverage: denominator includes every source record in the 50 states and DC.\n")
  coverage <- hud[proj_st %in% c(state.abb,"DC"),.(records=.N,unknown_type=sum(is.na(type)),new_construction=sum(type=="1",na.rm=TRUE)),by=.(state=proj_st)]
  coverage[,unknown_pct:=round(100*unknown_type/records,2)]
  print(coverage[order(-unknown_pct)],nrows=51)
  cat("\nTotals before and after first-address selection; units are reported total_units, excluding missing.\n")
  for (sample in c("All new-construction records","Selected first-address records")) {
    d <- if (sample=="All new-construction records") x else x[keep_first %in% TRUE]
    cat(sample,"\n",sep="")
    print(d[,.(records=.N,known_year=sum(!is.na(pis_year)),known_units=sum(!is.na(total_units)),units=sum(total_units,na.rm=TRUE),mean_units=round(mean(total_units,na.rm=TRUE),2),median_units=median(total_units,na.rm=TRUE))])
  }
  cat("\nSelection by state. Unresolved records are excluded from selected counts, but preserved in source records.\n")
  states <- x[,.(raw=.N,selected=sum(keep_first %in% TRUE),raw_units=sum(total_units,na.rm=TRUE),selected_units=sum(total_units[keep_first %in% TRUE],na.rm=TRUE)),by=state]
  states[,`:=`(records_removed_pct=round(100*(1-selected/raw),2),units_removed_pct=round(100*(1-selected_units/raw_units),2))]
  print(states[order(-records_removed_pct)],nrows=51)
  cat("\nSelection by placed-in-service year. NA includes missing/unconfirmed years and 2025 dates outside the study window.\n")
  print(x[,.(raw=.N,selected=sum(keep_first %in% TRUE),raw_units=sum(total_units,na.rm=TRUE),selected_units=sum(total_units[keep_first %in% TRUE],na.rm=TRUE)),by=pis_year][order(pis_year)],nrows=50)
  cat("\nReproduce the three exploratory spot checks, sampled from usable locations with PIS 2010-2020:\n")
  set.seed(20260911)
  d <- x[usable_location==TRUE & pis_year %between% c(2010,2020)]
  print(d[sample(.N,3),.(hud_id,project_name,state_project_id,street,city,state,pis_year,total_units,bedrooms_consistent)])
  cat("\nTargeted missing-type example (not randomly selected):\n")
  print(hud[hud_id=="INA20157173",.(hud_id,project,proj_add,proj_cty,type,yr_pis,n_units,li_units)])
  cat("\nMD5 fingerprints of the files read, not independent data validation:\n")
  print(tools::md5sum(c("../input/LIHTCPUB.xlsx","../input/project_records.csv")))
})
writeLines(sub("[[:blank:]]+$","",report),"../report/checks.txt")
