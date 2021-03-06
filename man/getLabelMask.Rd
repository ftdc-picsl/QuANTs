% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getLabelMask.R
\name{getLabelMask}
\alias{getLabelMask}
\title{getLabelMask}
\usage{
getLabelMask(labels, cortex = FALSE,
  hemisphere = levels(mindBoggleLabels$hemisphere),
  lobe = levels(mindBoggleLabels$lobe), bilateral = FALSE,
  labelSystem = "mindboggle")
}
\arguments{
\item{labels}{the image of labels or its filename}

\item{cortex}{boolean for cortical labels only}

\item{hemisphere}{array of hemispheres to include}

\item{lobe}{array of lobes/groups to includes, options include:
\itemize{
  \item cerebellum: cerebellum
  \item frontal: frontal
  \item insular: insular
  \item limbic: limbic
  \item occipital: occipital
  \item parietal: parietal
  \item subcortical: subcortical
  \item temporal: temporal
  \item ventricle: ventricle
 }}

\item{bilateral}{flag for only returning labels with both left and right components}

\item{labelSystem}{scheme for labels, only "mindboggle" currently supported}
}
\description{
get a mask created by merging specific labels
}
