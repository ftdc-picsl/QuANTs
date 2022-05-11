import itk
import SimpleITK as sitk
#import quantsifier as qf
#import quantsUtilities as qu
import quants
import numpy as np
import pandas as pd
import os 
import sys
import json


def parsePath( path ):

    dirParts = os.path.split(dir.rstrip('/'))
    sesTag = dirParts[1]
    subTag = os.path.split(dirParts[0])[1]

    id = subTag.split('-')[1]
    ses = sesTag.split('-')[1]

    return((id,ses))

dir = sys.argv[1]
template = sys.argv[2]
networkDir = sys.argv[3]
networkImageDir = sys.argv[4]
odir = sys.argv[5]

q = quants.Quantsifier()

#q.templateImg = sitk.ReadImage("/Users/jtduda/projects/Grossman/tpl-TustisonAging2019ANTs/tpl-TustisonAging2019ANTs_res-01_T1w.nii.gz")

templateDir = os.path.dirname(os.path.abspath(template))
templateF = open(template)
templateDef = json.load(templateF)
templateF.close()
q.SetTemplate(templateDef, templateDir)



bidsInfo = parsePath(dir)
inputFiles =  quants.getFTDCInputs(dir)
print(inputFiles)
inputImgs = {}
for tag in inputFiles.keys():
    if tag != 'mat':
        if tag != 'warp':
            if len(inputFiles[tag])>0:
                print("Reading "+inputFiles[tag][0])
                inputImgs[tag] = sitk.ReadImage(inputFiles[tag][0])
            else:
                inputImgs[tag] = None



if len(inputFiles['mat']) > 0:
    txMat = sitk.ReadTransform(inputFiles['mat'][0])
    txWarp = sitk.DisplacementFieldTransform( sitk.ReadImage(inputFiles['warp'][0]) )
    q.subjectMat = txMat
    q.subjectWarp = txWarp


    if 'thickness' in inputImgs:
        print("Apply thickness masking")
        thickMask = sitk.BinaryThreshold(inputImgs['thickness'], lowerThreshold=0.0001 )
        thickMask = sitk.Cast(thickMask, sitk.sitkUInt32)
        cortex = sitk.Threshold(inputImgs['seg'], lower=2, upper=2)
        cortex = sitk.Multiply(thickMask, cortex)

        c1 = sitk.Threshold(inputImgs['seg'], lower=1, upper=1)
        c3 = sitk.Threshold(inputImgs['seg'], lower=3, upper=3)
        c4 = sitk.Threshold(inputImgs['seg'], lower=4, upper=4)
        c5 = sitk.Threshold(inputImgs['seg'], lower=5, upper=5)
        c6 = sitk.Threshold(inputImgs['seg'], lower=6, upper=6)

        seg = sitk.Add(cortex, c1)
        seg = sitk.Add(seg, c3)
        seg = sitk.Add(seg, c4)
        seg = sitk.Add(seg, c5)
        seg = sitk.Add(seg, c6)
        inputImgs['seg'] = seg
        sitk.WriteImage(seg, "seg.nii.gz")


    q.SetSegmentation(inputImgs['seg'])
    q.SetMask(inputImgs['mask'])

    # 1=CSF, 2=CGM, 3=WM, 4=SCGM, 5=BS, 6=CBM
    # Add measure named 'thickness' for voxels with segmentation==2
    q.AddMeasure(inputImgs['thickness'], 'thickness', [2])
    q.AddMeasure(inputImgs['t1'], 'intensity0N4', [1,2,3,4,5,6])


    networks = quants.getNetworks(networkDir)

    for n in networks:
        #print( n["Identifier"])
        if 'Filename' in n:
            fname = os.path.join(networkImageDir, n['Filename'])
            if os.path.exists(fname):
                print("Adding Network: "+n["Identifier"])
                img = sitk.ReadImage(fname)
                q.AddNetwork(n,img)

    #x = quants.getFTDCQuantsifier(filenames)
    q.SetConstants({"id": bidsInfo[0], "date": bidsInfo[1]})
    q.Update()
    stats = q.GetOutput()

    pd.set_option("display.max_rows", None, "display.max_columns", None)
    ofile = os.path.join(odir, bidsInfo[0]+"_"+bidsInfo[1]+"_quants.csv")
    stats.to_csv(ofile, index=False, float_format='%.4f')

    #print("Done")