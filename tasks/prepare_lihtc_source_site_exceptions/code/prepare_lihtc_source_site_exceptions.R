# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/prepare_lihtc_source_site_exceptions/code")

suppressPackageStartupMessages({
  library(arrow)
  library(data.table)
  library(stringr)
})

normalize_text <- function(value) {
  value <- iconv(value, from = "", to = "ASCII//TRANSLIT", sub = "")
  value <- str_to_upper(str_squish(value))
  value <- str_replace_all(value, "[^A-Z0-9]+", " ")
  value <- str_squish(value)
  value[value == ""] <- NA_character_
  value
}

normalize_street <- function(value) {
  value <- normalize_text(value)
  replacements <- c(
    "NORTHEAST" = "NE",
    "NORTHWEST" = "NW",
    "SOUTHEAST" = "SE",
    "SOUTHWEST" = "SW",
    "NORTH" = "N",
    "SOUTH" = "S",
    "EAST" = "E",
    "WEST" = "W",
    "STREET" = "ST",
    "AVENUE" = "AVE",
    "BOULEVARD" = "BLVD",
    "CIRCLE" = "CIR",
    "COURT" = "CT",
    "DRIVE" = "DR",
    "EXPRESSWAY" = "EXPY",
    "HIGHWAY" = "HWY",
    "LANE" = "LN",
    "PARKWAY" = "PKWY",
    "PLACE" = "PL",
    "PLAZA" = "PLZ",
    "ROAD" = "RD",
    "TERRACE" = "TER",
    "TRAIL" = "TRL",
    "TURNPIKE" = "TPKE",
    "APARTMENT" = "APT",
    "BUILDING" = "BLDG"
  )
  for (term in names(replacements)) {
    value <- str_replace_all(
      value,
      paste0("\\b", term, "\\b"),
      replacements[[term]]
    )
  }
  str_squish(value)
}

make_site_key <- function(state, street, city) {
  paste(
    fcoalesce(normalize_text(state), ""),
    fcoalesce(normalize_street(street), ""),
    fcoalesce(normalize_text(city), ""),
    sep = "|"
  )
}

development <- as.data.table(read_parquet(
  "../input/lihtc_development_2024_single_address_adjudicated.parquet"
))
episode <- as.data.table(read_parquet(
  "../input/lihtc_project_episode_2024_single_address_adjudicated.parquet"
))
site <- as.data.table(read_parquet(
  "../input/lihtc_development_site_2024_single_address_adjudicated.parquet"
))
multisite <- as.data.table(read_parquet(
  "../input/lihtc_multisite_2024_raw_text.parquet"
))
identical_members <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_members.parquet"
))
identical_reviews <- as.data.table(read_parquet(
  "../input/lihtc_identical_address_set_reviews.parquet"
))
cross_reviews <- as.data.table(read_parquet(
  "../input/lihtc_cross_development_address_decisions.parquet"
))
evidence_updates <- fread("source_exception_evidence_updates.csv")
evidence_updates[, reviewed_on := as.character(reviewed_on)]

if (nrow(development) != 54030L ||
    uniqueN(development$development_id) != nrow(development) ||
    nrow(episode) != 55345L || uniqueN(episode$hud_id) != nrow(episode) ||
    nrow(site) != 133324L ||
    uniqueN(site$development_site_id) != nrow(site) ||
    uniqueN(site, by = c("development_id", "site_key")) != nrow(site) ||
    nrow(multisite) != 161715L ||
    any(!unique(multisite$hud_id) %chin% episode$hud_id) ||
    nrow(identical_members) != 3306L ||
    nrow(identical_reviews) != 98L ||
    uniqueN(identical_reviews$review_question_id) !=
      nrow(identical_reviews) ||
    nrow(cross_reviews) != 137L ||
    uniqueN(cross_reviews$identity_question_id) != nrow(cross_reviews) ||
    nrow(evidence_updates) != 3L ||
    uniqueN(evidence_updates$source_exception_group_id) != 3L) {
  stop("A source-site exception input count or key changed.",
    call. = FALSE)
}

