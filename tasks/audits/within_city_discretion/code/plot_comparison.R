# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/within_city_discretion/code")
library(data.table)
library(ggplot2)
x <- fread("../output/city_comparison.csv")[sample == "all_city_tracts"]
order <- x[variable == "homeowner_share"][order(percent_change), city_name]
x[, city_name := factor(city_name, levels = rev(order))]
x[, variable := factor(variable, levels = c("homeowner_share", "nh_black_share", "log_income"),
  labels = c("Homeowner share +10 points", "Non-Hispanic Black share +10 points", "Household income +10%"))]
colors <- c(compliance_route = "#246e9b", triggered_subjective_review = "#bb6b29",
  state_limited_review = "#82569a", unresolved_2022 = "#777777")
labels <- c("Compliance route", "Subjective review when triggered", "Local review / state limit", "2022 coding unresolved")
p <- ggplot(x, aes(x = percent_change, y = city_name, color = pilot_category)) +
  geom_vline(xintercept = 0, color = "grey75") +
  geom_segment(aes(x = percent_ci_low, xend = percent_ci_high, yend = city_name), linewidth = .6) +
  geom_point(size = 2.8) + facet_wrap(~variable, nrow = 1, scales = "free_x") +
  scale_color_manual(values = colors, breaks = names(colors), labels = labels) +
  labs(x = "Associated change in annual LIHTC projects per baseline housing unit (%)", y = NULL, color = NULL,
    title = "City placement gradients beside a first legal-route assessment",
    subtitle = "Colors describe documented routes, not a ranking or a verified historical city index.",
    caption = "1987–2022 placements; joint demographics, housing controls and city-specific year effects.\n95% tract-clustered intervals. Legal evidence has mixed dates; Boston remains unresolved for 2022.") +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", legend.text = element_text(size = 10),
    panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), plot.caption = element_text(hjust = 0))
ggsave("../output/city_comparison.png", p, width = 13, height = 6, dpi = 170, bg = "white")
