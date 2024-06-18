# correctedC
 Compute C index for various survival models
 
## General info
 The current c index function for random survival forests model is not correct and the c index for deep neural network based models in `survivalmodels' package ignores censoring. This package is for computing the c index for various survival models.

## Install

```
library(devtools)
install_github("YushuShi/correctedC")
```
## Usage

```
UnoC(time,event,predicted,tau=NULL)
```
* **time** The vector of the event times.
* **event** The vector of events, 1 for the event, 0 for censored.
* **predicted** The predicted value varies depending on the model used. For a Cox model, the predicted value is the linear combination of the predictors. For a random survival forests model, the predicted value is the predicted mortality, which represents the number of events in the dataset if all observations had this set of predictors. For survival models using the `survivalmodels` package, the predicted value is the risk, defined as the rank of the negative mean survival time. Generally, a higher predicted value indicates worse survival.
* **tau** The truncation point, the default is the largest event time.

### Output
The estimated Uno-type C-index

```
bootUnoC(time,event,predicted,B=1000,parallel=TRUE,numCore=NULL,tau=NULL)
```
* **B** The number of bootstrap samples.
* **parallel** Whether to use parallel processing. The default is TRUE.
* **numCore** The number of cores to use. If NULL, the number of cores is detected.

### Output
A vector of bootstrap samples of Uno-type C-index

## Reference
Uno H, Cai T, Pencina MJ, D'Agostino RB, Wei LJ. On the C-statistics for evaluating overall adequacy of risk prediction procedures with censored survival data. Stat Med. 2011 May 10;30(10):1105-17. doi: 10.1002/sim.4154. Epub 2011 Jan 13. PMID: 21484848; PMCID: PMC3079915.

## Examples
```
library(reticulate)
use_condaenv("/opt/anaconda3/bin/python", required = TRUE)
library(survivalmodels)
library(randomForestSRC)
library(correctedC)

dataPath<-system.file("extdata","data1.csv",
                      package = "correctedC")
data<-read.csv(dataPath)
data$num_comorb<-factor(data$num_comorb)
data$race<-factor(data$race)
data$cancer<-factor(data$cancer)
data$diab<-factor(data$diab)
data$sex<-factor(data$sex)
data$dementia<-factor(data$dementia)

rfModel <- rfsrc(Surv(time,status)~.,data)
rfPred <- predict(rfModel,newdata = data)
# randomForestSRC default cindex function is not correct
get.cindex(data$time, data$status, rfPred$predicted)
UnoC(data$time, data$status,  rfPred$predicted)
BSUnoC<-bootUnoC(data$time, data$status, rfPred$predicted)
quantile(BSUnoC,c(0.025,0.975))
# out of bag c index
get.cindex(rfModel$yvar[,1], rfModel$yvar[,2], rfModel$predicted.oob) 
UnoC(rfModel$yvar[,1], rfModel$yvar[,2], rfModel$predicted.oob) 
oobC<-bootUnoC(rfModel$yvar[,1], rfModel$yvar[,2], rfModel$predicted.oob) 
quantile(oobC,c(0.025,0.975))

deepSurvModel<-deepsurv(data=data,frac=0.2,
                        activation="relu",
                        num_nodes=c(64L,64L),
                        dropout=0.2,
                        early_stopping=TRUE,
                        epochs=1000L,
                        patience=50L,
                        batch_norm = TRUE,
                        batch_size=250L,
                        shuffle=TRUE)
# The cindex function in survivalmodels package ignores censoring
deepSurvPred <- predict(deepSurvModel, type="risk",newdata = data)
cindex(risk = deepSurvPred, truth = data$time)
UnoC(data$time, data$status, deepSurvPred)
deepSurvBootC<-bootUnoC(data$time, data$status, deepSurvPred)
quantile(deepSurvBootC,c(0.025,0.975))
```
