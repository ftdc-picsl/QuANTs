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

my ($baseDirectory) = @ARGV;

my @subjectIDs = <${baseDirectory}/*>;

for( my $d = 0; $d < @subjectIDs; $d++ )
#for( my $d = 0; $d < 1; $d++ )
{
  my $id = basename($subjectIDs[$d]);
  chomp($id);
  if ( length($id) )
  {
    my @subjectDirs = <${baseDirectory}/${id}/*>;
    #print("@subjectDirs\n");

    for ( my $s=0; $s < @subjectDirs; $s++) {

      my $dir = ${subjectDirs[$s]};
      #print("$id $dir\n");
      my $timeStamp = basename($dir);

      print "\nSubjectID: $id\n";
      print "Time:      $timeStamp\n";

      #my @t1s = <${baseDirectory}/${id}/${timeStamp}/${id}_${timeStamp}_t1Head.nii.gz>;

      my @thicks = <${baseDirectory}/${id}/${timeStamp}/${id}_${timeStamp}_CorticalThickness.nii.gz>;
      my $thick = $thicks[0];

      my @labels = <${baseDirectory}/${id}/${timeStamp}/${id}_${timeStamp}_PG_antsLabelFusionLabels.nii.gz>;
      my $label = $labels[0];

      my @segs = <${baseDirectory}/${id}/${timeStamp}/${id}_${timeStamp}_BrainSegmentation.nii.gz>;
      my $seg = $segs[0];

      my $localOutputDirectory = "${baseDirectory}/${id}/${timeStamp}/stats";
      my $runIt=1;

      my $thickMask = "${localOutputDirectory}/${id}_${timeStamp}_thickMask.nii.gz";
      my $tempMask = "${localOutputDirectory}/${id}_${timeStamp}_cortexSegMask.nii.gz";

      if( ! -d $localOutputDirectory )
        {
        mkpath( $localOutputDirectory );
        $runIt = 1;
        }

      my $commandFile = "${localOutputDirectory}/antsMB.sh";
      my $outFile = "${localOutputDirectory}/${id}_${timeStamp}_mindboggle.csv";

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

        system("chmod ug+x $commandFile");

        #system("sh $commandFile");

        system( "qsub -binding linear:1 -pe unihost 1 -o ${localOutputDirectory}/${id}_${timeStamp}_mb.stdout -e ${localOutputDirectory}/${id}_${timeStamp}_mb.stderr $commandFile" );
        #print("\n");
        sleep(1);
        }
      }
    }
  }
