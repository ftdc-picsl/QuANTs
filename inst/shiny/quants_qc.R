library(shiny)
library(shinyFiles)
source("directoryInput.R")

defaultPath="/mnt/chead/grossman/pipedream2018/crossSectional/antsct"

load_subject = function( id, date, path ) {
    print("load_subject")
    subpath = paste(sep="/", path, id, date )
    #t1 = list.files(path=subpath, pattern=glob2rx("*t1Head.nii.gz"), full.names=T)
    t1 = list.files(path=subpath,  pattern=glob2rx("*BrainSegmentation0N4.nii.gz"), full.names=T)
    seg = list.files(path=subpath, pattern=glob2rx("*BrainSegmentation.nii.gz"), full.names=T)
    snapCall = paste("/Applications/ITK-SNAP.app/Contents/MacOS/ITK-SNAP -g",t1,"-s",seg)
    system(paste(snapCall, "&"))
    return(snapCall)
}

get_kill_id = function( info ) {
  print("get_kill_id()")
  parts = strsplit(info, " ")[[1]]
  parts = parts[parts!=""]
  print(paste("kill id = ", parts[1]))
  return(parts[1])
}

# Define UI for data upload app ----
ui <- fluidPage(

  # App title ----
  titlePanel("QuANTs QC"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    position="right",
    # Sidebar panel for inputs ----
    sidebarPanel(

      #textInput("path", "Path to base directory of ACT output",
      #  value=defaultPath ),

      #directoryInput('directory', label = 'select a directory', value=defaultPath),

      fluidRow( column(12,h5("Path to base directory of ACT output") )),
      fluidRow(
        column(2, div(style="padding: 0px 0px;", shinyDirButton("path", "Browse...", "ACT"))),
        column(10, div(style="padding: 0px 0px; margin-left:-5px", verbatimTextOutput("path")))),

      # Input: Select a file ----
      fileInput("file1", "Choose subject list",
                multiple = TRUE,
                accept = c("text/csv",
                         "text/comma-separated-values,text/plain",
                         ".csv")),

      fileInput("load", "Load a QC file", multiple = TRUE,
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv")),

      #shinyFilesButton('files', 'File select', 'Please select a file', FALSE),

      # Horizontal line ----
      tags$hr(),

      h4(textOutput("text1")),

      tags$hr(),

      radioButtons("t1", "Raw T1", choices=c("Fail (=1)"=1, "Usable (=2)"=2, "Good (=3)"=3), inline=T),

      checkboxInput("motion", "Motion", value=FALSE),

      checkboxInput("artefact", "Artefact", value=FALSE),

      radioButtons("mask", "Brain Mask", choices=c("T1 Failed (=0)"=0, "Fail (=1)"=1, "Usable (=2)"=2, "Good (=3)"=3), inline=T),

      radioButtons("seg", "Segmentation", choices=c("T1 Failed (=0)"=0, "Fail (=1)"=1, "Usable (=2)"=2, "Good (=3)"=3), inline=T),

      textInput("notes", "Notes", value=""),

      actionButton("submit", "Submit this subject"),


      tags$hr(),

      tableOutput("contents")
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Data file ----
      #div(style="display: inline-block;vertical-align:top; width: 300px;",downloadButton("down", "Save QC Data")),
      shinySaveButton('save', 'Save file', 'Save file as...', filetype=list(csv='csv')),
      #verbatimTextOutput('savefile'),
      tableOutput("qc")

    )

  )
)

# Define server logic to read selected file ----
server <- function(input, output, session) {

  roots = c(wd='/')
  shinyFileChoose(input, 'files', session=session, roots=roots, filetypes=c('', 'txt'))

  options(DT.options = list(pageLength = 25))
  values = reactiveValues(subjects=NULL,id="NA", date="NA", loaded=0, qcData=NULL, snap=NULL,
                          path=defaultPath)

  output$path = renderText({values$path})

  shinyFileSave(input, 'save', roots=roots, session=session, restrictions=system.file(package='base'))

  #output$savefile <- renderPrint({
  #  print("output$savefile")
  #  parseSavePath(roots, input$save)
#})

  #output$down = downloadHandler(
  #  print("download handler")
  #)

  shinyDirChoose(input, "path", roots=roots)
  observeEvent(input$path, {
    print("Choose ACT path")
    values$path = parseDirPath(roots, input$path)
  })

  #observeEvent( ignoreNULL=TRUE, eventExp={input$directory},
  #              handlerExp={
  #              newpath = choose.dir(default = readDirectoryInput(session, 'directory'))
  #              values$path = newpath[length(newpath)]
  #              updateDirectoryInput(session, 'directory', value = values$path)
  #              })

  observeEvent( input$save, {
    print("input$save called")
    fname=parseSavePath(roots, input$save)
    print(fname)
    print(fname$datapath)

    write.csv( values$qcData, as.character(fname$datapath), row.names=F )
  })

  observeEvent(input$t1, {
    if ( input$t1 == 1 ) {
      updateRadioButtons( session, "mask", selected=0)
      updateRadioButtons( session, "seg", selected=0)
    }
  })

  observeEvent(input$mask, {
    if ( input$t1 == 1 ) {
      updateRadioButtons( session, "mask", selected=0)
    }
  })
  observeEvent(input$seg, {
    if ( input$t1 == 1 ) {
      updateRadioButtons( session, "seg", selected=0)
    }
  })

  observeEvent(input$load, {
    print("Load QC Data")
  })

  observeEvent(input$submit, {
    if ( values$id != "NA") {
      print(paste("submitted",values$id,values$date,input$t1))

      row = data.frame(INDDID=values$id,
        Timepoint=values$date,
        Reviewer=Sys.getenv("LOGNAME"),
        T1Quality=input$t1,
        ExtractQuality=input$mask,
        SegmentationQuality=input$seg,
        Movement=as.character(as.integer(input$motion)),
        Notes=input$notes )

      values$qcData = rbind(row, values$qcData)
      print(values$qcData)


      if ( !is.null(values$subjects) ) {
        nSubs = dim(values$subjects)[1]
        values$id = values$subjects$ID[1]
        values$date = values$subjects$Date[1]
        if (nSubs > 1) {
          values$subjects = values$subjects[2:nSubs,]
        }
        else {
          values$subjects = NULL
        }
      }
      else {
        values$id = "NA"
        values$date = "NA"
      }

      updateRadioButtons(session, "t1", selected=1)
      updateRadioButtons(session, "mask", selected=0)
      updateRadioButtons(session, "seg", selected=0)
      updateTextInput(session, "notes", value="")

      psCall = paste(sep="", 'ps | grep "', values$snap, '"| grep -v grep')
      print(psCall)
      inf = system(psCall,intern=T)
      if (length(inf) > 0 ) {
        killid = get_kill_id(inf)
        system(paste("kill",killid))
      }

      if (values$id != "NA") {
        values$snap = load_subject(values$id, values$date, input$path)
      }


    }
  })

  #values$subjects = {
  #  req(input$file1)
  #  df = read.csv(input$file1$datapath, sep="/", header=F )
  #  names(df) = c("ID", "Date")
  #  return(df)
  #}

  #output$contents = renderTable( {
  #  req(values$subjects)
  #  return(values$subjects)
  #})

  output$text1 = renderText({paste("ID:",values$id,"Date:",values$date)})

  output

  output$qc = renderTable({
    req(values$qcData)
    return(values$qcData)
  })

  output$contents <- renderTable({
    print("output$contents update")
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.

    req(input$file1)

    if ( !values$loaded  ) {
      df <- read.csv(input$file1$datapath,
               sep = "/",
               header = FALSE )
      names(df) = c("ID", "Date")
      values$id = df$ID[1]
      values$date = df$Date[1]
      values$loaded = 1

      values$snap = load_subject( values$id, values$date, input$path)
      values$subjects = df[-1,]
    }
    df = values$subjects
    return(df)

  })

}
# Run the app ----
shinyApp(ui, server)
