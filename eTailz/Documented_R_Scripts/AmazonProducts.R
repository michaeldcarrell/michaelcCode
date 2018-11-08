library(RMySQL)

neptune = dbConnect(MySQL(), user='analyst', password='Da7aD0nut5', dbname='neptune', host='172.16.144.30')
unity = dbConnect(MySQL(), user='analyst', password='Da7aD0nut5', dbname='unity', host='unity-production.c1gbobf11g3m.us-west-2.rds.amazonaws.com')

UnityAmzProducts<-fetch(dbSendQuery(unity, "Select p.ca_sku sku from products p where p.asin is not null"), n=-1)

NeptuneAmzProducts<-fetch(dbSendQuery(neptune, "Select s.sku from skus s"), n=-1)

AmazonProducts<-rbind(UnityAmzProducts, NeptuneAmzProducts)