excluded_portfolio_members <- identical_members[
  identical_address_set_id %chin% c("IAS0670", "IAS0687"),
  .(
    development_id,
    source_exception_group_id = identical_address_set_id
  )
]
if (nrow(excluded_portfolio_members) != 16L ||
    uniqueN(excluded_portfolio_members$development_id) != 16L ||
    excluded_portfolio_members[
      source_exception_group_id == "IAS0670",
      .N
    ] != 6L ||
    excluded_portfolio_members[
      source_exception_group_id == "IAS0687",
      .N
    ] != 10L) {
  stop("The two excluded copied portfolio sets changed.",
    call. = FALSE)
}

bad_identical_assessments <- c(
  "administrative_or_parcel_descriptions",
  "copied_across_distinct_developments",
  "contains_unrelated_addresses"
)
bad_cross_address_reasons <- c(
  "bad_or_placeholder_shared_source_address",
  "distinct_developments_source_cross_listing",
  "portfolio_episode_overlaps_distinct_development",
  "portfolio_or_phase_overlaps_distinct_development"
)

source_exception <- development[
  development_id %chin% excluded_portfolio_members$development_id |
    identical_address_set_address_assessments %chin%
      bad_identical_assessments |
    cross_address_review_reason_code %chin% bad_cross_address_reasons
]
source_exception[, `:=`(
  source_exception_group_id = NA_character_,
  concern_origin = NA_character_
)]
source_exception[excluded_portfolio_members,
  `:=`(
    source_exception_group_id = i.source_exception_group_id,
    concern_origin = "excluded_identical_address_set"
  ),
  on = "development_id"
]
source_exception[
  identical_address_set_address_assessments %chin%
    bad_identical_assessments,
  `:=`(
    source_exception_group_id =
      identical_address_set_review_question_ids,
    concern_origin = "reviewed_identical_address_set"
  )
]
source_exception[
  cross_address_review_reason_code %chin% bad_cross_address_reasons,
  `:=`(
    source_exception_group_id = cross_address_identity_question_id,
    concern_origin = "earlier_cross_address_review"
  )
]

if (nrow(source_exception) != 57L ||
    uniqueN(source_exception$development_id) != 57L ||
    anyNA(source_exception$source_exception_group_id) ||
    anyNA(source_exception$concern_origin) ||
    any(grepl("[|]", source_exception$source_exception_group_id)) ||
    source_exception[concern_origin ==
      "excluded_identical_address_set", .N] != 16L ||
    source_exception[concern_origin ==
      "reviewed_identical_address_set", .N] != 13L ||
    source_exception[concern_origin ==
      "earlier_cross_address_review", .N] != 28L ||
    uniqueN(source_exception$source_exception_group_id) != 22L) {
  stop("The frozen source-site exception universe changed.",
    call. = FALSE)
}

