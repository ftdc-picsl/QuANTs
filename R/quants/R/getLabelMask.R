#' getLabelMask
#'
#' get a mask created by merging specific labels
#'
#' @param labels the image of labels or its filename
#' @param cortex boolean for cortical labels only
#' @param hemisphere array of hemispheres to include
#' @param lobe array of lobes/groups to includes, options include:
#' \itemize{
#'   \item cerebellum: cerebellum
#'   \item frontal: frontal
#'   \item insular: insular
#'   \item limbic: limbic
#'   \item occipital: occipital
#'   \item parietal: parietal
#'   \item subcortical: subcortical
#'   \item temporal: temporal
#'   \item ventricle: ventricle
#'  }
#' @param labelSystem scheme for labels, only "mindboggle" currently supported
#' @param bilateral flag for only returning labels with both left and right components

getLabelMask <- function( labels, cortex=FALSE,
  hemisphere=levels(mindBoggleLabels$hemisphere),
  lobe=levels(mindBoggleLabels$lobe),
  bilateral=FALSE,
  labelSystem="mindboggle" ) {

  if ( class(labels) != "antsImage" ) {
    stop("Invalid label image")
  }

  mask = labels*0

  if ( labelSystem=="mindboggle" ) {
    labelSet = mindBoggleLabels
  }
  else {
    stop("Unsupported label system")
  }

  ids = unique(labelSet$number)

  if ( cortex ) {
    ids = unique(labelSet$number[labelSet$cortex==1])
  }

  if ( length(hemisphere) < length(levels(labelSet$hemisphere)) ) {
    hIds = c()
    for ( i in hemisphere ) {
      hIds = c(hIds, labelSet$number[labelSet$hemisphere==i])
    }
    ids = intersect(ids, hIds)
  }

  if ( length(lobe) < length(levels(labelSet$lobe)) ) {
    lIds = c()
    for ( i in lobe ) {
      lIds = c(lIds, labelSet$number[labelSet$lobe==i])
    }
    ids = intersect(ids, lIds)
  }

  if ( bilateral==TRUE ) {
    bIds = labelSet$number[!is.na(labelSet$bilateral)]
    ids = intersect(ids, bIds)
  }

  for ( i in ids ) {
    mask[labels==i] = 1
  }

  return(mask)

}
