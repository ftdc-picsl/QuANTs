#' mergeBilateralLabels
#'
#' get a mask created by merging specific labels
#'
#' @param labels the image of labels or its filename
#' @param labelSystem scheme for labels, only "mindboggle" currently supported


mergeBilateralLabels <- function( labels, labelSystem="mindboggle" ) {

  if ( class(labels) != "antsImage" ) {
    stop("Invalid label image")
  }

  mergedLabels = labels*0

  if ( labelSystem=="mindboggle" ) {
    labelSet = mindBoggleLabels
  }
  else {
    stop("Unsupported label system")
  }


  subset = mindBoggleLabels[ !is.na(mindBoggleLabels$bilateral), ]

  biLabels = unique(subset$bilateral)

  for ( b in biLabels ) {
    twoLabels = subset$number[subset$bilateral==b]
    newLabel = min(twoLabels)
    mergedLabels[labels==twoLabels[1]]=newLabel
    mergedLabels[labels==twoLabels[2]]=newLabel
  }

  return(mergedLabels)

}
