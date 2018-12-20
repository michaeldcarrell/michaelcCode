source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")

UnityHistoricalMarginSql<-"P:/Drop Ship/dropship_scripts/PostgreSQL/UnityHistoricalMargin.sql"

query<-readChar(UnityHistoricalMarginSql, file.info(UnityHistoricalMarginSql)$size)

UnityHistoricalMargin<-fetch(dbSendQuery(redshift, query),n=-1)
