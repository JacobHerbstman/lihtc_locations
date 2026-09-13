# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/nyc_homeownership/code")
library(data.table)
library(ggplot2)
x <- fread("../output/annual_summary.csv", na.strings = "")
period <- fread("periods.csv")[specification == "main"]
lines <- melt(x, id.vars = "placement_year", measure.vars = c("project_mean_homeowner_pct", "housing_weighted_homeowner_pct"),
              variable.name = "series", value.name = "homeowner_pct")
g <- ggplot(lines, aes(placement_year, homeowner_pct, color = series)) +
  geom_vline(xintercept = period$cutoff_year + .5, linetype = "dashed", color = "gray40") +
  geom_line(linewidth = .7, na.rm = TRUE) + geom_point(size = 1.4, na.rm = TRUE) +
  scale_color_manual(values = c(project_mean_homeowner_pct = "#b2182b", housing_weighted_homeowner_pct = "#2166ac"),
    labels = c(project_mean_homeowner_pct = "At project locations", housing_weighted_homeowner_pct = "Across existing housing")) +
  scale_x_continuous(breaks = c(1987, 1992, 1997, 2002, 2007, 2012, 2017, 2022)) +
  labs(title = "Were later placements in neighborhoods with fewer homeowners?",
    subtitle = "New York City; latest Census observation ending before each placed-in-service year",
    x = "Placed-in-service year", y = "Mean prior homeowner share (%)", color = NULL,
    caption = "Project locations receive one vote per HUD project. The city comparison weights tracts by baseline housing units.\nNo retained NYC placements are dated 1987–1989. The dashed line separates periods, not individual approval dates.") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", plot.caption = element_text(hjust = 0))
ggsave("../output/annual_homeownership.png", g, width = 10, height = 5.5, dpi = 170, bg = "white")
