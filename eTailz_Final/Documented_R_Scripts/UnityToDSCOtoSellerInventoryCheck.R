dscoInventory<-read.csv(file.choose())

source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")

UnityInventory<-fetch(dbSendQuery(unity, "SELECT p.id ProductId,
                                      CONCAT(v.supplier_id, '-', RIGHT(p.ca_sku, LENGTH(p.ca_sku) - LOCATE('-', p.ca_sku))) CompositeSku,
                                      p.ca_sku,
                                      SUM(i.quantity) quantity
                                  FROM products p
                                  JOIN product_inventory i on p.id = i.product_id
                                  JOIN vendors v on p.vendor_id = v.id
                                  GROUP BY p.ca_sku"), n=-1)

dscoInventoryLimit<-data.frame(CompositeSku=paste(dscoInventory$dsco_supplier_id, dscoInventory$sku, sep = '-'), DscoQuantity = dscoInventory$quantity_available)

UnityToDSCO<-merge(UnityInventory, dscoInventoryLimit, by = "CompositeSku", all.x = T)

SellerInventory<-read.table(file.choose(), sep = '\t', header = T)
SellerInventoryLimit<-data.frame(ca_sku = SellerInventory$ï..sku, ScQuantity = SellerInventory$quantity)

SellerToDSCO<-merge(UnityToDSCO, SellerInventoryLimit, by = 'ca_sku', all.x = T)

UnityNotInDSCO<-SellerToDSCO[!is.na(SellerToDSCO$quantity)&is.na(SellerToDSCO$DscoQuantity)&!is.na(SellerToDSCO$CompositeSku),]

ScNotInUnity<-SellerToDSCO[!is.na(SellerToDSCO$ScQuantity)&is.na(SellerToDSCO$quantity),]

ScNotEqualUnity<-SellerToDSCO[which(abs(SellerToDSCO$quantity - SellerToDSCO$ScQuantity) > 10 & SellerToDSCO$ScQuantity > SellerToDSCO$quantity),]

UnityNotEqualDSCO<-SellerToDSCO[which(abs(SellerToDSCO$quantity - SellerToDSCO$DscoQuantity) > 10 &
                                        SellerToDSCO$DscoQuantity < SellerToDSCO$quantity &
                                        !is.na(SellerToDSCO$DscoQuantity)),]

UnityNon0s<-SellerToDSCO[which(SellerToDSCO$quantity!=0 & SellerToDSCO$DscoQuantity==0),]

