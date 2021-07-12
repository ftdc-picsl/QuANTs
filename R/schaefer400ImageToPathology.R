schaefer400ImageToPathology = function( img ) {

  oImg = img*0
  for ( l in 1:length(schaefer400Labels$number) ) {
    if ( schaefer400$PathologyLabel[l] > 0 ) {
      oImg[img==schaefer400Labels$number[l]] = schaefer400Labels$PathologyLabel[l]
    }
  }

  return(oImg)
}
