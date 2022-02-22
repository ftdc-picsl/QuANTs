quantsValueImage <- function( value.data, label.image, id=NA, date=NA, metric=NA, measure=NA ) {

  if ( !isQuants(value.data) ) {
    stop("Data frame must be from QuANTs")
  }

  if ( class(label.image) != 'antsImage' ) {
    stop("label.image must be an 'antsImage'")
  }

  dat = value.data
  if ( !is.na(id) ) {
    dat = dat[ dat$id == id, ]
  }
  if ( !is.na(date) ) {
    dat = dat[ dat$date==date, ]
  }
  if ( !is.na(metric) ) {
    dat = dat[ dat$metric==metric, ]
  }
  if ( !is.na(measure) ) {
    dat = dat[ dat$measure==measure, ]
  }

  valueImage = label.image*0
  for ( i in 1:(dim(dat)[1]) ) {
    t = label.image==dat$label[i]
    if ( sum(t) > 0 ) {
      valueImage[ t ] = dat$value[i]
    }
  }

  return(valueImage)

}
