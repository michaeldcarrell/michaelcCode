library(RODBC)

channel<-odbcDriverConnect("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=P:/Employees/MichaelC/dsco_catalog.accdb")

data<-sqlQuery(channel, "SELECT * FROM dsco_catalog")

dsco_catalog<-read.csv(file.choose())

sqlSave(channel = channel, dat = dsco_catalog, tablename = "dsco_catalog", rownames = "ID", verbose = T, fast = T, safer = F)
