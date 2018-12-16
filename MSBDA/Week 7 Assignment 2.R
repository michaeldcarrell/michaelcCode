#CHAPTER 16: MARKET BASKET ANALYSIS: ASSOCIATION RULES AND LIFT

#Example 1: Online Radio 

### *** Play counts *** ###

lastfm <- read.csv(file.choose())
lastfm[1:19,]
length(lastfm$user)   ## 289,955 records in the file
lastfm$user <- factor(lastfm$user)
levels(lastfm$user)   ## 15,000 users
levels(lastfm$artist) ##  1,004 artists

library(arules) ## a-rules package for association rules
## Computational environment for mining association rules and 
## frequent item sets 

## we need to manipulate the data a bit for arules
playlist <- split(x=lastfm[,"artist"],f=lastfm$user) ## split into a list of users
playlist <- lapply(playlist,unique)     ## remove artist duplicates
playlist[1:2]
## the first two listeners (1 and 3) listen to the following bands 

playlist <- as(playlist,"transactions") 
## view this as a list of "transactions"
## transactions is a data class defined in arules

itemFrequency(playlist) 
## lists the support of the 1,004 bands
## number of times band is listed to on the shopping trips of 15,000 users
## computes the rel freq each artist mentioned by the 15,000 users

itemFrequencyPlot(playlist,support=.08,cex.names=1.5) 
## plots the item frequencies (only bands with > % support)

## Finally, we build the association rules 
## only rules with support > 0.01 and confidence > .50
## so it can???t be a super rare band 

musicrules <- apriori(playlist,parameter=list(support=.01,confidence=.5)) 

inspect(musicrules)

## let's filter by lift > 5. 
## Among those associations with support > 0.01 and confidence > .50, 
## only show those with lift > 5

inspect(subset(musicrules, subset=lift > 5)) 

## lastly, order by confidence to make it easier to understand

inspect(sort(subset(musicrules, subset=lift > 5), by="confidence")) 




#Example 2: Predicting Income 

library(arules)
data(AdultUCI)
dim(AdultUCI)
AdultUCI[1:3,]

AdultUCI[["fnlwgt"]] <- NULL
AdultUCI[["education-num"]] <- NULL
AdultUCI[["age"]] <- ordered(cut(AdultUCI[["age"]], c(15, 25, 45, 65, 100)), labels = c("Young", "Middle-aged", "Senior", "Old"))
AdultUCI[["hours-per-week"]] <- ordered(cut(AdultUCI[["hours-per-week"]], c(0, 25, 40, 60, 168)), labels = c("Part-time", "Full-time", "Over-time", "Workaholic"))
AdultUCI[["capital-gain"]] <- ordered(cut(AdultUCI[["capital-gain"]], c(-Inf, 0, median(AdultUCI[["capital-gain"]][AdultUCI[["capital-gain"]] > 0]), Inf)), labels = c("None", "Low", "High"))
AdultUCI[["capital-loss"]] <- ordered(cut(AdultUCI[["capital-loss"]], c(-Inf, 0, median(AdultUCI[["capital-loss"]][AdultUCI[["capital-loss"]] > 0]), Inf)), labels = c("none", "low", "high"))

Adult <- as(AdultUCI[AdultUCI$age=="Young",], "transactions")
Adult
summary(Adult)

aa=as(Adult,"matrix") # transforms transaction matrix into incidence matrix
aa[1:2,]   # print the first two rows of the incidence matrix
itemFrequencyPlot(Adult[, itemFrequency(Adult) > 0.2], cex.names = 1)

rules <- apriori(Adult, parameter = list(support = 0.01, confidence = 0.6))
rules
summary(rules)
rulesIncomeSmall <- subset(rules, subset = rhs %in% "income=small" & lift > 1.2)
inspect(sort(rulesIncomeSmall, by = "confidence")[1])
rulesIncomeLarge <- subset(rules, subset = rhs %in% "income=large" & lift > 1.2)
inspect(sort(rulesIncomeLarge, by = "confidence")[1])
