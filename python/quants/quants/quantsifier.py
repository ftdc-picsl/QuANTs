#import itk
import SimpleITK as sitk
import numpy as np
import pandas as pd
import glob
import os
import logging
import json
import re
from .image_itk_ants import ants_2_sitk
from .image_itk_ants import sitk_2_ants
import ants

class Quantsifier():

    def __init__(self):

        #super().__init__()
        logging.basicConfig(
            format='%(asctime)s %(name)s %(levelname)-8s %(message)s',
            level=logging.INFO,
            datefmt='%Y-%m-%d %H:%M:%S')
        self.log = logging.getLogger(__name__)
        #self.log.setLevel(logging.INFO)

        #threader = itk.MultiThreaderBase.New()
        #threader.SetGlobalDefaultNumberOfThreads(1)
        #print("ITK Max Threads = " + str(threader.GetGlobalDefaultNumberOfThreads()))

        sitk.ProcessObject.SetGlobalDefaultNumberOfThreads(1)
        print("SimpleITK Max Threads = " + str(sitk.ProcessObject.GetGlobalDefaultNumberOfThreads()))

        # Mapping from tissue names to ANTsCT segmentation labels
        self.tissueNames = { "Other": 0, "CorticalSpinalFluid" :1, "CorticalGrayMatter": 2, "WhiteMatter": 3, "SubcorticalGrayMatter": 4, "Brainstem": 5, "Cerebellum": 6}

        self.networks = {}
        self.template = None
        self.templateImg = None
        self.templateRes = "01"
        self.templateDirectory = None

        self.subjectMat = None
        self.subjectWarp = None

        self.labels = {}
        self.measures = {}
        self.voxvol=0

        self.constants={}
        self.mask = None 
        self.segmentation = None
        self.segmentationRules = {}
        self.segmentationRegions = None
        self.verbose = False

        self.regionMasks={}

        self.labelNumbers = None
        self.labelRegions = None
        self.output = None
        self.outputDiretory = None

        self.saveImages = True

        self.threadString="None"

        self.refspace = {'origin':None, 'spacing': None, 'direction': None, 'size': None}

        self.label_propagation = {}

    def AddLabelPropagation(self, network, prop_mask):

        self.label_propagation[network] = prop_mask


    def getMyPID( self ):
        """Get the process ID of the current process.

        Returns:
            str : process ID for this job
        """
        s1 = os.popen("whoami")
        uname = s1.read().split('\n')[0]
        s1.close()

        stream = os.popen("ps -elf | grep "+uname)
        jobList = stream.read().split('\n')
        stream.close()

        if self.threadString == "None":
            return None

        if not jobList is None:
            thisJob = [ x for x in jobList if self.threadString in x ]

            if len(thisJob) > 1:
                print("Too many jobs found for "+self.threadString)
                return None

            thisJob = thisJob[0]
            thisJob = re.sub(' +', ' ', thisJob)
            pid=str(thisJob.split(' ')[3])
            return(pid)
        else:
            print("No jobs found for "+self.threadString)

        return(None)

    def getMyThreads( self ):

        pid = self.getMyPID()
        if not pid is None:
            stream = os.popen("ps -o thcount "+str(pid) )
            outtxt = stream.read()
            outtxt = outtxt.split("\n")
            stream.close()
            return( outtxt[1] )
        else:
            return None
    

    def SetLoggingLevel(self, level):
        """Set level of logging

        Args:
            level (str): Level to use for logging
        """
        self.log.setLevel(level)

    def SetOutputDirectory(self, dir):
        self.outputDirectory = dir

    # Add a scalar image to quantify values in
    #   measure - itkImage of values to summarize
    #   name - what to call these values in output files
    #   tissues - which tissues should these values be examined in
    #   threshold - values below this are ignored
    def AddMeasure(self, measure, name, tissues, threshold=0.00001):
        if not name in self.measures.keys():
            if self.ValidateInput(measure):
                self.measures[name] = {"image":measure, "tissues":tissues, "threshold":threshold}
                if self.verbose:
                    self.log.info("Added measure image named: "+name)
                    self.log.info("nThreads"+str(self.getMyThreads()))
            else:
                self.log.error("Validation failed for "+name)
                
    # Set the segmentation image (6 tissue)
    #   segmentation - itkImage
    def SetSegmentation(self, segmentation):
        if self.ValidateInput(segmentation):
            self.segmentation = segmentation

            #self.segmentationRegions = np.unique(itk.array_view_from_image(self.segmentation))
            #if 0 in self.segmentationRegions:
            #    self.segmentationRegions = np.delete(self.segmentationRegions, 0)
            #if self.verbose:
            #    self.log.info("Segmentation regions: "+str(self.segmentationRegions))
            #self.voxvol = np.prod( itk.GetArrayFromVnlVector( segmentation.GetSpacing().GetVnlVector() ) )
        else:
            self.log.error("Validation failed for segmentation image")


    def AddSegmentationMaskingRule( self, region, include=None, exclude=None ):
        self.segmentationRules[region] = (include, exclude)

    def SetConstants(self, constants):
        self.constants = constants

    def SetMask(self, mask):
        if self.ValidateInput(mask):
            self.mask = mask


    def AddNetwork(self, networkDefinition, networkImage):
        tissueNumbers = []
        for r in networkDefinition['ROI']:
            for g in r['Groups']:
                if g['Name']=="Tissue":
                    if g['Value'] in self.tissueNames:
                        tissueNumber = self.tissueNames[g['Value']]
                        if not tissueNumber in tissueNumbers:
                            tissueNumbers.append( tissueNumber )
                    else:
                        self.log.warning("Unknown Tissue Name: " + g['Value'])

        #print( networkDefinition['Identifier'] + " -> " + str(tissueNumbers) )
        self.networks[networkDefinition['Identifier']] = (networkDefinition, networkImage, tissueNumbers)

    def SetTemplate(self, templateDefinition, templateDirectory):
        self.template = templateDefinition
        self.templateDirectory = templateDirectory


    def AddLabelingSystem(self, labelImage, numbers, regions, systemName, measures):
        if self.ValidateInput(labelImage) and ( not systemName in self.labels.keys() ):
            if self.ValidateSystemLabels(labelImage, regions):
                self.labels[systemName] = (labelImage, numbers, regions, measures)
                if self.verbose:
                    self.log.info("Added image labels for system: "+systemName)

    def ValidateSystemLabels(self, labels, system):

        # FIXME - what needs to be done here?
        valid = True
        return(valid)

    def ssd(self,a,b,tolerance=0.00001):
        sum = 0

        for i in range(len(a)):
            diff = a[i]-a[i]
            sum += diff*diff

        return(diff)


    def ValidateInput(self, img):

        return(True)

        # Check all image headers for consistency
        valid = True
        if self.refspace['origin'] is None:
            self.refspace['origin'] = img.GetOrigin()
            self.refspace['spacing'] = img.GetSpacing()
            self.refspace['direction'] = img.GetDirection()
            self.refspace['size'] = img.shape
            valid = True
        else:
            if  self.ssd( self.refspace['origin'], img.GetOrigin() ) > 0.0001:
                valid = False
                self.log.error("Unmatched origins ")

            if self.ssd( self.refspace['spacing'], img.GetSpacing() ) > 0.0001:
                valid= False
                self.log.error("Unmatched spacing")

            if self.ssd( self.refspace['direction'], img.GetDirection() ) > 0.0001:
                valid=False
                self.log.error("Unmatched direction")

            if self.ssd( self.refspace['size'], img.shape) > 0.0001:
                valid=False
                self.log.error("Unmatched size")

        if not valid:
            self.log.error("Invalid input image")

        return(valid)

    def GetSegmentationMask(self, include):
        mask=None

        if len(include)==0:
            mask = sitk.BinaryThreshold(mask, lowerThreshold=0)
        else:
            mask = sitk.Multiply( self.segmentation, 0 )
            for i in include:
                iMask = sitk.BinaryThreshold(self.segmentation, lowerThreshold=i, upperThreshold=i)
                iMask = sitk.Cast(iMask, sitk.sitkUInt32)
                mask = sitk.Add(mask, iMask)

        return(mask)

    def GetSingleLabel(self, img, label):
        iMask = sitk.BinaryThreshold(img, lowerThreshold=label, upperThreshold=label)
        iMask = sitk.Cast(iMask, sitk.sitkUInt32)
        iMask = iMask * int(label)

        return(iMask)

    def LabelPropagation(self, mask, labels):
        """Propagate labels through a mask using ants"""
        antsMask = sitk_2_ants(mask)
        antsLabels = sitk_2_ants(labels)
        antsPropLabels = ants.iMath_propagate_labels_through_mask(mask, labels, 3, 0)
        propLabels = ants_2_sitk(antsPropLabels)
        return(propLabels)



    def ApplyNetworkMasking(self, networkName, labels):

        #print("Masking "+networkName)
        nDef = self.networks[networkName][0]
        origLabels = sitk.Cast(labels, sitk.sitkUInt32)
        maskedLabels = origLabels * 0

        for r in nDef['ROI']:
            lbl = r['ImageID']
            if 'Masking' in r:
                tissues = [ self.tissueNames[x] for x in r['Masking']['Include'] ] 
                mask = self.GetSegmentationMask(tissues)
                rImg = self.GetSingleLabel(origLabels, int(lbl)) 
                maskedLabel = sitk.Multiply(rImg, mask)
                maskedLabels = sitk.Add(maskedLabels, maskedLabel)

        if networkName in self.label_propagation:
            self.log.info("Apply label propagation for "+networkName+"")
            prop_mask = self.label_propagation[networkName]
            maskedLabels = sitk.Multiply(maskedLabels, prop_mask)


        return(maskedLabels)


    def Update(self):

        self.log.info("Update()")
        self.log.info("nThreads"+str(self.getMyThreads()))

        if None in [self.mask, self.segmentation]:
            self.log.error("Missing inputs")
            return False
        if len(self.networks)==0:
            self.log.error("No networks")
            return False

        stats = []
        self.log.info("Summarizing "+str(len(self.networks.keys()))+ " networks" )
        self.log.info("nThreads"+str(self.getMyThreads()))
        for network in self.networks.keys():
            nDef = self.networks[network][0]
            nImg = self.networks[network][1]
            nTissues = self.networks[network][2]

            self.log.info("Network: "+nDef['Identifier']+" in space: "+nDef['TemplateSpace'])
            self.log.info("nThreads"+str(self.getMyThreads()))
            subLabels = None
            maskedLabels = None
            
            # Labels are already in the subject space
            if nDef['TemplateSpace']=='NATIVE':
                subLabels = nImg 
                maskedLabels = self.ApplyNetworkMasking(network, subLabels)
                maskedLabels = subLabels
                if not self.outputDirectory is None:
                    path = os.path.join( self.outputDirectory, 'sub-'+self.constants['id'], 'ses-'+self.constants['date'])
                    prefix = os.path.join( path, 'sub-'+self.constants['id']+"_ses-"+self.constants['date'] )
                    fName1 = prefix + '_' + nDef['Identifier'] + '_original.nii.gz'
                    fName2 = prefix + '_' + nDef['Identifier'] + '_masked.nii.gz'
                    if self.saveImages:
                        if not os.path.exists(path):
                            os.makedirs(path)
                        sitk.WriteImage( subLabels, fName1)
                        sitk.WriteImage( maskedLabels, fName2 )

            # Labels are in an arbitrary space
            else:
                txNameGlob = os.path.join(self.templateDirectory, "*"+"from-"+nDef['TemplateSpace']+"*.h5")
                txName=None
                txNames = glob.glob( txNameGlob )

                if len(txNames)==1:
                    if os.path.exists(txNames[0]):
                        txName=txNames[0]
                else:
                    if len(txNames) > 1:
                        self.log.error("Multiple template transforms found")
                        for t in txNames:
                            self.log.error("  template transform: "+t)

                if (not txName is None) or (nDef['TemplateSpace']==self.template["Identifier"]):
                    
                    fullTx=None

                    # Get transform from label space to subject space
                    if nDef['TemplateSpace']==self.template["Identifier"]:
                        fullTx = sitk.CompositeTransform( [self.subjectWarp, self.subjectMat] )
                    else:
                        templateTx = sitk.ReadTransform(txName)
                        fullTx = sitk.CompositeTransform( [templateTx, self.subjectWarp, self.subjectMat] )

                    resample = sitk.ResampleImageFilter()
                    resample.SetReferenceImage( self.segmentation )
                    resample.SetTransform( fullTx )
                    resample.SetInterpolator( sitk.sitkLabelGaussian )
                    resample.SetNumberOfThreads(1)

                    subLabels = resample.Execute(nImg)
                    maskedLabels = self.ApplyNetworkMasking(network, subLabels)
                    if self.saveImages:
                        path = os.path.join( self.outputDirectory, 'sub-'+self.constants['id'], 'ses-'+self.constants['date'])
                        prefix = os.path.join( path, 'sub-'+self.constants['id']+"_ses-"+self.constants['date'] )
                        fName1 = prefix + '_' + nDef['Identifier'] + '_original.nii.gz'
                        fName2 = prefix + '_' + nDef['Identifier'] + '_masked.nii.gz'
                        if not os.path.exists(path):
                            os.makedirs(path)

                        sitk.WriteImage( subLabels, fName1)
                        sitk.WriteImage( maskedLabels, fName2 )
                else:
                    self.log.error("No template transform found")

            

            measuresToUse = ['volume']
            if not self.measures is None:
                measureNames = self.measures.keys()

            if not nTissues is None:
                for m in self.measures.keys():
                    measureTissues = self.measures[m]['tissues']
                    validTissues = set(nTissues).intersection(set(measureTissues))
                    if len(validTissues) > 0:
                        measuresToUse.append(m)

            #print(nDef['Identifier'] + " -> " + str(measuresToUse))

            for mName in measuresToUse:
                mStats = self.Summarize(network, maskedLabels, mName)
                if not mStats is None:
                    stats += mStats

        stats = [ self.EntryToDataFrame(x) for x in stats ]
        self.output=pd.concat(stats)
        #print(self.output)
    
    def GetOutput(self):
        return self.output

    def EntryToDataFrame(self, stats):
        # "id","date","system","label","measure","metric","value"

        metric = [ x for x in stats['values'].keys() ]
        value = [ stats['values'][x] for x in stats['values'].keys() ]

        df = pd.DataFrame(data={'metric': metric, 'value': value})

        nRow = len(value)
        for (i,k) in enumerate(self.constants.keys()):
            df.insert( i, k, [ self.constants[k]]*nRow )

        df.insert(len(self.constants.keys()), 'system', [stats['system']]*nRow )
        df.insert(1+len(self.constants.keys()), 'label', [stats['label']]*nRow )
        df.insert(2+len(self.constants.keys()), 'name', [stats['name']]*nRow )
        df.insert(3+len(self.constants.keys()), 'measure', [stats['measure']]*nRow )        

        return(df)

    def Summarize(self, networkName, subjectLabels, measureName):

        self.log.info("Summarize( %s, %s )", networkName, measureName)
        self.log.info("nThreads"+str(self.getMyThreads()))

        nDef = self.networks[networkName][0]
        #nImg = self.networks[networkName][1]

        measureImg = subjectLabels
        measureTissueNumbers = []
        if measureName != "volume":
            measureImg = self.measures[measureName]['image']
            measureTissueNumbers = self.measures[measureName]['tissues']

        #print(subjectLabels)
        #print( np.unique(sitk.GetArrayFromImage(subjectLabels)) )
        nImg = sitk.Cast(subjectLabels, sitk.sitkUInt32)
        #print( np.unique(sitk.GetArrayFromImage(nImg)) )


        stats = sitk.LabelIntensityStatisticsImageFilter()
        stats.SetGlobalDefaultCoordinateTolerance(1e-04)
        stats.SetNumberOfThreads(1)
        stats.Execute(nImg, measureImg)
        labelsInImage = stats.GetLabels()
        #print(labelsInImage)

        statDat = []
        for r in nDef['ROI']:
            lbl = r['ImageID']
            roiName = r['Name']
       
            rTissueNumbers = []
            if 'Groups' in r:
                gps = r['Groups']
                for g in gps:
                    if g['Name']=="Tissue":
                        rTissueNumbers.append(self.tissueNames[g['Value']])

            #print(lbl, roiName)
            #print(measureTissueNumbers)
            #print(rTissueNumbers)
            tissueOverlap = [value for value in measureTissueNumbers if value in rTissueNumbers]
            #print(tissueOverlap)

            if lbl in labelsInImage:
                if measureName=="volume":  
                    #print("volume for "+str(lbl))
                    dat = {"system": networkName, "label":lbl, "name": roiName, "measure": "volume", "values": {} }
                    dat['values']['numeric'] = stats.GetPhysicalSize(lbl)
                    #print(str(lbl) + " vox = " + str(stats.GetNumberOfPixels(lbl)))
                    #print(str(lbl) + " " + measureName + " = " + str(stats.GetPhysicalSize(lbl)))
                    statDat.append(dat)
                else:
                    if len(tissueOverlap)>0:
                        dat = {"system": networkName, "label":lbl, "name": roiName, "measure": measureName, "values": {} }
                        dat['values']['mean'] = float(stats.GetMean(lbl))
                        dat['values']['sd'] = float(stats.GetStandardDeviation(lbl))
                        dat['values']['max'] = float(stats.GetMaximum(lbl))
                        dat['values']['min'] = float(stats.GetMinimum(lbl))
                        dat['values']['median'] = float(stats.GetMedian(lbl))
                        statDat.append(dat)
                        #print(str(lbl) + " " + measureName + " = " + str(stats.GetMean(lbl)))

        #for r in self.segmentationRegions:
        #    rstats = self.SummarizeRegion(systemName, measureName, r)
        #    if len(rstats)>0:
        #        stats += rstats
        return(statDat)



    def GetStats(self, labelView, labelValues, measureView, measureName):
        self.log.debug("GetStats()")
        self.log.info("nThreads"+str(self.getMyThreads()))
        statList = []    

        if measureName == "volume":
            statList = [ (self.LabelStats(labelView, int(i))) for i in labelValues ]
        else:
            statList += [ (self.MeasureStats(measureView[labelView==i], int(i), measureName) ) for i in labelValues ]

        return statList

    def LabelStats(self, labelView, number):
        dat = {"label":number, "measure": "volume", "values": {} }
        dat['values']['numeric'] = self.voxvol*float(np.sum(labelView==number))
        return(dat)

    def MeasureStats( self, values, number, measureName ):

        dat = {"label":number, "measure": measureName, "values": {} }
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
        'schaefer100x7v1',
        'schaefer100x17v2',
        'schaefer200x7v1',
        'schaefer200x17v2',
        'schaefer300x7v1',
        'schaefer300x17v2',
        'schaefer400x7v1',
        'schaefer400x17v2',
        'schaefer500x7v1',
        'schaefer500x17v2']

    return(names)

