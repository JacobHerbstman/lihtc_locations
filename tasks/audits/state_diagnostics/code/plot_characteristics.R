# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/state_diagnostics/code")
library(data.table)
library(ggplot2)
x <- fread("../output/characteristic_distributions.csv")
x[, panel := factor(measure, levels = c("Project size", "Bedroom mix"),
                    labels = c("Project size: percent of projects", "Bedroom mix: percent of units"))]
x[, category := factor(category, levels = rev(category))]
size_n <- x[measure == "Project size", unique(projects_with_data)]
bedroom_n <- x[measure == "Bedroom mix", unique(projects_with_data)]
unit_n <- x[measure == "Bedroom mix", unique(denominator)]
g <- ggplot(x, aes(percent, category)) +
  geom_col(fill = "#226b80", width = .67) +
  geom_text(aes(label = sprintf("%.1f%%", percent)), hjust = -.2, size = 4) +
  facet_wrap(~panel, ncol = 1, scales = "free_y") +
  scale_x_continuous(limits = c(0, max(x$percent) + 7), breaks = seq(0, 50, 10),
                     labels = function(v) paste0(v, "%"), expand = expansion(mult = c(0, 0))) +
  labs(title = "Project sizes and bedroom mix",
       subtitle = "HUD new-construction project IDs with HUD coordinates · 50 states and DC",
       x = NULL, y = NULL,
       caption = sprintf(paste0("Project size: %s known counts.\n",
                                "Bedroom mix: %s reported units in %s projects with complete, consistent bedroom counts.\n",
                                "The upper panel weights projects equally; the lower panel weights reported units equally."),
                         format(size_n, big.mark = ","), format(unit_n, big.mark = ","),
                         format(bedroom_n, big.mark = ","))) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0))
ggsave("../output/project_characteristics.png", g, width = 11.5, height = 8, dpi = 160, bg = "white")
