library(plyr)
library(openxlsx)

AsanaDepricatedTaskFiles<-list.files("P:/Biz Dev/Marketplace Expansion/Asana Tasks/Depricated Masters", pattern = ".xlsx", full.names = T)

#DepricatedFilesFrame<-data.frame(FileName=AsanaDepricatedTaskFiles, FileDate=file.info(AsanaDepricatedTaskFiles)$mtime)

DepricatedFiles<-data.frame()

for (i in 1:length(AsanaDepricatedTaskFiles)){
  HoldingFrame<-read.xlsx(AsanaDepricatedTaskFiles[i])
  HoldingFrame$FileDate<-gsub("P:/Biz Dev/Marketplace Expansion/Asana Tasks/Depricated Masters/Asana_Task_Master_Depricated-|.xlsx", "", AsanaDepricatedTaskFiles[i])
  HoldingFrame$TaskKey<-paste(HoldingFrame$AsanaTaskID, HoldingFrame$FileDate, sep = "-")
  DepricatedFiles<-rbind.fill(DepricatedFiles, HoldingFrame)
}

CurrentFile<-openxlsx::read.xlsx("P:/Biz Dev/Marketplace Expansion/Asana Tasks/Asana_Task_Master.xlsx")
CurrentFile$FileDate<-format(Sys.time(), "%m_%d_%Y")
CurrentFile$TaskKey<-paste(CurrentFile$AsanaTaskID, CurrentFile$FileDate, sep = "-")

DepricatedFiles<-rbind.fill(DepricatedFiles, CurrentFile)
