library(RMySQL)

source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")

UnityHistoricalMarginSql<-"C:/Users/michaelc/Documents/dropship_scripts/Documented_R_Scripts/UnityHistoricalMargin.sql"

query<-readChar(UnityHistoricalMarginSql, file.info(UnityHistoricalMarginSql)$size)

UnityHistoricalMargin<-fetch(dbSendQuery(unity, query),n=-1)
