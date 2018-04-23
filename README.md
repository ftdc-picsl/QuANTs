# QuANTs
Quality control, quantifying regional values, and querying of ANTs output

# Output files
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
Purpose: Summarize various useful quantities from output of antsCorticalThickness
Usage: RScript quantsANTsCTSummary.R -d outpath -t inpath/t1.nii.gz -o outpath/stats/out.csv

| option | flag | longflag | description |
| --- | --- | --- | --- |
| directory | -d | --directory | full path name of directory where a single subject's antsCorticalThickness output is located |
| T1-image | -t | --t1 | full path to image used as input for antsCorticalThickness |
| output file | -o | --output | full path name of file to store output (preferred location is in 'stats' subdirectory of ACT output directory) |

The output file includes:

| system | measure | metric | description |
| ---  | --- | --- | --- |
| brain | volume | numeric | defined via binary brain extraction mask |
| antsct | volume | numeric | defined via brain segmentation image |
| antsct | thickness | mean, median, sd, max, min, q1, q3 | defined via cortical thickness image and cortex from brain segmentation |
| antsct | T1_intentisty | mean, median, sd, max, min, q1, q3 | defined via original T1 image and brain segmentation |
| antsct | N4_intentisty | mean, median, sd, max, min, q1, q3 | defined via brain segmentation bias corrected image and brain segmentation |
