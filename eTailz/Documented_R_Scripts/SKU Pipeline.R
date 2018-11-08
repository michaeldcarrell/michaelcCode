options(java.parameters = "- Xmx1024m")
library(tictoc)
library(stringr)
library(xlsx)
library(data.table)
library(openxlsx)
library(DescTools)
library(plyr)
library(dplyr)

tic("Runtime")

fileNames<-list.files("P:/Biz Dev/Marketplace Expansion/ChannelAdvisor Exports", pattern = "*.xlsx", full.names = T)
fileNames<-fileNames[!(grepl("ebay", fileNames, ignore.case = T)|grepl("class", fileNames, ignore.case = T))]
#fileNames<-fileNames[!(fileNames %like% "eBay"|fileNames %like% "Classifications")]
SheetNames<-list.files("P:/Biz Dev/Marketplace Expansion/ChannelAdvisor Exports", pattern = "*.xlsx")
SheetNames<-SheetNames[!(grepl("ebay", SheetNames, ignore.case = T)|grepl("class", SheetNames, ignore.case = T))]
SheetNames<-gsub(" ", "", SheetNames)
SheetNames<-gsub(".xlsx", "", SheetNames)

CompiledListingStatus<-data.frame(ItemStatus=character(), ListingStatus=character(), ParentSKU=character(), SKU=character(), TemplatePrice=character(),
                                  ListingPrice=numeric(), PriceLeader=numeric(), PriceSource=character(), Title=character(), Messages=character(),
                                  LastSubmitted=character(), MessageTitles=character(), fileName=character())

for (i in 1:length(fileNames)) {
  CurrentFile<-fileNames[i]
  TempFrame<-read.xlsx(fileNames[i], sheet = 1)
  TempFrame$fileName<-SheetNames[i]
  if("Marketplace.Status" %in% names(TempFrame)){TempFrame$Marketplace.Status<-NULL}
  CompiledListingStatus<-rbind.fill(CompiledListingStatus, TempFrame)
}

for (i in 1:length(SheetNames)) {
  CompiledListingStatus[, SheetNames[i]]<-ifelse(CompiledListingStatus$fileName==SheetNames[i],1,0)
}

CompiledListingStatus$Item.Status<-as.character(CompiledListingStatus$Item.Status)
CompiledListingStatus$Listing.Status<-as.character(CompiledListingStatus$Listing.Status)

CompiledListingStatus<-CompiledListingStatus[(CompiledListingStatus$Item.Status=="Sent") | (CompiledListingStatus$Item.Status=="Not Sent") |
                                               (CompiledListingStatus$Item.Status=="Error"),]

eBayfileNames<-list.files("P:/Biz Dev/Marketplace Expansion/ChannelAdvisor Exports", pattern = "*.xlsx", full.names = T)
eBayfileNames<-eBayfileNames[grepl("ebay", eBayfileNames, ignore.case = T)]
eBaySheetNames<-list.files("P:/Biz Dev/Marketplace Expansion/ChannelAdvisor Exports", pattern = "*.xlsx")
eBaySheetNames<-eBaySheetNames[grepl("ebay", eBaySheetNames, ignore.case = T)]

eBayClosed<-read.xlsx(eBayfileNames[grepl("closed", eBayfileNames, ignore.case = T)], sheet = 1)
eBayOpen<-read.xlsx(eBayfileNames[grepl("open", eBayfileNames, ignore.case = T)], sheet = 1)
eBayErrors<-read.xlsx(eBayfileNames[grepl("error", eBayfileNames, ignore.case = T)], sheet = 1)

eBayOpenPipe<-data.frame(SKU=eBayOpen$SKU, Listed="Listed", ListingError=NA, Quantity=eBayOpen$Quantity, FileName="eBayOpen")
eBayErrorsPipe<-data.frame(SKU=eBayErrors$SKU, Listed=eBayErrors$eBay.Status, ListingError=eBayErrors$Errors, 
                           Quantity=eBayErrors$Quantity, FileName="eBayErrors")

CompiledListingStatusPipe<-data.frame(SKU=CompiledListingStatus$SKU, Listed=CompiledListingStatus$Listing.Status,
                                      ListingError=CompiledListingStatus$Messages, Quantity=CompiledListingStatus$Qty,
                                      FileName=CompiledListingStatus$fileName)


#eBayOpenPipe<-eBayOpenPipe[!(eBayOpenPipe$SKU %in% eBayErrorsPipe$SKU),]

FullCompiledListingStatus<-rbind.fill(CompiledListingStatusPipe, eBayOpenPipe)
FullCompiledListingStatus<-rbind(FullCompiledListingStatus, eBayErrorsPipe)

