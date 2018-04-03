#' getLabelSystem
#'
#' get info for a labeling scheme
#'
#' @param systemName the labeling system info to return
#' \itemize{
#'   \item mindboggle
#'   \item mindboggle-extended
#'   \item antsct
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
  else {
    stop("Unsupported labeling system")
  }

  return(sys)
}
