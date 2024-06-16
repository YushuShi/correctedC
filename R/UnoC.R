num_denom_calc <- function(I, time, predicted, tau, event, censSurv) {
  sum1 <- sum((time[I] < time)* (predicted[I] > predicted))
  sum2 <- sum((time[I] < time))
  sum1<-sum1*(time[I]<tau)* event[I]
  sum2<-sum2*(time[I]<tau)* event[I]
  # if the last observation is event, then last event's G(t) will be 0
  c(num = ifelse(censSurv$surv[I],sum1/(censSurv$surv[I])^2,0),
    denom =ifelse(censSurv$surv[I],sum2/(censSurv$surv[I])^2,0))
}

#' Uno type C-index
#'
#' @param time The vector of the observed times.
#' @param event The vector of events, 1 for event, 0 for censored.
#' @param predicted The predicted value varies depending on the model used. For a Cox model, the predicted value is the linear combination of the predictors. For a random survival forests model, the predicted value is the predicted mortality, which represents the number of events in the dataset if all observations had this set of predictors. For survival models using the `survivalmodels` package, the predicted value is the risk, defined as the rank of the negative mean survival time. Generally, a higher predicted value indicates worse survival.
#' @param tau The truncation point, the default is the largest event time.
#' @examples
#' # Example usage:
#' \donttest{
#'   library(survival)
#'   set.seed(123)
#'   time <- runif(10, 0, 100)
#'   event <- rbinom(10, 1, 0.5)
#'   predicted <- runif(10, 0, 1)
#'   UnoC(time, event, predicted, tau = 50)
#' }
#' @import survival
#' @export
UnoC<-function(time,event,predicted,tau=NULL){
  dataTemp<-data.frame(time=time,event=event,predicted=predicted)
  dataTemp<-dataTemp[apply(dataTemp,1,function(x) {!any(is.na(x))}),]
  dataTemp<-dataTemp[order(dataTemp$time),]
  time<-dataTemp$time
  event<-dataTemp$event
  predicted<-dataTemp$predicted

  censInd<-1-event
  if(is.null(tau)){
    tau<-max(time[event==1])
  }
  censSurv<-survfit(Surv(time,censInd)~1)
  # if the last observation is event, then last event's G(t) will be 0

  results <- sapply(1:length(time), num_denom_calc, time = time, predicted = predicted, tau = tau, event = event, censSurv = censSurv)
  num <- sum(results[1, ],na.rm=TRUE)
  denom <- sum(results[2, ],na.rm=TRUE)
  num/denom
}
  
bootSample<-function(time,event,predicted,seed,tau=NULL){
  set.seed(seed)
  index<-sample(1:length(time),length(time),replace=TRUE)
  UnoC(time[index],event[index],predicted[index],tau)
}

#' Get boostrap samples for Uno type C-index
#'
#' @param time The vector of the observed times.
#' @param event The vector of events, 1 for event, 0 for censored.
#' @param predicted The predicted value varies depending on the model used. For a Cox model, the predicted value is the linear combination of the predictors. For a random survival forests model, the predicted value is the predicted mortality, which represents the number of events in the dataset if all observations had this set of predictors. For survival models using the `survivalmodels` package, the predicted value is the risk, defined as the rank of the negative mean survival time. Generally, a higher predicted value indicates worse survival.
#' @param B The number of bootstrap samples.
#' @param parallel Whether to use parallel processing.
#' @param numCore The number of cores to use. If NULL, the number of cores is detected.
#' @param tau The truncation point, the default is the largest event time.
#' @examples
#' # Example usage:
#' \donttest{
#'   library(survival)
#'   set.seed(123)
#'   time <- runif(10, 0, 100)
#'   event <- rbinom(10, 1, 0.5)
#'   predicted <- runif(10, 0, 1)
#'   bootUnoC(time, event, predicted, tau = 50)
#' }
#' @import survival
#' @import foreach
#' @import doParallel
#' @export
bootUnoC<-function(time,event,predicted,B=1000,parallel=TRUE,numCore=NULL,tau=NULL){
  if(parallel){
    if(is.null(numCore)){
      numCore<-detectCores()
    }
    registerDoParallel(numCore)
    result<-foreach(seedNum=1:B,.combine=c,.packages=c("survival")) %dopar% {
      bootSample(time,event,predicted,seedNum,tau)}
   # stopCluster(numCore)
    registerDoSEQ()
    rm(numCore)
    gc()
  }else{
    result<-foreach(seedNum=1:B,.combine=c,.packages=c("survival")) %do% {
      bootSample(time,event,predicted,seedNum,tau)}
  }
  result
}