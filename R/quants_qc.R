library(shiny)

quants_qc <- function(subjects="", qc_file="") {

  p = .libPaths()[1]
  app = paste(sep="", .libPaths()[1], "/QuANTs/shiny/quants_qc/quants_qc_app.R")
  options(browser="/usr/bin/firefox")

  .GlobalEnv$.quants_info = list(subjects=subjects, qc_file=qc_file)
  on.exit(rm(.quants_info, envir=.GlobalEnv))

  runApp(app)

}
