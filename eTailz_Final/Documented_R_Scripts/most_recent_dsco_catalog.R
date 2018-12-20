most_recent_dsco_catalog<-function(){
  options(scipen = 999)
  source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")
  
  dscoCatalogs<-data.frame(files=list.files("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO"))
  dscoCatalogs$fileDate<-gsub(".csv|.xlsx|.xls", "", 
                              substr(dscoCatalogs$files, 
                                     max(as.integer(gregexpr("_", dscoCatalogs$files)[[1]]))+1, nchar(as.character(dscoCatalogs$files))
                              )
  )
  
  NewestFile<-as.character(dscoCatalogs$files[dscoCatalogs$fileDate==max(dscoCatalogs$fileDate)])
  MostRecentDscoCatalog<-read.csv(paste0("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO\\", NewestFile))
  
  UnityProductsToDscoSkus<-fetch(dbSendQuery(redshift, "SELECT p.ca_sku,
                                                               v.supplier_id||'-'||RIGHT(p.ca_sku, LENGTH(p.ca_sku)-POSITION('-' IN p.ca_sku)) dscosku
                                                       FROM etailz_unity.products p
                                                       JOIN etailz_unity.vendors v ON p.vendor_id = v.id
                                                       WHERE v.supplier_id IS NOT NULL"), n=-1)
  
  MostRecentDscoCatalog$CompositeSku<-paste(MostRecentDscoCatalog$dsco_supplier_id, MostRecentDscoCatalog$sku, sep = "-")
  
  MostRecentDscoCatalog<-merge(MostRecentDscoCatalog, UnityProductsToDscoSkus, by.x = "CompositeSku", by.y = "dscosku", all.x = T)
  
  MostRecentDscoCatalog$File_Updated_At<-file.mtime(paste0("P:\\Biz Dev\\Marketplace Expansion\\ChannelAdvisor Exports\\DSCO\\", NewestFile))
  
  return(MostRecentDscoCatalog)
}