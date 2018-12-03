#CHAPTER 12: MORE ON CLASSIFICATION AND A DISCUSSION OF DISCRIMINANT ANALYSIS  

#Example 1:  German Credit Data

#### ******* German Credit Data ******* ####
#### ******* data on 1000 loans ******* ####

library(MASS)	## includes lda and qda for discriminant analysis
set.seed(1)

## read data and create some 'interesting' variables
#credit <- read.csv("C:/DataMining/Data/germancredit.csv")
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

## take the continuous variables duration, amount, installment, age
## with indicators the assumptions of a normal distribution would be 
## tenuous at best; hence these variables are not considered here

cred1=credit[,c("Default","duration","amount","installment","age")]
cred1
summary(cred1) 

hist(cred1$duration)
hist(cred1$amount)
hist(cred1$installment)
hist(cred1$age)
cred1$Default
cred1=data.frame(cred1)

## linear discriminant analysis
## class proportions of the training set used as prior probabilities
zlin=lda(Default~.,cred1)
predict(zlin,newdata=data.frame(duration=6,amount=1100,installment=4,age=67))
predict(zlin,newdata=data.frame(duration=6,amount=1100,installment=4,age=67))$class
zqua=qda(Default~.,cred1)
predict(zqua,newdata=data.frame(duration=6,amount=1100,installment=4,age=67))
predict(zqua,newdata=data.frame(duration=6,amount=1100,installment=4,age=67))$class

n=1000
neval=1
errlin=dim(n)
errqua=dim(n)

## leave one out evaluation
for (k in 1:n) {
  train1=c(1:n)
  train=train1[train1!=k]
  ## linear discriminant analysis
  zlin=lda(Default~.,cred1[train,])
  predict(zlin,cred1[-train,])$class
  tablin=table(cred1$Default[-train],predict(zlin,cred1[-train,])$class)
  errlin[k]=(neval-sum(diag(tablin)))/neval
  ## quadratic discriminant analysis
  zqua=qda(Default~.,cred1[train,])
  predict(zqua,cred1[-train,])$class
  tablin=table(cred1$Default[-train],predict(zqua,cred1[-train,])$class)
  errqua[k]=(neval-sum(diag(tablin)))/neval
}
merrlin=mean(errlin)
merrlin
merrqua=mean(errqua)
merrqua




#Example 2:  Fisher Iris Data

library(MASS)	## includes lda and qda for discriminant analysis
set.seed(1)
iris3
Iris=data.frame(rbind(iris3[,,1],iris3[,,2],iris3[,,3]),Sp=rep(c("s","c","v"),rep(50,3)))
Iris
## linear discriminant analysis
## equal prior probabilities as same number from each species
zlin=lda(Sp~.,Iris,prior=c(1,1,1)/3)
predict(zlin,newdata=data.frame(Sepal.L.=5.1,Sepal.W.=3.5,Petal.L.=1.4, Petal.W.=0.2))
predict(zlin,newdata=data.frame(Sepal.L.=5.1,Sepal.W.=3.5,Petal.L.=1.4, Petal.W.=0.2))$class
## quadratic discriminant analysis
zqua=qda(Sp~.,Iris,prior=c(1,1,1)/3)
predict(zqua,newdata=data.frame(Sepal.L.=5.1,Sepal.W.=3.5,Petal.L.=1.4, Petal.W.=0.2))
predict(zqua,newdata=data.frame(Sepal.L.=5.1,Sepal.W.=3.5,Petal.L.=1.4, Petal.W.=0.2))$class

n=150
nt=100
neval=n-nt
rep=1000
errlin=dim(rep)
errqua=dim(rep)
for (k in 1:rep) {
  train=sample(1:n,nt)
  ## linear discriminant analysis
  m1=lda(Sp~.,Iris[train,],prior=c(1,1,1)/3)
  predict(m1,Iris[-train,])$class
  tablin=table(Iris$Sp[-train],predict(m1,Iris[-train,])$class)
  errlin[k]=(neval-sum(diag(tablin)))/neval
  ## quadratic discriminant analysis
  m2=qda(Sp~.,Iris[train,],prior=c(1,1,1)/3)
  predict(m2,Iris[-train,])$class
  tablin=table(Iris$Sp[-train],predict(m2,Iris[-train,])$class)
  errqua[k]=(neval-sum(diag(tablin)))/neval
}
merrlin=mean(errlin)
merrlin
merrqua=mean(errqua)
merrqua




#Example 3: Forensic Glass Data 

library(MASS)	## includes lda and qda for discriminant analysis
set.seed(1)
data(fgl)
glass=data.frame(fgl)
glass

## linear discriminant analysis
m1=lda(type~.,glass)
m1
predict(m1,newdata=data.frame(RI=3.0,Na=13,Mg=4,Al=1,Si=70,K=0.06,Ca=9,Ba=0,Fe=0))
predict(m1,newdata=data.frame(RI=3.0,Na=13,Mg=4,Al=1,Si=70,K=0.06,Ca=9,Ba=0,Fe=0))$class

## quadratic discriminant analysis: Not enough data as each 9x9
## covariance matrix includes (9)(8)/2 = 45 unknown coefficients

n=length(fgl$type)
nt=200
neval=n-nt

rep=100
errlin=dim(rep)

for (k in 1:rep) {
  train=sample(1:n,nt)
  glass[train,]
  ## linear discriminant analysis
  m1=lda(type~.,glass[train,])
  predict(m1,glass[-train,])$class
  tablin=table(glass$type[-train],predict(m1,glass[-train,])$class)
  errlin[k]=(neval-sum(diag(tablin)))/neval
}
merrlin=mean(errlin)
merrlin

n=214
neval=1
errlin=dim(n)
errqua=dim(n)

for (k in 1:n) {
  train1=c(1:n)
  train=train1[train1!=k]
  ## linear discriminant analysis
  m1=lda(type~.,glass[train,])
  predict(m1,glass[-train,])$class
  tablin=table(glass$type[-train],predict(m1,glass[-train,])$class)
  errlin[k]=(neval-sum(diag(tablin)))/neval
}
merrlin=mean(errlin)
merrlin




#Example 4: MBA Admission Data

library(MASS) 
set.seed(1)
## reading the data
admit <- read.csv(file.choose())
adm=data.frame(admit)
adm
plot(adm$GPA,adm$GMAT,col=adm$De)

## linear discriminant analysis
m1=lda(De~.,adm)
m1
predict(m1,newdata=data.frame(GPA=3.21,GMAT=497))

## quadratic discriminant analysis
m2=qda(De~.,adm)
m2
predict(m2,newdata=data.frame(GPA=3.21,GMAT=497))

n=85
nt=60
neval=n-nt

rep=100
errlin=dim(rep)

for (k in 1:rep) {
  train=sample(1:n,nt)
  ## linear discriminant analysis
  m1=lda(De~.,adm[train,])
  predict(m1,adm[-train,])$class
  
  tablin=table(adm$De[-train],predict(m1,adm[-train,])$class)
  errlin[k]=(neval-sum(diag(tablin)))/neval
}

merrlin=mean(errlin)
merrlin