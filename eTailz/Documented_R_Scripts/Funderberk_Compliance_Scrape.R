library(RMySQL)
library(openxlsx)
library(tcltk)
library(stringr)
library(conn.qk)
library(dplyr)
library(lubridate)

source("P:/Employees/MichaelC/R/Asin_Finder MySQL Connect.R")

FilePath<-file.choose()

VendorName<-str_split(FilePath, "_")[[1]][2]

FileBaseName<-paste0(Sys.Date(), "_",VendorName)

ManualReviewFile<-read.xlsx(FilePath)
ManualReviewFile<-ManualReviewFile[, !names(ManualReviewFile) %in% c("rank, brand")]

Asins<-gsub('"', "'", shpaste(as.vector(ManualReviewFile$asin)))

AsinFinderData<-fetch(dbSendQuery(asin_finder, paste0("Select * From asins a
                                                Where a.asin in (", Asins,")")), n=-1)

#Return only most recent ASIN Finder Datapoints
AsinFinderData<-AsinFinderData[, !names(AsinFinderData) %in% c("sku")]
AsinFinderData<-AsinFinderData[rev(order(as_datetime(AsinFinderData$created_at), AsinFinderData$asin)),]
AsinFinderData<-AsinFinderData[!duplicated(AsinFinderData$asin),]
 
AsinDataLeadGen<-conn_qk(paste0("Select p.gtin, p.asin, pd.features, pd.afn_lowest_price, pd.mfn_lowest_price from etailz_lead_generation.products p
                                Left Join etailz_lead_generation.product_details pd on pd.product_id = p.id
                                Where p.asin in (", Asins, ")
                                and p.marketplace_id = 1"), "dw01_etailz", "df")

AsinDataManualReview<-merge(ManualReviewFile, AsinFinderData, by = "asin")

AsinData<-merge(AsinDataManualReview, AsinDataLeadGen[AsinDataLeadGen$features!=""&!is.na(AsinDataLeadGen$features),], by = 'asin')

FeatureHolding<-merge(AsinDataManualReview, AsinDataLeadGen[AsinDataLeadGen$features==""|is.na(AsinDataLeadGen$features),], by = 'asin')

FeatureHolding<-FeatureHolding[colnames(FeatureHolding) %in% c("hyperlink", "asin", "upc", "partner_product_number", "mpn_batch", 
                                                               "product_title", "amazon_title", "rank", "mpn_product_id")]

write.xlsx(FeatureHolding, paste0("P:/Drop Ship/New Product Additions/3 - Manual Compliance Review/Waiting for Features/", FileBaseName, 
                                   "_ASINs_Awaiting_Features_", hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0),".xlsx"))

ProductsNotinLG<-anti_join(AsinDataManualReview, AsinData, by = "asin")

ProductsNotinLG<-ProductsNotinLG[colnames(ProductsNotinLG) %in% c("hyperlink", "asin", "upc", "partner_product_number", "mpn_batch", 
                                                                  "product_title", "amazon_title", "rank", "mpn_product_id")]

write.xlsx(ProductsNotinLG, paste0("P:/Drop Ship/New Product Additions/2 - ASINS to Scrape/ASINs for LG/", FileBaseName, "_ASINs_to_Add_LG_",
                                   hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0),".xlsx"))

FlagTerms<-read.xlsx("P:/Compliance/Scraper/Terms.xlsx")
PackTerms<-read.xlsx("P:/Operations/Drop Ship/Drop Ship Docs/Pack Sizing Terms.xlsx")
if(VendorName=="McKesson"){FlagTerms<-read.xlsx("P:/Compliance/Scraper/McKesson Terms.xlsx")}


#Compliance Scraper
#Tilte Scrape
AsinData$FlagPos<-str_match(tolower(AsinData$amazon_title), tolower(FlagTerms$Terms[1]))
AsinData$flagCheck<-""
AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(FlagTerms$Terms[1])]<-FlagTerms$Terms[1]
AsinData$FlagList<-AsinData$flagCheck
#Features Scrape
AsinData$FlagPos<-str_match(tolower(AsinData$features), tolower(FlagTerms$Terms[1]))
AsinData$flagCheck<-""
AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(FlagTerms$Terms[1])]<-FlagTerms$Terms[1]
AsinData$FlagListFeatures<-AsinData$flagCheck
#Desc Scrape
AsinData$FlagPos<-str_match(tolower(AsinData$product_description), tolower(FlagTerms$Terms[1]))
AsinData$flagCheck<-""
AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(FlagTerms$Terms[1])]<-FlagTerms$Terms[1]
AsinData$FlagListDesc<-AsinData$flagCheck

