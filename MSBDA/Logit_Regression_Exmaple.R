library(dplyr)

dpen<-read.csv(file.choose())

m1<-glm(Death~VRace+Agg, family = binomial, data = dpen)

m1
summary(m1)

exp(m1$coef[2])
exp(m1$coef[3])
fitBlack<-dim(501)
fitWhite<-dim(501)
ag<-dim(501)
for(i in 1:501){
  ag[i]=(99+i)/100
  fitBlack[i]<-exp(m1$coef[1]+ag[i]*m1$coef[3])/
    (1+exp(m1$coef[1]+ag[i]*m1$coef[3]))
  fitWhite[i]<-exp(m1$coef[1]+m1$coef[2]+ag[i]*m1$coef[3])/
                     (1+exp(m1$coef[1]+m1$coef[2]+ag[i]*m1$coef[3]))
  
}
plot(fitBlack~ag, col='black', ylab='Prob [Death]',
     xlab='Aggravation', ylim=c(0,1),
     main='red line for white victim; black line for black victim')
points(fitWhite~ag, col='red')

delFile<-file.choose()
del<-read.csv(delFile)
del$sched<-factor(floor(del$schedtime/100))

del$delay<-ifelse(del$delay=="delayed",1,0)

del$dayweek[del$dayweek=="Monday"]<-1
del$dayweek[del$dayweek=="Tuesday"]<-2
del$dayweek[del$dayweek=="Wednesday"]<-3
del$dayweek[del$dayweek=="Thursday"]<-4
del$dayweek[del$dayweek=="Friday"]<-5
del$dayweek[del$dayweek=="Saturday"]<-6
del$dayweek[del$dayweek=="Sunday"]<-7

del<-del[,c(-1,-3,-5,-6,-7,-11,-12)]
n<-length(del$delay)

n1<-floor(n*(0.6))
n2=n-n1

train=sample(1:n,n1)

Xdel<-model.matrix(delay~.,data=del)[,-1]
xtrain<-Xdel[train,]

xnew<-Xdel[-train,]
ytrain<-del$delay[train]
ynew<-del$delay[-train]
m1<-glm(delay~., family = binomial, data = data.frame(delay=ytrain, xtrain))
summary(m1)

ptest<-predict(m1, newdata = data.frame(xnew), type="response")

plot(ynew~ptest)

gg1<-floor(ptest+0.5)
ttt<-table(ynew, gg1)

error<-(ttt[1,2]+ttt[2,1])/n2
error

bb<-cbind(ptest, ynew)
bb1<-bb[order(ptest, decreasing = T),]

xbar<-mean(ynew)

axis=dim(n2)
ax=dim(n2)
ay<-dim(n2)
ax[1]<-xbar
ay1<-bb1[1,2]
for(i in 2:n2){
  axis[i]<-i
  ax[i]<-xbar*i
  ay[i]=ay[i-1]+bb1[i,2]
}

aaa<-cbind(bb1[,1], bb1[,2],ay,ax)

plot(axis, ay, xlab="number of cases", ylab="number of successes",
     main="Lift: Cum successes sorted by pred val/success prob")
points(axis, ax)


creditFile<-file.choose()
credit<-read.csv(creditFile)

credit$Default<-factor(credit$Default)

credit$history<-factor(credit$history, 
                       levels = c("A30", "A31", "A32", "A33", "A34"))

levels(credit$history)<-c("good", "good", "poor", "poor",
                          "terrible")

credit$foreign<-factor(credit$foreign,
                       levels = c("A201", "A202"),
                       labels = c("foreign", "german"))

credit$rent<-factor(credit$housing=="A151")

credit$purpose<-factor(credit$purpose,
                       levels = c("A40", "A41", "A42",
                                  "A43", "A44", "A45", 
                                  "A46", "A47", "A48",
                                  "A49", "A410"))

levels(credit$purpose)<-c("newcar", "usedcar", rep("goods/repair",4),
                          "edu", NA, "edu", "biz", "biz")

credit<-credit[,c("Default", "duration", "amount", "installment",
                  "age", "history", "purpose", "foreign", "rent")]

summary(credit)

Xcred<-model.matrix(Default~., data=credit)[,-1]
set.seed(1)
train<-sample(1:1000, 900)
xtrain<-Xcred[train,]
xnew<-Xcred[-train,]
ytrain<-credit$Default[train]
ynew<-credit$Default[-train]
credglm<-glm(Default~., family = binomial,
             data=data.frame(Default=ytrain, xtrain))

ptest<-predict(credglm, newdata = data.frame(xnew), type="response")
data.frame(ynew, ptest)

gg1<-floor(ptest+(5/6))
ttt<-table(ynew,gg1)
ttt

error<-(ttt[1,2]+ttt[2,1])/100
error
