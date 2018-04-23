# QuANTs
Summarize values from ANTs/Pipedream processed data


# quantsANTsCTSummary.R
This scripts produces a .csv file with a number of measures, defined as follows:

| system | measure | metric | description |
| ---  | --- | --- | --- |
| brain | volume | numeric | defined via binary brain extraction mask |
| antsct | volume | numeric | defined via brain segmentation image |
| antsct | thickness | * | defined via cortical thickness image and cortex from brain segmentation |
| antsct | T1_intentisty | * | defined via original T1 image and brain segmentation |
| antsct | N4_intentisty | * | defined via brain segmentation bias corrected image and brain segmentation |
