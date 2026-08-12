# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_external_benchmarks/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_low_income_share_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_low_income_share_adjudicated.parquet"
))
benchmarks <- fread("external_benchmarks.csv", na.strings = "")

if (nrow(development) != 53469L || nrow(episode) != 54902L ||
    uniqueN(development$development_id) != nrow(development) ||
    uniqueN(episode$hud_id) != nrow(episode) ||
    any(!episode$development_id %chin% development$development_id) ||
    uniqueN(benchmarks$benchmark_id) != nrow(benchmarks) ||
    nrow(benchmarks) != 21L ||
    anyNA(benchmarks[, .(
      benchmark_id, source_title, source_url, source_period, source_table,
      source_unit, statistic, category, published_value,
      local_comparison_id, comparability, source_note
    )])) {
  stop("An external-benchmark input count, key, or required field changed.",
    call. = FALSE)
}

complete_development_units <- development[
  !is.na(n_units_development) & n_units_development > 0 &
    !is.na(li_units_development) & li_units_development >= 0 &
    li_units_development <= n_units_development
]
valid_development_units <- complete_development_units[
  low_income_share_analysis_eligible == TRUE
]
if (nrow(complete_development_units) != 52919L ||
    nrow(valid_development_units) != 52831L) {
  stop("The complete physical-development unit sample changed.",
    call. = FALSE)
}

development_1995_1998 <- valid_development_units[
  first_pis_year %between% c(1995L, 1998L)
]
episode_1995_1998 <- episode[pis_year %between% c(1995L, 1998L)]

construction_1995_1998 <- episode_1995_1998[type %chin% c("1", "2", "3")]
construction_values <- construction_1995_1998[, .N, by = type]
construction_values[, `:=`(
  local_comparison_id = "hud_1995_1998_episode",
  statistic = "construction_share",
  category = c("1" = "new", "2" = "rehab", "3" = "both")[type],
  current_value = N / sum(N),
  current_n = sum(N)
)]

credit_1995_1998 <- episode_1995_1998[credit %chin% c("1", "2", "3")]
credit_values <- credit_1995_1998[, .N, by = credit]
credit_values[, `:=`(
  local_comparison_id = "hud_1995_1998_episode",
  statistic = "credit_share",
  category = c(
    "1" = "4_percent", "2" = "9_percent", "3" = "both"
  )[credit],
  current_value = N / sum(N),
  current_n = sum(N)
)]

bedroom_columns <- c("n_0br", "n_1br", "n_2br", "n_3br", "n_4br")
bedroom_1995_1998 <- episode_1995_1998[
  complete.cases(episode_1995_1998[, ..bedroom_columns])
]
bedroom_1995_1998[, (bedroom_columns) := lapply(.SD, as.numeric),
  .SDcols = bedroom_columns
]
bedroom_1995_1998 <- bedroom_1995_1998[
  rowSums(bedroom_1995_1998[, ..bedroom_columns]) > 0 &
    apply(bedroom_1995_1998[, ..bedroom_columns], 1L, min) >= 0
]
bedroom_totals <- bedroom_1995_1998[, lapply(.SD, sum),
  .SDcols = bedroom_columns
]
bedroom_values <- data.table(
  local_comparison_id = "hud_1995_1998_episode",
  statistic = "bedroom_unit_share",
  category = c(
    "0_bedroom", "1_bedroom", "2_bedroom", "3_bedroom",
    "4plus_bedroom"
  ),
  current_value = as.numeric(bedroom_totals) / sum(bedroom_totals),
  current_n = nrow(bedroom_1995_1998)
)

development_2005_2019 <- valid_development_units[
  first_pis_year %between% c(2005L, 2019L)
]
episode_2005_2019_9pct <- episode[
  pis_year %between% c(2005L, 2019L) & credit == "2" &
    !is.na(episode_units) & episode_units > 0 &
    !is.na(episode_low_income_units) & episode_low_income_units >= 0 &
    episode_low_income_units <= episode_units
]

