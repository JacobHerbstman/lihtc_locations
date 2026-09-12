# Shared report for a saved CSV; arguments identify the caller's dataset and report.
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)>=2L)
x <- data.table::fread(args[1], na.strings="")
# Project records use hud_id; aggregate diagnostics supply their explicit key columns.
keys <- if(length(args)>2L) args[3:length(args)] else "hud_id"
stopifnot(all(keys %in% names(x)),!anyNA(x[,..keys]),!anyDuplicated(x[,..keys]))
columns <- data.table::data.table(
  column=names(x), type=vapply(x,function(z) paste(class(z),collapse="/"),character(1)),
  nonmissing=vapply(x,function(z) sum(!is.na(z)),integer(1)),
  distinct=vapply(x,data.table::uniqueN,integer(1)),
  min=vapply(x,function(z) if(is.numeric(z) && any(!is.na(z))) as.character(min(z,na.rm=TRUE)) else "NA",character(1)),
  max=vapply(x,function(z) if(is.numeric(z) && any(!is.na(z))) as.character(max(z,na.rm=TRUE)) else "NA",character(1)))
con <- file(args[2],"w")
writeLines(c(paste("Rows:",nrow(x)),paste("Key:",paste(keys,collapse=", "),"complete and unique"),paste("Saved-file MD5:",unname(tools::md5sum(args[1])))),con)
write.table(columns,con,sep="\t",quote=FALSE,row.names=FALSE)
close(con)
