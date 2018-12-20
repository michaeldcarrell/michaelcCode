source("P:/Employees/MichaelC/R/Neptune MySQL Connect.R")
source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")

UnityAmzProducts<-fetch(dbSendQuery(redshift, "Select p.ca_sku sku from etailz_unity.products p where p.asin is not null"), n=-1)

NeptuneAmzProducts<-fetch(dbSendQuery(neptune, "Select s.sku from skus s"), n=-1)

AmazonProducts<-rbind(UnityAmzProducts, NeptuneAmzProducts)