eBayOpenToPipeLine<-data.frame(Item.Status=NA, Listing.Status="Listed", Parent.SKU=eBayOpen$Parent.SKU, SKU=eBayOpen$SKU,
                               Template.Price=NA, Listing.Price=eBayOpen$Current.Price, Price.Leader=NA, Price.Source=NA, Title=eBayOpen$Title,
                               Messages="", Last.Submitted=NA, Message.Titles="", Qty=eBayOpen$Quantity, fileName="eBayAll",
                               JetAll=0, OverstockAll=0, PricefallsAll=0, SearsAll=0, ShopAll=0, WalmartAll=0, WishAll=0, eBayAll=1)

eBayErrorsToPipeLine<-data.frame(Item.Status=NA, Listing.Status=eBayErrors$eBay.Status, Parent.SKU=eBayErrors$Parent.SKU, SKU=eBayErrors$SKU,
                                 Template.Price=NA, Listing.Price=NA, Price.Leader=NA, Price.Source=NA, Title=eBayErrors$Title,
                                 Messages=eBayErrors$Errors, Last.Submitted=NA, Message.Titles=eBayErrors$Errors, Qty=eBayErrors$Quantity, 
                                 fileName="eBayAll", JetAll=0, OverstockAll=0, PricefallsAll=0, SearsAll=0, ShopAll=0, WalmartAll=0, 
                                 WishAll=0, eBayAll=1)
eBayErrorsToPipeLine<-eBayErrorsToPipeLine %>% distinct(SKU, .keep_all = T)

CompiledListingStatus$eBayAll<-0
Pipeline<-rbind(eBayErrorsToPipeLine[!eBayErrorsToPipeLine$SKU %in% eBayOpenToPipeLine$SKU,], eBayOpenToPipeLine)

#Pipeline<-Pipeline[!duplicated(Pipeline$SKU),]
#if(length(setdiff(colnames(Pipeline), colnames(CompiledListingStatus)))!=0){
#  StaticColumnDiffCount<-length(setdiff(colnames(Pipeline), colnames(CompiledListingStatus)))
#  for (i in 1:StaticColumnDiffCount) {
#    Pipeline<-Pipeline[, -grep(setdiff(colnames(Pipeline), colnames(CompiledListingStatus))[1], colnames(Pipeline))]
#  }
#}
#if(length(setdiff(colnames(CompiledListingStatus), colnames(Pipeline)))!=0){
#  StaticColumnDiffCount<-length(setdiff(colnames(CompiledListingStatus), colnames(Pipeline)))
#  for (i in 1:StaticColumnDiffCount) {
#    CompiledListingStatus<-CompiledListingStatus[, -grep(setdiff(colnames(CompiledListingStatus), colnames(Pipeline))[1], colnames(CompiledListingStatus))]
#  }
#}
Pipeline<-rbind.fill(CompiledListingStatus, Pipeline)

row.names(Pipeline)<-seq.int(nrow(Pipeline))

Pipeline$prefix<-NA

FBAPipe<-Pipeline[substr(Pipeline$SKU, 1, 3)=="FBA",]
NonFBAPipe<-Pipeline[substr(Pipeline$SKU, 1, 3)!="FBA",]

FBAPipe$prefix<-substr(gsub("FBA-", "", FBAPipe$SKU), 1, as.numeric(regexpr('-', gsub("FBA-", "", FBAPipe$SKU)))-1)
NonFBAPipe$prefix<-substr(NonFBAPipe$SKU, 1 , as.numeric(regexpr('-', NonFBAPipe$SKU))-1)

PipelineFinal<-rbind(FBAPipe, NonFBAPipe)

PipelineFinal$AmazonAll<-0

library(RMySQL)

source("P:/Employees/MichaelC/R/Neptune MySQL Connect.R")
source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")


#Get All AMZ skus (AmazonProducts)

