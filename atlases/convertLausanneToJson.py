import json
import os
import sys

#defFile = "tpl-TustisonAging2019ANTs_atlas-Lausanne_desc-Scale125_dseg.tsv"
defFile = sys.argv[1]

nameParts = os.path.split(defFile)[1].split("_")
scale = nameParts[2].replace("desc-Scale", "")
atlasName="Lausanne"+scale+'v1'
print(atlasName)
version="1"
release="1"

hemiAbb = { 
    "left" : "left,",
    "right" : "right,"
}



atlasDict = {
    "Name": atlasName,
    "Identifier": atlasName,
    "Filename": "tpl-TustisonAging2019ANTs_res-01_atlas-Lausanne_desc-Scale"+scale+"_dseg.nii.gz",
    "Version": version,
    "Release": release,
    "Git-Repo": "",
    "Git-Commit": "",
    "Description": "",
    "DevNotes": [""],
    "QuantsVersion" : "1.0",
    "BIDSVersion": "1.0",
    "TemplateSpace": "tpl-TustisonAging2019ANTs",
    "res" : "01",
    "Species": "Homo sapiens",
    "Authors": "",
    "Maintainers": "",
    "ReferenceAndLinks": ["https://doi.org/10.1093/cercor/bhx179"],
    "License": "",
    "Domains" : ["Volume", "Cortical", "Functional", "Connectivity"],
}

nodeList = []
regionList = []
networkRegions = {}

masking = {"Group": "Tissue", "Include": [ "CorticalGrayMatter"] }

with open(defFile, 'r') as file:
    lines = file.readlines();
    file.close()

    for line in lines[1:len(lines)]:
        values = line.strip().split("\t")
        id = values[0]
        name = values[1]

        parts = name.split('-')
        hemi = parts[0]
        regionFull = parts[1]

        regionParts = regionFull.split('_')
        region=regionParts[0]
        localId=0
        if len(regionParts) > 1:
            localId = regionParts[1]

        hemisphere=hemiAbb[hemi]
        regionName = region
        
        #print( atlas + " " + hemi + " " + network + " " + str(region) + " " + localId)
        nGroups = [ {"Name": "Hemisphere", "Value": hemisphere} ]
        nGroups.append( { "Name": "Tissue", "Value": "CorticalGrayMatter"} )
        nGroups.append( {"Name": "Region", "Value": regionName, "GroupID": int(localId)})

        node = { "Name": name, "ImageID": int(id), "Groups": nGroups, "Masking": masking}
        nodeList.append(node)

        if not region in regionList:
            regionList.append(region)


hemiGroup = {"Name": "Hemisphere", "Values": []}
hemiGroup["Values"].append( { "Name": "left,", "Abbreviation": "LH"})
hemiGroup["Values"].append( { "Name": "right,", "Abbreviation": "RH"})
hemiGroup["Values"].append( { "Name": "none", "Abbreviation": "none"})

tissueGroup = {"Name": "Tissue", "Values": []}
tissueGroup["Values"].append( { "Name": "Other", "Abbreviation": "OTHER", "GroupID": 0})
tissueGroup["Values"].append( { "Name": "CorticalSpinalFluid", "Abbreviation": "CSF", "GroupID": 1})
tissueGroup["Values"].append( { "Name": "CorticalGrayMatter", "Abbreviation": "CGM", "GroupID": 2})
tissueGroup["Values"].append( { "Name": "WhiteMatter", "Abbreviation": "WM", "GroupID": 3})
tissueGroup["Values"].append( { "Name": "SubcorticalGrayMatter", "Abbreviation": "SCGM", "GroupID": 4})
tissueGroup["Values"].append( { "Name": "Brainstem", "Abbreviation": "BS", "GroupID": 5})
tissueGroup["Values"].append( { "Name": "Cerebellum", "Abbreviation": "CBM", "GroupID": 6})

regionGroup = {"Name": "Region", "Values": regionList}

atlasDict["Groups"] = [ hemiGroup, tissueGroup, regionGroup ]

atlasDict["ROI"]=nodeList
with open(atlasName+'.json', 'w') as outfile:
    json.dump(atlasDict, outfile, indent=2)