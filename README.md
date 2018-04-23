# QuANTs
Quality control, quantifying regional values, and querying of ANTs output.
There are three main components to QuANTs.

1. Label system definitions that define the relationship between labels and anatomy
2. Rscripts used to generate .csv files to summarize measures using label systems
3. R functions used to query to data stored in the .csv files

# Labeling systems
Currently, there are four different labeling systems supported by QuANTS

* brain (mask) - a single binary mask indicating brain (=1) or background (=0)
* antsct - the brain segmentation provided by antsCorticalThickness (ACT)
  0. Background
  1. CSF
  2. Cortex
  3. White matter
  4. Deep gray
  5. Brain stem
  6. Cerebellum
* mindboggle
* mideval

# Generating summary .csv files
All generated .csv files store data in "long" format, where each
row describes and records a single value. The columns are as follows:

| column name | description |
| --- | --- |
| id | subject ID |
| date | timestamp indicating when images were acquired |
| system | name of labeling system used for this measure ( brain, antsct, mindboggle, etc ) |
| label | label number |
| measure | what is being measured ( volume, thickness, FA, etc) |
| metric | how is measure summarized ( numeric, mean, max, etc) |
| value | the value of interest |

All scripts for generating the .csv files are stored in inst/bin so that they
are accessible after installation. These scripts include:

## quantsANTsCTSummary.R
Purpose: Summarize various useful quantities from output of ACT

Usage: RScript quantsANTsCTSummary.R -d outpath -t inpath/t1.nii.gz -o outpath/stats/out.csv

| option | flag | longflag | description |
| --- | --- | --- | --- |
| directory | -d | --directory | full path name of directory where a single subject's ACT output is located |
| T1-image | -t | --t1 | full path to image used as input for ACT |
| output file | -o | --output | full path name of file to store output (preferred location is in 'stats' subdirectory of ACT output directory) |

The output file includes:

| system | measure | metric | description |
| ---  | --- | --- | --- |
| brain | volume | numeric | defined via binary brain extraction mask |
| antsct | volume | numeric | defined via brain segmentation image |
| antsct | thickness | mean, median, sd, max, min, q1, q3 | defined via cortical thickness image and cortex from brain segmentation |
| antsct | T1_intensity | mean, median, sd, max, min, q1, q3 | defined via original T1 image and brain segmentation |
| antsct | N4_intensity | mean, median, sd, max, min, q1, q3 | defined via brain segmentation bias corrected image and brain segmentation |

Examples: Here we assume input is stored in /path/subjects/ and output is stored in /path/act/

To run in serial for a data set:

for i in \`ls /path/subjects\`; do for j in \`ls /path/subjects/$i\`; Rscript  quantsANTsCTSummary.R -d /path/act/${i}/${j} -t /path/subjects/${i}/${j}/MPRAGE/\*MPRAGE.nii.gz -o /path/act/${i}/${j}/stats/${i}_${j}_qc.csv; done; done

To run in parallel for a data set:

for i in \`ls /path/subjects\`; do for j in \`ls /path/subjects/$i\`; mkdir /path/act/${i}/${j}/stats; echo "#!/bin/bash" > /path/act/${i}/${j}/stats/${i}_{j}\_qc.sh; echo "Rscript  quantsANTsCTSummary.R -d /path/act/${i}/${j} -t /path/subjects/${i}/${j}/MPRAGE/\*MPRAGE.nii.gz -o /path/act/${i}/${j}/stats/${i}\_${j\}_qc.csv" >> /path/act/${i}/${j}/stats/${i}\_{j}\_qc.sh; qsub ${i}\_{j}\_qc.sh -o /path/act/${i}/${j}/stats/${i}\_{j}\_qc.stderr -e /path/act/${i}/${j}/stats/${i}\_{j}\_qc.stderr; done; done
