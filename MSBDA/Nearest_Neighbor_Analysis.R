<<<<<<< HEAD
#### ******* Forensic Glass ****** ####

=======
>>>>>>> d5273530843eefa04b5e099017cbb2abe34c7523
library(textir) ## needed to standardize the data
library(MASS)   ## a library of example datasets

data(fgl) 		## loads the data into R; see help(fgl)
fgl
## data consists of 214 cases
## here are illustrative box plots of the features stratified by 
## glass type
par(mfrow=c(3,3), mai=c(.3,.6,.1,.1))
plot(RI ~ type, data=fgl, col=c(grey(.2),2:6))
plot(Al ~ type, data=fgl, col=c(grey(.2),2:6))
plot(Na ~ type, data=fgl, col=c(grey(.2),2:6))
plot(Mg ~ type, data=fgl, col=c(grey(.2),2:6))
plot(Ba ~ type, data=fgl, col=c(grey(.2),2:6))
plot(Si ~ type, data=fgl, col=c(grey(.2),2:6))
plot(K ~ type, data=fgl, col=c(grey(.2),2:6))
plot(Ca ~ type, data=fgl, col=c(grey(.2),2:6))
plot(Fe ~ type, data=fgl, col=c(grey(.2),2:6))

## for illustration, consider the RIxAl plane
## use nt=200 training cases to find the nearest neighbors for 
## the remaining 14 cases. These 14 cases become the evaluation 
## (test, hold-out) cases

n=length(fgl$type)
nt=200
set.seed(1) ## to make the calculations reproducible in repeated runs
train <- sample(1:n,nt)

## Standardization of the data is preferable, especially if 
## units of the features are quite different
## could do this from scratch by calculating the mean and 
## standard deviation of each feature, and use those to 
## standardize.
## Even simpler, use the normalize function in the R-package textir; 
## it converts data frame columns to mean-zero sd-one
<<<<<<< HEAD
library(BBmisc)
x <- normalize(fgl[,c(4,1)])
=======

## x <- normalize(fgl[,c(4,1)])
x=fgl[,c(4,1)]
x[,1]=(x[,1]-mean(x[,1]))/sd(x[,1])
x[,2]=(x[,2]-mean(x[,2]))/sd(x[,2])

>>>>>>> d5273530843eefa04b5e099017cbb2abe34c7523
x[1:3,]

library(class)  
nearest1 <- knn(train=x[train,],test=x[-train,],cl=fgl$type[train],k=1)
nearest5 <- knn(train=x[train,],test=x[-train,],cl=fgl$type[train],k=5)
data.frame(fgl$type[-train],nearest1,nearest5)

## plot them to see how it worked
par(mfrow=c(1,2))
## plot for k=1 (single) nearest neighbor
plot(x[train,],col=fgl$type[train],cex=.8,main="1-nearest neighbor")
points(x[-train,],bg=nearest1,pch=21,col=grey(.9),cex=1.25)
## plot for k=5 nearest neighbors
plot(x[train,],col=fgl$type[train],cex=.8,main="5-nearest neighbors")
points(x[-train,],bg=nearest5,pch=21,col=grey(.9),cex=1.25)
legend("topright",legend=levels(fgl$type),fill=1:6,bty="n",cex=.75)

## calculate the proportion of correct classifications on this one 
## training set

pcorrn1=100*sum(fgl$type[-train]==nearest1)/(n-nt)
pcorrn5=100*sum(fgl$type[-train]==nearest5)/(n-nt)
pcorrn1
pcorrn5

## cross-validation (leave one out)
pcorr=dim(10)
for (k in 1:10) {
  pred=knn.cv(x,fgl$type,k)
  pcorr[k]=100*sum(fgl$type==pred)/n
}
pcorr
## Note: Different runs may give you slightly different results as ties 
## are broken at random

## using all nine dimensions (RI plus 8 chemical concentrations)

<<<<<<< HEAD
x <- normalize(fgl[,c(1:9)])
=======
## x <- normalize(fgl[,c(1:9)])
x=fgl[,c(1:9)]
for (j in 1:9) {
  x[,j]=(x[,j]-mean(x[,j]))/sd(x[,j])
}

>>>>>>> d5273530843eefa04b5e099017cbb2abe34c7523
nearest1 <- knn(train=x[train,],test=x[-train,],cl=fgl$type[train],k=1)
nearest5 <- knn(train=x[train,],test=x[-train,],cl=fgl$type[train],k=5)
data.frame(fgl$type[-train],nearest1,nearest5)