identical_evidence <- identical_reviews[
  review_question_id %chin% source_exception$source_exception_group_id,
  .(
    source_exception_group_id = review_question_id,
    external_evidence_status = fifelse(
      review_question_id == "IASR_003",
      "identity_only_site_partition_unresolved",
      "site_partition_supported"
    ),
    external_source_title,
    external_source_type,
    external_source_url,
    external_notes,
    reviewed_on = as.character(final_reviewed_on),
    evidence_priority = 1L
  )
]
cross_evidence <- cross_reviews[
  identity_question_id %chin% source_exception$source_exception_group_id,
  .(
    source_exception_group_id = identity_question_id,
    external_evidence_status = fifelse(
      identity_question_id %chin% c(
        "XDAQ_0113", "XDAQ_0114", "XDAQ_0115"
      ),
      "placeholder_diagnosis_site_replacement_unresolved",
      fifelse(
        identity_question_id %chin% c(
          "XDAQ_0122", "XDAQ_0128", "XDAQ_0129",
          "XDAQ_0131", "XDAQ_0132", "XDAQ_0134"
        ),
        "property_identity_supported_bin_partition_proposed",
        "portfolio_scope_supported_bridge_required"
      )
    ),
    external_source_title = pass2_source_title,
    external_source_type = pass2_source_type,
    external_source_url = pass2_source_url,
    external_notes = pass2_notes,
    reviewed_on = as.character(final_reviewed_on),
    evidence_priority = 1L
  )
]
evidence_updates[, evidence_priority := 2L]
source_evidence <- rbindlist(
  list(identical_evidence, cross_evidence, evidence_updates),
  use.names = TRUE,
  fill = TRUE
)
setorder(source_evidence,
  source_exception_group_id,
  -evidence_priority
)
source_evidence <- unique(
  source_evidence,
  by = "source_exception_group_id"
)
source_evidence[, evidence_priority := NULL]

if (nrow(source_evidence) != 22L ||
    uniqueN(source_evidence$source_exception_group_id) != 22L ||
    anyNA(source_evidence$external_evidence_status) ||
    anyNA(source_evidence$external_source_title) ||
    anyNA(source_evidence$external_source_type) ||
    anyNA(source_evidence$external_source_url) ||
    anyNA(source_evidence$external_notes) ||
    anyNA(source_evidence$reviewed_on)) {
  stop("A source-site exception lacks outside evidence metadata.",
    call. = FALSE)
}

source_exception[source_evidence,
  `:=`(
    external_evidence_status = i.external_evidence_status,
    external_source_title = i.external_source_title,
    external_source_type = i.external_source_type,
    external_source_url = i.external_source_url,
    external_notes = i.external_notes,
    outside_reviewed_on = i.reviewed_on
  ),
  on = "source_exception_group_id"
]
if (anyNA(source_exception$external_evidence_status)) {
  stop("An exception development did not join to outside evidence.",
    call. = FALSE)
}

source_exception[, `:=`(
  episode_scope_assessment = "source_site_repair_only",
  proposed_episode_action = "retain_episode_pending_site_repair"
)]
source_exception[
  source_exception_group_id %chin% c("XDAQ_0019", "XDAQ_0123"),
  `:=`(
    episode_scope_assessment =
      "umbrella_financing_spans_distinct_physical_properties",
    proposed_episode_action =
      "build_episode_site_bridge_and_split_aggregate_development"
  )
]
source_exception[
  source_exception_group_id == "XDAQ_0116",
  `:=`(
    episode_scope_assessment =
      "component_episode_and_total_episode_same_physical_property",
    proposed_episode_action =
      "merge_physical_property_identity_and_preserve_both_episodes"
  )
]
source_exception[
  source_exception_group_id %chin% c(
    "XDAQ_0113", "XDAQ_0114", "XDAQ_0115"
  ),
  `:=`(
    episode_scope_assessment =
      "portfolio_scope_with_nonphysical_placeholder_address",
    proposed_episode_action =
      "obtain_site_list_then_build_episode_site_bridge"
  )
]
source_exception[
  source_exception_group_id == "IASR_003",
  `:=`(
    episode_scope_assessment =
      "distinct_projects_with_unpartitioned_parcel_descriptions",
    proposed_episode_action =
      "retain_episodes_pending_outside_site_partition"
  )
]
source_exception[
  development_id %chin% c("DEV_MAB20200014", "DEV_MAB20200016"),
  `:=`(
    episode_scope_assessment =
      "multibuilding_property_with_incomplete_source_site_list",
    proposed_episode_action =
      "obtain_building_list_then_reassess_physical_development_structure"
  )
]
source_exception[
  development_id == "DEV_MAB20191004",
  `:=`(
    episode_scope_assessment = "true_property_absent_from_source_site_set",
    proposed_episode_action = "replace_site_from_public_agency_record"
  )
]
source_exception[, `:=`(
  repair_application_status = "not_applied",
  source_rows_changed = FALSE,
  submission_approval = "not_approved"
)]

