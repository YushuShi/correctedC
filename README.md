# correctedC
 Compute C index for various survival models
 
## General info
 The current c index function for random survival forests model is not correct and the c index for deep neural network based models in `survivalmodels' package ignores censoring. This package is for computing the c index for various survival models.

## Install

```
library(devtools)
install_github("YushuShi/corerctedC")
```

## Examples

dataPath<-system.file("extdata","data.csv",
                      package = "survivalContour")
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
bootUnoC(data$time, data$status, rfPred$predicted)
# out of sample c index
get.cindex(rfModel$yvar[,1], rfModel$yvar[,2], rfModel$predicted.oob) 
UnoC(rfModel$yvar[,1], rfModel$yvar[,2], rfModel$predicted.oob) 
bootUnoC(rfModel$yvar[,1], rfModel$yvar[,2], rfModel$predicted.oob) 

deepSurvModel<-deepsurv(data=data,frac=0.2,
                     activation="relu",
                     num_nodes=c(64L,64L),
                     dropout=0.2,
                     early_stopping=TRUE,
                     epochs=1000L,
                     patience=50L,
                     batch_norm = TRUE,
                     batch_size=256L,
                     shuffle=TRUE)
# The cindex function in survivalmodels package ignores censoring
deepSurvPred <- predict(deepSurvModel, type="risk",newdata = data)
cindex(risk = deepSurvPred, truth = data$time)
UnoC(data$time, data$status, deepSurvPred)
bootUnoC(data$time, data$status, deepSurvPred)