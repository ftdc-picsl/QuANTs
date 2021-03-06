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

      #print "\nSubjectID: $id\n";
      #print "Time:      $timeStamp\n";

      my @t1s = <${baseDirectory}/${id}/${timeStamp}/${id}_${timeStamp}_t1Head.nii.gz>;

      my $localOutputDirectory = "${baseDirectory}/${id}/${timeStamp}/stats";
      my $runIt=0;

      if( ! -d $localOutputDirectory )
        {
        mkpath( $localOutputDirectory );
        $runIt = 1;
        }


      my $commandFile = "${localOutputDirectory}/antsQC.sh";

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
        $antsCommands[1] = "   -d ${baseDirectory}/${id}/${timeStamp}/ \\";
        $antsCommands[2] = "   -o ${localOutputDirectory}/${id}_${timeStamp}_qc.csv \\";
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

        #system("sh $commandFile");

        system( "qsub -binding linear:1 -pe unihost 1 -o ${localOutputDirectory}/${id}_${timeStamp}_qc.stdout -e ${localOutputDirectory}/${id}_${timeStamp}_qc.stderr $commandFile" );
        #print("\n");
        sleep(1);
        }
      }
    }
  }