source_site <- site[source_exception[, .(
  development_id,
  development_name,
  source_exception_group_id,
  concern_origin,
  episode_scope_assessment,
  proposed_episode_action,
  external_evidence_status,
  external_source_title,
  external_source_type,
  external_source_url,
  external_notes,
  outside_reviewed_on,
  repair_application_status,
  source_rows_changed,
  submission_approval
)], on = "development_id", nomatch = 0L]
source_site[, `:=`(
  proposed_site_disposition = NA_character_,
  proposed_site_reason = NA_character_
)]

if (nrow(source_site) != 869L ||
    uniqueN(source_site$development_site_id) != 869L) {
  stop("The frozen source-site assignment count changed.",
    call. = FALSE)
}

multisite[, `:=`(
  raw_street_key = normalize_street(bin_add),
  site_key = make_site_key(proj_st, bin_add, bin_cty)
)]
multisite <- multisite[
  episode[, .(hud_id, development_id)],
  on = "hud_id",
  nomatch = 0L
]
raw_multisite_evidence <- multisite[
  development_id %chin% source_exception$development_id &
    !is.na(raw_street_key),
  .(
    raw_multisite_rows = .N,
    raw_multisite_hud_ids = paste(sort(unique(hud_id)), collapse = "|"),
    raw_bin_values = paste(
      sort(unique(bin[!is.na(bin) & bin != ""])),
      collapse = "|"
    ),
    raw_n_bin_values = uniqueN(bin[!is.na(bin) & bin != ""]),
    raw_street_examples = paste(
      sort(unique(bin_add[!is.na(bin_add) & bin_add != ""])),
      collapse = "|"
    ),
    raw_city_examples = paste(
      sort(unique(bin_cty[!is.na(bin_cty) & bin_cty != ""])),
      collapse = "|"
    ),
    raw_zip_examples = paste(
      sort(unique(bin_zip[!is.na(bin_zip) & bin_zip != ""])),
      collapse = "|"
    )
  ),
  by = .(development_id, site_key)
]
raw_site_bins <- unique(multisite[
  development_id %chin% source_exception$development_id &
    !is.na(raw_street_key) & !is.na(bin) & bin != "",
  .(development_id, site_key, raw_bin_value = bin)
])
raw_multisite_evidence[raw_bin_values == "", raw_bin_values := NA_character_]
source_site[raw_multisite_evidence,
  `:=`(
    raw_multisite_rows = i.raw_multisite_rows,
    raw_multisite_hud_ids = i.raw_multisite_hud_ids,
    raw_bin_values = i.raw_bin_values,
    raw_n_bin_values = i.raw_n_bin_values,
    raw_street_examples = i.raw_street_examples,
    raw_city_examples = i.raw_city_examples,
    raw_zip_examples = i.raw_zip_examples
  ),
  on = c("development_id", "site_key")
]

primary_evidence <- episode[
  development_id %chin% source_exception$development_id &
    !is.na(primary_site_key),
  .(
    primary_source_hud_ids = paste(sort(unique(hud_id)), collapse = "|"),
    primary_source_addresses = paste(
      sort(unique(proj_add[!is.na(proj_add) & proj_add != ""])),
      collapse = "|"
    ),
    primary_source_cities = paste(
      sort(unique(proj_cty[!is.na(proj_cty) & proj_cty != ""])),
      collapse = "|"
    ),
    primary_source_zips = paste(
      sort(unique(proj_zip[!is.na(proj_zip) & proj_zip != ""])),
      collapse = "|"
    ),
    primary_source_state_ids = paste(
      sort(unique(state_id[!is.na(state_id) & state_id != ""])),
      collapse = "|"
    )
  ),
  by = .(development_id, site_key = primary_site_key)
]
source_site[primary_evidence,
  `:=`(
    primary_source_hud_ids = i.primary_source_hud_ids,
    primary_source_addresses = i.primary_source_addresses,
    primary_source_cities = i.primary_source_cities,
    primary_source_zips = i.primary_source_zips,
    primary_source_state_ids = i.primary_source_state_ids
  ),
  on = c("development_id", "site_key")
]
source_site[, `:=`(
  raw_multisite_match = !is.na(raw_multisite_rows),
  primary_source_match = !is.na(primary_source_hud_ids)
)]

