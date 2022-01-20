import itk
import numpy as np
import pandas as pd

class Quantsifier():

    def __init__(self):

        #super().__init__()
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

    def AddMeasure(self, measure, name, regions, threshold=0.00001):
        if not name in self.measures.keys():
            if self.ValidateInput(measure):
                self.measures[name] = {"image":measure, "regions":regions, "threshold":threshold}
                if self.verbose:
                    print("Added measure image named: "+name)
                
    def SetSegmentation(self, segmentation):
        if self.ValidateInput(segmentation):
            self.segmentation = segmentation
            self.segmentationRegions = np.unique(itk.array_view_from_image(self.segmentation))
            if 0 in self.segmentationRegions:
                self.segmentationRegions = np.delete(self.segmentationRegions, 0)
        if self.verbose:
            print("Segmentation regions: "+str(self.segmentationRegions))
        self.voxvol = np.prod( itk.GetArrayFromVnlVector( segmentation.GetSpacing().GetVnlVector() ) )


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
            valid = self.refspace['origin'] == img.GetOrigin()
            valid = valid and self.refspace['spacing'] == img.GetSpacing()
            valid = valid and self.refspace['direction'] == img.GetDirection()
            valid = valid and self.refspace['size'] == img.shape

        if not valid:
            print("Invalid input image")
            print(self.refspace)
            print(img.GetOrigin())
            print(img.GetSpacing())
            print(img.GetDirection())
            print(img.shape)


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
        if self.verbose:
            print("Update")

        if None in [self.mask, self.segmentation]:
            return False
        if len(self.labels)==0:
            return False

        # Precompute segmentation region masks
        for i in self.segmentationRegions:
            self.regionMasks[i] = self.GetSegmentationMask(i)
        if self.verbose:
            print("Precomputed region masks")

        stats = []
        print( "Summarizing "+str(len(self.labels.keys())) + " labeling systems" )
        for sysName in self.labels.keys():
            if self.verbose:
                print("Summarizing system: " + sysName)

            measuresToUse = ['volume']
            if not self.measures is None:
                measureNames = self.measures.keys()

            sysMeasures = self.labels[sysName][3]
            if not sysMeasures is None:

                applicableMeaures = set(sysMeasures).intersection(measureNames)
                if len(applicableMeaures) > 0:
                    measuresToUse.extend(applicableMeaures)


            for mName in measuresToUse:
                if self.verbose:
                    print("Summarizing measure:"+mName)
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

        print("  >> Summarize( "+systemName+" "+measureName+" )")

        if self.verbose:
            print("Summarize( "+systemName+" "+measureName+" )")

        stats=[]
        for r in self.segmentationRegions:
            rstats = self.SummarizeRegion(systemName, measureName, r)
            if len(rstats)>0:
                stats += rstats

        return(stats)

    def SummarizeRegion(self, systemName, measureName, segRegion):

        if self.verbose:
            print("SummarizeRegion() for region=="+str(segRegion))

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
    