local_values <- rbindlist(list(
  data.table(
    local_comparison_id = "hud_1995_1998_physical",
    statistic = c("mean_total_units", "mean_low_income_share"),
    category = "all",
    current_value = c(
      mean(development_1995_1998$n_units_development),
      mean(
        development_1995_1998$li_units_development /
          development_1995_1998$n_units_development
      )
    ),
    current_n = nrow(development_1995_1998)
  ),
  construction_values[, .(
    local_comparison_id, statistic, category, current_value, current_n
  )],
  credit_values[, .(
    local_comparison_id, statistic, category, current_value, current_n
  )],
  bedroom_values,
  data.table(
    local_comparison_id = "soltas_2005_2019_9pct_episode",
    statistic = rep(c("mean_total_units", "mean_low_income_share"), each = 2L),
    category = rep(c("winner", "loser"), 2L),
    current_value = c(
      rep(mean(episode_2005_2019_9pct$episode_units), 2L),
      rep(mean(
        episode_2005_2019_9pct$episode_low_income_units /
          episode_2005_2019_9pct$episode_units
      ), 2L)
    ),
    current_n = nrow(episode_2005_2019_9pct)
  ),
  data.table(
    local_comparison_id = "soltas_2005_2019_physical",
    statistic = rep(c("mean_total_units", "mean_low_income_share"), each = 2L),
    category = rep(c("matched", "unmatched"), 2L),
    current_value = c(
      rep(mean(development_2005_2019$n_units_development), 2L),
      rep(mean(
        development_2005_2019$li_units_development /
          development_2005_2019$n_units_development
      ), 2L)
    ),
    current_n = nrow(development_2005_2019)
  )
), use.names = TRUE)

if (uniqueN(local_values,
  by = c("local_comparison_id", "statistic", "category")
) != nrow(local_values) ||
    local_values[
      local_comparison_id == "soltas_2005_2019_9pct_episode",
      uniqueN(current_value),
      by = statistic
    ][, any(V1 != 1L)] ||
    local_values[
      local_comparison_id == "soltas_2005_2019_physical",
      uniqueN(current_value),
      by = statistic
    ][, any(V1 != 1L)]) {
  stop("Local benchmark comparison keys are not unique.", call. = FALSE)
}

setkey(local_values, local_comparison_id, statistic, category)
setkey(benchmarks, local_comparison_id, statistic, category)
benchmark_audit <- local_values[benchmarks]
if (nrow(benchmark_audit) != nrow(benchmarks) ||
    anyNA(benchmark_audit$current_value) ||
    anyNA(benchmark_audit$current_n)) {
  stop("A published benchmark did not join one-to-one to a local statistic.",
    call. = FALSE)
}

benchmark_audit[, `:=`(
  absolute_difference = current_value - published_value,
  relative_difference = fifelse(
    published_value == 0,
    NA_real_,
    current_value / published_value - 1
  ),
  audit_role = fifelse(
    comparability == "direct_period_and_project_concept",
    "primary_external_benchmark",
    "context_only"
  )
)]

diagnostic <- data.table(
  diagnostic = c(
    "all_complete_physical_developments_before_tail_exclusion",
    "all_eligible_physical_developments",
    "original_frozen_developments_below_20_percent",
    "eligible_developments_below_20_percent",
    "eligible_wisconsin_below_20_percent",
    "physical_developments_1995_1998",
    "physical_developments_1995_1998_below_20_percent",
    "physical_developments_2005_2019",
    "physical_developments_2005_2019_below_20_percent"
  ),
  value = c(
    nrow(complete_development_units),
    nrow(valid_development_units),
    complete_development_units[
      pre_low_income_share_li_units_development /
        n_units_development < 0.20, .N
    ],
    valid_development_units[
      li_units_development / n_units_development < 0.20, .N
    ],
    valid_development_units[
      development_state == "WI" &
        li_units_development / n_units_development < 0.20, .N
    ],
    nrow(development_1995_1998),
    development_1995_1998[
      li_units_development / n_units_development < 0.20, .N
    ],
    nrow(development_2005_2019),
    development_2005_2019[
      li_units_development / n_units_development < 0.20, .N
    ]
  )
)

hud_rows <- benchmark_audit[grepl("^HUD_", benchmark_id)]
soltas_rows <- benchmark_audit[grepl("^SOLTAS_", benchmark_id)]

