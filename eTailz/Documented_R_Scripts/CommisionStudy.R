library(RMySQL)
library(lubridate)
library(progress)
library(DescTools)

unity = dbConnect(MySQL(), user='analyst', password='Da7aD0nut5', dbname='unity', host='unity-production.c1gbobf11g3m.us-west-2.rds.amazonaws.com')

UnityHistoricalMargin<-fetch(dbSendQuery(unity, "Select so.id SalesOrderId, soi.id SalesOrderItemId, p.id ProductId, m.id MarketplaceId, 
v.name VendorName, soi.wholesale_cost*soi.quantity COGS, soi.unit_price*soi.quantity TotalPrice, 
if(asbi.AvgShippingPerItemByOrder=0, p.estimated_shipping_cost*soi.quantity, asbi.AvgShippingPerItemByOrder*soi.quantity) AvgShippingOnOrderTimeQty, 
soi.quantity, if(m.id = 5, af.commission_fee, m.commission_fee_percentage) CommissionPercent, 
m.transaction_fee, ((soi.unit_price * if(m.id = 5, af.commission_fee, m.commission_fee_percentage))+m.transaction_fee)*soi.quantity Commission, 
(soi.unit_price - (soi.wholesale_cost + if(asbi.AvgShippingPerItemByOrder=0, p.estimated_shipping_cost, asbi.AvgShippingPerItemByOrder) + (soi.unit_price * if(m.id = 5, af.commission_fee, m.commission_fee_percentage))+m.transaction_fee))*soi.quantity Margin,
(soi.unit_price - (soi.wholesale_cost + if(asbi.AvgShippingPerItemByOrder=0, p.estimated_shipping_cost, asbi.AvgShippingPerItemByOrder) + ((soi.unit_price * if(m.id = 5, af.commission_fee, m.commission_fee_percentage))+m.transaction_fee)))/soi.unit_price MarginPercent,
so.ca_created_at, concat(year(so.created_at),'-', month(so.created_at), '-', day(so.created_at)) DateBins, so.ca_shipping_status
From sales_order_items soi
Join sales_orders so on so.id = soi.sales_order_id
Join products p on p.id = soi.product_id
Join vendors v on v.id = p.vendor_id
Join marketplaces m on m.marketplace_name = so.ca_site_name
Left Join amazon_fees af on af.id = p.amazon_category
Join (Select so.id, Coalesce(so.shipping_cost/sum(soi.quantity),0) AvgShippingPerItemByOrder from sales_order_items soi
		Join sales_orders so on so.id = soi.sales_order_id
		Group By so.id
) asbi on asbi.id = so.id
Where so.ca_shipping_status in ('Shipped')"),n=-1)

Vendors<-fetch(dbSendQuery(unity, "Select * From vendors"),n=-1)
UnityHistoricalMargin$ca_created_at<-as.POSIXct(UnityHistoricalMargin$ca_created_at, format = '%Y-%m-%d %H:%M:%S', tz = "UTC")

DataExport<-data.frame(Vendor=Vendors$name, 
                       Live_Date="", 
                       NM_Amount_1=0, 
                       NM_Amount_2=0,
                       NM_Amount_3=0,
                       NM_Amount_4=0,
                       NM_Amount_5=0,
                       NM_Amount_6=0,
                       NM_Amount_7=0,
                       NM_Amount_8=0,
                       NM_Amount_9=0,
                       NM_Amount_10=0,
                       NM_Amount_11=0,
                       NM_Amount_12=0,
                       TopLine_1=0,
                       TopLine_2=0,
                       TopLine_3=0,
                       TopLine_4=0,
                       TopLine_5=0,
                       TopLine_6=0,
                       TopLine_7=0,
                       TopLine_8=0,
                       TopLine_9=0,
                       TopLine_10=0,
                       TopLine_11=0,
                       TopLine_12=0)
DataExport$Live_Date<-as.POSIXct(DataExport$Live_Date, format = '%Y-%m-%d', tz = "UTC")

#pb<-progress_bar$new(total = nrow(DataExport), format = "[:bar] :percent Estimated Completion Time: :eta", clear = FALSE, width = 150) #For use in R Studio

for(i in 1:nrow(DataExport)){
  #Get Live Date
  DataExport$Live_Date[i]<-as.POSIXct(as.character(fetch(dbSendQuery(unity, paste0("SELECT MIN(p.created_at)
                                                           FROM products p
                                                           JOIN vendors v on p.vendor_id = v.id
                                                           WHERE v.name = '", DataExport$Vendor[i], "'")))), format = '%Y-%m-%d', tz = "UTC")
  if(!is.na(DataExport$Live_Date[i])){
    #Get NM Amounts by Months since creation
    for(x in 3:14){
      #Get Margin
      DataExport[i,x]<-sum(UnityHistoricalMargin[UnityHistoricalMargin$ca_created_at<=AddMonths(DataExport$Live_Date[i],(x-2))& #x-2 so it starts in the 3rd column but only adds one month
                                                 UnityHistoricalMargin$ca_created_at>=AddMonths(DataExport$Live_Date[i],(x-2-1))& #x-2-1 so the columns only grab one month of sales and it doesnt grab 2 months inadvance
                                                 UnityHistoricalMargin$VendorName==DataExport$Vendor[i]&
                                                 !is.na(UnityHistoricalMargin$Margin),]$Margin) 
      
      #Get Top Line Revenue
      DataExport[i,x+12]<-sum(UnityHistoricalMargin[UnityHistoricalMargin$ca_created_at<=AddMonths(DataExport$Live_Date[i],(x-2))&
                                                    UnityHistoricalMargin$ca_created_at>=AddMonths(DataExport$Live_Date[i],(x-2-1))&
                                                    UnityHistoricalMargin$VendorName==DataExport$Vendor[i]&
                                                    !is.na(UnityHistoricalMargin$TotalPrice),]$TotalPrice)
    }
  }
  #pb$tick() #For use in R Studio
}