for(i in 2:length(FlagTerms$Terms)){
  #Tilte Scrape
  AsinData$FlagPos<-""
  AsinData$FlagPos<-str_match(tolower(AsinData$amazon_title), tolower(FlagTerms$Terms[i]))
  AsinData$flagCheck<-""
  AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(FlagTerms$Terms[i])]<-FlagTerms$Terms[i]
  for (x in 1:nrow(AsinData)) {
    if(AsinData$flagCheck[x]!=""){
      if(AsinData$FlagList[x]!=""){AsinData$FlagList[x]<-paste0(AsinData$FlagList[x], ", ", AsinData$flagCheck[x])}
      if(AsinData$FlagList[x]==""){AsinData$FlagList[x]<-AsinData$flagCheck[x]}
    }
  }
  
  
  #Features Scrape
  AsinData$FlagPos<-""
  AsinData$FlagPos<-str_match(tolower(AsinData$features), tolower(FlagTerms$Terms[i]))
  AsinData$flagCheck<-""
  AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(FlagTerms$Terms[i])]<-FlagTerms$Terms[i]
  for (x in 1:nrow(AsinData)) {
    if(AsinData$flagCheck[x]!=""){
      if(AsinData$FlagListFeatures[x]!=""){AsinData$FlagListFeatures[x]<-paste0(AsinData$FlagListFeatures[x], ", ", AsinData$flagCheck[x])}
      if(AsinData$FlagListFeatures[x]==""){AsinData$FlagListFeatures[x]<-AsinData$flagCheck[x]}
    }
  }
  
  #Description Scrape
  AsinData$FlagPos<-""
  AsinData$FlagPos<-str_match(tolower(AsinData$product_description), tolower(FlagTerms$Terms[i]))
  AsinData$flagCheck<-""
  AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(FlagTerms$Terms[i])]<-FlagTerms$Terms[i]
  for (x in 1:nrow(AsinData)) {
    if(AsinData$flagCheck[x]!=""){
      if(AsinData$FlagListDesc[x]!=""){AsinData$FlagListDesc[x]<-paste0(AsinData$FlagListDesc[x], ", ", AsinData$flagCheck[x])}
      if(AsinData$FlagListDesc[x]==""){AsinData$FlagListDesc[x]<-AsinData$flagCheck[x]}
    }
  }
}

#Pack Scraper
#Tilte Scrape
AsinData$FlagPos<-str_match(tolower(AsinData$amazon_title), tolower(PackTerms$Pack.Size.Terms[1]))
AsinData$flagCheck<-""
AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(PackTerms$Pack.Size.Terms[1])]<-PackTerms$Pack.Size.Terms[1]
for (x in 1:nrow(AsinData)) {
  if(AsinData$flagCheck[x]!=""){
    if(AsinData$FlagList[x]!=""){AsinData$FlagList[x]<-paste0(AsinData$FlagList[x], ", ", AsinData$flagCheck[x])}
    if(AsinData$FlagList[x]==""){AsinData$FlagList[x]<-AsinData$flagCheck[x]}
  }
}
#Features Scrape
AsinData$FlagPos<-str_match(tolower(AsinData$features), tolower(PackTerms$Pack.Size.Terms[1]))
AsinData$flagCheck<-""
AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(PackTerms$Pack.Size.Terms[1])]<-PackTerms$Pack.Size.Terms[1]
for (x in 1:nrow(AsinData)) {
  if(AsinData$flagCheck[x]!=""){
    if(AsinData$FlagListFeatures[x]!=""){AsinData$FlagListFeatures[x]<-paste0(AsinData$FlagListFeatures[x], ", ", AsinData$flagCheck[x])}
    if(AsinData$FlagListFeatures[x]==""){AsinData$FlagListFeatures[x]<-AsinData$flagCheck[x]}
  }
}
#Desc Scrape
AsinData$FlagPos<-str_match(tolower(AsinData$product_description), tolower(PackTerms$Pack.Size.Terms[1]))
AsinData$flagCheck<-""
AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(PackTerms$Pack.Size.Terms[1])]<-PackTerms$Pack.Size.Terms[1]
for (x in 1:nrow(AsinData)) {
  if(AsinData$flagCheck[x]!=""){
    if(AsinData$FlagListDesc[x]!=""){AsinData$FlagListDesc[x]<-paste0(AsinData$FlagListDesc[x], ", ", AsinData$flagCheck[x])}
    if(AsinData$FlagListDesc[x]!=""){AsinData$FlagListDesc[x]<-AsinData$flagCheck[x]}
  }
}

