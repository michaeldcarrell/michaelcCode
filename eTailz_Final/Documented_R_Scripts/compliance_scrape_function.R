ComplianceScraper<-function(asins, termsource = "DS", vendor = "", email = F, export = T, test = T){
  if(require(crayon)){
    library(crayon)
  } else {
    cat("Installing crayon")
    install.packages("crayon")
    if(require(crayon)){
      library(crayon)
    } else {
      stop("Could not install crayon. Install package and re-run")
    }
  }
  
  if(require(openxlsx)){
    library(openxlsx)
  } else {
    cat(cyan("Installing openxlsx"))
    install.packages("openxlsx")
    if(require(openxlsx)){
      library(openxlsx)
    } else {
      stop("Could not install openxlsx. Install package and re-run")
    }
  }
  
  if(require(progress)){
    library(progress)
  } else {
    cat(cyan("Installing progress"))
    install.packages("progress")
    if(require(progress)){
      library(progress)
    } else {
      stop("Could not install progress. Install package and re-run")
    }
  }
  
  if(require(rJava)){
    library(rJava)
  } else {
    cat(cyan("Installing rJava"))
    install.packages("rJava")
    if(require(rJava)){
      library(rJava)
    } else {
      stop("Could not install rJava. Install package and re-run")
    }
  }
  
  if(require(mailR)){
    library(mailR)
  } else {
    cat(cyan("Installing mailR"))
    install.packages("mailR")
    if(require(mailR)){
      library(mailR)
    } else {
      stop("Could not install mailR. Install package and re-run")
    }
  }
  
  if(termsource == "3PM"){
    termFile<-"P:/Compliance/Scraper/3P Terms.xlsx"
  } else if(termsource == "DS"){
    termFile<-"P:/Compliance/Scraper/Terms.xlsx"
  } else if(termsource == "MK"){
    termFile<-"P:/Compliance/Scraper/McKesson Terms.xlsx"
  } else {
    stop('Select source of terms file either "3PM" or "DS"')
  }
  
  if(class(asins)!="character"){
    stop('asin must be a character vector produced by conn.qk package shpaste function')
  } else if(!exists("asins")){
    stop('Must provide character vector produced by conn.qk package shpaste function')
  }
  
  Terms<-openxlsx::read.xlsx(termFile)
  
  cat(cyan("Running ASIN Finder Query"))
  
  source("P:/Employees/MichaelC/R/Asin_Finder MySQL Connect.R")
  
  AsinFinderData<-fetch(dbSendQuery(asin_finder, paste0("SELECT a.asin, a.product_description, a.title
                                                        FROM asins a
                                                        WHERE a.asin IN (", asins, ")")), n=-1)
  dbDisconnect(asin_finder)
  
  cat(cyan("\nRunning Lead Gen Query\n"))
  
  source("P:/Employees/MichaelC/R/LG MySQL Connect.R")
  
  LgData<-fetch(dbSendQuery(lead_gen, paste0("SELECT p.asin, pd.features
                                             FROM products p 
                                             JOIN product_details pd ON pd.product_id = p.id
                                             WHERE p.marketplace_id = 1
                                             AND p.asin IN (", asins, ")")), n=-1)
  dbDisconnect(lead_gen)
  
  AsinData<-merge(AsinFinderData, LgData, by = "asin")
  AsinData$product_description<-gsub("<.*?>", " ", AsinData$product_description)
  AsinData$features<-gsub("<.*?>", " ", AsinData$features)
  
  AsinData$Title_Flag<-""
  AsinData$Description_Flag<-""
  AsinData$Features_Flag<-""
  
  pb<-progress_bar$new(total = nrow(Terms), format = "Running: :what [:bar] :percent ETA: :eta Time Passed: :elapsedfull", clear = FALSE, width = 150)
  
  for(i in 1:nrow(Terms)){
    if(length(AsinData$title[grepl(paste0("\\Q", Terms[i, 1], "\\E"), AsinData$title, ignore.case = T)==T])!=0){
      AsinData$Title_Flag[grepl(paste0("\\Q", Terms[i, 1], "\\E"),
                            AsinData$title,
                            ignore.case = T)==T]<-paste(AsinData$Title_Flag[grepl(paste0("\\Q", Terms[i, 1], "\\E"), AsinData$title, ignore.case = T)==T],
                                                                                     Terms[i,1], sep = ", ")
    }
    if(length(AsinData$product_description[grepl(paste0("\\Q", Terms[i, 1], "\\E"), AsinData$product_description, ignore.case = T)==T])!=0){
      AsinData$Description_Flag[grepl(paste0("\\Q", Terms[i, 1], "\\E"),
                                  AsinData$product_description,
                                  ignore.case = T)==T]<-paste(AsinData$Description_Flag[grepl(paste0("\\Q", Terms[i, 1], "\\E"),
                                                                                              AsinData$product_description, ignore.case = T)==T],
                                                                                                         Terms[i,1], sep = ", ")
    }
    if(length(AsinData$features[grepl(paste0("\\Q", Terms[i, 1], "\\E"), AsinData$features, ignore.case = T)==T])!=0){
      AsinData$Features_Flag[grepl(paste0("\\Q", Terms[i, 1], "\\E"),
                               AsinData$features,
                               ignore.case = T)==T]<-paste(AsinData$Features_Flag[grepl(paste0("\\Q", Terms[i, 1], "\\E"),
                                                                                        AsinData$features, ignore.case = T)==T],
                                                                                           Terms[i,1], sep = ", ")
    }
    pb$tick(tokens = list(what = "Compliance Substring Match"))
  }
  
  AsinData$Title_Flag[
    substr(AsinData$Title_Flag, 1, 2)==", "]<-substr(AsinData$Title_Flag[substr(AsinData$Title_Flag, 1, 2)==", "], 3,
                                                     nchar(AsinData$Title_Flag[substr(AsinData$Title_Flag, 1, 2)==", "]))
  AsinData$Description_Flag[
    substr(AsinData$Description_Flag, 1, 2)==", "]<-substr(AsinData$Description_Flag[substr(AsinData$Description_Flag, 1, 2)==", "], 3,
                                                           nchar(AsinData$Description_Flag[substr(AsinData$Description_Flag, 1, 2)==", "]))
  AsinData$Features_Flag[
    substr(AsinData$Features_Flag, 1, 2)==", "]<-substr(AsinData$Features_Flag[substr(AsinData$Features_Flag, 1, 2)==", "], 3,
                                                        nchar(AsinData$Features_Flag[substr(AsinData$Features_Flag, 1, 2)==", "]))
  
  ComplianceDenied<-AsinData[AsinData$Title_Flag!=""|AsinData$Description_Flag!=""|AsinData$Features_Flag!="",]
  DeniedFileName<-paste0("P:/Compliance/Scraper/Scraper Exports/Denied_Products-", termsource, "-", format(Sys.time(), "%m_%d_%Y"), ".xlsx")
  
  CurrentComplianceFiles<-list.files("P:/Compliance/Scraper/Scraper Exports", full.names = T)
  
  ComplianceDenied<-data.frame(status="",
                               url=paste0('www.amazon.com/dp/', ComplianceDenied$asin),
                               asin=ComplianceDenied$asin,
                               product_description=ComplianceDenied$product_description, 
                               title=ComplianceDenied$title,
                               features=ComplianceDenied$features,
                               Title_Flag=ComplianceDenied$Title_Flag,
                               Description_Flag=ComplianceDenied$Description_Flag,
                               Features_Flag=ComplianceDenied$Features_Flag)
  
  if(export){openxlsx::write.xlsx(ComplianceDenied, DeniedFileName)}
  
  if((email&!DeniedFileName %in% CurrentComplianceFiles)|test){
    Sys.setenv(JAVA_HOME='C:/Program Files/Java/jre1.8.0_161')
    if(test){
      to<-c("MichaelC@etailz.com")
      cc<-("")
    } else if(termsource == "3PM") {
      to<-c("RishiS@etailz.com", "AspenH@etailz.com")
      cc<-c("HaydenT@etailz.com", "EvanD@etailz.com")
    } else {
      to<-c("DustinF@etailz.com")
      cc<-c("HaydenT@etailz.com", "EvanD@etailz.com", "Jed@etailz.com")
    }
      
      send.mail(from = "MichaelC@etailz.com",
                to = to,
                bcc = "MichaelC@etailz.com",
                subject = "Compliance Scraper File",
                body = "Hello,
  
The attached file has been generate by the compliance scraper.

Thank you!", 
                authenticate = TRUE,
                smtp = list(host.name = "smtp.office365.com", port = 587,
                            user.name = "MichaelC@etailz.com", passwd = "ASDFtyu092018", tls = TRUE),
                attach.files = DeniedFileName)
  }
  
  AsinData<-AsinData[AsinData$Title_Flag==""|AsinData$Description_Flag==""|AsinData$Features_Flag=="",]

  return(AsinData)
}
#AsinData<-ComplianceScraper(asins = TaskASINs, termsource = "3PM", email = F, test = T, export = T)