if (any(source_site$n_bin_values > 0L & !source_site$raw_multisite_match) ||
    any(source_site$n_bin_values > 0L &
      source_site$raw_n_bin_values != source_site$n_bin_values) ||
    any(source_site$n_bin_values > 0L &
      !vapply(seq_len(nrow(source_site)), function(row) {
        if (source_site$n_bin_values[row] == 0L) {
          return(TRUE)
        }
        source_site$bin_example[row] %chin% strsplit(
          source_site$raw_bin_values[row],
          "|",
          fixed = TRUE
        )[[1L]]
      }, logical(1L))) ||
    any(grepl("project_primary", source_site$site_source) &
      !source_site$primary_source_match)) {
  stop("A current exception site could not be reconstructed from raw source evidence.",
    call. = FALSE)
}

baltimore_bin_families <- list(
  "DEV_MDA20171002" = "^MD-14-22001$",
  "DEV_MDA20171006" = "^MD-15-03001$",
  "DEV_MDA20171008" = "^MD-14-3200[1-4]$",
  "DEV_MDA20171010" = "^MD-14-18001$",
  "DEV_MDA20180006" = "^MD-16-04001$",
  "DEV_MDA20180009" = "^MD-16-16001$",
  "DEV_MDA20180019" = "^MD-16-09001$",
  "DEV_MDA20180023" = "^MD-16-13001$",
  "DEV_MDA20180026" = "^MD-14-35001$",
  "DEV_MDA20180032" = "^MD-16-27001$"
)
for (id in names(baltimore_bin_families)) {
  own_site_keys <- raw_site_bins[
    development_id == id &
      grepl(baltimore_bin_families[[id]], raw_bin_value),
    unique(site_key)
  ]
  source_site[
    development_id == id & site_key %chin% own_site_keys,
    `:=`(
      proposed_site_disposition = "retain_canonical_source_site",
      proposed_site_reason = "bin_matches_project_md_number"
    )
  ]
  source_site[
    development_id == id & !site_key %chin% own_site_keys,
    `:=`(
      proposed_site_disposition = "remove_cross_listed_source_site",
      proposed_site_reason = "bin_belongs_to_other_md_project"
    )
  ]
}

boston_ids <- excluded_portfolio_members[
  source_exception_group_id == "IAS0670",
  development_id
]
source_site[
  development_id %chin% boston_ids &
    development_id != "DEV_MAB20191004" &
    grepl("project_primary", site_source),
  `:=`(
    proposed_site_disposition = "retain_canonical_source_site",
    proposed_site_reason = "project_primary_matches_outside_project_record"
  )
]
source_site[
  development_id %chin% boston_ids &
    is.na(proposed_site_disposition),
  `:=`(
    proposed_site_disposition = "remove_cross_listed_source_site",
    proposed_site_reason = fifelse(
      development_id == "DEV_MAB20191004",
      "mechanic_mill_true_site_absent_from_source_set",
      "site_belongs_to_other_project_in_copied_set"
    )
  )
]

source_site[
  source_exception_group_id == "IASR_003",
  `:=`(
    proposed_site_disposition = "outside_partition_required",
    proposed_site_reason =
      "same_nonstreet_parcel_set_copied_to_distinct_projects"
  )
]

