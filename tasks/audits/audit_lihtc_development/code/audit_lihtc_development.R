# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/audit_lihtc_development/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
})

collapse_text <- function(value) {
  value <- sort(unique(value[!is.na(value) & value != ""]))
  if (length(value) == 0L) NA_character_ else paste(value, collapse = "|")
}

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024.parquet"
))
property <- as.data.table(read_parquet(
  "../input/lihtc_property_2024_raw_text.parquet"
))
multisite <- as.data.table(read_parquet(
  "../input/lihtc_multisite_2024_raw_text.parquet"
))

if (uniqueN(development$development_id) != nrow(development)) {
  stop("Development IDs are not unique.", call. = FALSE)
}
if (uniqueN(episode$hud_id) != nrow(episode)) {
  stop("HUD IDs are not unique in the episode table.", call. = FALSE)
}
if (uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site)) {
  stop("Development-site keys are not unique.", call. = FALSE)
}
if (any(!episode$development_id %chin% development$development_id)) {
  stop("An episode points to an unknown development.", call. = FALSE)
}
if (any(!site$development_id %chin% development$development_id)) {
  stop("A site points to an unknown development.", call. = FALSE)
}

source_columns <- names(property)
episode_source <- episode[order(source_property_row), ..source_columns]
if (!identical(property, episode_source)) {
  stop("The episode table changed a published property value.", call. = FALSE)
}
if (nrow(multisite) != 161715L ||
    any(!unique(multisite$hud_id) %chin% episode$hud_id)) {
  stop("The multi-address source does not reconcile to the episodes.", call. = FALSE)
}

episode_counts <- episode[, .(observed_project_episodes = .N), by = development_id]
development[, observed_project_episodes := episode_counts$observed_project_episodes[
  match(development_id, episode_counts$development_id)
]]
if (anyNA(development$observed_project_episodes) ||
    any(development$n_project_episodes != development$observed_project_episodes)) {
  stop("Published development episode counts do not reconcile.", call. = FALSE)
}
development[, observed_project_episodes := NULL]

linked_members <- episode[n_project_episodes > 1L, .(
  development_id,
  development_anchor_hud_id,
  hud_id,
  episode_number,
  is_development_anchor,
  project,
  proj_add,
  proj_cty,
  proj_st,
  state_id,
  yr_pis,
  yr_alloc,
  type,
  resyndication_cd,
  n_unitsr,
  li_unitr,
  development_linkage_basis,
  primary_site_key,
  datanote
)]
setorder(linked_members, development_id, episode_number, hud_id)

linked_group_details <- linked_members[, .(
  hud_ids = collapse_text(hud_id),
  project_names = collapse_text(project),
  primary_addresses = collapse_text(proj_add),
  state_ids = collapse_text(state_id),
  placed_in_service_years = collapse_text(yr_pis),
  allocation_years = collapse_text(yr_alloc),
  construction_type_codes = collapse_text(type),
  resyndication_codes = collapse_text(resyndication_cd),
  episode_unit_totals = collapse_text(n_unitsr),
  episode_low_income_unit_totals = collapse_text(li_unitr),
  has_data_note = any(!is.na(datanote) & datanote != "")
), by = development_id]

linked_groups <- development[n_project_episodes > 1L]
linked_groups[, group_detail_row := match(
  development_id,
  linked_group_details$development_id
)]
if (anyNA(linked_groups$group_detail_row)) {
  stop("A linked development has no episode details.", call. = FALSE)
}
for (column in setdiff(names(linked_group_details), "development_id")) {
  set(
    linked_groups,
    j = column,
    value = linked_group_details[[column]][linked_groups$group_detail_row]
  )
}
linked_groups[, group_detail_row := NULL]
linked_groups[, review_category := fcase(
  unit_aggregation_rule == "unresolved_component_or_changed_totals",
  "unresolved_component_or_changed_totals",
  unit_aggregation_rule == "candidate_one_unit_fragments_sum",
  "candidate_one_unit_fragments",
  !is.na(first_pis_year) & !is.na(last_pis_year) &
    last_pis_year - first_pis_year >= 10L,
  "repeated_total_long_gap",
  default = "repeated_total_near_year"
)]
setorder(
  linked_groups,
  review_category,
  -n_project_episodes,
  development_id
)

