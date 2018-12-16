#CHAPTER 15: CLUSTERING  

#Example 1: European Protein Consumption
### *** European Protein Consumption, in grams/person-day *** ###
## read in the data
food <- read.csv(file.choose())
food[1:3,]
## first, clustering on just Red and White meat (p=2) and k=3 clusters
set.seed(1) ## to fix the random starting clusters
grpMeat <- kmeans(food[,c("WhiteMeat","RedMeat")], centers=3, nstart=10)
grpMeat
## list of cluster assignments
o=order(grpMeat$cluster)
data.frame(food$Country[o],grpMeat$cluster[o])
## plotting cluster assignments on Red and White meat scatter plot
plot(food$Red, food$White, type="n", xlim=c(3,19), xlab="Red Meat", ylab="White Meat")
text(x=food$Red, y=food$White, labels=food$Country, col=grpMeat$cluster+1)

## same analysis, but now with clustering on all protein groups
## change the number of clusters to 7
set.seed(1)
grpProtein <- kmeans(food[,-1], centers=7, nstart=10) 
o=order(grpProtein$cluster)
data.frame(food$Country[o],grpProtein$cluster[o])
plot(food$Red, food$White, type="n", xlim=c(3,19), xlab="Red Meat", ylab="White Meat")
text(x=food$Red, y=food$White, labels=food$Country, col=rainbow(7)[grpProtein$cluster])




#Example 2: Monthly US Unemployment Rates 

## read the data; series are stored column-wise with labels in first row
raw <- read.csv(file.choose())
raw[1:3,]

## time sequence plots of three series
plot(raw[,5],type="l",ylim=c(0,12),xlab="month",ylab="unemployment rate") ## CA
points(raw[,32],type="l", cex = .5, col = "dark red")    ## New York
points(raw[,15],type="l", cex = .5, col = "dark green")  ## Iowa

## transpose the data
## then we have 50 rows (states) and 416 columns (time periods)
rawt=matrix(nrow=50,ncol=416)
rawt=t(raw)
rawt[1:3,]

## k-means clustering in 416 dimensions 
set.seed(1)
grpunemp2 <- kmeans(rawt, centers=2, nstart=10)
sort(grpunemp2$cluster)
grpunemp3 <- kmeans(rawt, centers=3, nstart=10)
sort(grpunemp3$cluster)
grpunemp4 <- kmeans(rawt, centers=4, nstart=10)
sort(grpunemp4$cluster)
grpunemp5 <- kmeans(rawt, centers=5, nstart=10)
sort(grpunemp5$cluster)

## another analysis
## data set unemp.csv with means and standard deviations for each state
## k-means clustering on 2 dimensions (mean, stddev) 
unemp <- read.csv(file.choose())
unemp[1:3,]

set.seed(1)
grpunemp <- kmeans(unemp[,c("mean","stddev")], centers=3, nstart=10)
## list of cluster assignments
o=order(grpunemp$cluster)
data.frame(unemp$state[o],grpunemp$cluster[o])
plot(unemp$mean,unemp$stddev,type="n",xlab="mean", ylab="stddev")
text(x=unemp$mean,y=unemp$stddev,labels=unemp$state, col=grpunemp$cluster+1)




#Example 3: European Protein Consumption Revisited (Mixture Model)

library(mixtools)

## for a brief description of mvnormalmixEM
## mvnormalmixEM(x, lambda = NULL, mu = NULL, sigma = NULL, k = 2,
##              arbmean = TRUE, arbvar = TRUE, epsilon = 1e-08, 
##              maxit = 10000, verb = FALSE)
## arbvar=FALSE			same cov matrices
## arbvar=TRUE (default)	different cov matrices
## arbmean=TRUE (default)	different means
## k	number of groups

food <- read.csv("C:/DataMining/Data/protein.csv")
## Consider just Red and White meat clusters
food[1:3,]
X=cbind(food[,2],food[,3])
X[1:3,]

set.seed(1) 
## here we use an iterative procedure and the results in repeated runs may 
## not be exactly the same
## set.seed(1) is used to obtain reproducible results

