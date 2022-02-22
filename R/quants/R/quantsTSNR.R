quantsTSNR = function( values, times=NULL, remove.linear=F ) {

  tSNR = mean(values)/sd(values)

  if ( remove.linear ) {
    if ( is.null(times) ) {
      times = c(1:length(values))
    }

    df = data.frame(Value=values, Time=times)
    fit = lm(Value ~ Time, df)
    fitValues = df$Value - fit$fitted.values + fit$fitted.values[1]
    tSNR = mean(fitValues)/sd(fitValues)
  }

  return(tSNR)

}
