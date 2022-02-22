#' quants_qc
#'
#' run the shiny app for data quality review
#'
#' @param subjects filename of list of subjects and dates to review
#' @param qc_file filename of location to store results


library(shiny)

quants_qc <- function(subjects="", qc_file="") {

  p = .libPaths()[1]
  app = paste(sep="", .libPaths()[1], "/QuANTs/shiny/quants_qc/quants_qc_app.R")
  options(browser="/usr/bin/firefox")

  if ( subjects != "" ) {
    if ( !file.exists( subjects) ) {
      stop(paste0("The subject file '", subjects, "' does not exist"))
    }
  }

  if ( qc_file != "" ) {
    if ( !file.exists( qc_file ) ) {
      df <- data.frame(Date=as.Date(character()),
                 File=character(),
                 User=character(),
                 stringsAsFactors=FALSE)

      df = data.frame( INDDID=character(),
        Timepoint=character(),
        Reviewer=character(),
        T1Quality=integer(),
        ExtractQuality=integer(),
        SegmentationQuality=integer(),
        Movement=integer(),
        Artefact=integer(),
        Timestamp=as.Date(character()),
        Notes=character() )
      write.csv(df, qc_file, row.names=F)
    }
  }

  .GlobalEnv$.quants_info = list(subjects=subjects, qc_file=qc_file)
  on.exit(rm(.quants_info, envir=.GlobalEnv))

  runApp(app)

}