## mixtures of two normal distributions on the first 2 features
## we consider different variances
out2<-mvnormalmixEM(X,arbvar=TRUE,k=2,epsilon=1e-02)
out2
prob1=round(out2$posterior[,1],digits=3)
prob2=round(out2$posterior[,2],digits=3)
prob=round(out2$posterior[,1])
o=order(prob)
data.frame(food$Country[o],prob1[o],prob2[o],prob[o])
plot(food$Red, food$White, type="n",xlab="Red Meat", ylab="White Meat")
text(x=food$Red,y=food$White,labels=food$Country,col=prob+1)

## mixtures of two normal distributions on all 9 features
## we consider equal variances
X1=cbind(food[,2],food[,3],food[,4],food[,5],food[,6],food[,7], food[,8],food[,9],food[,10])
X1[1:3,]
set.seed(1)
out2all<-mvnormalmixEM(X1,arbvar=FALSE,k=2,epsilon=1e-02)
out2all
prob1=round(out2all$posterior[,1],digits=3)
prob2=round(out2all$posterior[,2],digits=3)
prob=round(out2all$posterior[,1])
data.frame(food$Country,prob1,prob2,prob)
o=order(prob)
data.frame(food$Country[o],prob[o])



#R program to create Figure 15.1

library(cluster)
dis=matrix(nrow=5,ncol=5)
dis[1,1]=0
dis[2,2]=0
dis[3,3]=0
dis[4,4]=0
dis[5,5]=0
dis[2,1]=9 
dis[3,1]=3
dis[4,1]=6
dis[5,1]=11
dis[3,2]=7
dis[4,2]=5
dis[5,2]=10
dis[4,3]=9 
dis[5,3]=2
dis[5,4]=8
dis[1,2]=dis[2,1]
dis[1,3]=dis[3,1]
dis[1,4]=dis[4,1]
dis[1,5]=dis[5,1]
dis[2,3]=dis[3,2]
dis[2,4]=dis[4,2]
dis[2,5]=dis[5,2]
dis[3,4]=dis[4,3] 
dis[3,5]=dis[5,3]
dis[4,5]=dis[5,4]
plot(agnes(x=dis,diss=TRUE,metric="eucledian",method="single"))
plot(agnes(x=dis,diss=TRUE,metric="eucledian",method="complete"))

## correction with dis[5,3]=9
dis=matrix(nrow=5,ncol=5)
dis[1,1]=0
dis[2,2]=0
dis[3,3]=0
dis[4,4]=0
dis[5,5]=0
dis[2,1]=9 
dis[3,1]=3
dis[4,1]=6
dis[5,1]=11
dis[3,2]=7
dis[4,2]=5
dis[5,2]=10
dis[4,3]=9 
dis[5,3]=9	## corrected
dis[5,4]=8
dis[1,2]=dis[2,1]
dis[1,3]=dis[3,1]
dis[1,4]=dis[4,1]
dis[1,5]=dis[5,1]
dis[2,3]=dis[3,2]
dis[2,4]=dis[4,2]
dis[2,5]=dis[5,2]
dis[3,4]=dis[4,3] 
dis[3,5]=dis[5,3]
dis[4,5]=dis[5,4]
plot(agnes(x=dis,diss=TRUE,metric="eucledian",method="single"))
plot(agnes(x=dis,diss=TRUE,metric="eucledian",method="complete"))



#Example 4: European Protein Consumption Revisited (Agglomerative Clustering)

library(cluster)
## Protein Data
food <- read.csv("C:/DataMining/Data/protein.csv")
food[1:3,]
## we use the program agnes in the package cluster 
## argument diss=FALSE indicates that we use the dissimilarity 
## matrix that is being calculated from raw data. 
## argument metric="euclidian" indicates that we use Euclidian distance
## no standardization is used as the default
## the default is "average" linkage 

## first we consider just Red and White meat clusters
food2=food[,c("WhiteMeat","RedMeat")]
food2agg=agnes(food2,diss=FALSE,metric="euclidian")
food2agg
plot(food2agg)	## dendrogram
food2agg$merge	## describes the sequential merge steps
## identical result obtained by first computing the distance matrix
food2aggv=agnes(daisy(food2),metric="euclidian")
plot(food2aggv)