def getNetworks(directory):
    fnames = glob.glob(os.path.join(directory, "*.json"))
    networks = []
    for f in fnames:
        logging.debug("Reading network file: "+f)
        #logging.debug("nThreads"+str(self.getMyThreads()))
        f1 = open(f)
        x=json.load(f1)
        networks.append(x)
        f1.close()
        logging.debug("Loaded: "+x['Identifier'])
        #logging.debug("nThreads"+str(self.getMyThreads()))

    return(networks)

def getFTDCInputs(directory):

    suffix = {"t1": "*ExtractedBrain0N4.nii.gz",
            "mask": "*BrainExtractionMask.nii.gz",
            "seg": "*BrainSegmentation.nii.gz",
            "n4": "*BrainSegmentation0N4.nii.gz",
            "gmp": "*BrainSegmentationPosteriors2.nii.gz",
            "thickness": "*CorticalThickness.nii.gz",
            "warp" : "*_TemplateToSubject0Warp.nii.gz",
            "mat" : "*_TemplateToSubject1GenericAffine.mat"
    }

    imgFiles = suffix

    for tag in suffix.keys():
        files = glob.glob(os.path.join(directory, suffix[tag]))
        imgFiles[tag] = files

    return(imgFiles)

#def getFTDCQuantsifier( imgFiles ):
#    q = Quantsifier()
#    imgs = imgFiles
#    for tag in imgFiles.keys():
#        if tag != "mat":
#            if len(imgFiles[tag])>0:
#                imgs[tag] = itk.imread(imgFiles[tag][0], itk.F)
#            else:
#                imgs[tag] = None

#    # set images
#    q.SetSegmentation(imgs['seg'])
#    q.SetMask(imgs['mask'])

#    # Add measure named 'thickness' for voxels with segmentation==2
#    q.AddMeasure(imgs['thickness'], 'thickness', [2])
#    q.AddMeasure(imgs['t1'], 'intensity0N4', [1,2,3,4,5,6])

#    return(q)

def bidsTagValue( tag ):
    parts = tag.split("-")
    parts.pop(0)
    val = "-".join(parts)
    return(val)
    

def parseFile( fname ):

    file = os.path.basename(fname)
    fileParts = file.split("_")
    sub = bidsTagValue( fileParts[0] )
    ses = bidsTagValue( fileParts[1] )

    return((sub,ses))