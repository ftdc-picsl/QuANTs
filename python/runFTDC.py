import itk
#import quantsifier as qf
#import quantsUtilities as qu
import quants
import numpy as np
import pandas as pd
import os 
import sys


def parsePath( path ):

    dirParts = os.path.split(dir.rstrip('/'))
    sesTag = dirParts[1]
    subTag = os.path.split(dirParts[0])[1]

    id = subTag.split('-')[1]
    ses = sesTag.split('-')[1]

    return( (id,ses))

#path = "/Users/jtduda/quants-fw-test/antsct"
path = sys.argv[1]
odir = sys.argv[2]


subDirs = os.listdir(path)
for sub in subDirs:
    sesDirs = os.listdir( os.path.join(path, sub) ) 
    for ses in sesDirs:
        dir = os.path.join(path, sub, ses)
        print(dir)


        bidsInfo = parsePath(dir)
        filenames =  quants.getFTDCInputs(dir)

        x = quants.getFTDCQuantsifier(filenames)
        x.SetConstants({"id": bidsInfo[0], "date": bidsInfo[1]})
        x.Update()
        stats = x.GetOutput()

        pd.set_option("display.max_rows", None, "display.max_columns", None)
        ofile = os.path.join(odir, bidsInfo[0]+"_"+bidsInfo[1]+"_quants.csv")
        stats.to_csv(ofile, index=False, float_format='%.4f')

print("Done")