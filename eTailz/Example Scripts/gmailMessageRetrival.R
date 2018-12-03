gmailMessages<-messages(search = "Zillow")

gmailFrame<-data.frame(id=as.character(), thredId=as.character())
gmailFrame$id<-as.character()

i = 1

gmailMessages<-messages(search = "Zillow")

for(n in 1:length(gmailMessages[[1]]$messages)){
  if(n == 1){
    MessagesFrame<-data.frame(id=as.character(gmailMessages[[1]]$messages[[1]]$id), threadId=as.character(gmailMessages[[1]]$messages[[1]]$threadId))
  } else {
    gmailTempFrame<-data.frame(id=as.character(gmailMessages[[1]]$messages[[n]]$id), threadId=as.character(gmailMessages[[1]]$messages[[n]]$threadId))
    MessagesFrame<-rbind(MessagesFrame, gmailTempFrame)
  }
}


nextPageId<-gmailMessages[[1]]$nextPageToken

repeat{
  gmailMessages<-messages(search = "Zillow", page_token = nextPageId)
  for(n in 1:length(gmailMessages[[1]]$messages)){
    gmailTempFrame<-data.frame(id=as.character(gmailMessages[[1]]$messages[[n]]$id), threadId=as.character(gmailMessages[[1]]$messages[[n]]$threadId))
    MessagesFrame<-rbind(MessagesFrame, gmailTempFrame)
  }
  if(length(gmailMessages[[1]])<3){break}
  nextPageId<-gmailMessages[[1]]$nextPageToken
  i = i + 1
}