## calculate the proportion of correct classifications

pcorrn1=100*sum(fgl$type[-train]==nearest1)/(n-nt)
pcorrn5=100*sum(fgl$type[-train]==nearest5)/(n-nt)
pcorrn1
pcorrn5

## cross-validation (leave one out)

pcorr=dim(10)
for (k in 1:10) {
  pred=knn.cv(x,fgl$type,k)
  pcorr[k]=100*sum(fgl$type==pred)/n
}
pcorr

<<<<<<< HEAD
=======
#### ******* German Credit Data ******* ####
#### ******* data on 1000 loans ******* ####

library(textir)	## needed to standardize the data
library(class)	## needed for knn

## read data and create some `interesting' variables
credit <- read.csv(file.choose())
credit

credit$Default <- factor(credit$Default)

## re-level the credit history and a few other variables
credit$history = factor(credit$history, levels=c("A30","A31","A32","A33","A34"))
levels(credit$history) = c("good","good","poor","poor","terrible")
credit$foreign <- factor(credit$foreign, levels=c("A201","A202"), labels=c("foreign","german"))
credit$rent <- factor(credit$housing=="A151")
credit$purpose <- factor(credit$purpose, levels=c("A40","A41","A42","A43","A44","A45","A46","A47","A48","A49","A410"))
levels(credit$purpose) <- c("newcar","usedcar",rep("goods/repair",4),"edu",NA,"edu","biz","biz")

## for demonstration, cut the dataset to these variables
credit <- credit[,c("Default","duration","amount","installment","age",                    "history", "purpose","foreign","rent")]
credit[1:3,]
summary(credit) # check out the data

## for illustration we consider just 3 loan characteristics:
## amount,duration,installment
## Standardization of the data is preferable, especially if 
## units of the features are quite different
## We use the normalize function in the R-package textir; 
## it converts data frame columns to mean-zero sd-one

## x <- normalize(credit[,c(2,3,4)])
x=credit[,c(2,3,4)]
x[,1]=(x[,1]-mean(x[,1]))/sd(x[,1])
x[,2]=(x[,2]-mean(x[,2]))/sd(x[,2])
x[,3]=(x[,3]-mean(x[,3]))/sd(x[,3])

x[1:3,]

## training and prediction datasets
## training set of 900 borrowers; want to classify 100 new ones
set.seed(1)
train <- sample(1:1000,900) ## this is training set of 900 borrowers
xtrain <- x[train,]
xnew <- x[-train,]
ytrain <- credit$Default[train]
ynew <- credit$Default[-train]

## k-nearest neighbor method
library(class)
nearest1 <- knn(train=xtrain, test=xnew, cl=ytrain, k=1)
nearest3 <- knn(train=xtrain, test=xnew, cl=ytrain, k=3)
data.frame(ynew,nearest1,nearest3)[1:10,]

## calculate the proportion of correct classifications
pcorrn1=100*sum(ynew==nearest1)/100
pcorrn3=100*sum(ynew==nearest3)/100
pcorrn1
pcorrn3

## plot for 3nn
plot(xtrain[,c("amount","duration")],col=c(4,3,6,2)[credit[train,"installment"]],pch=c(1,2)[as.numeric(ytrain)],main="Predicted default, by 3 nearest neighbors",cex.main=.95)
points(xnew[,c("amount","duration")],bg=c(4,3,6,2)[credit[train,"installment"]],pch=c(21,24)[as.numeric(nearest3)],cex=1.2,col=grey(.7))
legend("bottomright",pch=c(1,16,2,17),bg=c(1,1,1,1),legend=c("data 0","pred 0","data 1","pred 1"),title="default",bty="n",cex=.8)
legend("topleft",fill=c(4,3,6,2),legend=c(1,2,3,4),title="installment %",horiz=TRUE,bty="n",col=grey(.7),cex=.8)

## above was for just one training set
## cross-validation (leave one out)
pcorr=dim(10)
for (k in 1:10) {
  pred=knn.cv(x,cl=credit$Default,k)
  pcorr[k]=100*sum(credit$Default==pred)/1000
}
pcorr

credit$Default<-as.integer(credit$Default)
creditLM<-lm(Default~., data = credit)

summary(creditLM)

credit$pred<-round(predict.lm(creditLM,credit))

credit$correct<-credit$pred == credit$Default
percentCorrect<-nrow(credit[credit$correct==T,])/nrow(credit)
percentCorrect
>>>>>>> d5273530843eefa04b5e099017cbb2abe34c7523