primary_partition_ids <- c(
  "DEV_INA19880021", "DEV_INA20020030",
  "DEV_MAB20181003", "DEV_MAB20181004", "DEV_MAB20181008",
  "DEV_MAB20190003", "DEV_MAB20200017"
)
source_site[
  development_id %chin% primary_partition_ids &
    grepl("project_primary", site_source),
  `:=`(
    proposed_site_disposition = "retain_canonical_source_site",
    proposed_site_reason = "outside_record_confirms_project_primary"
  )
]
source_site[
  development_id %chin% primary_partition_ids &
    is.na(proposed_site_disposition),
  `:=`(
    proposed_site_disposition = "remove_cross_listed_source_site",
    proposed_site_reason =
      "outside_record_assigns_site_to_other_named_project"
  )
]

source_site[
  development_id == "DEV_WAA20060155" & site_city == "SEATTLE",
  `:=`(
    proposed_site_disposition = "retain_canonical_source_site",
    proposed_site_reason = "wshfc_confirms_seattle_property"
  )
]
source_site[
  development_id == "DEV_WAA20060155" & site_city != "SEATTLE",
  `:=`(
    proposed_site_disposition = "remove_cross_listed_source_site",
    proposed_site_reason = "wshfc_identifies_anacortes_site_as_unrelated"
  )
]
source_site[
  development_id == "DEV_WAA20070160" & grepl("BLDG", site_street),
  `:=`(
    proposed_site_disposition = "retain_canonical_source_site",
    proposed_site_reason = "wshfc_confirms_murdock_court_buildings"
  )
]
source_site[
  development_id == "DEV_WAA20070160" &
    site_street == "123 N MURDOCK ST",
  `:=`(
    proposed_site_disposition = "consolidate_same_bin_address_variant",
    proposed_site_reason = "base_address_duplicates_building_a_bin"
  )
]
source_site[
  development_id == "DEV_WAA20070160" &
    site_city == "MOUNTLAKE TERRACE",
  `:=`(
    proposed_site_disposition = "remove_cross_listed_source_site",
    proposed_site_reason =
      "wshfc_identifies_mountlake_terrace_site_as_unrelated"
  )
]
source_site[
  development_id == "DEV_WAA20140035" & grepl("BLDG", site_street),
  `:=`(
    proposed_site_disposition = "retain_canonical_source_site",
    proposed_site_reason = "wshfc_confirms_bothell_property_buildings"
  )
]
source_site[
  development_id == "DEV_WAA20140035" &
    site_street == "17716 BOTHELL EVERETT HIGHWAY",
  `:=`(
    proposed_site_disposition = "consolidate_same_bin_address_variant",
    proposed_site_reason = "base_address_duplicates_building_a_bin"
  )
]
source_site[
  development_id == "DEV_WAA20140035" & site_city == "DES MOINES",
  `:=`(
    proposed_site_disposition = "remove_cross_listed_source_site",
    proposed_site_reason = "wshfc_identifies_des_moines_site_as_unrelated"
  )
]
source_site[
  development_id == "DEV_WAA20040200" & site_city == "SEATTLE",
  `:=`(
    proposed_site_disposition = "retain_canonical_source_site",
    proposed_site_reason = "wshfc_confirms_seattle_property"
  )
]
source_site[
  development_id == "DEV_WAA20040200" & site_city != "SEATTLE",
  `:=`(
    proposed_site_disposition = "remove_cross_listed_source_site",
    proposed_site_reason = "wshfc_identifies_nonseattle_sites_as_unrelated"
  )
]

