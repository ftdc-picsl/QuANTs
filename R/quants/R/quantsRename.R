#' quantsRename
#'
#' change the naming for quants columns
#'
#' @param input data.frame with column names to replace ( i.e. antsct_1_volume_numeric ) or vector of column names
#' @param renaming a data.frame with columns 'name' and 'number' or a csv filename
#' @param keep.measure append the measure name in the output name
#' @param keep.metric append the metric name in the output name
#' @param seperator character used when appending meaure and metric
quantsRename <- function( input, renaming, keep.measure=F, keep.metric=F, seperator="_" ) {

  nameVec = NA
  if ( class(input)=="data.frame" ) {
    nameVec = names(input)
  }
  if ( class(input)=="character" ) {
    nameVec = input
  }
  else {
    stop("Input type must be data.frame or character")
  }

  s = strsplit( nameVec, "_" )
  for ( i in 1:length(s) ) {
    if ( length(s[[i]])<4  ) {
      blnks = rep( NA, 4-length(s[[i]]))
      s[[i]] = c(s[[i]], blnks)
    }
  }

  df = data.frame(matrix(unlist(s), nrow=length(s), byrow=T))

  if ( length(unique(df$X1[!is.na(df$X2)])) > 1 ) {
    stop("Input must have only one labeling system")
  }

  if (class(renaming)=="character" ) {
    if (! file.exists( renaming ) ) {
      stop("Naming file not found")
    }
    renaming = read.csv(renaming)
  }
  else if ( class(renaming)=="data.frame" ) {
    naming = renaming
  }
  else {
    stop("renaming variable must be a data.frame or a filename")
  }

  if ( length(which(names(naming)=="number")) != 1 ) {
    stop("renaming must have a column named 'number' ")
  }

  if ( length(which(names(naming)=="name")) != 1 ) {
    stop("renaming must have a column named 'name' ")
  }

  n = dim(df)[1]
  df$name = rep("", n)

  for ( i in 1:n ) {
    if ( !is.na(df$X2[i]) ) {
      idx = which(naming$number == df$X2[i] )
      if ( length(idx) > 0 ) {
        df$name[i] = naming$name[ idx ]
        if ( keep.measure ) {
          df$name[i] = paste(sep=seperator, df$name[i], df$X3[i])
        }
        if ( keep.metric ) {
          df$name[i] = paste(sep=seperator, df$name[i], df$X4[i])
        }
      }
    }
    else {
      df$name[i] = as.character(df$X1[i])
    }
  }

  if ( class(input)=="character" ) {
    return( df$name )
  }

  names(input)=df$name
  return(input)



}
