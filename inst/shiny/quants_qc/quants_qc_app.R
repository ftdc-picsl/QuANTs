library(shiny)
library(shinyFiles)
library(shinyWidgets)
#source("directoryInput.R")



defaultPath="/data/grossman/pipedream2018/crossSectional/antsct"

load_subject = function( id, date, path ) {
    print("load_subject")
    subpath = paste(sep="/", path, id, date )
    t1 = list.files(path=subpath, pattern=glob2rx("*t1Head.nii.gz"), full.names=T)
    #t1 = list.files(path=subpath,  pattern=glob2rx("*BrainSegmentation0N4.nii.gz"), full.names=T)
    seg = list.files(path=subpath, pattern=glob2rx("*BrainSegmentation.nii.gz"), full.names=T)
    snapCall = paste("/share/apps/itksnap/itksnap-most-recent/bin/itksnap -g",t1,"-s",seg)
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

      fluidRow( column(12,h5("Path to base directory of ACT output") )),
      fluidRow(
        column(2, div(style="padding: 0px 0px;", shinyDirButton("path", "Browse...", "ACT"))),
        column(10, div(style="padding: 0px 0px; margin-left:-5px", verbatimTextOutput("path")))),

      # Input: Select a file ----
      #fileInput("file1", "Choose subject list",
      #          multiple = TRUE,
      #          accept = c("text/csv",
      #                   "text/comma-separated-values,text/plain",
      #                   ".csv")),

      #fileInput("load", "Load a QC file", multiple = TRUE,
      #          accept = c("text/csv",
      #                     "text/comma-separated-values,text/plain",
      #                     ".csv")),
      fluidRow(
        column(4, shinyFilesButton('loadsubs', 'Load Subjects File', 'load file...', multiple=FALSE)),
        column(4, shinyFilesButton('load', 'Load QC File', 'load file...', multiple=FALSE))
      ),

      tags$hr(),

      actionButton("start", "Start reviewing"),

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

      fluidRow(
        column(8, actionButton("submit", "Submit this subject")),
        column(4, actionButton("undo", "Undo last submit"))
      ),
      #actionButton("submit", "Submit this subject"),

      tags$hr(),

      actionButton("exit", "Exit"),

      tableOutput("contents")
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      fluidRow(
        column(2, div(style="padding: 0px 0px;", shinySaveButton('save', 'Save file', 'Save file as...', filetype=list(csv='csv')))),
        column(10, div(style="padding: 0px 0px; margin-left:-5px", verbatimTextOutput("savefile")))),


      #verbatimTextOutput('savefile'),
      tableOutput("qc")

    )

  )
)