washington_bin_families <- list(
  "DEV_WAA19969050" = "^WA-94-00055$",
  "DEV_WAA19979021" = "^WA-96-00123$",
  "DEV_WAA20019077" = "^WA-98-00285$",
  "DEV_WAA20070030" = "^WA-05-0041[2-3]$",
  "DEV_WAA20080125" = "^WA-07-001(59|6[0-9])$",
  "DEV_WAA20089032" = "^WA-07-005(3[8-9]|4[0-4])$",
  "DEV_WAA20090090" = "^WA-08-003(2[5-9]|3[0-3])$",
  "DEV_WAA20099025" = "^WA-08-00(39[0-9]|40[0-4])$",
  "DEV_WAA20130008" = "^WA-12-00063$",
  "DEV_WAA20180028" = "^WA-16-0021[5-6]$",
  "DEV_WAA20180045" = "^WA-16-0009[5-8]$"
)
for (id in names(washington_bin_families)) {
  own_site_keys <- raw_site_bins[
    development_id == id &
      grepl(washington_bin_families[[id]], raw_bin_value),
    unique(site_key)
  ]
  source_site[
    development_id == id & site_key %chin% own_site_keys,
    `:=`(
      proposed_site_disposition = "retain_canonical_source_site",
      proposed_site_reason =
        "bin_family_matches_project_oid_timing_and_location"
    )
  ]
  duplicate_bins <- raw_site_bins[
    development_id == id &
      grepl(washington_bin_families[[id]], raw_bin_value),
    .(n_site_keys = uniqueN(site_key)),
    by = raw_bin_value
  ][n_site_keys > 1L, raw_bin_value]
  duplicate_site_keys <- raw_site_bins[
    development_id == id & raw_bin_value %chin% duplicate_bins,
    unique(site_key)
  ]
  source_site[
    development_id == id & site_key %chin% duplicate_site_keys &
      !grepl(
        "(^| )(BLD|BLDG|BLDGS|BUILDING|BUILDINGS)( |$)",
        site_street
      ),
    `:=`(
      proposed_site_disposition =
        "consolidate_same_bin_address_variant",
      proposed_site_reason =
        "base_address_duplicates_detailed_building_bin"
    )
  ]
  source_site[
    development_id == id & !site_key %chin% own_site_keys &
      raw_multisite_match & raw_n_bin_values > 0L,
    `:=`(
      proposed_site_disposition = "remove_cross_listed_source_site",
      proposed_site_reason = "bin_family_belongs_to_other_wshfc_property"
    )
  ]
  source_site[
    development_id == id &
      (!raw_multisite_match | raw_n_bin_values == 0L) &
      is.na(proposed_site_disposition),
    `:=`(
      proposed_site_disposition = "outside_campus_primary_confirmation",
      proposed_site_reason =
        "primary_address_has_no_bin_and_may_be_office_or_site"
    )
  ]
}
source_site[
  development_id == "DEV_WAA20161021" &
    grepl("project_primary", site_source),
  `:=`(
    proposed_site_disposition = "retain_canonical_source_site",
    proposed_site_reason = "primary_matches_wshfc_bellingham_property"
  )
]
source_site[
  development_id == "DEV_WAA20161021" &
    is.na(proposed_site_disposition),
  `:=`(
    proposed_site_disposition = "remove_cross_listed_source_site",
    proposed_site_reason = "bin_family_belongs_to_other_wshfc_property"
  )
]

source_site[
  source_exception_group_id %chin% c(
    "XDAQ_0113", "XDAQ_0114", "XDAQ_0115"
  ),
  `:=`(
    proposed_site_disposition = "outside_site_replacement_required",
    proposed_site_reason = "street_only_placeholder_is_not_a_physical_site"
  )
]
source_site[
  source_exception_group_id %chin% c("XDAQ_0019", "XDAQ_0123"),
  `:=`(
    proposed_site_disposition =
      "retain_umbrella_financing_assignment_requires_bridge",
    proposed_site_reason =
      "episode_legitimately_spans_distinct_physical_properties"
  )
]
source_site[
  source_exception_group_id == "XDAQ_0116",
  `:=`(
    proposed_site_disposition =
      "retain_same_physical_property_site",
    proposed_site_reason =
      "official_city_record_places_all_addresses_on_one_project_and_tax_lot"
  )
]