site_review <- site[requires_site_review == TRUE | n_coordinate_pairs > 1L]
setorder(site_review, development_id, site_number)

fwrite(linked_groups, "../output/development_linkage_groups.csv", na = "")
fwrite(linked_members, "../output/development_linkage_members.csv", na = "")
fwrite(site_review, "../output/development_site_review.csv", na = "")

linkage_basis_counts <- development[, .(
  developments = .N,
  project_episodes = sum(n_project_episodes)
), by = development_linkage_basis][order(-project_episodes)]
unit_rule_counts <- development[, .(
  developments = .N,
  project_episodes = sum(n_project_episodes)
), by = unit_aggregation_rule][order(-project_episodes)]
review_counts <- linked_groups[, .(
  developments = .N,
  project_episodes = sum(n_project_episodes)
), by = review_category][order(review_category)]

format_markdown_table <- function(table) {
  header <- paste0("| ", paste(names(table), collapse = " | "), " |")
  divider <- paste0("| ", paste(rep("---", ncol(table)), collapse = " | "), " |")
  rows <- apply(table, 1L, function(row) {
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  c(header, divider, rows)
}

summary_lines <- c(
  "# LIHTC Development Construction Audit",
  "",
  "## Data Contract",
  "",
  paste0("- Published property rows: ", format(nrow(property), big.mark = ","), "."),
  paste0("- Project-episode rows: ", format(nrow(episode), big.mark = ","), "."),
  paste0("- Provisional physical developments: ", format(nrow(development), big.mark = ","), "."),
  paste0("- Development sites: ", format(nrow(site), big.mark = ","), "."),
  paste0("- Raw multi-address rows: ", format(nrow(multisite), big.mark = ","), "."),
  "- Every published property row and value is retained unchanged in the episode table.",
  "- Development IDs, HUD episode IDs, and development-site keys pass uniqueness checks.",
  "- Every episode and site points to an existing development.",
  "",
  "## Linkage Status",
  "",
  paste0(
    "- Linked developments requiring review: ",
    format(nrow(linked_groups), big.mark = ","),
    " covering ",
    format(nrow(linked_members), big.mark = ","),
    " HUD episodes."
  ),
  paste0(
    "- Singleton developments: ",
    format(sum(development$n_project_episodes == 1L), big.mark = ","),
    "."
  ),
  paste0(
    "- Developments whose unit aggregation requires review: ",
    format(sum(
      development$unit_aggregation_status == "requires_review"
    ), big.mark = ","),
    "."
  ),
  paste0(
    "- Developments with no informative address: ",
    format(sum(development$n_development_sites == 0L), big.mark = ","),
    "."
  ),
  paste0(
    "- Development sites flagged for unit-like addresses or coordinate conflicts: ",
    format(nrow(site_review), big.mark = ","),
    "."
  ),
  "",
  "All non-singleton development links remain provisional. Shared BIN values, fuzzy names, and partial address overlaps do not create a link.",
  "",
  "## Linkage Basis",
  "",
  format_markdown_table(linkage_basis_counts),
  "",
  "## Development Unit Rules",
  "",
  format_markdown_table(unit_rule_counts),
  "",
  "## Linked-Development Review Queue",
  "",
  format_markdown_table(review_counts),
  "",
  "The CSV review files preserve the development groups, their episode members, and flagged site records. They are review queues rather than corrections or exclusions."
)
writeLines(summary_lines, "../output/audit_summary.md")

cat(
  "Audited ", format(nrow(development), big.mark = ","),
  " developments and wrote ", format(nrow(linked_groups), big.mark = ","),
  " provisional linkage groups for review.\n",
  sep = ""
)