# Define server logic to read selected file ----
server <- function(input, output, session) {

  roots = c(wd='/')
  #shinyFileChoose(input, 'files', session=session, roots=roots, filetypes=c('', 'txt'))

  options(DT.options = list(pageLength = 25))
  values = reactiveValues(subjects=NULL,id="NA", date="NA", loaded=0, qcData=NULL, snap=NULL,
                          path=defaultPath, save="NA", subfile=NULL, lastID=NA, lastDate=NA, lastTimestamp=NA)

  observeEvent(input$start, {
    print("start reviewing")
    req(values$subjects)

    nSubs = dim(values$subjects)[1]
    values$id = values$subjects$ID[1]
    values$date = values$subjects$Date[1]
    if (nSubs > 1) {
      values$subjects = values$subjects[2:nSubs,]
    }
    else {
      values$subjects = NULL
    }

    if (values$id != "NA") {
      values$snap = load_subject(values$id, values$date, values$path)
    }

  })

  shinyFileChoose(input, 'loadsubs', roots=roots, session=session, filetypes=c('txt', 'csv') )
  observeEvent( input$loadsubs, {
    print("input$load subjects called")
    fname = parseFilePaths(roots, input$loadsubs)
    print( fname )

    df <- read.csv(as.character(fname$datapath), sep = "/", header = FALSE )
    names(df) = c("ID", "Date")

    if ( !is.null(values$qcData) ) {
        subList = paste(df$ID, df$Date)
        datList = paste(values$qcData$INDDID, values$qcData$Timepoint)
        df = df[!(subList %in% datList), ]
    }

    values$subjects = df
    values$loaded = 1

  })

  shinyFileChoose(input, 'load', roots=roots, session=session, filetypes=c('', 'csv') )
  observeEvent( input$load, {
    print( "input$load QC event called" )
    fname = parseFilePaths(roots, input$load)
    print( fname$datapath )

    loadData = read.csv(as.character(fname$datapath))
    print(names(loadData))
    print(loadData)

    values$qcData = rbind(values$qcData, loadData)

    values$save = as.character(fname$datapath)

    # check againts subjects list
    print(values$subjects)

    subList = paste(values$subjects$ID, values$subjects$Date)

    datList = paste(values$qcData$INDDID, values$qcData$Timepoint)

    #print( subList %in% datList )
    values$subjects = values$subjects[!(subList %in% datList), ]

  })

  shinyFileSave(input, 'save', roots=roots, session=session, restrictions=system.file(package='base'))
  observeEvent( input$save, {
    print("input$save called")
    fname=parseSavePath(roots, input$save)
    print(fname)
    print(fname$datapath)
    values$save = as.character(fname$datapath)
    write.csv( values$qcData, values$save, row.names=F )
  })
  output$savefile = renderText((values$save))

  shinyDirChoose(input, "path", roots=roots)
  observeEvent(input$path, {
    print("Choose ACT path")
    values$path = parseDirPath(roots, input$path)
  })
  output$path = renderText({values$path})


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

  #observeEvent(input$load, {
  #  print("Load QC Data")
  #})

  observeEvent(input$submit, {
    if ( values$id != "NA") {
      print(paste("submitted",values$id,values$date,input$t1))

      notes = input$notes
      notes = gsub( '"', "'", input$notes)
      sTime = as.character(Sys.time())

      values$lastID = values$id
      values$lastdate = values$date
      values$lastTimestamp = sTime

      row = data.frame(INDDID=as.character(values$id),
        Timepoint=as.character(values$date),
        Reviewer=Sys.getenv("LOGNAME"),
        T1Quality=as.character(as.integer(input$t1)),
        ExtractQuality=as.character(as.integer(input$mask)),
        SegmentationQuality=as.character(as.integer(input$seg)),
        Movement=as.character(as.integer(input$motion)),
        Artefact=as.character(as.integer(input$artefact)),
        Timestamp=sTime,
        Notes=notes )

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

      if (values$save != "NA") {
        print("Save submission")
        write.csv(row.names=F, values$qcData, values$save)
      }

      #psCall = paste(sep="", 'ps | grep "', values$snap, '"| grep -v grep')
      #print(psCall)
      #inf = system(psCall,intern=T)
      #if (length(inf) > 0 ) {
      #  killid = get_kill_id(inf)
      #  system(paste("kill",killid))
      #}

      if (values$id != "NA") {
        values$snap = load_subject(values$id, values$date, values$path)
      }


    }
  })


  observeEvent(input$undo, {
    if (!is.null(values$qcData) ) {
      nRows = dim(values$qcData)[1]
      undoId = values$qcData$INDDID[1]
      undoDate = values$qcData$Timepoint[1]
      undoStamp = values$qcData$Timestamp[1]

      if (nRows == 1) {
        values$qcData = NULL
      }
      else {
        values$qcData = values$qcData[2:nRows,]
      }

      if (values$save != "NA") {
        print( paste("remove:", undoId, undoDate, undoStamp))
        odat = read.csv(values$save)
        idx = which( ((odat$INDDID==undoId) * (odat$Timepoint==undoDate) * (odat$Timestamp==undoStamp))==1 )
        odat = odat[-idx,]
        write.csv(row.names=F, odat, values$save)
      }

      values$subjects = rbind( data.frame(ID=values$id, Date=values$date), values$subjects )
      values$id = undoId
      values$date = undoDate
      values$snap = load_subject(values$id, values$date, values$path)

    }

  })

  observeEvent(input$exit, {
    confirmSweetAlert(session=session,
      inputId="quants_qc_exit",
      type="warning",
      title="Do you want to exit?",
      danger_mode=TRUE,
      btn_labels = c("Cancel", "Exit") )
  })

  observeEvent(input$quants_qc_exit, {
    if ( input$quants_qc_exit ) {
        stopApp()
    }
  })

  output$text1 = renderText({paste("ID:",values$id,"Date:",values$date)})

  output$qc = renderTable({
    req(values$qcData)
    return(values$qcData)
  })

  output$contents <- renderTable({
    print("output$contents update")
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.

    req(values$subjects)

    if ( !values$loaded  ) {
      df <- read.csv(input$file1$datapath,
               sep = "/",
               header = FALSE )
      names(df) = c("ID", "Date")

      #values$id = df$ID[1]
      #values$date = df$Date[1]
      values$loaded = 1

      #values$snap = load_subject( values$id, values$date, values$path)
      #values$subjects = df[-1,]
      values$subjects = df
    }
    df = values$subjects
    return(df)

  })

}
# Run the app ----
shinyApp(ui, server)
