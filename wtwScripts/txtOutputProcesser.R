# Finkel 20180507
# get output text files from wtw scripts, merge them, save as CSV with all variables
setwd('/data/jux/BBL/projects/finkelGrmpyWtw/finkelGrmpyWtwScripts/wtwScripts/txt_output/qtask_nodra/')
fileNames <- list.files()
fileNames <- fileNames[grepl(".txt", fileNames)]
wtw <- data.frame()
for (i in 1:length(fileNames)) {
  wtwTemp <- read.table(fileNames[i], sep="\t", header=FALSE, col.names=c("id", "study", substring(fileNames[i], 1, nchar(fileNames[i])-4)))
  if (i == 1) {wtw <- wtwTemp}
  else if (i > 1) {wtw <- merge(wtw, wtwTemp,by=c("id","study"))}
}

# remove 99352 - has multiple trial?
wtw <- wtw[!wtw$id == "99352",]

filePath <- paste0('/data/jux/BBL/projects/finkelGrmpyWtw/processedData/', "WTWFinkel", format(Sys.Date(), "%Y%m%d"), ".csv")

write.csv(wtw, filePath, row.names = FALSE)