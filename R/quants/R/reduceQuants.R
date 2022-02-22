#' reduceQuants
#'
#' merge values from multiple label ( e.g. merge all frontal regions )
#'
#' @param x data.frame obtained from getQuants() that contains volume and one metric/measure (e.g. mean thickness)
#' @param name what to call the reduce value
#' @param metric the metric to reduce (e.g. "mean")
#' @param measure the measure to reduce (e.g. "thickness")
reduceQuants = function( x, name, measure, metric ) {
  v = x[ x$measure=="volume",]
  th = aggregate(x$value, by=list(x$id, x$date, x$label), FUN=prod )
  th = aggregate(th$x, by=list(th$Group.1, th$Group.2), FUN=sum)
  v = aggregate( v$value, by=list(v$id, v$date), FUN=sum )
  names(v) = c("id", "date", "volume")
  names(th) = c("id", "date", "value")
  th = merge( v, th )
  th$value = th$value / th$volume

  names(th) = c("id", "date", paste(sep="_", name, "volume"), paste(sep="_", name, measure, "mean"))
  return(th)
}
