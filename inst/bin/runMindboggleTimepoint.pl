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

      [ options ]

  Required args:

  --subject
     Subject ID

  --timepoint
     Timepoint to process

  Options:

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

GetOptions ("directory=s" => \$directory,
    "subject=s" => \$id,
	  "timepoint=s" => \$timeStamp,
	  "qsub=i" => \$submitToQueue,
    "force=i" => \$force
    )
    or die("Error in command line arguments\n");

#my @t1s = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_t1Head.nii.gz>;

my @thicks = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_CorticalThickness.nii.gz>;
my $thick = $thicks[0];

my @labels = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_PG_antsLabelFusionLabels.nii.gz>;
my $label = $labels[0];

my @segs = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_BrainSegmentation.nii.gz>;
my $seg = $segs[0];

my $localOutputDirectory = "${directory}/${id}/${timeStamp}/stats";

my $runIt=1;
if( ! -d $localOutputDirectory )
  {
  mkpath( $localOutputDirectory );
  }

my $commandFile = "${localOutputDirectory}/antsMB.sh";
my $outFile = "${localOutputDirectory}/${id}_${timeStamp}_mindboggle.csv";

if ( -f ${outFile} ) {
  if ( ! $force ) {
    die("Output file ${outFile} already exists, rerun with '--force 1' to overwrite existing output");
    $runIt = 0;
  }
}

my $thickMask = "${localOutputDirectory}/${id}_${timeStamp}_thickMask.nii.gz";
my $tempMask = "${localOutputDirectory}/${id}_${timeStamp}_cortexSegMask.nii.gz";

if ( $runIt ) {

  print "$commandFile\n";

  open( FILE, ">${commandFile}" );
  print FILE "#!/bin/bash\n\n";

  print FILE "export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1\n";
  print FILE "export R_LIBS=\"\"";
  print FILE "export R_LIBS_USER=\"\"";
  print FILE "\n";

  my @antsCommands = ();
  $antsCommands[0] = "ThresholdImage 3 $seg $tempMask 2 2";
  $antsCommands[1] = "ThresholdImage 3 $thick $thickMask 0.00001 inf";
  $antsCommands[2] = "ImageMath 3 $thickMask m $thickMask $tempMask";
  $antsCommands[3] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
  $antsCommands[4] = "   -l $label -c TRUE -m $thickMask -x 1 -g $thick -n thickness \\";
  $antsCommands[5] = "   -o ${outFile} -a FALSE \\";
  $antsCommands[6] = "   -i $id -t $timeStamp";
  $antsCommands[7] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
  $antsCommands[8] = "   -l $label -c FALSE \\";
  $antsCommands[9] = "   -o ${outFile} -a TRUE \\";
  $antsCommands[10] = "   -i $id -t $timeStamp";

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
  system("chmod ug+w $commandFile");

  if ( $submitToQueue == 1 ) {
    system( "qsub -binding linear:1 -pe unihost 1 -o ${localOutputDirectory}/${id}_${timeStamp}_mb.stdout -e ${localOutputDirectory}/${id}_${timeStamp}_mb.stderr $commandFile" );
  }
  else {
    system("sh $commandFile");
  }

  #print("\n");
  sleep(1);
  }
