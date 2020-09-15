lausanne250ImageToPathology = function( img ) {

  oImg = img*0
  for ( l in 1:length(lausanne250Labels$number) ) {
    if ( lausanne250Labels$PathologyLabel[l] > 0 ) {
      idx = which( img==lausanne250Labels$number[l] )
      if ( length(idx) > 0 ) {
        oImg[idx] = lausanne250Labels$PathologyLabel[l]
      }
    }
  }

  return(oImg)
}
