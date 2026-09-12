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
  cat("External benchmark calculations: HUD 2024 release; current first-address rules\n")
  cat("See ../README.md for external evidence and interpretation. No records are changed.\n\n")
  cat("HUD published all-type totals: 55,345 records and 3,860,546 adjusted units. Both match.\n")
  cat("All ten published annual property and adjusted-unit counts also match:\n")
  print(observed)
  cat("\nConstruction-type coverage: denominator includes every source record in the 50 states and DC.\n")
  coverage <- hud[proj_st %in% c(state.abb,"DC"),.(records=.N,unknown_type=sum(is.na(type)),new_construction=sum(type=="1",na.rm=TRUE)),by=.(state=proj_st)]
  coverage[,unknown_pct:=round(100*unknown_type/records,2)]
  print(coverage[order(-unknown_pct)],nrows=51)
  cat("\nCurrent selection and unit comparisons are produced by ../state_diagnostics, using the selected table's consensus hedonics.\n")
  cat("\nThree examples originally sampled at revision 36228a3 using seed 20260911; IDs held fixed as the production rules change:\n")
  print(x[hud_id %in% c("CAA20120846","GAA20100035","OHA20160031"),.(hud_id,project_name,state_project_id,street,city,state,pis_year,total_units,bedrooms_consistent)])
  cat("\nTargeted missing-type example (not randomly selected):\n")
  print(hud[hud_id=="INA20157173",.(hud_id,project,proj_add,proj_cty,type,yr_pis,n_units,li_units)])
  cat("\nMD5 fingerprints of the files read, not independent data validation:\n")
  print(tools::md5sum(c("../input/LIHTCPUB.xlsx","../input/project_records.csv")))
})
writeLines(sub("[[:blank:]]+$","",report),"../output/checks.txt")
