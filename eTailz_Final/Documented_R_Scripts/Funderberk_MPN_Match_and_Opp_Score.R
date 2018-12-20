library(RMySQL)
library(openxlsx)
library(tcltk)
library(stringr)
library(conn.qk)
library(dplyr)
library(lubridate)
library(RSQLite)
options(scipen=999)

#Database Connection
source("P:/Employees/MichaelC/R/Asin_Finder MySQL Connect.R")
source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")

AllVendors<-fetch(dbSendQuery(unity, "Select v.name, v.id From vendors v"))
AllVendors<-AllVendors[order(AllVendors$name),]
AsinFinderJob<-"8574"
VendorName<-tk_select.list(as.vector(AllVendors$name), title = "Select Vendor")

#First Job
ASINsBook<-fetch(dbSendQuery(asin_finder, paste0("Select * From job_items ji
                             Join eans e on e.ean = ji.item_key
                             Join asin_ean ae on ae.ean_id = e.id
                             Join asins a on a.id = ae.asin_id
                             Where ji.job_id in (", AsinFinderJob, ")")), n=-1)

CatalogType<-tk_select.list(c('DSCO Catalog', 'Excel Catalog'), title = "Select Catalog Type")

if(CatalogType=="Excel Catalog"){
  #Choose Vendor File
  print("Choose File for Vendor Catalog (Must be .xlsx or .csv)")
  MpnFilePath<-file.choose()
  if(grep(".xlsx", MpnFilePath)==1){MpnFile<-read.xlsx(MpnFilePath, sheet = 1)}
  if(grep(".csv", MpnFilePath)==1){MpnFile<-read.csv(MpnFilePath)}
  
  #Select MPN and UPC Columns
  MpnFileMPN<-tk_select.list(colnames(MpnFile), title = "Select MPN/Part Number column from Vendor Catalog")
  MpnFileUPC<-tk_select.list(colnames(MpnFile), title = "Select UPC column from Vendor Catalog")
  ProductTitle<-tk_select.list(colnames(MpnFile), title = "Select Product Title column from Vendor Catalog")
}

if(CatalogType=="DSCO Catalog"){
  MpnFilePath<-"DSCO"
  source("P:/Employees/MichaelC/R/DSCO_Products MySQL Connect.R")
  dsco_catalog<-fetch(dbSendStatement(dsco_products, "SELECT * FROM products"),n=-1)
  dsco_catalog<-dsco_catalog[order(dsco_catalog$dscoSupplierName),]
  dsco_vendor<-tk_select.list(unique(dsco_catalog$dscoSupplierName), title = "Select DSCO Vendor Catalog")
  
  MpnFile<-dsco_catalog[dsco_catalog$dscoSupplierName==dsco_vendor,]
  MpnFileMPN<-"sku"
  MpnFileUPC<-"upc"
  ProductTitle<-"title"
}


MpnFile<-MpnFile[c(MpnFileMPN, MpnFileUPC, ProductTitle)]

#Match MpnFile to Asins
AsinData<-data.frame(asin=ASINsBook$asin, upc=as.numeric(ASINsBook$item_key), PartNumberAsinFinder=ASINsBook$part_number, 
                     MpnAsinFinder=ASINsBook$mpn, ModelAsinFinder=ASINsBook$model, rank=ASINsBook$rank, amazon_title=ASINsBook$title, 
                     product_description=ASINsBook$product_description)
AsinData<-AsinData[unique(AsinData$asin),]
AsinData<-merge(AsinData, MpnFile, by.x = "upc", by.y = MpnFileUPC)

#Exact Matchs
AsinData$PartNumberMatch<-as.numeric(AsinData$PartNumberAsinFinder %in% MpnFile[,MpnFileMPN])
AsinData$MpnMatch<-as.numeric(AsinData$MpnAsinFinder %in% MpnFile[,MpnFileMPN])
AsinData$ModelMatch<-as.numeric(AsinData$ModelAsinFinder %in% MpnFile[,MpnFileMPN])
  
#Create Columns for Partial Matches
AsinData$PartialPartMatch<-""
AsinData$PartialMpnMatch<-""
AsinData$PartialModelMatch<-""
AsinData$ManualReviewMpnFlag<-""
AsinData$DiscardFlag<-""
AsinData$MpnApproved<-""
AsinData$MpnSection<-""
AsinData$MultiAsinFlag<-""
AsinData$asin<-as.character(AsinData$asin)
AsinData<-as.data.frame(gsub("\\*", "", as.matrix(AsinData)))
AsinData<-mutate_all(AsinData, as.character)

#Substring Matches
for(i in 1:nrow(AsinData)){
  #StartTime<-Sys.time()
  if(!is.na(AsinData[i, MpnFileMPN])){
    AsinData$PartialPartMatch[i]<-grepl(AsinData$PartNumberAsinFinder[i], AsinData[i, MpnFileMPN])
    AsinData$PartialMpnMatch[i]<-grepl(AsinData$MpnAsinFinder[i], AsinData[i, MpnFileMPN])
    AsinData$PartialModelMatch[i]<-grepl(AsinData$ModelAsinFinder[i], AsinData[i, MpnFileMPN])
  }
  #EndTime<-Sys.time()
  #RunTime<-EndTime-StartTime
  #RunTime
}
AsinData$PartialPartMatch[is.na(AsinData$PartialPartMatch)]<-0
AsinData$PartialPartMatch<-gsub(TRUE, 1, AsinData$PartialPartMatch)
AsinData$PartialPartMatch<-gsub(FALSE, 0, AsinData$PartialPartMatch)
AsinData$PartialMpnMatch[is.na(AsinData$PartialMpnMatch)]<-0
AsinData$PartialMpnMatch<-gsub(TRUE, 1, AsinData$PartialMpnMatch)
AsinData$PartialMpnMatch<-gsub(FALSE, 0, AsinData$PartialMpnMatch)
AsinData$PartialModelMatch[is.na(AsinData$PartialModelMatch)]<-0
AsinData$PartialModelMatch<-gsub(TRUE, 1, AsinData$PartialModelMatch)
AsinData$PartialModelMatch<-gsub(FALSE, 0, AsinData$PartialModelMatch)

AsinData$PercentPartialMatch<-(as.numeric(AsinData$PartialModelMatch)+as.numeric(AsinData$PartialMpnMatch)+as.numeric(AsinData$PartialPartMatch))/3

#Flag Multiple MPN to UPC
SectionStartPosition<-1
SectionCounter<-1
AsinID<-1
AsinData$upc<-as.character(AsinData$upc)
AsinData$MultiAsinNumb<-""
row.names(AsinData)<-seq.int(1, nrow(AsinData), 1)
PercentMarker<-nrow(AsinData)/100
Times<-0
PercStartTime<-Sys.time()

CurrentUpc<-AsinData$upc[1]

AsinData<-AsinData[order(AsinData$upc, AsinData$asin),]

for(i in 1:nrow(AsinData)-1){
  if(AsinData$upc[i+1]!=CurrentUpc){
    CurrentSection<-AsinData[SectionStartPosition:i,]
    #No MPN's Match ASIN Finder MPN's
    if(length(unique(CurrentSection[,MpnFileMPN]))>1){
      AsinData$ManualReviewMpnFlag[SectionStartPosition:i]<-1
    }
    if(length(unique(CurrentSection[,MpnFileMPN]))==1&(CurrentSection$PercentPartialMatch[1]!=1|is.na(CurrentSection$PercentPartialMatch[1]))){
      AsinData$ManualReviewMpnFlag[SectionStartPosition:i]<-1
    }
    #Exactly One MPN Matches ASIN Finder MPN's #Scrap Auto Select for Multi MPN per UPC
    #if(nrow(CurrentSection[CurrentSection$PercentPartialMatch==1,])==1){
    #  AsinData$DiscardFlag[SectionStartPosition:i]<-1
    #  AsinData$MpnApproved[which(grepl(1, CurrentSection$PercentPartialMatch))+SectionStartPosition-1]<-1
    #  AsinData$DiscardFlag[which(grepl(-1, CurrentSection$PercentPartialMatch))+SectionStartPosition-1]<-""
    #}
    #Multiple MPN's Match ASIN Finder MPN's #Scrap Auto Select for Multi MPN per UPC
    #if(nrow(CurrentSection[CurrentSection$PercentPartialMatch==1,])>1){
    #  AsinData$DiscardFlag[SectionStartPosition:i]<-1
    #  AsinData$ManualReviewMpnFlag[which(grepl(1, CurrentSection$PercentPartialMatch))+SectionStartPosition-1]<-1
    #  AsinData$DiscardFlag[which(grepl(1, CurrentSection$PercentPartialMatch))+SectionStartPosition-1]<-""
    #}
    #Multi ASIN FLAG
    if(length(unique(CurrentSection$asin))>1){
      AsinData$MultiAsinFlag[SectionStartPosition:i]<-1
      AsinData$MultiAsinNumb[SectionStartPosition:i]<-seq.int(1, i-SectionStartPosition+1)
    }
    AsinData$MpnSection[SectionStartPosition:i]<-SectionCounter
    SectionCounter = SectionCounter + 1
    SectionStartPosition = i + 1
    CurrentUpc<-AsinData$upc[SectionStartPosition]
  
    #For Testing
    #if(i > 60){
    #  readline(i + 1)
    #}
    #if(i>PercentMarker*Times){ #For Long Runs
    #  PercEndTime<-Sys.time()
    #  PercTime<-difftime(PercEndTime, PercStartTime, units = "mins")
    #  print(paste0(Times, "%"))
    #  print(paste0("Estimated Time Remaining: ", round(as.numeric(PercTime/(Times/100)),2), " min"))
    #  Times<-Times + 1
    #}
  }
}

#Set Filter for Approved ASINs
AsinData$MpnApproved[AsinData$ManualReviewMpnFlag!=1&AsinData$MultiAsinFlag!=1]<-1

#Separate Different Files
ApprovedASINs<-AsinData[AsinData$MpnApproved==1,]
MultiAsinReview<-AsinData[AsinData$MultiAsinFlag==1&AsinData$ManualReviewMpnFlag!=1,]
MpnReview<-AsinData[AsinData$ManualReviewMpnFlag==1,]

#Write to Files
FileBaseName<-paste0(Sys.Date(), "_",VendorName)

#Assign Multi ASIN Product ID's
CurrentUpc<-MultiAsinReview$upc[1]
ProductId<-1
BatchStartPosition<-1
MultiAsinReview$mpn_product_id<-as.numeric("")
for(i in 1:nrow(MultiAsinReview)){
  if(CurrentUpc!=MultiAsinReview$upc[i+1]|is.na(MultiAsinReview$upc[i+1])){
    MultiAsinReview$mpn_product_id[BatchStartPosition:i]<-as.numeric(ProductId)
    ProductId<-ProductId+1
    BatchStartPosition<-i+1
    CurrentUpc<-MultiAsinReview$upc[i+1]
  }
}

#Assign MPN Product ID's
CurrentUpc<-MpnReview$upc[1]
ProductId<-1
BatchStartPosition<-1
MpnReview$mpn_product_id<-as.numeric("")
for(i in 1:nrow(MpnReview)){
  if(CurrentUpc!=MpnReview$upc[i+1]|is.na(MpnReview$upc[i+1])){
    MpnReview$mpn_product_id[BatchStartPosition:i]<-as.numeric(ProductId)
    ProductId<-ProductId+1
    BatchStartPosition<-i+1
    CurrentUpc<-MpnReview$upc[i+1]
  }
}

#Parse Files Down
MultiAsinReview<-data.frame(asin=MultiAsinReview$asin, upc=MultiAsinReview$upc, partner_product_number=MultiAsinReview[,MpnFileMPN],
                            mpn_product_id=MultiAsinReview$mpn_product_id, partner_product_title=MultiAsinReview[,ProductTitle], amazon_title=MultiAsinReview$amazon_title, 
                            rank=MultiAsinReview$rank, hyperlink=paste0('https://www.amazon.com/dp/', MultiAsinReview$asin), decision="")
MultiAsinReview<-format(MultiAsinReview, scientific = F)
MultiAsinReview<-MultiAsinReview[order(MultiAsinReview$mpn_product_id, MultiAsinReview$rank),]

MpnReview<-data.frame(asin=MpnReview$asin, upc=MpnReview$upc, partner_product_number=MpnReview[,MpnFileMPN],
                      mpn_product_id=MpnReview$mpn_product_id, partner_product_title=MpnReview[,ProductTitle],  amazon_title=MpnReview$amazon_title,
                      rank=MpnReview$rank, hyperlink=paste0('https://www.amazon.com/dp/', MpnReview$asin), decision="")
MpnReview<-MpnReview[order(MpnReview$mpn_product_id, MpnReview$rank),]

#Write Multi ASIN Files
if(max(MultiAsinReview$mpn_product_id)>=500){
  for(i in 1:ceiling(max(MultiAsinReview$mpn_product_id)/500)){
    write.xlsx(MultiAsinReview[MultiAsinReview$mpn_product_id>=((i*500)-499)&MultiAsinReview$mpn_product_id<=(i*500),], 
               paste0("P:/Drop Ship/New Product Additions/1.1 - Multi Asin Selection/", FileBaseName, "_Multi-ASIN_Select",
               "_" ,hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0), "_Section-", i, ".xlsx"))
  }
}
if(max(MultiAsinReview$mpn_product_id)<500){
  write.xlsx(MultiAsinReview[MultiAsinReview$mpn_product_id>=((1*500)-499)&MultiAsinReview$mpn_product_id<=(1*500),], 
             paste0("P:/Drop Ship/New Product Additions/1.1 - Multi Asin Selection/", FileBaseName, "_Multi-ASIN_Select",
                    "_" ,hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0), "_Section-", 1, ".xlsx"))
}

#Write MPN Files
if(max(MpnReview$mpn_product_id)>=500){
  for(i in 1:ceiling(max(MpnReview$mpn_product_id)/500)){
    write.xlsx(MpnReview[MpnReview$mpn_product_id>=((i*500)-499)&MpnReview$mpn_product_id<=(i*500),], 
               paste0("P:/Drop Ship/New Product Additions/1.2 - Title to Description Verification/", FileBaseName, "_MPN_Select",
                      "_" ,hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0), "_Section-", i, ".xlsx"))
  }
}
if(max(MpnReview$mpn_product_id)<500){
  write.xlsx(MpnReview[MpnReview$mpn_product_id>=((1*500)-499)&MpnReview$mpn_product_id<=(1*500),], 
             paste0("P:/Drop Ship/New Product Additions/1.2 - Title to Description Verification/", FileBaseName, "_MPN_Select",
                    "_" ,hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0), "_Section-", 1, ".xlsx"))
}

