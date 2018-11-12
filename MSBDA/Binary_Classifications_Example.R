library(ROCR)

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

cut<-1/2

truepos<-ynew==1 & ptest >=cut
trueneg<-ynew==0 & ptest < cut

sum(truepos)/sum(ynew==1)
sum(trueneg)/sum(ynew==0)

gg1=floor(ptest+(1-cut))
ttt=table(ynew,gg1)
ttt
error=(ttt[1,2]+ttt[2,1])/100
error

roc<-function(p,y){
  y<-factor(y)
  n<-length(p)
  p<-as.vector(p)
  Q<-p>matrix(rep(seq(0,1,length=500),n), ncol=, byrow=TRUE)
  fp<-colSums((y==levels(y)[1])*Q)/sum(y==levels(y)[1])
  tp<-colSums((y==levels(y)[2])*Q)/sum(y==levels(y)[2])
  plot(fp, tp, xlab = "1-Specificity", ylab="Sensitivity")
  abline(a=0, b=1, lty=2, col=8)
}

roc(p=ptest, y=ynew)

credglmall<-glm(credit$Default~Xcred, family = binomial)
roc(p=credglmall$fitted.values, y=credglmall$y)

prediction<-ptest
labels<-ynew
data<-data.frame(prediction, labels)
data

pred<-prediction(data$prediction, data$labels)
pred

pref<-performance(pred, "sens", "fpr")
pref

plot(pref)

credglmall<-glm(credit$Default~Xcred, family = binomial)
predictions<-credglmall$fitted.values
labels<-credglmall$y

data<-data.frame(predictions, labels)
pred<-prediction(data$predictions, data$labels)
perf<-performance(pred, "sens", "fpr")
plot(perf)