summary_lines <- c(
  "# External LIHTC Benchmark Audit",
  "",
  "This audit compares the final physical-development and financing-episode tables with published HUD and Soltas statistics. It does not treat a competitive application, a financing episode, and a physical development as interchangeable.",
  "",
  "## Population",
  "",
  sprintf("- Final physical developments: %s.", format(nrow(development), big.mark = ",")),
  sprintf("- Final financing episodes: %s.", format(nrow(episode), big.mark = ",")),
  sprintf("- Physical developments with complete valid total and low-income counts: %s.", format(nrow(complete_development_units), big.mark = ",")),
  sprintf("- Complete developments eligible after the targeted low-share review: %s.", format(nrow(valid_development_units), big.mark = ",")),
  "",
  "## HUD 1995-1998 comparison",
  "",
  sprintf(
    "The final physical-development table contains %s complete developments first placed in service from 1995 through 1998. Its mean size is %.1f units versus HUD's published 62.2, and its unweighted mean qualifying-unit share is %.1f percent versus HUD's published 96.6 percent.",
    format(nrow(development_1995_1998), big.mark = ","),
    benchmark_audit[benchmark_id == "HUD_9598_MEAN_UNITS", current_value],
    100 * benchmark_audit[benchmark_id == "HUD_9598_MEAN_LI_SHARE", current_value]
  ),
  "",
  "The construction, credit, and bedroom comparisons use current financing-episode fields because those source characteristics are preserved at the episode level. They are close historical checks, not claims that every episode is a distinct physical project.",
  "",
  paste0(
    "- Construction shares, current versus published: new ",
    sprintf("%.1f/%.1f", 100 * hud_rows[benchmark_id == "HUD_9598_CONSTRUCTION_NEW", current_value], 65),
    ", rehab ",
    sprintf("%.1f/%.1f", 100 * hud_rows[benchmark_id == "HUD_9598_CONSTRUCTION_REHAB", current_value], 34),
    ", both ",
    sprintf("%.1f/%.1f percent.", 100 * hud_rows[benchmark_id == "HUD_9598_CONSTRUCTION_BOTH", current_value], 2)
  ),
  paste0(
    "- Credit shares, current versus published: 4 percent ",
    sprintf("%.1f/%.1f", 100 * hud_rows[benchmark_id == "HUD_9598_CREDIT_4PCT", current_value], 22),
    ", 9 percent ",
    sprintf("%.1f/%.1f", 100 * hud_rows[benchmark_id == "HUD_9598_CREDIT_9PCT", current_value], 67),
    ", both ",
    sprintf("%.1f/%.1f percent.", 100 * hud_rows[benchmark_id == "HUD_9598_CREDIT_BOTH", current_value], 10)
  ),
  paste0(
    "- Bedroom-category unit shares, current versus published: ",
    paste(sprintf(
      "%.1f/%.1f",
      100 * hud_rows[statistic == "bedroom_unit_share", current_value],
      100 * hud_rows[statistic == "bedroom_unit_share", published_value]
    ), collapse = ", "),
    " percent for 0, 1, 2, 3, and 4-plus bedrooms."
  ),
  "",
  "## Soltas 2005-2019 context",
  "",
  sprintf(
    "The current 9-percent financing episodes average %.1f units and %.1f percent low-income units. Soltas's winning and losing competitive applications average 61.6/64.9 units and 97.5/98.1 percent low-income units. This is a rough scale check only: applications and placed-in-service financing episodes are different objects. The output intentionally repeats the same unconditioned local statistic beside each published subgroup; it does not estimate local winner/loser or matched/unmatched groups.",
    soltas_rows[benchmark_id == "SOLTAS_TABLE1_WINNER_UNITS", current_value],
    100 * soltas_rows[benchmark_id == "SOLTAS_TABLE1_WINNER_LI_SHARE", current_value]
  ),
  "",
  "## Targeted low-share review",
  "",
  sprintf(
    "The frozen pre-review counts produced %s developments below 20 percent. The two-read review replaces 176 counts, affirms 11 documented nominal 20-percent set-asides whose integer ratios round below 20 percent, and excludes 88 unresolved records from share analysis. The eligible table now contains %s sub-20-percent developments, including %s in Wisconsin. Only %s eligible sub-20-percent developments appear in the 1995-1998 comparison period.",
    format(diagnostic[diagnostic == "original_frozen_developments_below_20_percent", value], big.mark = ","),
    format(diagnostic[diagnostic == "eligible_developments_below_20_percent", value], big.mark = ","),
    format(diagnostic[diagnostic == "eligible_wisconsin_below_20_percent", value], big.mark = ","),
    format(diagnostic[diagnostic == "physical_developments_1995_1998_below_20_percent", value], big.mark = ",")
  ),
  "",
  "The Parquet preserves every published value, citation, comparison unit, local denominator, and numeric difference. `context_only` rows must not be presented as replications."
)

setorder(benchmark_audit, benchmark_id)
write_parquet(
  benchmark_audit,
  "../output/lihtc_external_benchmark_audit.parquet",
  compression = "zstd"
)
writeLines(summary_lines, "../output/benchmark_summary.md")

if (!identical(
  benchmark_audit,
  as.data.table(read_parquet(
    "../output/lihtc_external_benchmark_audit.parquet"
  ))
)) {
  stop("The external-benchmark Parquet changed on round trip.",
    call. = FALSE)
}

cat(
  "External benchmark audit complete:\n",
  " - ", nrow(benchmark_audit), " published comparisons\n",
  " - ", nrow(development_1995_1998), " complete 1995-1998 developments\n",
  " - ", diagnostic[
    diagnostic == "original_frozen_developments_below_20_percent", value
  ], " sub-20-percent developments flagged\n",
  sep = ""
)
