library(shiny)

quants_qc <- function() {

  p = .libPaths()[1]
  app = paste(sep="", .libPaths()[1], "/QuANTs/shiny/quants_qc/quants_qc_app.R")
  runApp(app)

}
