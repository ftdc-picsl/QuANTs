#!/usr/bin/perl -w

##
## sample usage:  perl runQC.pl /out/put/dir/
##
##


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

    See runQCTimepoint.pl for details of output. This script is a wrapper that sets up I/O and logs for running processScanDTI.pl.

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

my @t1s = <${directory}/${id}/${timeStamp}/${id}_${timeStamp}_t1Head.nii.gz>;

my $localOutputDirectory = "${directory}/${id}/${timeStamp}/stats";

my $runIt=1;
if( ! -d $localOutputDirectory )
  {
  mkpath( $localOutputDirectory );
  }

my $commandFile = "${localOutputDirectory}/antsQC.sh";
my $outFile = "${localOutputDirectory}/${id}_${timeStamp}_qc.csv";

if ( -f ${outFile} ) {
  if ( ! $force ) {
    die("Output file ${outFile} already exists, rerun with '--force 1' to overwrite existing output");
    $runIt = 0;
  }
}

if ( $runIt ) {

  print "$commandFile\n";

  open( FILE, ">${commandFile}" );
  print FILE "#!/bin/bash\n\n";

  print FILE "export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1\n";
  print FILE "export R_LIBS=\"\"";
  print FILE "export R_LIBS_USER=\"\"";
  print FILE "\n";

  my @antsCommands = ();
  $antsCommands[0] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsANTsCTSummary.R \\";
  $antsCommands[1] = "   -d ${directory}/${id}/${timeStamp}/ \\";
  $antsCommands[2] = "   -o ${outFile} \\";
  $antsCommands[3] = "   -s $timeStamp \\";
  $antsCommands[4] = "   -t $t1s[0]";

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
  system("chmod ug+x $commandFile");

  if ( $submitToQueue == 1 ) {
    system( "qsub -binding linear:1 -pe unihost 1 -o ${localOutputDirectory}/${id}_${timeStamp}_qc.stdout -e ${localOutputDirectory}/${id}_${timeStamp}_qc.stderr $commandFile" );
  }
  else {
    system( "sh $commandFile");
  }
  #print("\n");
  sleep(1);
  }
