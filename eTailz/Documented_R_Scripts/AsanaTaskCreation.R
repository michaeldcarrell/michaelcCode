library(openxlsx)
library(stringr)
library(plyr)
library(dplyr)
library(tidyr)
library(DescTools)
library(xlsx)
source("P:/Employees/MichaelC/R/Asin_Finder MySQL Connect.R")
source("P:/Employees/MichaelC/R/Neptune MySQL Connect.R")
source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")

#Grab Previously Denied Listings
DeniedFiles<-list.files("P:/Biz Dev/Marketplace Expansion/Asana Tasks/Compliance Files/Denied", full.names = T)

for(i in 1:length(DeniedFiles)){
  if(i==1){
    DeniedListings<-openxlsx::read.xlsx(DeniedFiles[i])
  } else {DeniedListings<-rbind.fill(DeniedListings, openxlsx::read.xlsx(DeniedFiles[i]))}
}

#Get CA SKUs
CaExportFiles<-list.files("P:/Biz Dev/Marketplace Expansion/ChannelAdvisor Exports", full.names = T, include.dirs = F, recursive = F)

ClassificationsFile<-CaExportFiles[grepl("class", tolower(CaExportFiles)) & !grepl("error", tolower(CaExportFiles))]

CaClassifications<-openxlsx::read.xlsx(ClassificationsFile)

#Get Unity Products
Unity_Asana_TaskFile<-"P:/Drop Ship/dropship_scripts/Documented_R_Scripts/Unity_Asana_Task.sql"

Unity_Asana_Task<-readChar(Unity_Asana_TaskFile, file.info(Unity_Asana_TaskFile)$size)

NetSuiteLabels<-read.csv("P:/Development/BI Documentation/Kat/Data for Michael/approved_marketplaces.csv")
NetSuiteLabels$marketplace<-as.character(NetSuiteLabels$marketplace)
NetSuiteLabels$marketplace[NetSuiteLabels$marketplace=="Shop"]<-"Shop.com"

prefixes<-gsub("\"", "'", paste(shQuote(NetSuiteLabels$partner_prefix[!duplicated(NetSuiteLabels$partner_prefix)]), collapse=", "))

