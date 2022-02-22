quantsWScore = function( controlData, subjectData, target, predictors ) {

  model = paste(target, "~", predictors)
  controlModel = lm( as.formula(model), controlData)
  wscoreDenom = sd(resid(controlModel))

  wScore = (subjectData[target] - predict(controlMod, subjectData))/wscoreDenom
  return(wScore)
  
}
