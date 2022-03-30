import itk
import numpy as np
import pandas as pd
import glob
import os
import logging

class Quantsifier():

    def __init__(self):

        #super().__init__()
        logging.basicConfig()
        self.log = logging.getLogger(__name__)
        self.log.setLevel(logging.INFO)

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

        self.refspace = {'origin':None, 'spacing': None, 'direction': None, 'size': None}

    def SetLoggingLevel(self, level):
        self.log.setLevel(level)

    def AddMeasure(self, measure, name, regions, threshold=0.00001):
        if not name in self.measures.keys():
            if self.ValidateInput(measure):
                self.measures[name] = {"image":measure, "regions":regions, "threshold":threshold}
                if self.verbose:
                    self.log.info("Added measure image named: "+name)
            else:
                self.log.error("Validation failed for "+name)
                
    def SetSegmentation(self, segmentation):
        if self.ValidateInput(segmentation):
            self.segmentation = segmentation
            self.segmentationRegions = np.unique(itk.array_view_from_image(self.segmentation))
            if 0 in self.segmentationRegions:
                self.segmentationRegions = np.delete(self.segmentationRegions, 0)
            if self.verbose:
                self.log.info("Segmentation regions: "+str(self.segmentationRegions))
            self.voxvol = np.prod( itk.GetArrayFromVnlVector( segmentation.GetSpacing().GetVnlVector() ) )
        else:
            self.log.error("Validation failed for segmentation image")


    def AddSegmentationMaskingRule( self, region, include=None, exclude=None ):
        self.segmentationRules[region] = (include, exclude)

    def SetConstants(self, constants):
        self.constants = constants

    def SetMask(self, mask):
        if self.ValidateInput(mask):
            self.mask = mask

    def AddLabelingSystem(self, labelImage, numbers, regions, systemName, measures):
        if self.ValidateInput(labelImage) and ( not systemName in self.labels.keys() ):
            if self.ValidateSystemLabels(labelImage, regions):
                self.labels[systemName] = (labelImage, numbers, regions, measures)
                if self.verbose:
                    print("Added image labels for system: "+systemName)

    def ValidateSystemLabels(self, labels, system):

        # FIXME - what needs to be done here?
        valid = True
        return(valid)

    def ssd(self,a,b,tolerance=0.00001):
        sum = 0
        if isinstance(a, type(itk.Matrix[itk.D,3,3]()) ):
            a = itk.GetArrayFromMatrix(a).flatten().tolist()
            b = itk.GetArrayFromMatrix(b).flatten().tolist()

        for i in range(len(a)):
            diff = a[i]-a[i]
            sum += diff*diff

        return(diff)
        

    def ValidateInput(self, img):
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

    def GetSegmentationMask(self, region):
        seg = itk.array_view_from_image(self.segmentation)
        inmask = np.full(seg.shape, 1, dtype=np.int16)

        if not self.mask is None:
            inmask[ itk.array_view_from_image(self.mask)==0]=0

        if region in self.segmentationRules.keys():
            rule = self.segmentationRules[region]

            # Limit to segmentation inclusion regions
            if not rule[0] is None:
                inmask = np.full(seg.shape, 0)
                for i in rule[0]:
                    inmask[seg==i]=1

            # Eliminate exclusion regions
            if not rule[1] is None:
                for i in rule[1]:
                    inmask[seg==i]=0
            
        else:
            inmask[seg!=region]=0
        
        # Apply global masking
        if not self.mask is None:
            inmask[ itk.array_view_from_image(self.mask)==0]=0

        segMask = itk.image_from_array(inmask)
        segMask.SetSpacing( self.segmentation.GetSpacing() )
        segMask.SetOrigin( self.segmentation.GetOrigin() )
        segMask.SetDirection( self.segmentation.GetDirection() )

        return(segMask)
        

    def Update(self):

        if None in [self.mask, self.segmentation]:
            return False
        if len(self.labels)==0:
            return False

        # Precompute segmentation region masks
        for i in self.segmentationRegions:
            self.regionMasks[i] = self.GetSegmentationMask(i)

        stats = []
        self.log.info( "Summarizing "+str(len(self.labels.keys())) + " labeling systems" )
        for sysName in self.labels.keys():

            measuresToUse = ['volume']
            if not self.measures is None:
                measureNames = self.measures.keys()

            sysMeasures = self.labels[sysName][3]
            if not sysMeasures is None:
                applicableMeaures = set(sysMeasures).intersection(measureNames)
                if len(applicableMeaures) > 0:
                    measuresToUse.extend(applicableMeaures)


            for mName in measuresToUse:
                mStats = self.Summarize(sysName, mName)
                if not mStats is None:
                    stats += mStats

        stats = [ self.EntryToDataFrame(x) for x in stats ]
        self.output=pd.concat(stats)
    
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
        df.insert(2+len(self.constants.keys()), 'measure', [stats['measure']]*nRow )        

        return(df)

    def Summarize(self, systemName, measureName):

        self.log.info("Summarize( %s %s )", systemName, measureName)


        stats=[]
        for r in self.segmentationRegions:
            rstats = self.SummarizeRegion(systemName, measureName, r)
            if len(rstats)>0:
                stats += rstats

        return(stats)

    def SummarizeRegion(self, systemName, measureName, segRegion):

        labelImage = self.labels[systemName][0]
        labelNum = self.labels[systemName][1]
        labelReg = self.labels[systemName][2]


        maskView = itk.array_view_from_image(self.mask)
        labelView = np.copy(itk.array_view_from_image(labelImage))
        segView = itk.array_view_from_image(self.regionMasks[segRegion])
        labelView[segView==0] = 0

        measureView = None 
        if measureName != "volume":
            if segRegion in self.measures[measureName]['regions']:
                measureView = itk.array_view_from_image( self.measures[measureName]['image'] )
                if self.measures[measureName]['threshold'] > 0:
                    labelView[measureView < self.measures[measureName]['threshold']] = 0
            else:
                measureName = None

        statList = []
        if not measureName is None:
            #print(labelReg==segRegion)
            #labelSubset = labelNum[labelReg==segRegion]
            labelSubset = [x for (x,y) in zip(labelNum, labelReg) if y==segRegion]

            statList = self.GetStats(labelView, labelSubset, measureView, measureName)
            for i in range(len(statList)):
                statList[i]['system']=systemName

        return(statList)

 
    def GetStats(self, labelView, labelValues, measureView, measureName):
        if self.verbose:
            print("GetStats() ")

        statList = []    

        if measureName == "volume":
            statList = [ (self.LabelStats(labelView, int(i))) for i in labelValues ]
        else:
            statList += [ (self.MeasureStats(measureView[labelView==i], int(i), measureName) ) for i in labelValues ]

        return statList

    def LabelStats(self, labelView, number):
        #if self.verbose:
        #    print("LabelStats()")
        dat = {"label":number, "measure": "volume", "values": {} }
        dat['values']['numeric'] = self.voxvol*float(np.sum(labelView==number))
        return(dat)

    def MeasureStats( self, values, number, measureName ):
        #if self.verbose:
        #    print("MeasureStats()")

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
        'schaefer100x7',
        'schaefer100x17',
        'schaefer200x7',
        'schaefer200x17',
        'schaefer300x7',
        'schaefer300x17',
        'schaefer500x7',
        'schaefer500x17']

    return(names)


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
              "schaefer400x7":"*Schaefer2018_300Parcels7Networks.nii.gz",
              "schaefer400x17":"*Schaefer2018_300Parcels17Networks.nii.gz",
              "schaefer500x7":"*Schaefer2018_500Parcels7Networks.nii.gz",
              "schaefer500x17":"*Schaefer2018_500Parcels17Networks.nii.gz"
    }

    imgFiles = suffix

    for tag in suffix.keys():
        files = glob.glob(os.path.join(directory, suffix[tag]))
        imgFiles[tag] = files

    return(imgFiles)

def getFTDCQuantsifier( imgFiles ):
    q = Quantsifier()
    imgs = imgFiles
    for tag in imgFiles.keys():
        if len(imgFiles[tag])>0:
            #print("Reading "+imgFiles[tag][0])
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