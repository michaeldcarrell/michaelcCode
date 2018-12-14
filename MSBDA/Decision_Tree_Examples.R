#Example 1: Prostate Cancer 

prostate <- read.csv(file.choose())
prostate

library(tree)
## Construct the tree
pstree <- tree(lcavol ~., data=prostate, mindev=0.1, mincut=1)
pstree <- tree(lcavol ~., data=prostate, mincut=1)

pstree
plot(pstree, col=8)
text(pstree, digits=2)

pstcut <- prune.tree(pstree,k=1.7)
plot(pstcut)
text(pstcut)
pstcut

pstcut <- prune.tree(pstree,k=2.05)
plot(pstcut)
text(pstcut)
pstcut

pstcut <- prune.tree(pstree,k=3)
plot(pstcut)
text(pstcut)
pstcut

pstcut <- prune.tree(pstree)
pstcut
plot(pstcut)

pstcut <- prune.tree(pstree,best=3)
pstcut
plot(pstcut)
text(pstcut)

## Use cross-validation to prune the tree
set.seed(2)
cvpst <- cv.tree(pstree, K=10)
cvpst$size
cvpst$dev
plot(cvpst, pch=21, bg=8, type="p", cex=1.5, ylim=c(65,100))

pstcut <- prune.tree(pstree, best=3)
pstcut
plot(pstcut, col=8)
text(pstcut)

## Plot what we end up with
plot(prostate[,c("lcp","lpsa")],cex=0.2*exp(prostate$lcavol))
abline(v=.261624, col=4, lwd=2)
lines(x=c(-2,.261624), y=c(2.30257,2.30257), col=4, lwd=2)

#alpha 5.0
pstcut<-prune.tree(pstree, k=5)
pstcut
plot(pstcut)
text(pstcut)




#Example 2: Motorcycle Acceleration

library(MASS)
library(tree)
data(mcycle)
mcycle
plot(accel~times,data=mcycle)
mct <- tree(accel ~ times, data=mcycle)
mct
plot(mct, col=8)
text(mct, cex=.75) ## we use different font size to avoid print overlap

#prune tree
prunedset<-prune.tree(mct, best = 5)
prunedset

plot(prunedset)
text(prunedset)

x=c(1:6000)
x=x/100
y1=seq(-4.357,-4.357,length.out=1510)
y2=seq(-39.120,-39.120,length.out=(1650-1510))
y3=seq(-98.940,-98.940,length.out=790)
y4=seq(-42.49,-42.49,length.out=300)
y5=seq(11.780,11.780,length.out=3260)
y=c(y1,y2,y3,y4,y5)
plot(accel~times,data=mcycle)
lines(y~x)

## scatter plot of data with overlay of fitted function
x=c(1:6000)
x=x/100
y1=seq(-4.357,-4.357,length.out=1510)
y2=seq(-39.120,-39.120,length.out=140)
y3=seq(-86.31,-86.31,length.out=300)
y4=seq(-114.7,-114.7,length.out=490)
y5=seq(-42.49,-42.49,length.out=300)
y6=seq(10.25,10.25,length.out=240)
y7=seq(40.72,40.72,length.out=520)
y8=seq(3.291,3.291,length.out=2500)
y=c(y1,y2,y3,y4,y5,y6,y7,y8)
plot(accel~times,data=mcycle)
lines(y~x)




#Example 3:  Fisher Iris Data Revisited

library(MASS) 
library(tree)
## read in the iris data
data(iris)
iris

plot(iris_numeric$Species, iris_numeric$Petal.Width, col = "red", ylab = "length (blue) / width (red)", ylim = c(0,7))
par(new = TRUE)
plot(iris_numeric$Species, iris_numeric$Petal.Length, col = "blue", ylab = "length (blue) / width (red)", ylim = c(0,7))


iristree <- tree(Species~.,data=iris)
iristree
plot(iristree)
plot(iristree,col=8)
text(iristree,digits=2)
summary(iristree)
irissnip=snip.tree(iristree,nodes=c(7,12))
irissnip
plot(irissnip)
text(irissnip)

library(textclean)
iris$color<-mgsub(iris$Species, c("setosa", "versicolor", "virginica"), c("red", "blue", "yellow4"))
plot(iris[,c("Petal.Length", "Petal.Width")], col=iris$color)
legend("bottomright", legend=c("setosa", "versicolor", "virginica"), col = c("red", "blue", "yellow4"), pch = 1) #pch = point type (kinda have to look up)
abline(v=2.45, col=4, lwd=2)
lines(x=c(2.45, 4.95), y=c(1.75, 1.75), col=4, lwd=2)
lines(x=c(4.95, 4.95), y=c(1.75, 0), col=4, lwd=2)

