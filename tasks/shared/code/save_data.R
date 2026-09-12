# Write a CSV and its deterministic data report together.
SaveData <- function(x, file, report, keys="hud_id") {
  stopifnot(all(keys %in% names(x)), !anyNA(x[,..keys]), !anyDuplicated(x[,..keys]))
  data.table::fwrite(x,file,na="")
  saved <- data.table::fread(file,na.strings="")
  columns <- data.table::data.table(
    column=names(saved),type=vapply(saved,function(z) paste(class(z),collapse="/"),character(1)),
    nonmissing=vapply(saved,function(z) sum(!is.na(z)),integer(1)),
    distinct=vapply(saved,data.table::uniqueN,integer(1)),
    min=vapply(saved,function(z) if(is.numeric(z) && any(!is.na(z))) as.character(min(z,na.rm=TRUE)) else "NA",character(1)),
    max=vapply(saved,function(z) if(is.numeric(z) && any(!is.na(z))) as.character(max(z,na.rm=TRUE)) else "NA",character(1)))
  con <- file(report,"w")
  on.exit(close(con))
  writeLines(c(paste("Rows:",nrow(saved)),paste("Key:",paste(keys,collapse=", "),"complete and unique"),
    paste("Saved-file MD5:",unname(tools::md5sum(file)))),con)
  write.table(columns,con,sep="\t",quote=FALSE,row.names=FALSE)
}
