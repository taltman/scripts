## Use various techniques to attempt dimensionality reduction on a data
## set.
## This code focuses on gaining an intuition about the underlying
## structure of the dataset, and less concerned about optimal dimensional
## reduction, or feature engineering.

### Distance Heatmap Plot

## Do robust scaling of data

metaDist <- dist(table,method="euclidean")
hc <- hclust(table,method="ward")
image(as.matrix(metaDist)[hc$order,hc$order])

### Principal Components

## First, see whether PCA is even justified:
## Might want to bypass and go straight to other methods depending on the result:
library(mvnormtest)
mshapiro.test
      
require(graphics)
pcs <- prcomp(table,scale=TRUE,retx=TRUE)
plot(pcs)
plot(pcs$x)
summary(pcs)
biplot(pcs)

## www.statmethods.net/graphs/scatterplot.html
##qqplot as well
      
## Independent Component Analysis
library(fastICA)

## Self-Organizing Maps

## Non-negative matrix factorization

## Positive Integer matrix factorization
