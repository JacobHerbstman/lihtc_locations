# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/placement_gradients/code")
library(data.table)
library(ggplot2)
period <- fread("periods.csv")
x <- fread("../output/models.csv")
x <- x[sample == "all_city_tracts" & comparison == "pooled"]
x[, variable := factor(variable, levels = c("log_income", "nh_black_share", "homeowner_share"),
  labels = c("Household income", "Black population share", "Homeowner share"))]
x[, model := factor(model, levels = c("separate", "joint"),
  labels = c("Each characteristic separately", "All three together"))]
p <- ggplot(x, aes(x = rate_ratio, y = variable)) +
  geom_vline(xintercept = 1, color = "grey60", linetype = 2) +
  geom_errorbar(aes(xmin = ci_low, xmax = ci_high), orientation = "y", width = .15, color = "#176b9b") +
  geom_point(size = 2.6, color = "#176b9b") +
  facet_grid(model ~ city_name) +
  scale_x_log10(breaks = c(.03125, .0625, .125, .25, .5, 1, 2, 4, 8),
    labels = c("0.03×", "0.06×", "0.125×", "0.25×", "0.5×", "1×", "2×", "4×", "8×")) +
  labs(title = "Which neighborhood characteristic has the stronger placement gradient?",
    subtitle = sprintf("Pooled %d–%d within each city; one standard deviation higher characteristic, using the same sample across variables",
      period$first_year, period$last_year),
    x = "LIHTC project placement rate ratio (log scale): below 1 = fewer placements; above 1 = more", y = NULL,
    caption = paste("Annual project counts, year effects, and baseline housing-unit exposure. Bars: tract-code-clustered 95% intervals.",
      "Black share is non-Hispanic Black population share. Income is log median household income in 2024 dollars.",
      "Neighborhood observations end strictly before project opening; this is a descriptive association.", sep = "\n")) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(),
    strip.text.y = element_text(angle = 0), plot.caption = element_text(hjust = 0),
    plot.title = element_text(face = "bold"), axis.text.x = element_text(size = 10))
ggsave("../output/gradients.png", p, width = 13, height = 7, dpi = 180, bg = "white")