for(i in 2:length(PackTerms$Pack.Size.Terms)){
  #Tilte Scrape
  AsinData$FlagPos<-""
  AsinData$FlagPos<-str_match(tolower(AsinData$amazon_title), tolower(PackTerms$Pack.Size.Terms[i]))
  AsinData$flagCheck<-""
  AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(PackTerms$Pack.Size.Terms[i])]<-PackTerms$Pack.Size.Terms[i]
  for (x in 1:nrow(AsinData)) {
    if(AsinData$flagCheck[x]!=""){
      if(AsinData$FlagList[x]!=""){AsinData$FlagList[x]<-paste0(AsinData$FlagList[x], ", ", AsinData$flagCheck[x])}
      if(AsinData$FlagList[x]==""){AsinData$FlagList[x]<-AsinData$flagCheck[x]}
    }
  }
  #Features Scrape
  AsinData$FlagPos<-""
  AsinData$FlagPos<-str_match(tolower(AsinData$features), tolower(PackTerms$Pack.Size.Terms[i]))
  AsinData$flagCheck<-""
  AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(PackTerms$Pack.Size.Terms[i])]<-PackTerms$Pack.Size.Terms[i]
  for (x in 1:nrow(AsinData)) {
    if(AsinData$flagCheck[x]!=""){
      if(AsinData$FlagListFeatures[x]!=""){AsinData$FlagListFeatures[x]<-paste0(AsinData$FlagListFeatures[x], ", ", AsinData$flagCheck[x])}
      if(AsinData$FlagListFeatures[x]==""){AsinData$FlagListFeatures[x]<-AsinData$flagCheck[x]}
    }
  }
  
  #Description Scrape
  AsinData$FlagPos<-""
  AsinData$FlagPos<-str_match(tolower(AsinData$product_description), tolower(PackTerms$Pack.Size.Terms[i]))
  AsinData$flagCheck<-""
  AsinData$flagCheck[tolower(AsinData$FlagPos)==tolower(PackTerms$Pack.Size.Terms[i])]<-PackTerms$Pack.Size.Terms[i]
  for (x in 1:nrow(AsinData)) {
    if(AsinData$flagCheck[x]!=""){
      if(AsinData$FlagListDesc[x]!=""){AsinData$FlagListDesc[x]<-paste0(AsinData$FlagListDesc[x], ", ", AsinData$flagCheck[x])}
      if(AsinData$FlagListDesc[x]==""){AsinData$FlagListDesc[x]<-AsinData$flagCheck[x]}
    }
  }
}

#Parse Approved to Sell
AsinData$ComplianceCleared[
  AsinData$FlagList==""&AsinData$FlagListDesc==""&AsinData$FlagListFeatures==""
  ]<-"Cleared"

AsinData$ComplianceCleared[is.na(AsinData$ComplianceCleared)|AsinData$ComplianceCleared==""]<-"Denied"
ProductsDenied<-AsinData[AsinData$ComplianceCleared=="Denied",]
ProductsApproved<-AsinData[AsinData$ComplianceCleared=="Cleared",]

#Parse only needed columns
ProductsApproved<-data.frame(SKU=ProductsApproved$partner_product_number, ASIN=ProductsApproved$asin, UPC=ProductsApproved$upc, Length=(ProductsApproved$length/100), Width=(ProductsApproved$width/100),
                             Height=(ProductsApproved$height/100), Weight=(ProductsApproved$weight/100), Title_Description=ProductsApproved$amazon_title, Wholesale_Cost="", Estimated_Shipping="", MAP="", Price="")

#No UPCs
#ProductsApproved<-data.frame(SKU=ProductsApproved$partner_product_number, ASIN=ProductsApproved$asin, UPC="", Length=(ProductsApproved$length/100), Width=(ProductsApproved$width/100),
#                             Height=(ProductsApproved$height/100), Weight=(ProductsApproved$weight/100), Title_Description=ProductsApproved$amazon_title, Wholesale_Cost="", Estimated_Shipping="", MAP="", Price="")

ProductsDenied<-data.frame(sku=ProductsDenied$partner_product_number, asin=ProductsDenied$asin, UPC=ProductsDenied$upc,  product_description=ProductsDenied$partner_product_title, amazon_title=ProductsDenied$title,
                           amazon_description=ProductsDenied$product_description, amazon_features=ProductsDenied$features, title_flags=ProductsDenied$FlagList, description_flags=ProductsDenied$FlagListDesc, features_flags=ProductsDenied$FlagListFeatures)

#No UPCs
#ProductsDenied<-data.frame(sku=ProductsDenied$partner_product_number, asin=ProductsDenied$asin, UPC="",  product_description=ProductsDenied$partner_product_title, amazon_title=ProductsDenied$title,
#                           amazon_description=ProductsDenied$product_description, amazon_features=ProductsDenied$features, title_flags=ProductsDenied$FlagList, description_flags=ProductsDenied$FlagListDesc, features_flags=ProductsDenied$FlagListFeatures)

ProductsApproved<-format(ProductsApproved, scientific = F)
ProductsDenied<-format(ProductsDenied, scientific = F)

#Write to files
write.xlsx(ProductsDenied, paste0("P:/Drop Ship/New Product Additions/3 - Manual Compliance Review/", FileBaseName, "_Manual_Compliance_Review_", 
                                  hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0),".xlsx"))
write.xlsx(ProductsApproved, paste0("P:/Drop Ship/New Product Additions/4- Approved Products Amazon/", FileBaseName, "_Auto_Approved_Products_",
                                    hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0), ".xlsx"))
