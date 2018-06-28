#' getLabelSystem
#'
#' get info for a labeling scheme
#'
#' @param systemName the labeling system info to return
#' \itemize{
#'   \item mindboggle
#'   \item mindboggle-extended
#'   \item antsct
#'   \item jhuLabels
#'   \item jhuTracts
#'  }
getLabelSystem <- function( systemName ) {
  if ( systemName == "mindboggle") {
    sys = mindBoggleLabels
  }
  else if ( systemName == "mindboggle-extended") {
    sys = mindBoggleLabelsExtended
  }
  else if ( systemName == "antsct" ) {
    sys = antsct
  }
  else if ( systemName == "jhuLabels") {
    sys = jhuLabels
  }
  else if ( systemName == "jhuTracts") {
    sys = jhuTracts
  }
  else {
    stop("Unsupported labeling system")
  }

  return(sys)
}
