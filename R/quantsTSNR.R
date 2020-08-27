quantsTSNR = function( values, times=NA, remove.linear=F ) {

  tSNR = mean(values)/sd(values)
  if ( remove.linear ) {
    if ( is.na(times) ) {
      stop("Need time values to remove linear trend")
    }

    df = data.frame(Value=values, Time=times)
    fit = lm(Value ~ Time, df)
    fitValues = df$Valeus - fit$fitted.values + fit$fitted.values[1]

    tSNR = mean(fitValues)/sd(fitValues)
  }

  return(tSNR)

}
