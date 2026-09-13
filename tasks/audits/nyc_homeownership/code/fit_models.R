# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
library(sandwich)
source("../../../shared/code/save_data.R")
x <- fread("../output/tract_years.csv", na.strings = "", colClasses = c(tract_geoid = "character"))
periods <- fread("periods.csv")
out <- list()
for (i in seq_len(nrow(periods))) {
  s <- periods[i]
  z <- x[analysis_included == TRUE & placement_year >= s$first_year & placement_year <= s$last_year]
  z[, `:=`(homeowner_10pp = homeowner_share / .1, post = as.integer(placement_year > s$cutoff_year))]
  for (adjustment in c("year", "borough_year")) {
    z[, stratum := if (adjustment == "year") as.character(placement_year) else paste(borough, placement_year)]
    # A stratum with no placements has no finite intercept and no slope information.
    z[, stratum_projects := sum(new_projects), by = stratum]
    fit_data <- z[stratum_projects > 0]
    fit <- glm(new_projects ~ homeowner_10pp + homeowner_10pp:post + factor(stratum),
      offset = log(housing_units), family = poisson(), data = fit_data,
      control = glm.control(maxit = 100))
    stopifnot(fit$converged, all(is.finite(coef(fit))))
    covariance <- vcovCL(fit, cluster = fit_data$tract_geoid, type = "HC1")
    for (comparison in c("through_2002", "after_2002", "later_minus_earlier")) {
      contrast <- setNames(rep(0, length(coef(fit))), names(coef(fit)))
      if (comparison != "later_minus_earlier") contrast["homeowner_10pp"] <- 1
      if (comparison != "through_2002") contrast["homeowner_10pp:post"] <- 1
      estimate <- sum(contrast * coef(fit))
      standard_error <- sqrt(as.numeric(t(contrast) %*% covariance %*% contrast))
      out[[length(out) + 1L]] <- data.table(specification = s$specification,
        adjustment, comparison, log_rate_change = estimate, standard_error,
        rate_ratio = exp(estimate), ci_low = exp(estimate - 1.96 * standard_error),
        ci_high = exp(estimate + 1.96 * standard_error),
        p_value = 2 * pnorm(-abs(estimate / standard_error)),
        tract_years = nrow(fit_data), tract_code_clusters = uniqueN(fit_data$tract_geoid),
        projects = sum(fit_data$new_projects),
        zero_stratum_tract_years_omitted = nrow(z) - nrow(fit_data))
    }
  }
}
models <- rbindlist(out)
SaveData(models, "../output/models.csv", "../report/models.txt", c("specification", "adjustment", "comparison"))
