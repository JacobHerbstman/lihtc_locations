# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/clean_census/code")
library(data.table)
library(readxl)
source("../../shared/code/save_data.R")

# Census's published continuous national price series: R-CPI-U-RS before 2000,
# chained CPI-U from 2000 onward. This changes dollars over time, not across places.
raw <- as.data.table(read_excel("../input/annual-index-value_annual-percent-change.xls",
                               skip = 3L, col_names = FALSE, col_types = "text"))
x <- raw[, .(dollar_year = suppressWarnings(as.integer(...1)),
             price_index = suppressWarnings(as.numeric(...2)))]
x <- x[dollar_year %in% 1979:2024]
stopifnot(nrow(x) == 46L, !anyNA(x$price_index), all(x$price_index > 0))
x[, `:=`(real_dollar_year = 2024L, price_index_geography = "United States",
         price_index_series = "Census historical income price series (2025 release)")]
x[, factor_to_2024 := price_index[dollar_year == 2024L] / price_index]
SaveData(x, "../output/price_index.csv", "../report/price_index.txt", "dollar_year")
