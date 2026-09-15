# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/fetch_local_governments/code")
library(data.table)
source("../../shared/code/save_data.R")
x <- data.table(
  source_file = c("govt_units_2022.ZIP", "list1_2020.xls", "list2_2020.xls", "co-est2021-alldata.csv"),
  reference_period = c("2022 governments", "March 2020 MSA counties", "March 2020 principal cities", "July 2021 population; 2021 vintage"),
  expected_sha256 = c("3ef3d93c91697b00d4d53384176dc584db9dacbd0f0a23e45657f0a3a1058c28",
    "95b389487efcd818d71ba2a992e1edd43af93228e70c2a9634fd152acb345409",
    "be3a0aa2499d032d5b8125635569b946ba15b7d71ea0776f415c93c2b77c83af",
    "684883133405a88edbd43156382ccd7771fe1d6608b7ea1b992cb28bb6d31c83"))
for (i in seq_len(nrow(x))) {
  file <- paste0("../../../data_raw/census_governments/2026-09-15/", x$source_file[i])
  hash <- system2("shasum", c("-a", "256", file), stdout = TRUE)
  stopifnot(length(hash) == 1L, is.null(attr(hash, "status")), substr(hash, 1, 64) == x$expected_sha256[i])
  x[i, bytes := file.info(file)$size]
}
SaveData(x, "../output/source_inventory.csv", "../report/source_inventory.txt", "source_file")
