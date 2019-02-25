#!/bin/bash 

subject=$1

rm -f /tmp/univar.R /tmp/univar.png

cat <<EOF > /tmp/univar.R
rawtable <- read.table("stdin")
## Don't take more than 100,000 values, to prevent R and xpdf from choking:
myTable <- as.numeric(rawtable[sample.int(nrow(rawtable))[1:100000],1])
summary(myTable)
stem(myTable)
pdf(file="/tmp/univar.pdf")
par(mfrow=c(2,3))
if ( "$subject" != "" ) { title.suffix <- paste(" of ", "$subject",sep="")} else title.suffix <- ""
title <- paste("Histogram",title.suffix,sep="")
hist(myTable, main=title, breaks=40)
title <- paste("Box-plot",title.suffix,sep="")
boxplot(myTable, main=title)
##plot(density(myTable, main="Density plot of $subject"))
#plot(1:nrow(myTable),myTable)
title <- paste("Sort Plot",title.suffix,sep="")
plot(sort(myTable),main=title)
title <- paste("Log Histogram",title.suffix,sep="")
hist(log(myTable), main="Histogram of $subject", breaks=40)
title <- paste("Log Box-plot",title.suffix,sep="")
boxplot(log(myTable), main="Box-plot of $subject")
title <- paste("Log Sort Plot",title.suffix,sep="")
plot(sort(log(myTable)),main=title)
dev.off()
##print(dim(myTable))
if ( length(myTable) <= 5000 )
   shapiro.test(myTable)
ks.test(myTable, "pnorm", mean = mean(myTable), sd = sqrt(var(myTable)))
t.test(myTable)
wilcox.test(myTable)

EOF

cat - | Rscript /tmp/univar.R

rm -f /tmp/univar.R

#mv /tmp/univar.pdf ~/WWW/crypt/imgs
#chmod 755 ~/WWW/crypt/imgs/univar.pdf
