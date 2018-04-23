# QuANTs
Summarize values from ANTs/Pipedream processed data

# Output files
All generated .csv files store data in "long" format, where each
row describes and records a single value. The columns are as follows:

| column name | description |
| --- | --- |
| id | subject ID |
| date | timestamp indicating when images were acquired |
| system | name of labeling system used for this measure ( brain, anstsct, mindboggle, etc ) |
| label | label number |
| measure | what is being measured ( volume, thickness, FA, etc) |
| metric | how is measure summarized ( numeric, mean, max, etc) |
| value | the value of interest |

# quantsANTsCTSummary.R
This scripts produces a .csv file with a number of measures, defined as follows:

| system | measure | metric | description |
| ---  | --- | --- | --- |
| brain | volume | numeric | defined via binary brain extraction mask |
| antsct | volume | numeric | defined via brain segmentation image |
| antsct | thickness | * | defined via cortical thickness image and cortex from brain segmentation |
| antsct | T1_intentisty | * | defined via original T1 image and brain segmentation |
| antsct | N4_intentisty | * | defined via brain segmentation bias corrected image and brain segmentation |