UnityAmzProducts<-fetch(dbSendQuery(unity, "Select p.ca_sku sku, p.ca_title title, pit.Qty from products p
                                    Join (Select pi.product_id, sum(pi.quantity) Qty From product_inventory pi
                                    Group by pi.product_id) pit on pit.product_id = p.id
                                    where p.asin is not null"), n=-1)

NeptuneAmzProducts<-fetch(dbSendQuery(neptune, "Select s.sku, sd.title, si.sellable Qty from skus s
                                      Join sku_details sd on sd.sku_id = s.id
                                      Join sku_inventory si on si.sku_id = s.id"), n=-1)

AmazonProducts<-rbind(UnityAmzProducts, NeptuneAmzProducts)

PipelineFinal$AmazonAll<-0

AmazonAll<-data.frame(Item.Status=NA, Listing.Status="Listed", Parent.SKU=AmazonProducts$sku, SKU=AmazonProducts$sku,
                      Template.Price=NA, Listing.Price=NA, Price.Leader=NA, Price.Source=NA, Title=AmazonProducts$title,
                      Messages=NA, Last.Submitted=NA, Message.Titles=NA, Qty=AmazonProducts$Qty, 
                      fileName="AmazonAll", JetAll=0, OverstockAll=0, PricefallsAll=0, SearsAll=0, ShopAll=0, WalmartAll=0, 
                      WishAll=0, eBayAll=0, prefix=substr(AmazonProducts$sku, 1 , as.numeric(regexpr('-', AmazonProducts$sku))-1),
                      AmazonAll=1, stringsAsFactors = F)

AmazonAll$prefix[AmazonAll$prefix=="FBA"]<-substr(gsub("FBA-", "", AmazonAll$SKU[i]), 1, str_locate(gsub("FBA-", "", AmazonAll$SKU[i]), "-")-1)

#if(length(setdiff(colnames(AmazonAll), colnames(PipelineFinal)))!=0){
#  StaticColumnDiffCount<-length(setdiff(colnames(AmazonAll), colnames(PipelineFinal)))
#  for (i in 1:StaticColumnDiffCount) {
#    AmazonAll<-AmazonAll[, -grep(setdiff(colnames(AmazonAll), colnames(PipelineFinal))[1], colnames(AmazonAll))]
#  }
#}
#if(length(setdiff(colnames(PipelineFinal), colnames(AmazonAll)))!=0){
#  StaticColumnDiffCount<-length(setdiff(colnames(PipelineFinal), colnames(AmazonAll)))
#  for (i in 1:StaticColumnDiffCount) {
#    PipelineFinal<-PipelineFinal[, -grep(setdiff(colnames(PipelineFinal), colnames(AmazonAll))[1], colnames(PipelineFinal))]
#  }
#}


#AmazonAll$prefix[AmazonAll$prefix == "FBA"]<-substr(gsub("FBA-", "", AmazonAll$SKU), 1, str_locate(gsub("FBA-", "", AmazonAll$SKU), "-")-1)

PipelineFinal<-rbind.fill(PipelineFinal, AmazonAll)

#Matching Vendors
Vendors<-fetch(dbSendQuery(unity , "Select v.name, v.prefix, v.id UnityId from vendors v"),n=-1)
Partners<-fetch(dbSendQuery(neptune, "Select p.name, p.prefix, p.id NeptuneId from partners p"),n=-1)

Vendors$NeptuneId<-NA
Partners$UnityId<-NA

AllVendors<-rbind(Vendors, Partners)

AllVendors<-AllVendors[order(AllVendors$UnityId, AllVendors$NeptuneId),]
AllVendors<-AllVendors[!duplicated(AllVendors$prefix),]
AllVendors<-AllVendors[!is.na(AllVendors$name),]
AllVendors<-AllVendors[!is.na(AllVendors$prefix),]

PipelineFinalVendors<-merge(PipelineFinal, AllVendors, by = "prefix", all.x = T)

#Error Code Analysis
ErrorCodeClasses<-read.xlsx('P:/Biz Dev/Marketplace Expansion/ChannelAdvisor Exports/Error Classifications/Error Classifications.xlsx', sheet = 1)

PipelineFinalVendors$ErrorCodeClassFlag<-""
PipelineFinalVendors$ErrorCodeClass<-""
PipelineFinalVendors$ErrorCodeCorrectable<-""

for(i in 1:nrow(ErrorCodeClasses)){
  PipelineFinalVendors$ErrorCodeClassFlag<-grepl(ErrorCodeClasses[i,1], PipelineFinalVendors$Messages, ignore.case = T)
  PipelineFinalVendors$ErrorCodeClass[PipelineFinalVendors$ErrorCodeClassFlag==TRUE]<-ErrorCodeClasses[i,1]
  PipelineFinalVendors$ErrorCodeCorrectable[PipelineFinalVendors$ErrorCodeClassFlag==TRUE]<-ErrorCodeClasses[i,2]
}

PipelineFinalVendors$ErrorCodeCorrectable[PipelineFinalVendors$ErrorCodeCorrectable=="Yes"]<-1
PipelineFinalVendors$ErrorCodeCorrectable[PipelineFinalVendors$ErrorCodeCorrectable=="No"]<-0

PipelineFinalVendors$LastRefreshed<-file.mtime(fileNames[1])

toc()