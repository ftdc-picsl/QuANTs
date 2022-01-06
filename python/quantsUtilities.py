import itk
import numpy as np
import pandas as pd

def loadLabelSystem(name):
    sys=None
    if name=="BrainCOLOR":
        sys = pd.read_csv("/apps/quants/data/braincolor_labels.csv")

    return(sys)


def compareImageHeaders(img1, img2, tolerance=0.00001):
    print("Comparing headers")
    sp1=itk.GetArrayFromVnlVector(itk.spacing(img1).GetVnlVector())
    sp2=itk.GetArrayFromVnlVector(itk.spacing(img2).GetVnlVector())
    spVar=np.sum(np.abs(sp2-sp1))

    if (spVar > tolerance):
        return(False)

    or1=itk.GetArrayFromVnlVector(itk.origin(img1).GetVnlVector())
    or2=itk.GetArrayFromVnlVector(itk.origin(img2).GetVnlVector())
    orVar=np.sum(np.abs(or2-or1))

    if (orVar > tolerance):
        return(False)

    return(True)

def scalarStats( values, number, voxvol, measureName ):

    dat = {"number":number, "measure": measureName, "values": {} }
    #"mean": None, "sd": None, "min": None, "max": None, "median": None, "q1": None, "q3": None}


    values = np.sort(values)
    nVox = len(values)
    #dat['values']['volume'] = voxvol*dat['values']['nVox']
    if len(values)==0:
        return dat
    dat['values']['mean'] = float(np.mean(values))
    dat['values']['sd'] = float(np.std(values))
    dat['values']['max'] = float(np.max(values))
    dat['values']['min'] = float(np.min(values))
    dat['values']['median'] = float(np.median(values))
    n = np.floor( len(values)/2.0 )
    if nVox > 3:
        dat['values']['q1'] = float(np.median( values[0:int(n-1)] ))
        dat['values']['q3'] = float(np.median( values[int(len(values)-n+1):len(values)] ))

    return(dat)

def labelScalarStats(labelImg, valueImg, labelNumbers=None ):

    if labelNumber is None:
        labelNumbers = np.unique(labelImg)

    stats = [ ( int(i), scalarStats(thickView[lblView==i]) ) for i in np.unique(lblView) ]
