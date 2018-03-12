#' subjectLabels
#'
#' summarize a subjects labels:
#'
#' @param labels the image of labels or its filename
#' @param image the image whose values are summarized, or its filename
#' @param mask an image mask to apply to labels, or it's filename
#' @param outfile filename for resulting data to be saved
#'
subjectLabels <- function( labels, image=NULL, mask=NULL, outfile=NULL ) {

  if ( is.character(labels) ) {
    labels = antsImageRead(labels)
  }

  if ( is.character(image) ) {
    image = antsImageRead(image)
  }

  if ( is.character(mask) ) {
    mask = antsImageRead(mask)
  }

  if ( class(labels) != "antsImage" ) {
    stop("Invalid label image")
  }

  if ( !is.null(mask) ) {
    labels = labels*mask
  }

  voxvol = prod(antsGetSpacing(labels))
  for ( i in mindBoggleLabels$Number ) {
    value = NA
    if ( is.null(image) ) {
      count = sum(labels==i)
      if ( count > 0 ) {
        value = count*voxvol
      }
    }
  }

  if ( !is.null(outfile) ) {
    #write.csv(outfile, DATA, row.names=F)
  }



}
