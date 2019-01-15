library(odbc)
zoidberg<-dbConnect(odbc(), 'zoidberg-ro')
#data<-dbFetch(dbSendQuery(zoidberg, 'SELECT SalesID, OrderID FROM btdata.dbo.Sales'), n = -1) #example statement
