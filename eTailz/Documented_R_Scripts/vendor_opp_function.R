vendorOpp<-function(){
  require(dplyr)
  require(DescTools)
  require(lars)
  require(lmtest)
  require(caret)
  require(glmnet)
  require(tidyverse)
  require(broom)
  require(crayon)
  options(scipen = 999)
  
  source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")
  source("P:/Employees/MichaelC/R/Asin_Finder MySQL Connect.R")
  source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")
  
  SqlFile<-"P:/Drop Ship/dropship_scripts/Documented_R_Scripts/PostgreSQL/UnityHistoricalMargin.sql"
  
  query<-readChar(SqlFile, file.info(SqlFile)$size)
  
  source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")
  
  cat(cyan("Running Unity Query\n"))
  
  UnityData<-fetch(dbSendQuery(unity, query), n=-1)
  
  UnityASINs<-fetch(dbSendQuery(unity, "SELECT p.id ProductId,
                                p.asin,
                                p.wholesale_price,
                                p.estimated_shipping_cost,
                                mp.price,
                                p.vendor_id,
                                p.created_at
                                FROM products p
                                JOIN marketplace_product mp on p.id = mp.product_id
                                WHERE mp.marketplace_id = 5
                                AND p.estimated_shipping_cost IS NOT NULL"), n=-1)
  
  UnityData<-merge(UnityData, UnityASINs, by = "ProductId", all.x = T)
  
  UnityAsins<-gsub("\"", "'", paste(shQuote(UnityData$asin[!duplicated(UnityData$asin)&!is.na(UnityData$asin)]), collapse=", "))
  
  cat(cyan("Running ASIN Finder Query\n"))
  
  AsinFinderData<-fetch(dbSendQuery(asin_finder, paste0("SELECT a.asin ASIN,
                                                        a.product_description Description,
                                                        a.merchant BBmercharnt,
                                                        a.number_of_offers,
                                                        a.large_image_url ListingUrl,
                                                        a.length/100 length,
                                                        a.width/100 width,
                                                        a.height/100 height,
                                                        a.weight/100 weight,
                                                        a.lowest_new_price/100 list_price,
                                                        a.product_group,
                                                        a.rank
                                                        FROM asins a
                                                        WHERE a.asin in (", UnityAsins, ")
                                                        AND a.merchant IS NOT NULL
                                                        AND a.number_of_offers IS NOT NULL
                                                        AND a.length IS NOT NULL
                                                        AND a.width IS NOT NULL
                                                        AND a.height IS NOT NULL
                                                        AND a.weight IS NOT NULL")), n=-1)
  
  cat(cyan("Running Opp Calc Query\n"))
  
  OppCalc<-fetch(dbSendQuery(redshift, paste0("SELECT faoc.asin, faoc.cat_1, faoc.created_at FROM etailz_dw.fact_asin_opp_calc faoc
                          WHERE faoc.asin IN (", UnityAsins,")")), n=-1)
  
  OppCalcOrdered<-OppCalc[rev(order(OppCalc$created_at)),]
  OppCalcUnique<-OppCalcOrdered[!duplicated(OppCalcOrdered$asin),]
  
  AsinFinderData$Sales<-Freq(UnityData$asin)$freq[match(AsinFinderData$ASIN, Freq(UnityData$asin)$level)]
  AsinFinderData$wholesale_cost<-UnityData$wholesale_price[match(AsinFinderData$ASIN, UnityData$asin)]
  AsinFinderData$wholesalePercent<-AsinFinderData$wholesale_cost/AsinFinderData$list_price
  AsinFinderData$est_ship<-UnityData$estimated_shipping_cost[match(AsinFinderData$ASIN, UnityData$asin)]
  AsinFinderData$DimWeight<-(AsinFinderData$height*AsinFinderData$width*AsinFinderData$length)/166
  AsinFinderData$WsPercOfBB<-(AsinFinderData$list_price - AsinFinderData$wholesale_cost)/AsinFinderData$list_price
  AsinFinderData$WsAbsDisToBB<-AsinFinderData$list_price - AsinFinderData$wholesale_cost
  AsinFinderData$eTailzPrice<-UnityData$price[match(AsinFinderData$ASIN, UnityData$asin)]
  AsinFinderData$EstPricePercFromBB<-(AsinFinderData$list_price - AsinFinderData$eTailzPrice)/AsinFinderData$list_price
  AsinFinderData$EstPriceDistFromBB<-AsinFinderData$eTailzPrice - AsinFinderData$list_price
  AsinFinderData$WsToBbRatio<-AsinFinderData$wholesale_cost/AsinFinderData$list_price
  AsinFinderData$oppcalc<-OppCalcUnique$cat_1[match(AsinFinderData$ASIN, OppCalcUnique$asin)]
  AsinFinderData$oppcalc[is.na(AsinFinderData$oppcalc)]<-"err"
  AsinFinderData$livetime<-Sys.time()-as.POSIXlt(UnityData$created_at[match(AsinFinderData$ASIN, UnityData$asin)])
  AsinFinderData$AbsBbPos<-ifelse(AsinFinderData$eTailzPrice>AsinFinderData$list_price, 1, 0)
  AsinFinderData$WsRelBb<-ifelse(AsinFinderData$wholesale_cost>AsinFinderData$list_price, 1, 0)
  AsinFinderData$estShipPercLp<-AsinFinderData$est_ship/AsinFinderData$eTailzPrice
  
  ModelFrame<-AsinFinderData[complete.cases(AsinFinderData),]
  
  cat(cyan("Regressing Model Query\n"))
  
  ProductModel<-lm(Sales~rank+number_of_offers+estShipPercLp+oppcalc+livetime+AbsBbPos+WsRelBb, data = ModelFrame)
  return(ModelFrame)
}

dataCollection<-function(asins){
  require(conn.qk)
  source("P:/Employees/MichaelC/R/Unity MySQL Connect.R")
  source("P:/Employees/MichaelC/R/Asin_Finder MySQL Connect.R")
  source("P:/Employees/MichaelC/R/Redshift PostgreSQL Connect.R")
  
  asins<-gsub("\"", "'", paste(shQuote(asins), collapse=", "))
  
  cat(cyan("Running ASIN Finder Query\n"))
  
  AsinFinderData<-fetch(dbSendQuery(asin_finder, paste0("SELECT a.asin ASIN,
                                                    a.number_of_offers,
                                                    a.lowest_new_price/100 list_price,
                                                    a.rank
                                                  FROM asins a
                                                  WHERE a.asin in (", asins, ")
                                                  AND a.number_of_offers IS NOT NULL
                                                  AND a.rank IS NOT NULL")), n=-1)
  
  cat(cyan("Running Opp Calc Query\n"))
  
  OppCalc<-fetch(dbSendQuery(redshift, paste0("SELECT faoc.asin, faoc.cat_1, faoc.created_at FROM etailz_dw.fact_asin_opp_calc faoc
                          WHERE faoc.asin IN (", asins,")")), n=-1)
  
  OppCalcOrdered<-OppCalc[rev(order(OppCalc$created_at)),]
  OppCalcUnique<-OppCalcOrdered[!duplicated(OppCalcOrdered$asin),]
  AsinFinderData$oppcalc<-OppCalcUnique$cat_1[match(AsinFinderData$ASIN, OppCalcUnique$asin)]
  
  cat(cyan("Constructing Data Frame\n"))
  
  ModelFrame<-AsinFinderData[complete.cases(AsinFinderData),]
  return(ModelFrame)
}