## Using data on all nine variables (features)
## Euclidean distance and average linkage 
foodagg=agnes(food[,-1],diss=FALSE,metric="euclidian")
plot(foodagg)	## dendrogram
foodagg$merge	## describes the sequential merge steps
## Using data on all nine variables (features)
## Euclidean distance and single linkage
foodaggsin=agnes(food[,-1],diss=FALSE,metric="euclidian",method="single")	## corrected
plot(foodaggsin)	## dendrogram
foodaggsin$merge	## describes the sequential merge steps
## Euclidean distance and complete linkage
foodaggcomp=agnes(food[,-1],diss=FALSE,metric="euclidian",method="single")	## corrected
plot(foodaggcomp)	## dendrogram
foodaggcomp$merge	## describes the sequential merge steps
foodaggcomp=agnes(food[,-1],diss=FALSE,metric="euclidian")			## corrected
plot(foodaggcomp)	## dendrogram
foodaggcomp$merge	## describes the sequential merge steps


## try hclust. You need to calculate the distance matrix first.
food
food1=food[,-1]	## strips name
d=dist(food1, method="euclidean")  
fit=hclust(d=d, method="average")	## "single", "complete","average",  
fit
plot(fit, hang=-1)
groups=cutree(fit, k=5) # "k=" defines the number of clusters you are using
groups
table(groups)
rect.hclust(fit, k=5, border="red") # draw dendogram with red borders around the 5 clusters



#Example 4: Monthly US Unemployment Rates (Agglomerative Clustering)

library(cluster)
## US unemployment data 
library(cluster)
raw <- read.csv("C:/DataMining/Data/unempstates.csv")
raw[1:3,]
rawt=matrix(nrow=50,ncol=416)
rawt=t(raw)
rawt[1:3,]
## transpose so that we have 50 rows (states) and 416 columns 
## (time periods)
## Agglomerative clustering unemployment 50 states ###
## dissimilarity matrix calculated from the raw data. 
## Euclidian distance and default "average" linkage
outagg=agnes(rawt,diss=FALSE,metric="euclidian")
plot(outagg)	## dendrogram
outagg$merge	## describes the sequential merge steps
## we see about three clusters
## Cluster 1: AL, IL, OH, TN, KY, OR, WA, PA, IN, MO, WI, NC, NV, SC, 
##            AR, NM, ID, MT, TX, AZ, FL, GA, ME, NJ, NY, RI, CA
## Cluster 2: AK, LA, MS, WV, MI
## Cluster 3: CO, IA, MN, UT, KS, OK, WY, NE, SD, ND, CT, MA, DE, MD, 
##            VT, VA, NH, HI




#Example 5: Monthly US Unemployment Rates Revisited 

## agglomerative clustering on the correlation between the series
## 2 versions: levels and differences

library(cluster)
raw <- read.csv("C:/DataMining/Data/unempstates.csv")
raw[1:3,]

## Correlation on levels
corlevel=cor(data.frame(raw))
disslevel=1-corlevel
outcorlevel=agnes(disslevel,diss=TRUE,metric="euclidian",method="single")
plot(outcorlevel)	## dendrogram; single linkage
outcorlevel=agnes(disslevel,diss=TRUE,metric="euclidian",method="complete")
plot(outcorlevel)	## dendrogram; complete linkage
outcorlevel=agnes(disslevel,diss=TRUE,metric="euclidian")
plot(outcorlevel)	## dendrogram; average linkage

## Correlation on differences
X=matrix(nrow=415,ncol=50)
for (j in 1:50) {
  for (i in 1:415) {
    X[i,j]=raw[i+1,j]-raw[i,j]
  }
}
colnames(X)=colnames(raw)
cordiff=cor(data.frame(X))
dissdiff=1-cordiff
outcordiff=agnes(dissdiff,diss=TRUE,metric="euclidian",method="single")
plot(outcordiff)	## dendrogram; single linkage
outcordiff=agnes(dissdiff,diss=TRUE,metric="euclidian",method="complete")
plot(outcordiff)	## dendrograml; complete linkage
outcordiff=agnes(dissdiff,diss=TRUE,metric="euclidian")
plot(outcordiff)	## dendrogram; average linkage
