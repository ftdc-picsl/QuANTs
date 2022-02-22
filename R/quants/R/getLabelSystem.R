#' getLabelSystem
#'
#' get info for a labeling scheme
#'
#' @param systemName the labeling system info to return
#' \itemize{
#'   \item mindboggle
#'   \item mindboggle-extended
#'   \item braincolor
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
  else if ( systemName == "braincolor" ) {
    sys = braincolorLabels
  }
  else if ( systemName == "antsct" ) {
    sys = antsct
  }
  else if ( systemName == "brain" ) {
    sys = brainLabel
  }
  else if ( systemName == "jhuLabels") {
    sys = jhuLabels
  }
  else if ( systemName == "jhuTracts0") {
    sys = jhuTracts
  }
  else if ( systemName == "jhuTracts25") {
    sys = jhuTracts
  }
  else if ( systemName == "jhuTracts50") {
    sys = jhuTracts
  }
  else if ( systemName == "midevel") {
    sys = midEvelLabels
  }
  else if ( systemName == "lausanne33" ) {
    sys = lausanne33Labels
  }
  else if ( systemName == "lausanne60" ) {
    sys = lausanne60Labels
  }
  else if ( systemName == "lausanne125" ) {
    sys = lausanne125Labels
  }
  else if ( systemName == "lausanne250" ) {
    sys = lausanne250Labels
  }
  else {
    stop("Unsupported labeling system")
  }

  return(sys)
}
