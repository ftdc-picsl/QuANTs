
isQuants <- function(x) {
  return( sum(names(x) == c("id","date","system","label","measure","metric","value"))==7 )
}

getQuants <- function(path, id, date=NULL, system=NULL, label=NULL, measure=NULL, metric=NULL, as.wide=FALSE ) {

  # Gather names of all requested .csv files
  files = c()
  for (sub in id) {
    subPaths=NULL
    if ( !is.null(date) ) {
      subPaths = c(paste(sep="", path, "/", sub, "/", date ))
    }
    else {
      subPaths = list.dirs(path=paste(sep="", path, "/", sub), full.names=T)
    }

    for (d in subPaths) {
      statDir = paste(sep="", d, "/stats")
      subFiles = list.files(path=statDir, pattern=glob2rx("*.csv"), full.names=T)
      files = c(files, subFiles)
    }

  }

  dat = NULL
  for ( f in files ) {
    fDat = read.csv(f)
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
          print("generic labels")
          labelIdx = idx*0
          for ( l in label ) {
            labelIdx[fDat$label==l] = 1
          }
          idx = idx*labelIdx
        }
        else {
          print("system specific labels")
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

      fDat = fDat[idx==1,]
      dat = rbind(dat, fDat)
    }
  }

  if ( as.wide ) {
    dat$name = paste(sep="_", dat$system,dat$label,dat$measure,dat$metric)
    dat = dcast(dat, id + date ~ name, value.var="value")
  }
  return(dat)


}
