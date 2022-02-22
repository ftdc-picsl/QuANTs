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
my @antsmats = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_TemplateToSubject1GenericAffine.mat>;
my $tx4 = $antsmats[0];

my @antswarps = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_TemplateToSubject0Warp.nii.gz>;
my $tx3 = $antswarps[0];

my $tx2 = "[ /data/grossman/pipedream2018/templates/OASIS/MNI152/T_template0_ToMNI1520GenericAffine.mat, 1]";
my $tx1 = "/data/grossman/pipedream2018/templates/OASIS/MNI152/T_template0_ToMNI1521InverseWarp.nii.gz ";

my @segs = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_BrainSegmentation.nii.gz>;
my $seg = $segs[0];

my $localOutputDirectory = "${directory}/${id}/${timeStamp}/stats";

my $runIt=1;
if( ! -d $localOutputDirectory )
  {
  mkpath( $localOutputDirectory );
  }

my $commandFile = "${localOutputDirectory}/antsME.sh";
my $outFile = "${localOutputDirectory}/${id}_${timeStamp}_midevel.csv";

if ( -f ${outFile} ) {
  if ( ! $force ) {
    die("Output file ${outFile} already exists, rerun with '--force 1' to overwrite existing output");
    $runIt = 0;
  }
}

my $tempMask = "${localOutputDirectory}/${id}_${timeStamp}_midEvel.nii.gz";

if ( $runIt ) {

  print "$commandFile\n";

  open( FILE, ">${commandFile}" );
  print FILE "#!/bin/bash\n\n";

  print FILE "export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1\n";
  print FILE "export R_LIBS=\"\"\n";
  print FILE "export R_LIBS_USER=\"\"";
  print FILE "\n";

  my @antsCommands = ();
  $antsCommands[0] = "antsApplyTransforms -v 1 -d 3 -i /data/grossman/master_templates/labels/MidEveL/MidEveL_MNI152.nii.gz -r $seg -o $tempMask -n MultiLabel -t $tx4 -t $tx3 -t $tx2 -t $tx1";
  $antsCommands[1] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
  $antsCommands[2] = "   -l $tempMask \\";
  $antsCommands[3] = "   -o ${outFile} -a FALSE -s midevel\\";
  $antsCommands[4] = "   -i $id -t $timeStamp";

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
    system( "qsub -binding linear:1 -pe unihost 1 -o ${localOutputDirectory}/${id}_${timeStamp}_me.stdout -e ${localOutputDirectory}/${id}_${timeStamp}_me.stderr $commandFile" );
  }
  else {
    system("sh $commandFile");
  }

  #print("\n");
  sleep(1);
  }
