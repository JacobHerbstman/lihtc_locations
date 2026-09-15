# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
library(ggplot2)
period <- fread("periods.csv")
x <- fread("../output/models.csv")
x <- x[sample == "all_city_tracts" & model == "joint" & adjustment %in% c("same_sample", "housing_controls")]
x[, variable := factor(variable, levels = c("homeowner_share", "nh_black_share", "log_income"),
  labels = c("Homeowner share", "Non-Hispanic Black share", "Household income"))]
x[, city_name := factor(city_name, levels = rev(sort(unique(city_name))))]
x[, adjustment := factor(adjustment, levels = c("same_sample", "housing_controls"),
  labels = c("Before housing controls", "Add vacancy and density"))]
p <- ggplot(x, aes(x = rate_ratio, y = city_name, color = adjustment)) +
  geom_vline(xintercept = 1, color = "grey60", linetype = 2) +
  geom_errorbar(aes(xmin = ci_low, xmax = ci_high), orientation = "y", width = .15,
    position = position_dodge(width = .4)) +
  geom_point(size = 2.6, position = position_dodge(width = .4)) +
  facet_grid(. ~ variable) +
  scale_x_log10(breaks = c(.125, .25, .5, 1, 2, 4, 8),
    labels = c("0.125×", "0.25×", "0.5×", "1×", "2×", "4×", "8×")) +
  scale_color_manual(values = c("#176b9b", "#bd4933")) +
  labs(title = "Do the placement gradients persist after accounting for neighborhood housing?",
    subtitle = sprintf("Pooled %d–%d within each city; all three characteristics together; identical samples before and after controls",
      period$first_year, period$last_year),
    x = "Placement rate ratio for one standard deviation higher characteristic", y = NULL, color = NULL,
    caption = paste("Every model includes year fixed effects and baseline housing-unit exposure. Bars: tract-code-clustered 95% intervals.",
      "Added controls: prior vacancy share and log housing units per km² of mapped tract area (including inland water).",
      "All neighborhood characteristics precede opening. Density is not a measure of buildable land; these are descriptive associations.", sep = "\n")) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(),
    strip.text.y = element_text(angle = 0), plot.caption = element_text(hjust = 0),
    plot.title = element_text(face = "bold"), axis.text.x = element_text(size = 10))
ggsave("../output/housing_controls.png", p, width = 13, height = 7, dpi = 180, bg = "white")
