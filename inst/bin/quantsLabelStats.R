library("optparse")
library("QuANTs")

option_list = list(
  #make_option(c("-d", "--directory"), type="character", default=NULL,
  #            help="directory with a subject's JLF output", metavar="character"),
  make_option(c("-i", "--id"), type="character", default=NA,
              help="subject ID", metavar="ID"),
  make_option(c("-t", "--time"), type="character", default=NA,
              help="timestamp for data", metavar="yyyy_mm_dd_time"),
  make_option(c("-c", "--cortical"), type="logical", default=NA,
              help="only examine non-cortical labels(=FALSE), only examine cortical(=TRUE)", metavar="logical"),
  make_option(c("-l", "--labels"), type="character", default=NULL,
              help="filename of labeled image", metavar="ScalarImage.nii.gz"),
  make_option(c("-m", "--mask"), type="character", default=NA,
              help="filename of an image to mask the labels", metavar="MaskImage.nii.gz"),
  make_option(c("-n", "--name"), type="character", default=NA,
              help="name of measure in --image", metavar="thickness"),
  make_option(c("-x", "--maskvalue"), type="numeric", default=1,
              help="value in mask image to use", metavar="1"),
  make_option(c("-a", "--image"), type="character", default=NULL,
              help="filename of labeled image", metavar="Labels.nii.gz"),
  make_option(c("-o", "--out"), type="character", default="out.csv",
              help="output file name [default= %default]", metavar="out.csv"),
  make_option(c("-s", "--system"), type="character", default="mindboggle",
              help="labeling system name (or .csv file) [default= %default]", metavar="mindboggle")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

# Check for valid inputs
if (is.null(opt$labels)){
  print_help(opt_parser)
  stop("A labeled image must be supplied", call.=FALSE)
}
if (!file.exists(opt$labels)) {
  stop("Labeled file does not exit")
}

if ( is.na(opt$id) ) {
  stop("Must provide an ID")
}
if ( is.na(opt$time) ) {
  stop("Must provide a timestamp")
}


print(opt)

sys = NA
if ( file.exists(opt$system ) ) {
  sys = read.csv(opt$system)
} else {
  sys = getLabelSystem(opt$system)
}

mask=NULL
if ( file.exists(opt$mask) ) {
  mask = antsImageRead(opt$mask)
  mask[ mask != opt$maskvalue ] = 0
  mask[ mask != 0 ] = 1
}

if ( !is.na(opt$cortical) ) {
  if ( opt$cortical ) {
    print("Cortical labels only")
    sys=sys[sys$cortex==1,]
  }
  else {
    print("Non-cortical labels only")
    sys=sys[sys$cortex==0,]
  }
}


# Get volumes
labelImg = antsImageRead(opt$labels)
dat = subjectLabelStats(labelImg, image=opt$image, mask, labelSet=sys$number, measure=opt$name, labelSystem=opt$system)

n = dim(dat)[1]
dat = data.frame(id=rep(opt$id,n), time=rep(opt$time,n), dat )

print(dat)
write.csv(dat, opt$out, row.names=F)
