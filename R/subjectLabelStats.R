#' subjectLabelStats
#'
#' summarize a subjects labels:
#'
#' @param labels the image of labels or its filename
#' @param labelSet an array of all valid label values
#' @param image the image whose values are summarized, or its filename
#' @param mask an image mask to apply to labels, or it's filename
#' @param outfile filename for resulting data to be saved
#'
subjectLabelStats <- function( labels, image=NULL, mask=NULL, weights=NULL, outfile=NULL, labelSet=NULL, labelSystem="mindboggle" ) {

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

  if ( is.null(labelSet) ) {
    if ( labelSystem=="mindboggle") {
      labelSet = mindBoggleLabels$number
    }
    else {
      stop("Only mindboggle labels are currently supported")
    }
  }

  voxvol = prod(antsGetSpacing(labels))
  volumes = rep(NA, length(labelSet))
  outData = NA
  if ( is.null(image) ) {
      outData = data.frame(number=labelSet, volume=volumes)
    }
  else {
    outData = data.frame(number=labelSet, volume=volumes, mean=volumes, median=volumes, min=volumes, max=volumes, sd=volumes)
    if ( !antsImagePhysicalSpaceConsistency(labels, image) ) {
      #print("Resample image to label image space")
      #image = resampleImageToTarget(image, labels, interpType="genericLabel")
      image = resampleImageToTarget(image, labels, interpType="linear")
      warning("Image was resampled to match physical space of labeled image")
    }
  }

  if ( !is.null(mask) ) {
    if ( !antsImagePhysicalSpaceConsistency(mask, labels) ) {
      #print("Resample mask")
      mask = resampleImageToTarget(mask, labels, interpType="nearestNeighbor")
    }
    labels = labels*mask
  }

  for ( i in 1:length(labelSet) ) {
    value = NA
    count = sum(labels==labelSet[i])

    if (count > 0 ) {
      outData$volume[i] = count*voxvol

      if (!is.null(image) ) {
        vals = image[labels==labelSet[i]]
        outData$mean[i] = mean(vals)
        outData$median[i] = median(vals)
        outData$min[i] = min(vals)
        outData$max[i] = max(vals)
        outData$sd[i] = sqrt(var(vals))
      }
    }
    #print(outData[i,])
  }

  if ( !is.null(outfile) ) {
    write.csv(outData, outfile, row.names=F)
  }

  return(outData)

}
