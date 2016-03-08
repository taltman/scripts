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
library(mvnormtest)
mshapiro.test
      
require(graphics)
pcs <- prcomp(table,scale=TRUE)
plot(pcs)
summary(pcs)
biplot(pcs)


      
## Independent Component Analysis

library(fastICA)


## Self-Organizing Maps

## Non-negative matrix factorization

## Positive Integer matrix factorization
