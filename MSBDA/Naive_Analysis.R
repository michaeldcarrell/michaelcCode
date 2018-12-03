set.seed(1)
library(car)	#used to recode a variable

## reading the data
delay <- read.csv(file.choose())
delay
del=data.frame(delay)
del$schedf=factor(floor(del$schedtime/100))
del$delay=recode(del$delay,"'delayed'=1;else=0")
response=as.numeric(levels(del$delay)[del$delay])
hist(response)
mm=mean(response)
mm

## determining test and evaluation data sets
n=length(del$dayweek)
n
n1=floor(n*(0.6))
n1
n2=n-n1
n2
train=sample(1:n,n1)

## determining marginal probabilities

tttt=cbind(del$schedf[train],del$carrier[train],del$dest[train],del$origin[train],del$weather[train],del$dayweek[train],response[train])
tttrain0=tttt[tttt[,7]<0.5,]
tttrain1=tttt[tttt[,7]>0.5,]

## prior probabilities

tdel=table(response[train])
tdel=tdel/sum(tdel)
tdel

## scheduled time

ts0=table(tttrain0[,1])
ts0=ts0/sum(ts0)
ts0
ts1=table(tttrain1[,1])
ts1=ts1/sum(ts1)
ts1

## scheduled carrier

tc0=table(tttrain0[,2])
tc0=tc0/sum(tc0)
tc0
tc1=table(tttrain1[,2])
tc1=tc1/sum(tc1)
tc1

## scheduled destination

td0=table(tttrain0[,3])
td0=td0/sum(td0)
td0
td1=table(tttrain1[,3])
td1=td1/sum(td1)
td1

## scheduled origin

to0=table(tttrain0[,4])
to0=to0/sum(to0)
to0
to1=table(tttrain1[,4])
to1=to1/sum(to1)
to1

## weather

tw0=table(tttrain0[,5])
tw0=tw0/sum(tw0)
tw0
tw1=table(tttrain1[,5])
tw1=tw1/sum(tw1)
tw1
## bandaid as no observation in a cell
tw0=tw1
tw0[1]=1
tw0[2]=0

## scheduled day of week

tdw0=table(tttrain0[,6])
tdw0=tdw0/sum(tdw0)
tdw0
tdw1=table(tttrain1[,6])
tdw1=tdw1/sum(tdw1)
tdw1

## creating test data set
tt=cbind(del$schedf[-train],del$carrier[-train],del$dest[-train],del$origin[-train],del$weather[-train],del$dayweek[-train],response[-train])

## creating predictions, stored in gg

p0=ts0[tt[,1]]*tc0[tt[,2]]*td0[tt[,3]]*to0[tt[,4]]*tw0[tt[,5]+1]*tdw0[tt[,6]]
p1=ts1[tt[,1]]*tc1[tt[,2]]*td1[tt[,3]]*to1[tt[,4]]*tw1[tt[,5]+1]*tdw1[tt[,6]]
gg=(p1*tdel[2])/(p1*tdel[2]+p0*tdel[1])
hist(gg)
plot(response[-train]~gg)

## coding as 1 if probability 0.5 or larger
gg1=floor(gg+0.5)
ttt=table(response[-train],gg1)
ttt
error=(ttt[1,2]+ttt[2,1])/n2
error

## coding as 1 if probability 0.3 or larger
gg2=floor(gg+0.7)
ttt=table(response[-train],gg2)
ttt
error=(ttt[1,2]+ttt[2,1])/n2
error

## Here we calculate the lift (see Chapter 4) 
## The output is not shown in the text
bb=cbind(gg,response[-train])
bb
bb1=bb[order(gg,decreasing=TRUE),]
bb1
## order cases in test set naccording to their success prob
## actual outcome shown next to it

## overall success (delay) prob in evaluation set
xbar=mean(response[-train])
xbar

## calculating the lift
## cumulative 1's sorted by predicted values
## cumulative 1's using the average success prob from training set
axis=dim(n2)
ax=dim(n2)
ay=dim(n2)
axis[1]=1
ax[1]=xbar
ay[1]=bb1[1,2]
for (i in 2:n2) {
  axis[i]=i
  ax[i]=xbar*i
  ay[i]=ay[i-1]+bb1[i,2]
}

aaa=cbind(bb1[,1],bb1[,2],ay,ax)
aaa[1:100,]

plot(axis,ay,xlab="number of cases",ylab="number of successes",main="Lift: Cum successes sorted by pred val/success prob")
points(axis,ax,type="l")



