#' subjectLabelStats
#'
#' summarize a subjects labels:
#'
#' @param labels the image of labels or its filename
#' @param labelSet an array of all valid label values
#' @param image the image whose values are summarized, or its filename
#' @param mask an image mask to apply to labels, or it's filename
#' @param outfile filename for resulting data to be saved
#' @param measure name of the measure in 'image' (default="measure")
#' @param labelSystem name of label system (default="mindboggle")
#' @param include.volume should volumes be calculated (default=TRUE)
#' @param force.resample resample image to match label space if necessary (default=FALSE)
#'

subjectLabelStats <- function( labels, image=NULL, measure="measure", mask=NULL,
  weights=NULL, outfile=NULL, labelSet=NULL, labelSystem="mindboggle", include.volume=TRUE, force.resample=FALSE ) {

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
    #print(labelSystem)
    if ( labelSystem=="mindboggle") {
      labelSet = mindBoggleLabels$number
    }
    else if ( labelSystem=="antsct") {
      labelSet = antsct$number
    }
    else if (labelSystem=="brain") {
      labelSet = c(1)
    }
    else if (labelSystem=="jhuLabels") {
      labelSet = jhuLabels$number
    }
    else {
      stop("Only mindboggle & antsct labels are currently supported")
    }
  }

  dataRow = data.frame(system=NA, label=NA, measure=NA, metric=NA, value=NA)

  voxvol = prod(antsGetSpacing(labels))
  volumes = rep(NA, length(labelSet))
  outData = NULL
  if ( !is.null(image) ) {
    #outData = data.frame(number=labelSet, volume=volumes, mean=volumes, median=volumes, min=volumes, max=volumes, sd=volumes)
    if ( !antsImagePhysicalSpaceConsistency(labels, image) ) {
      #print("Resample image to label image space")
      #image = resampleImageToTarget(image, labels, interpType="genericLabel")
      if ( force.resample ) {
        image = resampleImageToTarget(image, labels, interpType="linear")
        warning("Image was resampled to match physical space of labeled image")
      }
      else {
        stop("Image not in same physical space as labeled image")
      }
    }
  }

  if ( !is.null(mask) ) {
    if ( !antsImagePhysicalSpaceConsistency(mask, labels) ) {

      if ( force.resample ) {
        mask = resampleImageToTarget(mask, labels, interpType="nearestNeighbor")
      }
      else {
        stop("Mask not in same space as label image")
      }
    }
    labels = labels*mask
  }

  for ( i in 1:length(labelSet) ) {
    #print(labelSet[i])
    value = NA
    count = sum(labels==labelSet[i])

    if (count > 0 ) {

      if ( include.volume ) {
        volumeRow = dataRow
        volumeRow$value = count*voxvol
        volumeRow$measure = "volume"
        volumeRow$metric = "numeric"
        volumeRow$label = labelSet[i]
        volumeRow$system = labelSystem
        outData = rbind(outData,volumeRow)
      }

      if ( !is.null(image) ) {
        vals = image[labels==labelSet[i]]

        dRows = rbind(dataRow,dataRow,dataRow,dataRow,dataRow,dataRow,dataRow)
        dRows$measure=rep(measure,7)
        dRows$metric=c("mean", "median", "min", "max", "sd", "q1", "q3")
        quant = quantile( vals, probs=c(0.25,0.75))
        dRows$value=c( mean(vals), median(vals), min(vals), max(vals), sqrt(var(vals)), quant[1], quant[2] )
        dRows$label=rep(labelSet[i],7)
        dRows$system=rep(labelSystem,7)
        outData=rbind(outData, dRows)
      }
    }

  }

  if ( !is.null(outfile) ) {
    write.csv(outData, outfile, row.names=F)
  }
  return(outData)

}
