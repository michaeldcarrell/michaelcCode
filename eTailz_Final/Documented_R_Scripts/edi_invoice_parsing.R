library(plyr)
library(stringr)

files<-list.files("C:/Users/michaelc/Documents/McKesson Invoices", full.names = T)

findElements<-function(file, search_key){
  elements<-strsplit(
    as.vector(gsub(paste0("~", search_key,"\\*|~|^\\*|\\*$|^~|~$"), "" , str_match_all(file, paste0("~", search_key,"(.*?)~"))[[1]][,1])), "\\*"
  )
  frame<-data.frame()
  rows<-length(elements)
  columns<-max(mapply(length, elements))
  for(c in 1:columns){
    for(r in 1:rows){
      frame[r, c]<-elements[[r]][c]
    }
  }
  colnames(frame)<-seq.int(1, ncol(frame), 1)
  return(frame)
}

Invoice<-data.frame()

for(i in 1:length(files)){
  file<-readChar(files[i], file.info(files[i])$size)
  file<-gsub("ISA\\*00\\*          \\*00\\*          \\*ZZ\\*MCKEAST        \\*ZZ\\*ETAILZ         ", "", file)
  
  big<-findElements(file, "BIG")
  n1<-findElements(file, "N1")
  n3<-findElements(file, "N3")
  n4<-findElements(file, "N4")
  dtm<-findElements(file, "DTM")
  it1<-findElements(file, "IT1")
  #tx1<-findElements(file, "TXI")
  pid<-findElements(file, "PID")
  
  LineItem<-data.frame(po=big[,4],
                       ship_to_name=n1[n1$`1`=="ST",2],
                       ship_to_address=n3[seq.int(1, nrow(n3), 2), 1],
                       ship_to_city=n4[seq.int(1, nrow(n3), 2), 1],
                       ship_to_state=n4[seq.int(1, nrow(n3), 2), 2],
                       zip_plus_4=n4[seq.int(1, nrow(n3), 2), 3],
                       date_ordered=dtm[,2],
                       qty=it1[,2],
                       unit_price=it1[,4],
                       description=pid[,5])
  
  Invoice<-rbind.fill(Invoice, LineItem)
}
