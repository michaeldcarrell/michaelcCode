library(lubridate)

source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")

MinDate<-fetch(dbSendQuery(unity, "SELECT MIN(so.created_at)
                           FROM sales_orders so
                           JOIN sales_order_items item on so.id = item.sales_order_id
                           JOIN products p on item.product_id = p.id
                           WHERE p.vendor_id = 4"))

QueryMonth<-month(as.Date(MinDate[1,1])) - 1
QueryYear<-year(as.Date(MinDate[1,1]))

MaxDate<-fetch(dbSendQuery(unity, "SELECT MAX(so.created_at)
                           FROM sales_orders so
                           JOIN sales_order_items item on so.id = item.sales_order_id
                           JOIN products p on item.product_id = p.id
                           WHERE p.vendor_id = 4"))

MaxDateMonth<-month(as.Date(MaxDate[1,1])) - 1
MaxDateYear<-year(as.Date(MaxDate[1,1]))

DataFrame<-data.frame(revenue=as.numeric(), orders=as.numeric(), items=as.numeric())

colnumb<-0

repeat{
  
  QueryMonth<-QueryMonth + 1
  if(QueryMonth>12){
    QueryMonth<-1
    QueryYear<-QueryYear + 1
  }
  
  if(QueryMonth>MaxDateMonth+1&QueryYear==MaxDateYear){break}
  
  colnumb<-colnumb + 1
  
  if(nchar(QueryMonth)<2){
    QueryMinDate<-paste0(QueryYear, '-0', QueryMonth)
  } else {
    QueryMinDate<-paste0(QueryYear, '-', QueryMonth)
  }
  
  if(QueryMonth>11){
    MaxQueryMonth<-1
  } else {
    MaxQueryMonth<-QueryMonth+1
  }
  
  if(QueryMonth!=12){
    if(nchar(MaxQueryMonth)<2){
      QueryMaxDate<-paste0(QueryYear, '-0', MaxQueryMonth)
    } else {
      QueryMaxDate<-paste0(QueryYear, '-', MaxQueryMonth)
    }
  } else {
    if(nchar(MaxQueryMonth)<2){
      QueryMaxDate<-paste0(QueryYear + 1, '-0', MaxQueryMonth)
    } else {
      QueryMaxDate<-paste0(QueryYear + 1, '-', MaxQueryMonth)
    }
  }
  
  sales<-fetch(dbSendQuery(unity, paste0("SELECT COUNT(DISTINCT(so.id)) Sales FROM products p
                                  JOIN sales_order_items item on p.id = item.product_id
                                  JOIN sales_orders so on item.sales_order_id = so.id
                                  WHERE p.vendor_id = 4
                                  AND so.created_at > '", QueryMinDate,"'
                                  AND so.created_at < '", QueryMaxDate,"'")), n=-1)
  
  units<-fetch(dbSendQuery(unity, paste0("SELECT COUNT(item.id) Sales FROM products p
                                  JOIN sales_order_items item on p.id = item.product_id
                                  JOIN sales_orders so on item.sales_order_id = so.id
                                  WHERE p.vendor_id = 4
                                  AND so.created_at > '", QueryMinDate,"'
                                  AND so.created_at < '", QueryMaxDate,"'")), n=-1)
  
  revenue<-fetch(dbSendQuery(unity, paste0("SELECT SUM(item.unit_price) Sales FROM products p
                                  JOIN sales_order_items item on p.id = item.product_id
                                  JOIN sales_orders so on item.sales_order_id = so.id
                                  WHERE p.vendor_id = 4
                                  AND so.created_at > '", QueryMinDate,"'
                                  AND so.created_at < '", QueryMaxDate,"'")), n=-1)
  
  TempFrame<-data.frame(revenue=as.numeric(revenue), orders=as.numeric(sales), units=as.numeric(units))
  
  DataFrame<-rbind(DataFrame, TempFrame)
  
  rownames(DataFrame)[colnumb]<-QueryMinDate
}

write.csv(DataFrame, "TWEC_DATA.csv", row.names = T)
