# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/local_control/code")
library(data.table)
library(ggplot2)
x <- fread("../output/metro_comparison.csv")
x <- x[sample == "all_city_tracts"]
x[, general_purpose_governments := as.numeric(general_purpose_governments)]
x[, city_name := c(Atlanta = "ATL", Boston = "BOS", Chicago = "CHI", Houston = "HOU",
  "Los Angeles" = "LA", "New York City" = "NYC", "San Francisco" = "SF", Seattle = "SEA")[city_name]]
x[, `:=`(effect = 100 * (natural_rate_ratio - 1),
  low = 100 * (natural_ci_low - 1), high = 100 * (natural_ci_high - 1))]
z <- melt(x, id.vars = c("city_name", "variable", "effect", "low", "high"),
  measure.vars = c("general_purpose_governments", "governments_per_100k", "central_city_population_share"),
  variable.name = "measure")
z[measure == "central_city_population_share", value := 100 * value]
z[, measure := factor(measure, levels = c("general_purpose_governments", "governments_per_100k", "central_city_population_share"),
  labels = c("Active general-purpose governments", "Governments per 100,000 residents", "Central-city share of metro population (%)"))]
z[, variable := factor(variable, levels = c("homeowner_share", "nh_black_share", "log_income"),
  labels = c("Homeowner share: +10 percentage points", "Non-Hispanic Black share: +10 percentage points", "Household income: +10 percent"))]
p <- ggplot(z, aes(value, effect)) +
  geom_hline(yintercept = 0, color = "grey75", linetype = 2) +
  geom_linerange(aes(ymin = low, ymax = high), color = "#80a5b5", linewidth = .5) +
  geom_point(color = "#176b9b", size = 2) +
  geom_text(aes(label = city_name), nudge_x = 0, vjust = -1, size = 2.7, check_overlap = FALSE) +
  facet_grid(variable ~ measure, scales = "free") +
  scale_x_continuous(expand = expansion(mult = c(.15, .2))) +
  scale_y_continuous(expand = expansion(mult = c(.12, .2))) +
  labs(title = "Metro fragmentation and central-city LIHTC placement",
    subtitle = "Eight metros; government structure in 2022 versus pooled 1987–2022 city placement gradients",
    x = NULL, y = "Associated change in annual LIHTC projects per baseline housing unit (%)",
    caption = paste("Each point represents one central city and its MSA. Bars: 95% intervals for its estimated LIHTC gradient.",
      "All models include city-specific year effects, the other two demographics, prior vacancy and housing density.",
      "Government counts use Census primary-county assignment; population is from 2021 and MSA boundaries from March 2020.",
      "These are government-fragmentation proxies, not zoning-authority counts or causal effects. More negative means a steeper negative placement gradient.",
      "ATL Atlanta · BOS Boston · CHI Chicago · HOU Houston · LA Los Angeles · NYC New York City · SF San Francisco · SEA Seattle", sep = "\n")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), strip.text.y = element_text(angle = 0),
    plot.caption = element_text(hjust = 0), plot.title = element_text(face = "bold"))
ggsave("../output/metro_gradients.png", p, width = 16, height = 11, dpi = 160, bg = "white")
