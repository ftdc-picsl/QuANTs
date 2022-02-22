#!/usr/bin/perl -w

# use module
use Data::Dumper;
use Cwd 'realpath';
use Cwd;
use File::Spec;
use File::Find;
use File::Basename;
use File::Path;
use Getopt::Long;

my $submitToQueue=1;
my $force=0;
my $directory="/data/grossman/pipedream2018/crossSectional/antsct";

my $usage = qq{

  $0
      --subject

      --timepoint

      --system-definition

      --system-name

      --labels

      --image

      --mask

      --mask-values

      [ options ]

  Required args:

  --subject
     Subject ID

  --timepoint
     Timepoint to process

  --system-definition
     .csv file defining the labeling system. must have the following columns (extra columns will be ignored)
     number - number used for a given label
     name - name of the structure

  --labels
      image of labels

  --image
     image to measure values in (e.g. cortical thickness, FA, etc)


  Options:

   --mask
     mask or segmentation image for masking out parts of the image

  --mask-values
     only measure values in the image, for voxels that have these values in the in mask image

   --directory
       Base directory for processed data (default = $directory).

   --qsub
     Submit processing jobs to qsub (default = $submitToQueue).

   --force
     Overwrite existing output file if it is already there (default = $force).

  Output:

    Creates an output summary file: <directory>/<subject>/<timepoint>/stats/<subject>_<timepoint>_mindboggle.csv

};

if ($#ARGV < 0) {
    print $usage;
    exit 1;
}

my $id= "";
my $timeStamp = "";
my $mask= "";
my $labels = "";
my $sysdef = "";
my $sysname = "";
my $output = "";
my $valueName = "";
my @maskValues = ();

GetOptions ("directory=s" => \$directory,
    "subject=s" => \$id,
	  "timepoint=s" => \$timeStamp,
    "system-definition=s" => \$sysdef,
    "labels=s" => \$labels,
    "image=s" => \$image,
    "value-name=s" => \$valueName,
    "mask=s" => \$mask,
    "mask-value=s" => \@maskValues,
	  "qsub=i" => \$submitToQueue,
    "output=s" => \$output,
    "force=i" => \$force
    )
    or die("Error in command line arguments\n");


# get output directory name
my($oname,$opath) = fileparse($output, ".csv");

my $runIt=1;
if( ! -d $opath )
  {
  mkpath( $opath );
  }

my $commandFile = "${opath}/${oname}.sh";
my $outFile = "${output}";

if ( -f ${outFile} ) {
  if ( ! $force ) {
    die("Output file ${outFile} already exists, rerun with '--force 1' to overwrite existing output");
    $runIt = 0;
  }
}

my $maskValuesString = "";

if ( scalar(@maskValues) > 0 ) {
  $maskValuesString = "-x ".join( ",", @maskValues);
}

if ( $runIt ) {

  print "$commandFile\n";

  open( FILE, ">${commandFile}" );
  print FILE "#!/bin/bash\n\n";

  print FILE "export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1\n";
  print FILE "export R_LIBS=\"\"\n";
  print FILE "export R_LIBS_USER=\"\"";
  print FILE "\n";

  my @antsCommands = ();
  $antsCommands[0] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
  $antsCommands[1] = "   -l $labels -m $mask $maskValuesString -g $image -n $valueName \\";
  $antsCommands[2] = "   -o ${output} -a FALSE \\";
  $antsCommands[3] = "   -i $id -t $timeStamp -s $sysdef";

  print( "@antsCommands\n");

  for( my $k = 0; $k < @antsCommands; $k++ )
    {
    if( $k < @antsCommands )
      {
      print FILE "$antsCommands[$k]\n";
      }
    }
  print FILE "\n";
  close( FILE );
  system("chmod ug+wx $commandFile");

  if ( $submitToQueue == 1 ) {
    system( "qsub -binding linear:1 -pe unihost 1 -o ${opath}/${oname}.stdout -e ${opath}/${oname}.stderr $commandFile" );
  }
  else {
    system("sh $commandFile");
  }

  #print("\n");
  sleep(1);
  }
