# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
# specification = "main"
if (!interactive()) specification <- commandArgs(trailingOnly = TRUE)[[1L]]
library(data.table)
library(ggplot2)
periods <- fread("periods.csv")
selected <- specification
s <- periods[specification == selected]
stopifnot(nrow(s) == 1L)
x <- fread("../output/binned_rates.csv")[specification == selected]
x <- melt(x, id.vars = c("era", "bin_lower_pct"),
  measure.vars = c("projects_per_10000_housing_years", "known_units_per_10000_housing_years"),
  variable.name = "outcome", value.name = "rate")
x[, outcome := factor(outcome, levels = c("projects_per_10000_housing_years", "known_units_per_10000_housing_years"),
                       labels = c("Project placements", "Known project units"))]
labels <- c(through_2002 = paste0(s$first_year, "–", s$cutoff_year),
            after_2002 = paste0(s$cutoff_year + 1L, "–", s$last_year))
g <- ggplot(x, aes(bin_lower_pct + 5, rate, color = era, shape = era)) +
  geom_line(linewidth = .7) + geom_point(size = 2.5) +
  facet_wrap(~outcome, scales = "free_y", nrow = 1) +
  scale_color_manual(values = c(through_2002 = "#2166ac", after_2002 = "#b2182b"), labels = labels) +
  scale_shape_manual(values = c(through_2002 = 16, after_2002 = 17), labels = labels) +
  scale_x_continuous(breaks = seq(0, 100, 20), limits = c(0, 100)) +
  labs(title = "New York City: placements and prior homeownership",
    subtitle = paste0(if (selected == "same_2000") "Same 2000 Census values and boundaries: " else "",
                      labels[["through_2002"]], " versus ", labels[["after_2002"]]),
    x = "Prior owner-occupied share of occupied housing (%)", y = "Per 10,000 existing housing units per year",
    color = NULL, shape = NULL,
    caption = "Fixed 10-percentage-point bins; denominators include zero-placement tract-years.\nHomeownership and existing housing come from the latest observation ending before placed-in-service. Unit sums include reported totals only.") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", plot.caption = element_text(hjust = 0))
ggsave(paste0("../output/rates_", selected, ".png"), g, width = 11, height = 5.4, dpi = 170, bg = "white")
