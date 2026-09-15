# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
library(ggplot2)
period <- fread("periods.csv")
x <- fread("../output/models.csv")
x <- x[sample == "all_city_tracts" & model == "joint" & adjustment == "housing_controls"]
city_order <- x[variable == "homeowner_share"][order(natural_rate_ratio), city_name]
x[, city_name := factor(city_name, levels = rev(city_order))]
x[, variable := factor(variable, levels = c("homeowner_share", "nh_black_share", "log_income"),
  labels = c("Homeowner share\n10 percentage points higher",
    "Non-Hispanic Black share\n10 percentage points higher", "Household income\n10 percent higher"))]
x[, `:=`(change = 100 * (natural_rate_ratio - 1),
  low = 100 * (natural_ci_low - 1), high = 100 * (natural_ci_high - 1))]
p <- ggplot(x, aes(x = change, y = city_name)) +
  geom_vline(xintercept = 0, color = "grey60", linetype = 2) +
  geom_errorbar(aes(xmin = low, xmax = high), orientation = "y", width = .15, color = "#176b9b") +
  geom_point(size = 2.8, color = "#176b9b") +
  facet_grid(. ~ variable) +
  scale_x_continuous(labels = function(z) paste0(z, "%")) +
  labs(title = "Where is the homeowner placement gradient steeper?",
    subtitle = sprintf("Pooled %d–%d within each city; race, income, prior vacancy and housing density held fixed",
      period$first_year, period$last_year),
    x = "Associated change in annual LIHTC projects per baseline housing unit", y = NULL,
    caption = paste("City-specific year fixed effects. Bars: tract-code-clustered 95% confidence intervals.",
      "Cities are ordered by the homeowner point estimate; overlapping intervals do not establish a precise ranking.",
      "Compare cities within a column. Use the standardized figure to compare characteristics within a city. Descriptive associations.", sep = "\n")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0),
    plot.title = element_text(face = "bold"))
ggsave("../output/cross_city.png", p, width = 13, height = 7, dpi = 180, bg = "white")
