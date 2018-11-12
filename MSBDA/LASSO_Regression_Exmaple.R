library(lars)

prostate<-read.csv(file.choose())

m1<-lm(lcavol~., data = prostate)

summary(m1)

x<-model.matrix(lcavol~age+lbph+lcp+gleason+lpsa, data=prostate)
x<-x[,-1]

lasso<-lars(x=x, y=prostate$lcavol, trace = T)
plot(lasso)
lasso

coef(lasso, s=c(0.25,0.50,0.75,1.0), mode="fraction")

cv.lars(x=x, y=prostate$lcavol, K=10)

MSElasso25<-dim(10)
MSElasso50<-dim(10)
MSElasso75<-dim(10)
MSElasso100<-dim(10)
set.seed(1)

for(i in 1:10){
  train<-sample(1:nrow(prostate), 80)
  lasso<-lars(x=x[train,], y=prostate$lcavol[train])
  MSElasso25[i]=mean((predict(lasso, x[-train,], s=0.25,
                              mode="fraction")$fit-
                        prostate$lcavol[-train])^2)
  MSElasso50[i]=mean((predict(lasso, x[-train,], s=0.50,
                              mode="fraction")$fit-
                        prostate$lcavol[-train])^2)
  MSElasso75[i]=mean((predict(lasso, x[-train,], s=0.75,
                              mode="fraction")$fit-
                        prostate$lcavol[-train])^2)
  MSElasso100[i]=mean((predict(lasso, x[-train,], s=1.00,
                              mode="fraction")$fit-
                        prostate$lcavol[-train])^2)
}

mean(MSElasso25)
mean(MSElasso50)
mean(MSElasso75)
mean(MSElasso100)

boxplot(MSElasso25, MSElasso50, MSElasso75, MSElasso100,
        ylab="MSE", sub="LASSO model",
        xlab = "s=0.25     s=0.50     s-0.75     s=1.0(LS)")



#OJ Exmaple
oj<-read.csv(file.choose())

x<-model.matrix(logmove~log(price)*(feat+brand+AGE60+EDUC+
                                    ETHNIC+INCOME+HHLARGE+
                                    WORKWOM+HVAL150+SSTRDIST+
                                    SSTRVOL+CPDIST5+CPWVOL5)^2, data=oj)

dim(x)

x=x[,-1]

for(j in 1:209){
  x[,j]=(x[,j]-mean(x[,j]))/sd(x[,j])
}

reg<-lm(oj$logmove~x)
summary(reg)
p0<-predict(reg)

lasso<-lars(x=x, y=oj$logmove, trace = T)
coef(lasso, s=c(0.25, 0.50, 0.75, 1.00), mode='fraction')

p1=predict(lasso, x, s=1, mode='fraction')

pdiff=p1$fit-p0


MSElasso10<-dim(10)
MSElasso50<-dim(10)
MSElasso90<-dim(10)
MSElasso100<-dim(10)
set.seed(1)

for(i in 1:10){
  train<-sample(1:nrow(oj), 20000)
  lasso<-lars(x=x[train,], y=oj$logmove[train])
  MSElasso10[i]=mean((predict(lasso, x[-train,], s=0.10,
                mode="fraction")$fit-oj$logmove[-train])^2)
  MSElasso50[i]=mean((predict(lasso, x[-train,], s=0.50,
                              mode="fraction")$fit-oj$logmove[-train])^2)
  MSElasso90[i]=mean((predict(lasso, x[-train,], s=0.90,
                              mode="fraction")$fit-oj$logmove[-train])^2)
  MSElasso100[i]=mean((predict(lasso, x[-train,], s=1.00,
                              mode="fraction")$fit-oj$logmove[-train])^2)
}

mean(MSElasso10)
mean(MSElasso50)
mean(MSElasso90)
mean(MSElasso100)

boxplot(MSElasso10, MSElasso50, MSElasso90, MSElasso100,
        ylab="MSE", sub="LASSO model")
