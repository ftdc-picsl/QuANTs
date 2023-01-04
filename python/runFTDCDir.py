import os 
os.environ['ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS'] = str(1)
os.environ['MKL_NUM_THREADS'] = str(1)
os.environ['OMP_NUM_THREADS'] = str(1)
os.environ['NUMEXPR_NUM_THREADS'] = str(1)

import itk
import SimpleITK as sitk
import quants
import numpy as np
import pandas as pd
import sys
import json
import glob
import logging
import argparse
import time
import os


def parsePath( path ):

    dirParts = os.path.split(path.rstrip('/'))
    sesTag = dirParts[1]
    subTag = os.path.split(dirParts[0])[1]

    id = subTag.split('-')[1]
    ses = sesTag.split('-')[1]

    return((id,ses))


def getMyPID( uname, output ):
    stream = os.popen("ps -elf | grep "+uname)
    jobList = stream.read().split('\n')
    stream.close()
    thisJob = [ x for x in jobList if output in x ]

    if len(thisJob) > 1:
        return None

    return(thisJob[0].split(' ')[3])

def getMyThreads( uname, output ):
    pid = getMyPID( uname, output )
    stream = os.popen("ps -o thcount "+str(pid) )
    output = stream.read().split('\n')
    stream.close()
    return( output[1] )
    
    

def main():


    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Summarize ROI values using ANTsCT output")
    parser.add_argument("--antsct_dir", type=str, required=True, help="output directory on ANTsCT")
    parser.add_argument("--template", type=str, required=True, help="JSON file listing template info")
    parser.add_argument("--atlas_dir", type=str, required=True, help="Directory with label system definition files (json)") 
    parser.add_argument("--atlas_images", type=str, required=True, help="Directory with label sytem images")
    parser.add_argument("--output", type=str, required=True, help="Output filename")
    args = parser.parse_args()
    print(args)

    logging.basicConfig(
        format='%(asctime)s %(name)s %(levelname)-8s %(message)s',
        level=logging.INFO,
        datefmt='%Y-%m-%d %H:%M:%S')

    psOut = getMyPID( 'jtduda', args.output )
    threads = getMyThreads( 'jtduda', args.output )
    logging.info("Started with nThreads="+str(threads))

    threader = itk.MultiThreaderBase.New()
    threader.SetGlobalDefaultNumberOfThreads(1)
    logging.info("ITK Max Threads = " + str(threader.GetGlobalDefaultNumberOfThreads()))

    sitk.ProcessObject.SetGlobalDefaultNumberOfThreads(1)
    logging.info("SimpleITK Max Threads = " + str(sitk.ProcessObject.GetGlobalDefaultNumberOfThreads()))


    dir = args.antsct_dir
    template = args.template
    networkDir = args.atlas_dir
    networkImageDir = args.atlas_images
    oFile = args.output

    q = quants.Quantsifier()
    q.threadString=oFile
    logging.info("q.threadString= "+q.threadString)

    user = os.getlogin()
    threads = getMyThreads( user, args.output )
    logging.info("Initialized quantsifier with nThreads="+str(threads))

    templateDir = os.path.dirname(os.path.abspath(template))
    templateF = open(template)
    templateDef = json.load(templateF)
    templateF.close()
    q.SetTemplate(templateDef, templateDir)


    bidsInfo = parsePath(dir)
    inputFiles =  quants.getFTDCInputs(dir)
    inputImgs = {}
    for tag in inputFiles.keys():
        if tag != 'mat':
            if tag != 'warp':
                if len(inputFiles[tag])>0:
                    #print("Reading "+inputFiles[tag][0])
                    inputImgs[tag] = sitk.ReadImage(inputFiles[tag][0])
                else:
                    inputImgs[tag] = None

    threads = getMyThreads( user, args.output )
    logging.info("Set quantsifier inputs with nThreads="+str(threads))

    if len(inputFiles['mat']) > 0:
        txMat = sitk.ReadTransform(inputFiles['mat'][0])
        txWarp = sitk.DisplacementFieldTransform( sitk.ReadImage(inputFiles['warp'][0]) )
        q.subjectMat = txMat
        q.subjectWarp = txWarp

        if 'thickness' in inputImgs:
            logging.info("Apply thickness masking using" + inputFiles['thickness'][0])
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
            #sitk.WriteImage(seg, "seg.nii.gz")

            threads = getMyThreads( user, args.output )
            logging.info("Applied thickness masking with nThreads="+str(threads))


        q.SetSegmentation(inputImgs['seg'])
        q.SetMask(inputImgs['mask'])

        # 1=CSF, 2=CGM, 3=WM, 4=SCGM, 5=BS, 6=CBM
        # Add measure named 'thickness' for voxels with segmentation==2
        q.AddMeasure(inputImgs['thickness'], 'thickness', [2])
        q.AddMeasure(inputImgs['t1'], 'intensity0N4', [1,2,3,4,5,6])


        networks = quants.getNetworks(networkDir)
        def networkIdentifierFunc(x):
            return( x['Identifier'])
        networks.sort(key=networkIdentifierFunc)

        # Add networks with labels in NATIVE space (ie no template labels exist)
        for n in networks:
            templateSpace = n['TemplateSpace']

            if templateSpace=='NATIVE':
                #logging.info("Looking for NATIVE labels matching: "+n['Filename'])
                nativeLabelName = glob.glob( os.path.join(dir, n['Filename']))
                #logging.info(nativeLabelName)

                if len(nativeLabelName)==1:
                    img = sitk.ReadImage(nativeLabelName[0])
                    q.AddNetwork(n,img)
                else:
                    if len(nativeLabelName)==0:
                        logging.warning("No NATIVE label image found")
                    else:
                        logging.warning(n['Identifier']+" does not have unique label image")
                        for nm in nativeLabelName:
                            logging.warning("  lbl="+nm)

            else:
                if 'Filename' in n:
                    fname = os.path.join(networkImageDir, n['Filename'])
                    if os.path.exists(fname):
                        logging.info("Adding Network: "+n["Identifier"])
                        img = sitk.ReadImage(fname)
                        q.AddNetwork(n,img)
                else:
                    logging.error("No template image found for "+n['Identifier'])

        #x = quants.getFTDCQuantsifier(filenames)
        q.SetConstants({"id": bidsInfo[0], "date": bidsInfo[1]})
        q.SetOutputDirectory( os.path.dirname(oFile) )
        if 'LabelPropagation' in n:
            if n['LabelPropagation']=='True':
                prop_mask = sitk.Threshold(inputImgs['seg'], lower=2, upper=2)
                q.AddLabelPropagation(n['Identifier'], prop_mask)

        threads = getMyThreads( user, args.output )
        logging.info("Pre Update() with nThreads="+str(threads))
        time.sleep(5)
        threads = getMyThreads( user, args.output )
        logging.info("Pre Update() with nThreads="+str(threads))
        q.Update()
        stats = q.GetOutput()

        pd.set_option("display.max_rows", None, "display.max_columns", None)
        stats.to_csv(oFile, index=False, float_format='%.4f')
        logging.info("Output written to: "+oFile)

        #print("Done")

if __name__ == "__main__":
    main()