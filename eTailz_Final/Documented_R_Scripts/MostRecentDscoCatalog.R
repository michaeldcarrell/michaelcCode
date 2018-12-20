library(RMySQL)

options(scipen = 999)

source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")

dscoCatalogs<-data.frame(files=list.files("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO"))
dscoCatalogs$fileDate<-gsub(".csv|.xlsx|.xls", "", 
                            substr(dscoCatalogs$files, 
                                   max(as.integer(gregexpr("_", dscoCatalogs$files)[[1]]))+1, nchar(as.character(dscoCatalogs$files))
                            )
)

NewestFile<-as.character(dscoCatalogs$files[dscoCatalogs$fileDate==max(dscoCatalogs$fileDate)])
MostRecentDscoCatalog<-read.csv(paste0("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO\\", NewestFile))

UnityProductsToDscoSkus<-fetch(dbSendQuery(unity, "SELECT p.ca_sku, CONCAT(v.supplier_id, '-', substring_index(p.ca_sku, '-', -1)) dscoSKU  FROM products p
                                           JOIN vendors v ON p.vendor_id = v.id
                                           WHERE v.supplier_id IS NOT NULL"), n=-1)

MostRecentDscoCatalog$CompositeSku<-paste(MostRecentDscoCatalog$dsco_supplier_id, MostRecentDscoCatalog$sku, sep = "-")

MostRecentDscoCatalog<-merge(MostRecentDscoCatalog, UnityProductsToDscoSkus, by.x = "CompositeSku", by.y = "dscoSKU", all.x = T)

MostRecentDscoCatalog$File_Updated_At<-file.mtime(paste0("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO\\", NewestFile))