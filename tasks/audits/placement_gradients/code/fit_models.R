# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
library(sandwich)
source("../../../shared/code/save_data.R")
x <- fread("../output/tract_years.csv", na.strings = "", colClasses = c(place_geoid = "character", tract_geoid = "character"))
scales <- fread("../output/scales.csv", colClasses = c(place_geoid = "character"))
period <- fread("periods.csv")
variables <- c("homeowner_share", "nh_black_share", "log_income")
out <- list()
for (city in unique(x$place_geoid)) {
  z <- x[place_geoid == city & analysis_included == TRUE &
    placement_year >= period$first_year & placement_year <= period$last_year]
  s <- scales[place_geoid == city]
  for (v in variables) z[, (paste0(v, "_sd")) := (get(v) - s[variable == v, mean]) / s[variable == v, sd]]
  z[, `:=`(vacancy_10pp = vacancy_share / .1, log2_housing_density = log_housing_density / log(2))]
  for (sample in c("all_city_tracts", "interior_tracts")) {
    for (adjustment in c("baseline", "same_sample", "housing_controls")) {
      fit_data <- if (sample == "interior_tracts") z[interior_tract == TRUE] else copy(z)
      if (adjustment != "baseline") fit_data <- fit_data[controls_included == TRUE]
      eligible_rows <- nrow(fit_data)
      fit_data[, year_projects := sum(new_projects), by = placement_year]
      fit_data <- fit_data[year_projects > 0]
      # All three single-characteristic models and the joint model use exactly the same rows.
      for (model in c(variables, "joint")) {
        terms <- if (model == "joint") paste0(variables, "_sd") else paste0(model, "_sd")
        if (adjustment == "housing_controls") terms <- c(terms, "vacancy_10pp", "log2_housing_density")
        # One slope for the full study period; year effects still absorb annual placement volume.
        formula <- reformulate(c(terms, "factor(placement_year)"), response = "new_projects")
        fit <- glm(formula, offset = log(housing_units), family = poisson(), data = fit_data,
          control = glm.control(maxit = 100))
        stopifnot(fit$converged, all(is.finite(coef(fit))), nobs(fit) == nrow(fit_data))
        covariance <- vcovCL(fit, cluster = fit_data$tract_geoid, type = "HC1")
        for (v in if (model == "joint") variables else model) {
          term <- paste0(v, "_sd")
          estimate <- unname(coef(fit)[term])
          se <- sqrt(covariance[term, term])
          natural_scale <- s[variable == v, natural_change / sd]
          out[[length(out) + 1L]] <- data.table(place_geoid = city, city_name = z$city_name[[1L]],
            sample, adjustment, model = if (model == "joint") "joint" else "separate", variable = v, comparison = "pooled",
            log_rate_change = estimate, standard_error = se, rate_ratio = exp(estimate),
            ci_low = exp(estimate - 1.96 * se), ci_high = exp(estimate + 1.96 * se),
            p_value = 2 * pnorm(-abs(estimate / se)),
            natural_rate_ratio = exp(estimate * natural_scale),
            natural_ci_low = exp((estimate - 1.96 * se) * natural_scale),
            natural_ci_high = exp((estimate + 1.96 * se) * natural_scale),
            tract_years = nrow(fit_data), tract_code_clusters = uniqueN(fit_data$tract_geoid),
            projects = sum(fit_data$new_projects), zero_year_tract_years_omitted = eligible_rows - nrow(fit_data))
        }
      }
    }
  }
}
m <- rbindlist(out)
SaveData(m, "../output/models.csv", "../report/models.txt",
  c("place_geoid", "sample", "adjustment", "model", "variable", "comparison"))