expected_dispositions <- data.table(
  proposed_site_disposition = c(
    "remove_cross_listed_source_site",
    "retain_canonical_source_site",
    "consolidate_same_bin_address_variant",
    "outside_site_replacement_required",
    "outside_partition_required",
    "outside_campus_primary_confirmation",
    "retain_umbrella_financing_assignment_requires_bridge",
    "retain_same_physical_property_site"
  ),
  expected_n = c(648L, 99L, 28L, 10L, 22L, 4L, 52L, 6L)
)
observed_dispositions <- source_site[, .N, by = proposed_site_disposition]
expected_dispositions[observed_dispositions,
  observed_n := i.N,
  on = "proposed_site_disposition"
]
if (anyNA(source_site$proposed_site_disposition) ||
    anyNA(source_site$proposed_site_reason) ||
    anyNA(expected_dispositions$observed_n) ||
    any(expected_dispositions$expected_n !=
      expected_dispositions$observed_n) ||
    any(source_site$repair_application_status != "not_applied") ||
    any(source_site$source_rows_changed) ||
    any(source_site$submission_approval != "not_approved")) {
  print(expected_dispositions)
  stop("A proposed source-site disposition changed.", call. = FALSE)
}

source_episode <- episode[source_exception[, .(
  development_id,
  development_name,
  source_exception_group_id,
  concern_origin,
  episode_scope_assessment,
  proposed_episode_action,
  external_evidence_status,
  external_source_title,
  external_source_type,
  external_source_url,
  external_notes,
  outside_reviewed_on,
  repair_application_status,
  source_rows_changed,
  submission_approval
)], on = "development_id", nomatch = 0L]
if (nrow(source_episode) != 68L || uniqueN(source_episode$hud_id) != 68L ||
    any(source_episode$repair_application_status != "not_applied") ||
    any(source_episode$source_rows_changed) ||
    any(source_episode$submission_approval != "not_approved") ||
    source_episode[
      episode_scope_assessment ==
        "umbrella_financing_spans_distinct_physical_properties",
      uniqueN(development_id)
    ] != 4L ||
    source_episode[
      episode_scope_assessment ==
        "component_episode_and_total_episode_same_physical_property",
      uniqueN(development_id)
    ] != 2L) {
  stop("The source-exception episode assignment changed.",
    call. = FALSE)
}

metadata_columns <- c(
  "source_exception_group_id",
  "concern_origin",
  "development_id",
  "development_name",
  "episode_scope_assessment",
  "proposed_episode_action",
  "external_evidence_status",
  "external_source_title",
  "external_source_type",
  "external_source_url",
  "external_notes",
  "outside_reviewed_on",
  "repair_application_status",
  "source_rows_changed",
  "submission_approval"
)
setcolorder(
  source_site,
  c(
    metadata_columns,
    "development_site_id",
    "proposed_site_disposition",
    "proposed_site_reason"
  )
)
setcolorder(
  source_episode,
  c(metadata_columns, "hud_id")
)
setorder(source_site,
  source_exception_group_id,
  development_id,
  site_number
)
setorder(source_episode,
  source_exception_group_id,
  development_id,
  episode_number,
  hud_id
)

write_parquet(
  source_site,
  "../output/lihtc_source_site_exception_assignments.parquet"
)
write_parquet(
  source_episode,
  "../output/lihtc_source_site_exception_episodes.parquet"
)

roundtrip_site <- as.data.table(read_parquet(
  "../output/lihtc_source_site_exception_assignments.parquet"
))
roundtrip_episode <- as.data.table(read_parquet(
  "../output/lihtc_source_site_exception_episodes.parquet"
))
if (!identical(source_site, roundtrip_site) ||
    !identical(source_episode, roundtrip_episode)) {
  stop("A source-site exception output failed its Parquet round trip.",
    call. = FALSE)
}

message(
  "Prepared 57 developments, 68 episodes, and 869 source-site ",
  "assignments; no repair applied and no query approved."
)