#write.xlsx(MultiAsinReview, paste0("P:/Drop Ship/New Product Additions/1.1 - Multi Asin Selection/", FileBaseName, "_Multi-ASIN_Select.xlsx"))

#write.xlsx(MpnReview, paste0("P:/Drop Ship/New Product Additions/1.2 - Title to Description Verification/", FileBaseName, "_MPN_Select.xlsx"))

AsinDataManualReview<-ApprovedASINs

#Compliance Scrape for Approved MPN/ASIN Matches
FlagTerms<-read.xlsx("P:/Compliance/Scraper/Terms.xlsx")
PackTerms<-read.xlsx("P:/Operations/Drop Ship/Drop Ship Docs/Pack Sizing Terms.xlsx")
if(VendorName=="McKesson"){FlagTerms<-read.xlsx("P:/Compliance/Scraper/McKesson Terms.xlsx")}

#Get Data From Lead Gen
Asins<-gsub('"', "'", shpaste(as.vector(AsinData$asin)))

AsinDataLeadGen<-conn_qk(paste0("Select p.gtin, p.asin, pd.title, pd.features, pd.afn_lowest_price, pd.mfn_lowest_price from etailz_lead_generation.products p
                                Left Join etailz_lead_generation.product_details pd on pd.product_id = p.id
                                Where p.asin in (", Asins, ")
                                and p.marketplace_id = 1"), "dw01_etailz", "df")

#AsinDataManualReview<-merge(AsinData, AsinDataLeadGen, by = 'asin')

AsinData<-merge(AsinDataManualReview, AsinDataLeadGen[AsinDataLeadGen$features!=""&!is.na(AsinDataLeadGen$features),], by = 'asin')

FeatureHolding<-merge(AsinDataManualReview, AsinDataLeadGen[AsinDataLeadGen$features==""|is.na(AsinDataLeadGen$features),], by = 'asin')

FeatureHolding<-FeatureHolding[colnames(FeatureHolding) %in% c("hyperlink", "asin", "upc", "partner_product_number", "mpn_batch", 
                                                               "product_title", "amazon_title", "rank", "mpn_product_id")]

write.xlsx(FeatureHolding, paste0("P:/Drop Ship/New Product Additions/3 - Manual Compliance Review/Waiting for Features/", FileBaseName, 
                                   "_ASINs_to_Add_LG_", hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0),".xlsx"))

ProductsNotinLG<-anti_join(AsinDataManualReview, AsinDataManualReview, by = "asin")

ProductsNotinLG<-ProductsNotinLG[colnames(ProductsNotinLG) %in% c("hyperlink", "asin", "upc", "partner_product_number", "mpn_batch", 
                                                                  "product_title", "amazon_title", "rank", "mpn_product_id")]

write.xlsx(ProductsNotinLG, paste0("P:/Drop Ship/New Product Additions/2 - ASINS to Scrape/ASINs for LG/", FileBaseName, "_ASINs_to_Add_LG_",
                                   hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0),".xlsx"))

FlagTerms[,1]<-as.character(FlagTerms[,1])


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

AsinData$ComplianceCleared[is.na(AsinData$ComplianceCleared)]<-"Denied"
ProductsDenied<-AsinData[AsinData$ComplianceCleared=="Denied",]
ProductsApproved<-AsinData[AsinData$ComplianceCleared=="Cleared",]
ProductsApproved<-format(ProductsApproved, scientific = F)
ProductsDenied<-format(ProductsDenied, scientific = F)

#Write to files
write.xlsx(ProductsDenied, paste0("P:/Drop Ship/New Product Additions/3 - Manual Compliance Review/", FileBaseName, "_Manual_Compliance_Review_", 
                                  hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0),".xlsx"))
write.xlsx(ProductsApproved, paste0("P:/Drop Ship/New Product Additions/4- Approved Products Amazon/", FileBaseName, "_Auto_Approved_Products_", 
                                    hour(Sys.time()), "-", minute(Sys.time()), "-", round(second(Sys.time()),0),".xlsx"))
