#' getQuantsLabelNumbers
#'
#' get label numbers for regions of interest
#'
#' @param system labeling systems to obtain values for


getQuantsLabelNumbers <- function(system="mindboggle", cortex=NA, group=NA, hemisphere=NA, return.index=FALSE) {

  labels = c()
  idx = c()
  if ( system=="mindboggle" ) {
    sys = mindBoggleLabels
    idx = 1:(dim(sys)[1])

    if ( !is.na(cortex) ) {
      if ( cortex == TRUE ) {
        idx = idx * (sys$cortex==1)
      }
      else {
        idx = idx * (sys$cortex==0)
      }
    }

    if ( !is.na(group) ) {
      idx = idx * (sys$lobe == group )
    }

    if ( !is.na(hemisphere) ) {
      idx = idx * (sys$hemisphere == hemisphere )
    }

    idx[is.na(idx)] = 0
    labels = sys$number[ idx>0 ]

  }
  else {
    stop("Only mindboggle labels are currently supported")
  }


  if ( return.index ) {
    labels = idx
  }

  return(labels)

}
