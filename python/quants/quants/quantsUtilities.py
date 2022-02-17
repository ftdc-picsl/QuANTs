from os import supports_effective_ids
import itk
import numpy as np
import pandas as pd
import quantsifier as qf
import glob
import os

def brainColorSubcorticalSystem():
    sysDict={4:1,11:1,23:4,30:4,31:4,32:4,35:5,36:4,37:4,38:6,39:6,40:6,41:6,44:3,45:3,46:1,47:4,48:4,49:1,50:1,51:1,52:1,55:4,56:4,57:4,58:4,59:4,60:4,61:4,62:4,63:1,64:1,69:1,71:6,72:6,73:6,75:4,76:4}
    
    k, v = [], []
    for key, value in sysDict.items():
        k.append(key)
        v.append(value)  

    return( (k,v) )
    

def corticalSystemNames():

    names =  ['lausanne33', 
        'lausanne60', 
        'lausanne125', 
        'lausanne250', 
        'schaefer100x7',
        'schaefer100x17',
        'schaefer200x7',
        'schaefer200x17',
        'schaefer300x7',
        'schaefer300x17',
        'schaefer500x7',
        'schaefer500x17']

    return(names)


def getFTDCQuantsifier( imgFiles ):
    q = qf.Quantsifier()

    imgs = imgFiles
    for tag in imgFiles.keys():
        if len(imgFiles[tag])>0:
            imgs[tag] = itk.imread(imgFiles[tag][0], itk.F)
        else:
            imgs[tag] = None

    # set images
    q.SetSegmentation(imgs['seg'])
    q.SetMask(imgs['mask'])

    # Add measure named 'thickness' for voxels with segmentation==2
    q.AddMeasure(imgs['thickness'], 'thickness', [2])
    q.AddMeasure(imgs['t1'], 'intensity0N4', [1,2,3,4,5,6])


    # Masking rule for subcortical(=4) == include everything except CSF(=1) and Whitematter(=3)
    q.AddSegmentationMaskingRule( 4, exclude=[1,3] )
    #q.AddSegmentationMaskingRule( 5, include=[1,2,3,4,5,6] ) 


    # Add ANTsCT segmentation as a labeling system
    q.AddLabelingSystem(imgs['seg'], np.asarray([1,2,3,4,5,6]), np.asarray([1,2,3,4,5,6]), 'antsct', ['thickness','intensity0N4'] )

    # Add brainmask as a labeling system
    q.AddLabelingSystem(imgs['mask'], np.asarray([1]), np.asarray([1]), 'brain', [None])

    # Subcortical regions
    #bcLabels = np.unique(itk.GetArrayViewFromImage(imgs['braincolor']))
    #bcLabels = bcLabels[bcLabels > 0]
    #q.AddLabelingSystem(imgs['braincolor'], bcLabels,  np.full(len(bcLabels), 4), 'braincolor', [None])
    bc=brainColorSubcorticalSystem()
    if not imgs['braincolor'] is None:
        q.AddLabelingSystem(imgs['braincolor'], bc[0], bc[1], 'braincolor', [None])
    

    for sys in corticalSystemNames():
        if not imgs[sys] is None:
            lbl = imgs[sys]
            cxLabels = np.unique(itk.GetArrayViewFromImage(lbl))
            cxLabels = cxLabels[cxLabels > 0]
            q.AddLabelingSystem(lbl, cxLabels, np.full(len(cxLabels), 2), sys, ['thickness'])

    return(q)

def getFTDCInputs(directory):

    suffix = {"t1": "*ExtractedBrain0N4.nii.gz",
              "mask": "*BrainExtractionMask.nii.gz",
              "seg": "*BrainSegmentation.nii.gz",
              "n4": "*BrainSegmentation0N4.nii.gz",
              "gmp": "*BrainSegmentationPosteriors2.nii.gz",
              "thickness": "*CorticalThickness.nii.gz",
              "dkt31": "*DKT31.nii.gz",
              "braincolor": "*BrainColorSubcortical.nii.gz",
              "lausanne33":"*LausanneCorticalScale33.nii.gz",
              "lausanne60":"*LausanneCorticalScale60.nii.gz",
              "lausanne125": "*LausanneCorticalScale125.nii.gz",
              "lausanne250": "*LausanneCorticalScale250.nii.gz",
              "schaefer100x7":"*Schaefer2018_100Parcels7Networks.nii.gz",
              "schaefer100x17":"*Schaefer2018_100Parcels17Networks.nii.gz",
              "schaefer200x7":"*Schaefer2018_200Parcels7Networks.nii.gz",
              "schaefer200x17":"*Schaefer2018_200Parcels17Networks.nii.gz",
              "schaefer300x7":"*Schaefer2018_300Parcels7Networks.nii.gz",
              "schaefer300x17":"*Schaefer2018_300Parcels17Networks.nii.gz",
              "schaefer500x7":"*Schaefer2018_500Parcels7Networks.nii.gz",
              "schaefer500x17":"*Schaefer2018_500Parcels17Networks.nii.gz"
    }

    imgFiles = suffix

    for tag in suffix.keys():
        files = glob.glob(os.path.join(directory, suffix[tag]))
        imgFiles[tag] = files

    return(imgFiles)
    


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
