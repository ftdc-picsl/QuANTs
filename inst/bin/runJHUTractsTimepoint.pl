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
my $dtdirectory="/data/grossman/pipedream2018/crossSectional/dti";

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

my $commandFile = "${localOutputDirectory}/antsJHULabels.sh";
my $outFile = "${localOutputDirectory}/${id}_${timeStamp}_jhuLabels.csv";

my $fa = <${dtdirectory}/${id}/${timeStamp}/dtNorm/${id}_${timeStamp}_FANormalizedToStructural.nii.gz>;
my $md = <${dtdirectory}/${id}/${timeStamp}/dtNorm/${id}_${timeStamp}_MDNormalizedToStructural.nii.gz>;
my $rd = <${dtdirectory}/${id}/${timeStamp}/dtNorm/${id}_${timeStamp}_RDNormalizedToStructural.nii.gz>;
my $ad = <${dtdirectory}/${id}/${timeStamp}/dtNorm/${id}_${timeStamp}_ADNormalizedToStructural.nii.gz>;

if ( -f ${outFile} ) {
  if ( ! $force ) {
    die("Output file ${outFile} already exists, rerun with '--force 1' to overwrite existing output");
    $runIt = 0;
  }
}

if ( ! -f ${fa} ) {
  die("No DTI data found for ${id} ${timeStamp}");
  $runIt=0;
}

my $labels = "${localOutputDirectory}/${id}_${timeStamp}_jhuLabels.nii.gz";
my $tempMask = "${localOutputDirectory}/${id}_${timeStamp}_jhuMask.nii.gz";

if ( $runIt ) {

  print "$commandFile\n";

  open( FILE, ">${commandFile}" );
  print FILE "#!/bin/bash\n\n";

  print FILE "export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1\n";
  print FILE "export R_LIBS=\"\"\n";
  print FILE "export R_LIBS_USER=\"\"";
  print FILE "\n";

  my $idx = 0
  @thresholds = (0,25,50)
  foreach $thresh ( @threshold ) {

    my @antsCommands = ();
    $antsCommands[$idx++] = "antsApplyTransforms -v 1 -d 3 -i /data/grossman/pipedream2018/templates/OASIS/labels/JHU_ICBM/JHU-ICBM-tracts-maxprob-thr${thresh}-1mm.nii.gz -r $seg -o $labels -n GenericLabel -t $tx4 -t $tx3 -t $tx2 -t $tx1";
    $antsCommands[$idx++] = "ThresholdImage 3 $seg $tempMask 3 7";

    $antsCommands[$idx++] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
    $antsCommands[$idx++] = "   -l $labels -g $fa -n FA -m $tempMask -x 1 \\";
    $antsCommands[$idx++] = "   -o ${outFile} -a FALSE -s jhuTracts${thresh}\\";
    $antsCommands[$idx++] = "   -i $id -t $timeStamp";

    $antsCommands[$idx++] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
    $antsCommands[$idx++] = "   -l $tempMask -g $ad -n AD -m $tempMask -x 1 \\";
    $antsCommands[$idx++] = "   -o ${outFile} -a TRUE -s jhuTracts${thresh}\\";
    $antsCommands[$idx++] = "   -i $id -t $timeStamp -v FALSE";

    $antsCommands[$idx++] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
    $antsCommands[$idx++] = "   -l $tempMask -g $rd -n RD -m $tempMask -x 1 \\";
    $antsCommands[$idx++] = "   -o ${outFile} -a TRUE -s jhuTracts${thresh}\\";
    $antsCommands[$idx++] = "   -i $id -t $timeStamp -v FALSE";

    $antsCommands[$idx++] = "/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/Rscript /data/grossman/pipedream2018/bin/QuANTs/inst/bin/quantsLabelStats.R \\";
    $antsCommands[$idx++] = "   -l $tempMask -g $md -n MD -m $tempMask -x 1 \\";
    $antsCommands[$idx++] = "   -o ${outFile} -a TRUE -s jhuTracts${thresh}\\";
    $antsCommands[$idx++] = "   -i $id -t $timeStamp -v FALSE";
  }

  #print( "@antsCommands\n");

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
    #system( "qsub -binding linear:1 -pe unihost 1 -o ${localOutputDirectory}/${id}_${timeStamp}_jhutracts.stdout -e ${localOutputDirectory}/${id}_${timeStamp}_jhutracts.stderr $commandFile" );
  }
  else {
    #system("sh $commandFile");
  }

  #print("\n");
  sleep(1);
  }
