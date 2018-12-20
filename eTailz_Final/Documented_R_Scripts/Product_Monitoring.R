library(dplyr)
library(mailR)

source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")

UnitySaleMonitoring<-"P:/Drop Ship/dropship_scripts/Documented_R_Scripts/unity_sale_monitoring.sql"

query<-readChar(UnitySaleMonitoring, file.info(UnitySaleMonitoring)$size)

UnitySaleMonitoring<-fetch(dbSendQuery(unity, query),n=-1)

Past_Processed<-read.csv("P:/Drop Ship/Monitoring/Unity_Sale_Monitoring_File.csv")

Entries_New<-anti_join(UnitySaleMonitoring, Past_Processed, by = 'SalesOrderId')

Problem_Sales<-Entries_New[(Entries_New$ca_is_blocked==1&Entries_New$MarketplaceId!=5)|
                             (Entries_New$amazon_blocked==1&Entries_New$MarketplaceId==5)|
                             Entries_New$InactiveVendor==1,]

Problem_Sales$URL<-paste0("unity.etailz.com/salesOrders/", Problem_Sales$SalesOrderId)

write.csv(Problem_Sales, "P:/Drop Ship/Monitoring/Sold_Products.csv", row.names = F)

Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_161')
to<-c("MichaelC@etailz.com")

send.mail(from = "MichaelC@etailz.com",
          to = to,
          bcc = "MichaelC@etailz.com",
          subject = "Compliance Scraper File",
          body = "Hello,
          
          The attached file has been generate by the product warnings script and contains sales which either the vendor is inactive or the product is blocked.
          
          Thank you!", 
          authenticate = TRUE,
          smtp = list(host.name = "smtp.office365.com", port = 587,
                      user.name = "MichaelC@etailz.com", passwd = "ASDFtyu092018", tls = TRUE),
          attach.files = "P:/Drop Ship/Monitoring/Sold_Products.csv")

write.table(Entries_New, "P:/Drop Ship/Monitoring/Unity_Sale_Monitoring_File.csv", sep = ",", col.names = T, append = T)