FbaData<-fetch(dbSendQuery(neptune, paste0("SELECT s.sku 'Inventory Number',
                             detail.asin ASIN,
                             cost.item_number MPN,
                             RIGHT(s.gtin, 13) EAN,
                             RIGHT(s.gtin, 12) UPC,
                             detail.title 'Auction Title',
                             LENGTH(detail.title) 'Length_Auction Title',
                             'eBay Title' Attribute1_Name,
                             CASE
                             WHEN LENGTH(detail.title) > 120 THEN detail.title
                             END Attribute1_Value,
                             CASE
                             WHEN LENGTH(detail.title) > 120 THEN LENGTH(detail.title)
                             END 'Length_eBay Title',
                             'eBay, Walmart, Sears, Pricefalls, Shop.com, Overstock' Labels,
                             'Walmart Price' Attribute7_Name,
                             detail.listing_price Attribute7_Value,
                             'Jet Price' Attribute8_Name,
                             detail.listing_price Attribute8_Value,
                             'Sears Price' Attribute9_Name,
                             detail.listing_price Attribute9_Value,
                             detail.listing_price 'Buy It Now Price',
                             'eBay Key Features' Attribute10_Name,
                             'Wish Price' Attribute11_Name,
                             detail.listing_price Attribute11_Value,
                             'SHOP Price' Attribute12_Name,
                             detail.listing_price Attribute12_Value,
                             'Overstock Price' Attribute13_Name,
                             detail.listing_price Attribute13_Value,
                             'Pricefalls Price' Attribute14_Name,
                             detail.listing_price Attribute14_Value,
                             'FBA' Classification,
                             p.id VendorId,
                             'FBA' VendorType,
                             p.prefix
                           FROM skus s
                           JOIN sku_details detail on s.id = detail.sku_id
                           JOIN sku_costs cost on s.id = cost.sku_id
                           JOIN partners p on s.partner_id = p.id
                           JOIN system_list_items sli on p.account_status_id = sli.id
                           WHERE s.ignore_reorder_until_date < CURDATE()
                           AND sli.id = 6
                           AND p.prefix IN (", prefixes,")
                           ORDER BY p.id")), n=-1)

UnityData<-fetch(dbSendQuery(redshift, Unity_Asana_Task), n=-1)

UnityData<-data.frame(`Inventory Number`=UnityData$`inventory number`,
                      ASIN=UnityData$asin,
                      MPN=UnityData$mpn,
                      EAN=UnityData$ean,
                      UPC=UnityData$upc,
                      `Auction Title`=UnityData$`auction title`,
                      `Length_Auction Title`=UnityData$`length_auction title`,
                      Attribute1_Name=UnityData$attribute1_name,
                      Attribute1_Value=UnityData$attribute1_value,
                      `Length_eBay Title`=UnityData$`length_ebay title`,
                      Labels=UnityData$labels,
                      Attribute7_Name=UnityData$attribute7_name,
                      Attribute7_Value=UnityData$attribute7_value,
                      Attribute8_Name=UnityData$attribute8_name,
                      Attribute8_Value=UnityData$attribute8_value,
                      Attribute10_Name=UnityData$attribute10_name,
                      Attribute11_Name=UnityData$attribute11_name,
                      Attribute11_Value=UnityData$attribute11_value,
                      Attribute12_Name=UnityData$attribute12_name,
                      Attribute12_Value=UnityData$attribute12_value,
                      Attribute13_Name=UnityData$attribute13_name,
                      Attribute13_Value=UnityData$attribute13_value,
                      Attribute14_Name=UnityData$attribute14_name,
                      Attribute14_Value=UnityData$attribute14_value,
                      Classification=UnityData$classification,
                      VendorId=UnityData$vendorid,
                      VendorType=UnityData$vendortype,
                      CompositeSku=UnityData$compositesku)

names(UnityData)<-gsub("\\.", " ", names(UnityData))

dbDisconnect(redshift)
dbDisconnect(neptune)

#Remove listings already in CA or Denied by compliance
UnityData<-UnityData[!UnityData$`Inventory Number` %in% CaClassifications$Inventory.Number&!UnityData$ASIN %in% DeniedListings$asin,]
UnityData<-UnityData[!UnityData$ASIN %in% DeniedListings$asin,]
FbaData<-FbaData[FbaData$`Inventory Number` %in% CaClassifications$Inventory.Number&!FbaData$ASIN %in% DeniedListings$asin,]

#Fill in marketplace Labels for FBA
NsMarketplaces<-data.frame(prefix = NetSuiteLabels$partner_prefix[!duplicated(NetSuiteLabels$partner_prefix)], marketplaces = NA)

for(i in 1:nrow(NsMarketplaces)){
  NsMarketplaces$marketplaces[i]<-gsub("\"", "", paste(shQuote(NetSuiteLabels$marketplace[NetSuiteLabels$partner_prefix==NsMarketplaces$prefix[i]&
                    NetSuiteLabels$marketplace %in% c('eBay', 'Walmart', 'Sears', 'Pricefalls', 'Shop.com', 'Overstock')]), collapse=", "))
}

FbaData$Labels<-NsMarketplaces$marketplaces[match(FbaData$prefix, NsMarketplaces$prefix)]
FbaData<-FbaData[FbaData$Labels!="",]

TaskData<-rbind.fill(UnityData, FbaData)

ManualComplianeApprovedFiles<-list.files("P:/Biz Dev/Marketplace Expansion/Asana Tasks/Compliance Files/Approved", full.names = T, pattern = ".xlsx", recursive = T)

if(length(ManualComplianeApprovedFiles)!=0){
  ManualComplianeApprovedProducts<-openxlsx::read.xlsx(ManualComplianeApprovedFiles[1])
  if(length(ManualComplianeApprovedFiles)>1){
    for(i in 2:length(ManualComplianeApprovedFiles)){
      ManualComplianeApprovedProducts<-rbind.fill(ManualComplianeApprovedProducts, openxlsx::read.xlsx(ManualComplianeApprovedFiles[i]))
    }
  }
  NoManualCompliance<-FALSE
  TaskData<-merge(TaskData, data.frame(asin = ManualComplianeApprovedProducts$asin,
                                     Title_Flag = ManualComplianeApprovedProducts$Title_Flag,
                                     Description_Flag = ManualComplianeApprovedProducts$Description_Flag,
                                     Features_Flag = ManualComplianeApprovedProducts$Features_Flag), by.x = "ASIN", by.y = "asin", all.x = T)
  } else {
  TaskData$Title_Flag<-NA
  TaskData$Description_Flag<-NA
  TaskData$Features_Flag<-NA
  NoManualCompliance<-TRUE
}

TaskASINs<-gsub("\"", "'", paste(shQuote(TaskData$ASIN), collapse=", "))

AsinFinderData<-fetch(dbSendQuery(asin_finder, paste0("SELECT a.asin ASIN,
                                                          a.brand Brand,            
                                                          a.product_description Description,
                                                          LENGTH(a.product_description) Length_description,
                                                          a.length/100 Length,
                                                          a.width/100 Width,
                                                          a.height/100 Height,
                                                          a.weight/100 Weight,
                                                          a.created_at,
                                                          a.rank
                                                        FROM asins a
                                                        WHERE a.asin in (", TaskASINs,")")), n=-1)

dbDisconnect(asin_finder)

AsinFinderData<-AsinFinderData[rev(order(AsinFinderData$created_at)),]
AsinFinderData$Description<-substr(gsub("<.*?>", "", AsinFinderData$Description), 1, 30000) #Remove HTML tags and limits to the 30,000 char limit of excel


row.names(AsinFinderData)<-seq.int(1, nrow(AsinFinderData))

AsinFinderData<-AsinFinderData[!duplicated(AsinFinderData$ASIN),]

source("P:/Employees/MichaelC/R/LG MySQL Connect.R")

LgData<-fetch(dbSendQuery(lead_gen, paste0("SELECT p.asin ASIN, pd.features, pd.created_at FROM product_details pd
                JOIN products p ON p.id = pd.product_id
                WHERE p.asin IN (", TaskASINs,")")),n=-1)
dbDisconnect(lead_gen)

LgData<-LgData[rev(order(LgData$created_at)),]
row.names(LgData)<-seq.int(1, nrow(LgData))

LgData<-LgData[!duplicated(LgData$ASIN),]

LgData<-LgData %>% separate(features, c("Attribute2_Value", "Attribute3_Value", "Attribute4_Value", "Attribute5_Value", "Attribute6_Value"),
                            extra = 'drop', sep = "<br>", remove = F)

LgData$Attribute10_Value<-paste0("<li>", LgData$Attribute2_Value, "</li>",
                                 "<li>", LgData$Attribute3_Value, "</li>",
                                 "<li>", LgData$Attribute4_Value, "</li>",
                                 "<li>", LgData$Attribute5_Value, "</li>",
                                 "<li>", LgData$Attribute6_Value, "</li>")

LgData$Attribute10_Value<-gsub("<li>NA</li>|<li></li>", "", LgData$Attribute10_Value)

#options(scipen = 999)

dscoCatalogs<-data.frame(files=list.files("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO"))
dscoCatalogs$fileDate<-gsub(".csv|.xlsx|.xls", "", 
                            substr(dscoCatalogs$files, 
                                   max(as.integer(gregexpr("_", dscoCatalogs$files)[[1]]))+1, nchar(as.character(dscoCatalogs$files))
                            )
)

NewestFile<-as.character(dscoCatalogs$files[dscoCatalogs$fileDate==max(dscoCatalogs$fileDate)])
MostRecentDscoCatalog<-read.csv(paste0("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO\\", NewestFile))

MostRecentDscoCatalog$CompositeSku<-paste(MostRecentDscoCatalog$dsco_supplier_id, MostRecentDscoCatalog$sku, sep = "-")

MostRecentDscoCatalog$File_Updated_At<-file.mtime(paste0("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO\\", NewestFile))

ExportFrame<-merge(TaskData, LgData, by = 'ASIN', all.x = T)
ExportFrame<-merge(ExportFrame, AsinFinderData, by = 'ASIN', all.x = T)
ExportFrame<-merge(ExportFrame, MostRecentDscoCatalog, by = 'CompositeSku', all.x = T)

FbaExport<-ExportFrame[ExportFrame$VendorType=='FBA',]
DsExport<-ExportFrame[ExportFrame$VendorType=='Dropship',]

DsExport<-DsExport[order(DsExport$Description_Flag, DsExport$Title_Flag, DsExport$Features_Flag, DsExport$rank),]
FbaExport<-FbaExport[order(FbaExport$Description_Flag, FbaExport$Title_Flag, FbaExport$Features_Flag, FbaExport$rank),]

DsExport<-data.frame('Inventory Number'=DsExport$`Inventory Number`,
                      ASIN=DsExport$ASIN,
                      MPN=DsExport$MPN,
                      EAN=DsExport$EAN,
                      UPC=DsExport$UPC,
                      'Auction Title'=DsExport$`Auction Title`,
                      Length_Auction_Title=DsExport$`Length_Auction Title`,
                      Attribute1_Name=DsExport$Attribute1_Name,
                      Attribute1_Value=DsExport$Attribute1_Value,
                      'Length_eBay Title'=DsExport$`Length_eBay Title`,
                      Labels=DsExport$Labels,
                      Brand=DsExport$Brand,
                      Description=DsExport$Description,
                      Length_description=DsExport$Length_description,
                      Length=DsExport$Length,
                      Width=DsExport$Width,
                      Height=DsExport$Height,
                      Weight=DsExport$Weight,
                      Attribute2_Name='Keyfeature1',
                      Attribute2_Value=DsExport$Attribute2_Value,
                      Attribute3_Name='Keyfeature2',
                      Attribute3_Value=DsExport$Attribute3_Value,
                      Attribute4_Name='Keyfeature3',
                      Attribute4_Value=DsExport$Attribute4_Value,
                      Attribute5_Name='Keyfeature4',
                      Attribute5_Value=DsExport$Attribute5_Value,
                      Attribute6_Name='Keyfeature5',
                      Attribute6_Value=DsExport$Attribute6_Value,
                      Attribute10_Name=DsExport$Attribute10_Name,
                      Attribute10_Value=DsExport$Attribute10_Value,
                      'Picture URLs'="",
                      itemimageurl1="itemimageurl1=",
                      Image1=DsExport$product_image_reference_1,
                      itemimageurl2="itemimageurl2=",
                      Image2=DsExport$product_image_reference_2,
                      itemimageurl3="itemimageurl3=",
                      Image3=DsExport$product_image_reference_3,
                      itemimageurl4="itemimageurl4",
                      Image4="",
                      itemimageurl5="itemimageurl5",
                      Image5="",
                      Attribute7_Name=DsExport$Attribute7_Name,
                      Attribute7_Value=DsExport$Attribute7_Value,
                      Attribute8_Name=DsExport$Attribute8_Name,
                      Attribute8_Value=DsExport$Attribute8_Value,
                      Attribute9_Name=DsExport$Attribute9_Name,
                      Attribute9_Value=DsExport$Attribute9_Value,
                      'Buy It Now Price'=DsExport$`Buy It Now Price`,
                      Attribute11_Name=DsExport$Attribute11_Name,
                      Attribute11_Value=DsExport$Attribute11_Value,
                      Attribute12_Name=DsExport$Attribute12_Name,
                      Attribute12_Value=DsExport$Attribute12_Value,
                      Attribute13_Name=DsExport$Attribute13_Name,
                      Attribute13_Value=DsExport$Attribute13_Value,
                      Attribute14_Name=DsExport$Attribute14_Name,
                      Attribute14_Value=DsExport$Attribute14_Value,
                      Classification=DsExport$Classification,
                      AsanaTaskID=NA,
                      TaskAssignedTo="",
                      Vendor=DsExport$VendorId,
                      Title_Flag=DsExport$Title_Flag,
                      Description_Flag=DsExport$Description_Flag,
                      Features_Flag=DsExport$Features_Flag)



CurrentATID<-1
for(i in 1:nrow(DsExport)){
  if(i%%300==0){
    DsExport$AsanaTaskID[(i-299):i]<-CurrentATID
    CurrentATID<-CurrentATID+1
  }
  if(i==nrow(DsExport)){
    DsExport$AsanaTaskID[((CurrentATID-1)*300):i]<-CurrentATID
  }
}

DsExport<-arrange(DsExport, DsExport$AsanaTaskID, DsExport$Vendor)
DsExport$Vendor<-NULL
FinalExportDs<-DsExport[DsExport$AsanaTaskID<=10,]

FbaExport<-data.frame('Inventory Number'=FbaExport$`Inventory Number`,
                     ASIN=FbaExport$ASIN,
                     MPN=FbaExport$MPN,
                     EAN=FbaExport$EAN,
                     UPC=FbaExport$UPC,
                     'Auction Title'=FbaExport$`Auction Title`,
                     Length_Auction_Title=FbaExport$`Length_Auction Title`,
                     Attribute1_Name=FbaExport$Attribute1_Name,
                     Attribute1_Value=FbaExport$Attribute1_Value,
                     'Length_eBay Title'=FbaExport$`Length_eBay Title`,
                     Labels=FbaExport$Labels,
                     Brand=FbaExport$Brand,
                     Description=FbaExport$Description,
                     Length_description=FbaExport$Length_description,
                     Length=FbaExport$Length,
                     Width=FbaExport$Width,
                     Height=FbaExport$Height,
                     Weight=FbaExport$Weight,
                     Attribute2_Name='Keyfeature1',
                     Attribute2_Value=FbaExport$Attribute2_Value,
                     Attribute3_Name='Keyfeature2',
                     Attribute3_Value=FbaExport$Attribute3_Value,
                     Attribute4_Name='Keyfeature3',
                     Attribute4_Value=FbaExport$Attribute4_Value,
                     Attribute5_Name='Keyfeature4',
                     Attribute5_Value=FbaExport$Attribute5_Value,
                     Attribute6_Name='Keyfeature5',
                     Attribute6_Value=FbaExport$Attribute6_Value,
                     Attribute10_Name=FbaExport$Attribute10_Name,
                     Attribute10_Value=FbaExport$Attribute10_Value,
                     'Picture URLs'="",
                     itemimageurl1="itemimageurl1=",
                     Image1=FbaExport$product_image_reference_1,
                     itemimageurl2="itemimageurl2=",
                     Image2=FbaExport$product_image_reference_2,
                     itemimageurl3="itemimageurl3=",
                     Image3=FbaExport$product_image_reference_3,
                     itemimageurl4="itemimageurl4",
                     Image4="",
                     itemimageurl5="itemimageurl5",
                     Image5="",
                     Attribute7_Name=FbaExport$Attribute7_Name,
                     Attribute7_Value=FbaExport$Attribute7_Value,
                     Attribute8_Name=FbaExport$Attribute8_Name,
                     Attribute8_Value=FbaExport$Attribute8_Value,
                     Attribute9_Name=FbaExport$Attribute9_Name,
                     Attribute9_Value=FbaExport$Attribute9_Value,
                     'Buy It Now Price'=FbaExport$`Buy It Now Price`,
                     Attribute11_Name=FbaExport$Attribute11_Name,
                     Attribute11_Value=FbaExport$Attribute11_Value,
                     Attribute12_Name=FbaExport$Attribute12_Name,
                     Attribute12_Value=FbaExport$Attribute12_Value,
                     Attribute13_Name=FbaExport$Attribute13_Name,
                     Attribute13_Value=FbaExport$Attribute13_Value,
                     Attribute14_Name=FbaExport$Attribute14_Name,
                     Attribute14_Value=FbaExport$Attribute14_Value,
                     Classification=FbaExport$Classification,
                     AsanaTaskID=NA,
                     TaskAssignedTo="",
                     Vendor=FbaExport$VendorId,
                     Title_Flag=FbaExport$Title_Flag,
                     Description_Flag=FbaExport$Description_Flag,
                     Features_Flag=FbaExport$Features_Flag)

CurrentATID<-1
for(i in 1:nrow(FbaExport)){
  if(i%%300==0){
    FbaExport$AsanaTaskID[(i-299):i]<-CurrentATID + max(FinalExportDs$AsanaTaskID) 
    CurrentATID<-CurrentATID+1
  }
  if(i==nrow(FbaExport)){
    FbaExport$AsanaTaskID[((CurrentATID-1)*300):i]<-CurrentATID + max(FinalExportDs$AsanaTaskID) 
  }
}

FbaExport<-arrange(FbaExport, FbaExport$AsanaTaskID, FbaExport$Vendor)
FbaExport$Vendor<-NULL
FinalExportFba<-FbaExport[FbaExport$AsanaTaskID<=5 + max(FinalExportDs$AsanaTaskID) ,]

FinalExport<-rbind.fill(FinalExportDs, FinalExportFba)

#compliance Check
source("P:/Drop Ship/dropship_scripts/Documented_R_Scripts/compliance_scrape_function.R")
asins<-gsub("\"", "'", paste(shQuote(FinalExport$ASIN[which(is.na(FinalExport$Description_Flag)&
                                                              is.na(FinalExport$Title_Flag)&
                                                              is.na(FinalExport$Features_Flag))]), collapse=", "))

ComplianceCleared<-ComplianceScraper(asins = asins, termsource = "3PM", email = T, export = T, test = F)

if(!NoManualCompliance){
  FinalExport<-FinalExport[FinalExport$ASIN %in% ComplianceCleared$asin | FinalExport$ASIN %in% ManualComplianeApprovedProducts$asin,]
} else {
  FinalExport<-FinalExport[FinalExport$ASIN %in% ComplianceCleared$asin,]
}

FinalExport$Weight<-round(FinalExport$Weight, 1)

OldMaster<-openxlsx::read.xlsx("P:/Biz Dev/Marketplace Expansion/Asana Tasks/Asana_Task_Master.xlsx")
DepricationName<-paste0("P:/Biz Dev/Marketplace Expansion/Asana Tasks/Depricated Masters/Asana_Task_Master_Depricated-", format(Sys.time(), "%m_%d_%Y"), ".xlsx")
openxlsx::write.xlsx(OldMaster, DepricationName, row.names = F)

openxlsx::write.xlsx(FinalExport, "P:/Biz Dev/Marketplace Expansion/Asana Tasks/Asana_Task_Master.xlsx", row.names = F)
