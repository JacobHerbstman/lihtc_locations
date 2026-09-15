# setwd("/Users/jacobherbstman/Desktop/lihtc_locations/tasks/audits/within_city_discretion/code")
library(data.table)
source("../../../shared/code/save_data.R")
notes <- fread("evidence_notes.csv")
sources <- fread("sources.csv")
locus <- as.data.table(read.csv("../input/locus_city_text.csv", na.strings = "",
  colClasses = c(place_geoid = "character", county = "character")))
locus[is.na(content), content := ""]
stopifnot(!anyDuplicated(notes$evidence_id), !anyDuplicated(sources$file), !anyDuplicated(locus$chunk_id))
# External evidence is either unchanged downloaded PDF bytes or a disclosed web-tool excerpt.
# The latter is not a complete original HTML/PDF archive.
sources[, local_path := ifelse(acquisition == "original_pdf_via_curl", paste0("../input/", file), file)]
for (i in seq_len(nrow(sources))) {
  digest <- strsplit(system2("shasum", c("-a", "256", shQuote(sources$local_path[i])), stdout = TRUE), " ")[[1]][1]
  stopifnot(identical(digest, sources$sha256[i]), file.info(sources$local_path[i])$size == sources$bytes[i])
}
selected <- merge(notes[source_type == "locus"], locus, by.x = "source_locator", by.y = "chunk_id", all.x = TRUE)
stopifnot(nrow(selected) == sum(notes$source_type == "locus"), !anyNA(selected$header))
selected <- selected[, .(evidence_id, source_type, source_locator, section, interpretation,
  source_url = "https://huggingface.co/datasets/LocalLaws/LOCUS-v1", source_version = source_version_sha,
  place_geoid, header, content)]
external <- notes[source_type != "locus"]
external <- merge(external, sources, by.x = "source_locator", by.y = "file", all.x = TRUE)
stopifnot(nrow(external) == sum(notes$source_type != "locus"), !anyNA(external$sha256))
external[, content := ""]
for (i in seq_len(nrow(external))) {
  if (external$source_type[i] == "web_excerpt") {
    external$content[i] <- paste(readLines(external$local_path[i], warn = FALSE), collapse = "\n")
  }
}
external <- external[, .(evidence_id, source_type, source_locator, section, interpretation,
  source_url = url, source_version = sha256, place_geoid = NA_character_, header = section, content)]
evidence <- rbindlist(list(selected, external))
setorder(evidence, evidence_id)
SaveData(evidence, "../output/evidence.csv", "../report/evidence.txt", "evidence_id")
