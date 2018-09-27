
makeQuants <- function(x) {
  names(x) =  c("id","date","system","label","measure","metric","value")
  return(x)
}

isQuants <- function(x) {
  return( sum(names(x) == c("id","date","system","label","measure","metric","value"))==7 )
  #return( TRUE )
}

#' getQuants
#'
#' get values of interest from pre-generated .csv files
#'
#' @param path base directory for ANTsCT output
#' @param id list of subjects to collect values for
#' @param date optional list of dates for each subject (one-to-one mapping with id list)
#' @param system labeling systems to obtain values for
#' @param label label numbers of interest
#' @param measure what measure/s to collect
#' @param metric which metric/s to collect
#' @param as.wide flag to return wide format data frame

getQuants <- function(path, id, date=NULL, system=NULL, label=NULL, measure=NULL, metric=NULL, as.wide=FALSE, rename=FALSE, with.filenames=F ) {

  # Gather names of all requested .csv files
  files = c()
  for (i in 1:length(id)) {

    subPaths=NULL
    if ( !is.null(date) ) {
      subPaths = paste(sep="", path, "/", id[i], "/", date[i] )
    }
    else {
      subPaths = list.dirs(path=paste(sep="", path, "/", id[i]), full.names=T, recursive=F)
    }

    for (d in subPaths) {
      statDir = paste(sep="", d, "/stats")
      if ( dir.exists(statDir) ) {
        subFiles = list.files(path=statDir, pattern=glob2rx("*.csv"), full.names=T)
        files = c(files, subFiles)
      }
    }

  }

  dat = NULL
  filenames = NULL
  for ( f in files ) {
    fDat = read.csv(f)

    if ( !isQuants(fDat) ) {
      fDat = makeQuants(fDat)
      #write.csv(fDat, f, row.names=F)
    }

    if ( isQuants(fDat) ) {

      idx = rep(1, dim(fDat)[1])

      if ( !is.null(system) ) {
        sysIdx = idx*0
        for ( s in system ) {
          sysIdx[fDat$system==s] = 1
        }
        idx = idx*sysIdx
      }

      if ( !is.null(label) ) {
        if ( !is.list(label) ) {
          #print("generic labels")
          labelIdx = idx*0
          for ( l in label ) {
            labelIdx[fDat$label==l] = 1
          }
          idx = idx*labelIdx
        }
        else {
          #print("system specific labels")
          fullIdx = idx*0

          for (i in 1:length(label) ) {
            systemName = NULL
            labelIdx = idx*0
            systemIdx = idx*0
            if ( !is.null(system) ) {
              systemIdx[fDat$system == system[i]] = 1
            }
            else {
              systemIdx = systemIdx+1
            }

            for ( l in label[[i]] ) {
              labelIdx[fDat$label==l] = 1
            }

            fullIdx[labelIdx*systemIdx==1] = 1
          }
          idx = idx*fullIdx
        }
      }

      if ( !is.null(measure) ) {
        measureIdx = idx*0
        for ( m in measure ) {
          measureIdx[fDat$measure==m] = 1
        }
        idx = idx*measureIdx
      }

      if ( !is.null(metric) ) {
        metricIdx = idx*0
        for ( m in metric ) {
          metricIdx[fDat$metric==m] = 1
        }
        idx = idx*metricIdx
      }

      if ( sum(idx) > 0 ) {
        fDat = fDat[idx==1,]
        filenames = c(filenames, rep(f, dim(fDat)[1]))
        dat = rbind(dat, fDat)
      }

    }
  }

  uniqFiles = unique(filenames)
  dat$file = basename(filenames)

  dat$name = paste(sep="_", dat$system,dat$label,dat$measure,dat$metric)

  if ( rename ) {
    if (length(system) > 1) {
      stop("Renaming only works when using a single labeling system")
    }

    sys = getLabelSystem(system)
    n = dim(dat)[1]
    hemi = rep(NA, n)
    anat = rep(NA, n)

    for ( i in 1:n ) {
      hemi[i] = as.character(sys$hemisphere[ which(sys$number==dat$label[i]) ])
      iAnat =  as.character(sys$name[ which(sys$number==dat$label[i]) ])
      iAnat = gsub(" ", "_", iAnat)
      anat[i] = iAnat
      dat$name[i] = paste(sep="_", hemi[i], anat[i], dat$metric[i], dat$measure[i] )
    }

  }

  if ( as.wide ) {
    dat = dcast(dat, id + date ~ name, value.var="value")
  }

  #if (with.filenames) {
  #  dat = list(data=dat, filename=uniqFiles)
  #}

  # This prevents IDs from being cast as double values
  dat$id = as.character(dat$id)

  return(dat)

}
