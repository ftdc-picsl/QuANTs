#' getQuantsLabelNumbers
#'
#' get label numbers for regions of interest
#'
#' @param system labeling systems to obtain values for
#' @param cortex TRUE/FALSE flag for cortical regions
#' @param subcortical TRUE/FALSE flag for subcortical regions
#' @param hemishere flag for 'right' or 'left'
#' @param name return regions by name
#' @param group type of grouping (temporal, parietal, etc)
#' @param return.index flag to return system info index instead of label number


getQuantsLabelNumbers <- function(system="mindboggle", cortex=NA, group=NA, hemisphere=NA, name=NA, return.index=FALSE) {

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

    if ( !is.na(name) ) {
      idx = idx * ( as.character(sys$name) == name )
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
