schaefer400ImageToPathology = function( img, verbose=FALSE ) {

  oImg = img*0
  for ( l in 1:length(schaefer400Labels$number) ) {
    if ( schaefer400Labels$PathologyLabel[l] > 0 ) {
      pathLabel=schaefer400Labels$PathologyLabel[l]
      schaeferLabel=schaefer400Labels$number[l]
      if ( verbose ) {
        print( paste(schaeferLabel, "->", pathLabel) )
      }

      oImg[img==schaeferLabel] = pathLabel
    }
  }

  return(oImg)
}
