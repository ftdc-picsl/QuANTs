library("optparse")
library("QuANTs")

option_list = list(
  make_option(c("-d", "--directory"), type="character", default=NA,
              help="directory with a subject's ACT output", metavar="character"),
  make_option(c("-t", "--t1"), type="character", default=NA,
              help="raw T1 filename", metavar="T1.nii.gz"),
  make_option(c("-s", "--timestamp"), type="character", default=NA,
              help="time stamp of data acquisition", metavar="YYYYMMDD"),
  make_option(c("-o", "--out"), type="character", default="out.csv",
              help="output file name [default= %default]", metavar="out.csv")

)

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
print(opt)

if (is.na(opt$directory) ) {
  stop("Must provide a directory")
}

arr = strsplit(opt$directory, "/")[[1]]
id = arr[length(arr)-1]

date = arr[length(arr)]
if ( !is.na(opt$timestamp) ) {
  date = opt$timestamp
}

mask = list.files(path=opt$directory, pattern=glob2rx("*BrainExtractionMask.nii.gz"), full.names=T)
seg = list.files(path=opt$directory, pattern=glob2rx("*BrainSegmentation.nii.gz"), full.names=T)
thk = list.files(path=opt$directory, pattern=glob2rx("*CorticalThickness.nii.gz"), full.names=T)
n4 = list.files(path=opt$directory, pattern=glob2rx("*BrainSegmentation0N4.nii.gz"), full.names=T)
gmp = list.files(path=opt$directory, pattern=glob2rx("*BrainSegmentationPosteriors2.nii.gz"),full.names=T)

if ( length(mask) < 1 ) {
  stop("Brain extraction mask not found")
} else if ( length(seg) < 1 ) {
  stop("Brain segmentation image not found")
} else if ( length(thk) < 1) {
  stop("Cortical thickness image not found")
} else if ( length(n4) < 1 ) {
  stop("N4 image not found")
} else if ( length(gmp) < 1 ) {
  stop("GMP image not found")
}

if ( !file.exists(opt$t1) )
 {
   stop("T1 image not found")
 }


maskImg = antsImageRead(mask[1])
segImg = antsImageRead(seg[1])
thkImg = antsImageRead(thk[1])
n4Img = antsImageRead(n4[1])
t1Img = antsImageRead(opt$t1)
gmpImg = antsImageRead(gmp[1])

# Brain volume
bdat = subjectLabelStats(maskImg, labelSystem="brain")

# Tisse volumes - ignore cortex since we will mask that by thickness values
dat = subjectLabelStats(segImg, labelSystem="antsct", labelSet=c(1,3,4,5,6) )

# T1 intensity
datt1 = subjectLabelStats(segImg, image=t1Img, measure="T1_intensity", labelSystem="antsct", include.volume=F )

# N4 corrected intensity
datn4 = subjectLabelStats(segImg, image=n4Img, measure="N4_intensity", labelSystem="antsct", include.volume=F )

mask2 = maskImg*1
mask2[segImg != 2 ] = 0
mask2[ thkImg <= 0 ] = 0
mask2[ mask2 > 0] = 1

# Cortical thickness
dat2 = subjectLabelStats(segImg, mask=mask2, image=thkImg, labelSet=c(2), measure="thickness", labelSystem="antsct", include.volume=T)

# GMP
datGMP = subjectLabelStats(segImg, mask=mask2, image=gmpImg, labelSet=c(2), measure="gmp", labelSystem="antsct", include.volume=F)

dat = rbind(bdat, dat, dat2, datn4, datt1, datGMP)
dat = data.frame(id=id, date=date, dat )

#print(dat)

write.csv(dat, opt$out, row.names=F)
