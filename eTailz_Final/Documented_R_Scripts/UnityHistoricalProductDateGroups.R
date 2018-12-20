library(RMySQL)

unity = dbConnect(MySQL(), user='analyst', password='Da7aD0nut5', dbname='unity', host='unity-production.c1gbobf11g3m.us-west-2.rds.amazonaws.com')

UnityHistoricalProductDateGroups<-fetch(dbSendQuery(unity, "Select p.created_at, year(p.created_at) 'Year', month(p.created_at) 'Month', day(p.created_at) 'Day', 
                                                    hour(p.created_at) 'Hour', minute(p.created_at) 'Minute', second(p.created_at) 'Second'
                                                    From products p"), n=-1)

UnityHistoricalProductDateGroups$sumProductsByDate<-seq.int(nrow(UnityHistoricalProductDateGroups))

UnityHistoricalProductDateGroups<-UnityHistoricalProductDateGroups[!duplicated(UnityHistoricalProductDateGroups$created_at),]

UnityHistoricalProductDateGroups$YearMonthDay<-paste0(
  UnityHistoricalProductDateGroups$Year, "-", UnityHistoricalProductDateGroups$Month, "-", UnityHistoricalProductDateGroups$Day
)