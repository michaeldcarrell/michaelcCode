library(openxlsx)
library(RODBC)
library(plyr)
library(dplyr)
source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")

Unity_Old_Orders<-"P:/Drop Ship/dropship_scripts/MySQL/unshipped_orders-orders_48hr_old.sql"
Unity_Old_Orders<-readChar(Unity_Old_Orders, file.info(Unity_Old_Orders)$size)
Unity_Old_Orders<-fetch(dbSendQuery(redshift, Unity_Old_Orders), n=-1)

Unity_Tracking<-"P:/Drop Ship/dropship_scripts/MySQL/unshipped_orders-tracking.sql"
Unity_Tracking<-readChar(Unity_Tracking, file.info(Unity_Tracking)$size)
Unity_Tracking<-fetch(dbSendQuery(redshift, Unity_Tracking), n=-1)

Unity_Combined<-merge(Unity_Old_Orders, Unity_Tracking, by = "po_id", all.x = T)

Unity_No_Tracking<-Unity_Combined[is.na(Unity_Combined$tracking_number),]
Unity_No_Tracking$po_submitted_at<-as.POSIXct(Unity_No_Tracking$po_submitted_at)


#function to find number of non weekend days between two times
getDuration<-function(startDate){
  require(chron)
  calendar<-seq.Date(from = as.Date(min(startDate)),
                     to = as.Date(Sys.Date()),
                     by = 1)
  return(length(calendar[!is.weekend(calendar)])-1)
}

Unity_No_Tracking$weekdays_since_placed<-mapply(getDuration, Unity_No_Tracking$po_submitted_at)
Unity_Unshipped_Orders<-Unity_No_Tracking[Unity_No_Tracking$weekdays_since_placed>2,]
Unity_Unshipped_Orders<-Unity_Unshipped_Orders[rev(order(Unity_Unshipped_Orders$po_submitted_at)),]

msAcUnshippedOrders<-odbcDriverConnect("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=P:/Drop Ship/Customer Service/Unshipped_Orders.accdb")

msUnshippedOrders<-sqlQuery(msAcUnshippedOrders, "SELECT * FROM Unshipped_Orders")

#Backup
if(nrow(msUnshippedOrders)>0){
  write.csv(msUnshippedOrders, "P:/Drop Ship/Customer Service/Unshipped_Orders.csv")
}

Unity_Unshipped_Orders_Append<-Unity_Unshipped_Orders[!Unity_Unshipped_Orders$composite_key %in% msUnshippedOrders$composite_key,]
if(nrow(Unity_Unshipped_Orders_Append)>0){
  Unity_Unshipped_Orders_Append$status<-"Unshipped"
}

Unity_Unshipped_Orders_Update<-Unity_Unshipped_Orders[Unity_Unshipped_Orders$composite_key %in% msUnshippedOrders$composite_key,]

Unity_Unshipped_Orders_Update$notes<-msUnshippedOrders$notes[match(Unity_Unshipped_Orders_Update$composite_key, msUnshippedOrders$composite_key)]
Unity_Unshipped_Orders_Update$status<-msUnshippedOrders$status[match(Unity_Unshipped_Orders_Update$composite_key, msUnshippedOrders$composite_key)]
Unity_Unshipped_Orders_Update$tracking_number<-Unity_Tracking$tracking_number[match(Unity_Unshipped_Orders_Update$po_id, Unity_Tracking$po_id)]

Unity_Unshipped_Orders_Update<-Unity_Unshipped_Orders_Update %>% mutate_all(as.character)

Unity_Unshipped_Orders_Update$status[!is.na(Unity_Unshipped_Orders_Update$tracking_number)]<-"Tracked"

#Check for differences
msUnshippedOrders<-msUnshippedOrders %>% mutate_all(as.character)
Unity_Unshipped_Orders_Update<-anti_join(Unity_Unshipped_Orders_Update, msUnshippedOrders)

Unity_Unshipped_Orders_Append$po_submitted_at<-gsub("-", "/", Unity_Unshipped_Orders_Append$po_submitted_at)
Unity_Unshipped_Orders_Update$po_submitted_at<-gsub("-", "/", Unity_Unshipped_Orders_Update$po_submitted_at)

if(nrow(Unity_Unshipped_Orders_Append)>0){
  sqlSave(channel = msAcUnshippedOrders, dat = Unity_Unshipped_Orders_Append, tablename = "Unshipped_Orders",
          verbose = F, fast = F, safer = F, append = T, rownames = F)
}
if(nrow(Unity_Unshipped_Orders_Update)>0){
  sqlUpdate(channel = msAcUnshippedOrders, dat = Unity_Unshipped_Orders_Update, tablename = "Unshipped_Orders",
            verbose = F, fast = F, index = "composite_key")
}

backUpCheck<-sqlQuery(msAcUnshippedOrders, "SELECT * FROM Unshipped_Orders")

if(nrow(backUpCheck)!=(nrow(Unity_Unshipped_Orders_Append)+nrow(msUnshippedOrders))){
  backUpName<-paste0("P:/Drop Ship/Customer Service/Unshipped_Orders_Backup_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".csv")
  write.csv(msUnshippedOrders, "P:/Drop Ship/Customer Service/Unshipped_Orders.csv")
}

close(msAcUnshippedOrders)
