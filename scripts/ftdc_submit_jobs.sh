#!/bin/bash

logging() {
  message=$1
  logfile=$2
  testing=$3

  if [ $testing -eq 0 ]; then
    echo $message >> $logfile
  else 
    echo $message
  fi
}

usage() { echo "Usage: $0 -i input_dir -o output_dir -l log_dir -f sub_ses.csv  [-q queue_name]"; exit 1; } 

file="NA"
idir="NA"
odir="NA"
ldir="NA"
queue="ftdc_normal"
test=0

qdir="/project/ftdc_misc/jtduda/quants/QuANTs/"

adir="/project/ftdc_misc/jtduda/quants/atlases/"
ddir="NA"

template="/project/ftdc_misc/pcook/quants/tpl-TustisonAging2019ANTs/template_description.json"

while getopts a:d:f:i:l:o:q:hx flag
do 
  case "${flag}" in
     a) adir=${OPTARG};;
     d) ddir=${OPTARG};; 
     f) file=${OPTARG};;
     i) idir=${OPTARG};;
     l) ldir=${OPTARG};;
     o) odir=${OPTARG};;
     q) queue=${OPTARG};;
     t) template=${OPTARG};;
     x) test=1;;
     h) usage;;
  esac
done

if [ "$ddir" == "NA" ]; then
  ddir="${qdir}/atlases"
fi

if [ "$file" == "NA" ]; then
  usage
  return 1
fi
if [ "$idir" == "NA" ]; then
  usage
  return 1
fi
if [ "$odir" == "NA" ]; then
  usage
  return 1
fi
if [ "$ldir" == "NA" ]; then
  usage
  return 1 
fi

if [[ $test -eq 1 ]]; then
  echo "Testing mode - no jobs will be created or submitted"
fi

dt=`date`
dt=${dt// /_}
dt=${dt//:/_}
log="${ldir}/quants_log_${dt}.csv"
echo "Writing to log file $log"


if [[ -f "$file" ]]; then
  for i in `cat $file`; do
    ida=$(echo $i | cut -d ',' -f1)
    id=${ida//[.]/x}
    tp=$(echo $i | cut -d ',' -f2)

    if [ -d "${idir}/sub-${id}/ses-${tp}" ]; then 
      warp="/${idir}/sub-${id}/ses-${tp}/sub-${id}_ses-${tp}_TemplateToSubject0Warp.nii.gz"  
      if [[ -f "$warp" ]]; then
        if [[ -f "${odir}/sub-${id}_ses-${tp}_quants.csv" ]]; then
          logging "$id,$tp,already_exists" $log $test
        else
          if [[ $test -eq 0 ]]; then 
            job=${ldir}/quants_job_${id}_${tp}.sh
            echo "#!/bin/bash" > $job
            echo "#BSUB -J quants_${id}_${tp}" >> $job
            echo "#BSUB -o ${ldir}/sub-${id}_ses-${tp}_quantslog.out" >> $job
            echo "#BSUB -e ${ldir}/sub-${id}_ses-${tp}_quantslog.err" >> $job
            echo "module load python/3.8" >> $job
            echo "export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1" >> $job
            echo "export MKL_NUM_THREADS=1" >> $job
            echo "export OMP_NUM_THREADS=1" >> $job
            echo "python ${qdir}/python/runFTDCDir.py  --antsct_dir=${idir}/sub-${id}/ses-${tp}/ --template=$template --atlas_dir=$ddir --atlas_images=${adir}  --output=${odir}/sub-${id}_ses-${tp}_quants.csv" >> $job

            sub=`bsub -q $queue < $job`
            logging "$id,$tp,$sub" $log $test      
          else
            logging "$id,$tp,to_run" $log $test  
          fi
        fi
      else
        logging "$id,$tp,missing_warp" $log $test
      fi
    else
      logging "${id},${tp},missing_antsct" $log $test
    fi

  done
else
  usage
fi 


