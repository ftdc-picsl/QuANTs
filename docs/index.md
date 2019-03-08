# QuANTs
There are three main components to QuANTs:

1. An R package that provides functions for obtaining summary values for images processed by the ANTs cortical thickness pipeline
2. Rscripts used to generate .csv files that summarize measures using predefined anatonical labeling systems
3. Some simple tools to help in performing QC

Here we will focus on 1, the R functions that may be used to access the data in a hopefully convenient way.

# Running it
We recommend running QuANTs on the cluster via the following:
```
export R_LIBS=""
export R_LIBS_USER=""
/data/grossman/pipedream2018/bin/R/R-3.4.3/bin/R
> library(QuANTs)
```

# Get QuANTs values for subjects of interest (in R)
The workhouse of the package is the getQuants() function. Here we'll describe its basic use and later we will discuss some helper functions that can make more complex tasks less complicated. The basic idea behind getQuants() is that allows the user to treat the output of the image processing pipeline as a database that one can query to obtain the data of interest. getQuants() attempts to fullfill the following request: "For the data stored at this **_location_**, I would like to obtain this **_summary_** of this **_measure_** in this **_anatomy_** for these **_subjects_** whose data was acquired on these **_dates_**."

First, the required parameters for any call to getQuants() are:

* path: the **_location_** of the processed data, almost always "/data/grossman/pipedream2018/crossSectional/antsct/"
* id: a list of ids for all **_subjects_** of interest

If you only include the required parameters you will get all data for all subjects at all times which is probably a lot more than what you are actually interested in. The following parameters will help you narrow down the data returned and control the format in which the date is returned.

* date: a list of **_dates_** for each id in the id-list (default is to obtain all dates for each id)
* system: the name of the labeling system used to define the **_anatomy_** (may be a list)
* label: the label numbers used by the to identify **_anatomy_** (only use this when asking for a single system)
* measure: the image **_measure_** of interest (e.g. "thickness", "volume", etc)
* metric: the **_summary_** metric (e.g. "mean", "max", etc)
* as.wide: boolean flag to return a wide-format data.frame (default is long-format)
* rename: boolean flag to return descriptive names (default is 'system_label_metric_measure')

Here are some examples, assuming a pre-defined path and id list

## To get brain volumes

brainVolumes = getQuants(path=path, id=ids, system="brain", measure="volume", as.wide=T)

## To get the volumes of the six-tissue segmentations:

tissueVolumes = getQuants(path=path, id=ids, system="antsct", measure="volume", as.wide=T)

## To get the volumes of only white matter and cortex
tissue2Volumes = getQuants(path=path, id=ids, system="antsct", measure="volume", label=c(2,3), as.wide=T)

## To get mindboggle label volumes
mbVolumes = getQuants(path=path, id=ids, system="mindboggle", measure="volume", as.wide=T)

## To get mean thickness in mindboggle labels
mbThickness = getQuants(path=path, id=ids, system="mindboggle", measure="thickness", metric="mean", as.wide=T)

## Getting thickness if left-hemisphere cortical regions


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

* mindboggle - labels generated using JLF, inludes cortical and subcortical
* mideval - a hybrid label set of subcortical gray matter structures
* jhu - a set of white matter labels

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
| antsct | volume | numeric | defined via brain segmentation image, cortex is also masked by thickness > 0 |
| antsct | thickness | mean, median, sd, max, min, q1, q3 | defined via cortical thickness image and cortex from brain segmentation |
| antsct | gmp | mean, median, sd, max, min, q1, q3 | defined with cortex segmentation and cortex posterior image |
| antsct | T1_intensity | mean, median, sd, max, min, q1, q3 | defined via original T1 image and brain segmentation |
| antsct | N4_intensity | mean, median, sd, max, min, q1, q3 | defined via brain segmentation bias corrected image and brain segmentation |

Examples: Here we assume input is stored in /path/subjects/ and output is stored in /path/act/

To run in serial for a data set:

for i in \`ls /path/subjects\`; do for j in \`ls /path/subjects/$i\`; Rscript  quantsANTsCTSummary.R -d /path/act/${i}/${j} -t /path/subjects/${i}/${j}/MPRAGE/\*MPRAGE.nii.gz -o /path/act/${i}/${j}/stats/${i}_${j}_qc.csv; done; done

To run in parallel for a data set:

for i in \`ls /path/subjects\`; do for j in \`ls /path/subjects/$i\`; mkdir /path/act/${i}/${j}/stats; echo "#!/bin/bash" > /path/act/${i}/${j}/stats/${i}_{j}\_qc.sh; echo "Rscript  quantsANTsCTSummary.R -d /path/act/${i}/${j} -t /path/subjects/${i}/${j}/MPRAGE/\*MPRAGE.nii.gz -o /path/act/${i}/${j}/stats/${i}\_${j\}_qc.csv" >> /path/act/${i}/${j}/stats/${i}\_{j}\_qc.sh; qsub /path/act/${i}/${j}/stats/${i}\_{j}\_qc.sh -o /path/act/${i}/${j}/stats/${i}\_{j}\_qc.stdout -e /path/act/${i}/${j}/stats/${i}\_{j}\_qc.stderr; done; done
