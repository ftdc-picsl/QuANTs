schaefer400ImageToPathology = function( img ) {

  oImg = img*0
  for ( l in 1:length(lausanne250Labels$number) ) {
    if ( lausanne250Labels$PathologyLabel[l] > 0 ) {
      oImg[img==lausanne250Labels$number[l]] = lausanne250Labels$PathologyLabel[l]
    }
  }

  return(oImg)
}
