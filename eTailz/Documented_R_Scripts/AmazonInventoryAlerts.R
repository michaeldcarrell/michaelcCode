source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")

UnityData<-fetch(dbSendQuery(redshift, "SELECT p.ca_sku, pa.quantity unity_quantity FROM etailz_unity.products p
                                      JOIN etailz_unity.product_aggregate pa ON pa.ca_sku = p.ca_sku"), n=-1)

UnitySkus<-gsub("\"", "'", paste(shQuote(UnityData$ca_sku), collapse=", "))

AmazonQty<-fetch(dbSendQuery(redshift, paste0("SELECT seller_sku, quantity amazon_quantity, created_at, updated_at FROM etailz_fetch.mws_data_merchant_listings_data
                                        WHERE fulfillment_channel = 'DEFAULT'
                                        AND seller_sku IN (", UnitySkus, ")
                                        AND marketplace_id = 1")), n=-1)

UnityData$AmazonInventory<-AmazonQty$amazon_quantity[match(UnityData$ca_sku, AmazonQty$seller_sku)]

InventoryProblems<-UnityData[which(UnityData$unity_quantity==0 & UnityData$AmazonInventory!=0),]
