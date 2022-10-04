import json
import os
import sys

defFile = sys.argv[1]
# Tian_Subcortex_S3_3T_2009cAsym.nii.gz

nameParts = os.path.split(defFile)[1].split("_")
scale = nameParts[3]
fieldStrength = nameParts[4]
refSpace = "MNI152NonLinear2009cAsym"

atlasName = nameParts[0] + "_" + nameParts[1] + "_" + nameParts[2] + "_" + nameParts[3]

version="1"
release="1"

#atlasName=atlasName+'v'+version
print(atlasName)

hemiAbb = { 
    "lh" : "left",
    "rh" : "right"
}

regionAbb = {
    "HIP" : "hippocampus",
    "AMY" : "amygdala",
    "THA" : "thalamus",
    "NAc" : "nucleus accumbens",
    "GP" : "globus pallidus",
    "PUT" : "putamen",
    "CAU" : "caudate"
}

atlasDict = {
    "Name": atlasName,
    "Identifier": atlasName,
    "Version": version,
    "Release": release,
    "Git-Repo": "",
    "Git-Commit": "",
    "Description": "",
    "DevNotes": [""],
    "QuantsVersion" : "1.0",
    "BIDSVersion": "1.0",
    "TemplateSpace": refSpace,
    "Species": "Homo sapiens",
    "Authors": "",
    "Maintainers": "",
    "ReferenceAndLinks": ["https://doi.org/10.1093/cercor/bhx179"],
    "License": "",
    "Domains" : ["Volume", "Cortical", "Functional", "Connectivity"],
}


nodeList = []


masking = {"Group": "Tissue", "Include": [ "Cortical Gray Matter", "Subcortical Gray Matter", "Brainstem", "Cerebellum"] }

with open(defFile, 'r') as file:
    lines = file.readlines();
    file.close()

    index=1
    for line in lines:
        value = line.strip()
        id = index
        index = index + 1
        
        parts = value.split('-')
        hemi = parts[len(parts)-1]
        name = value
        hemisphere=hemiAbb[hemi]

        regionName = "none"
        for r in regionAbb.keys():
            if r in name:
                regionName = regionAbb[r]


        #print( atlas + " " + hemi + " " + network + " " + str(region) + " " + localId)
        nGroups = [ {"Name": "Hemisphere", "Value": hemisphere} ]
        nGroups.append( { "Name": "Tissue", "Value": "Subortical Gray Matter"} )
        nGroups.append( {"Name": "Region", "Value": regionName})
        #nGroups.append( {"Name": "Network", "Value": networkName})

        node = { "Name": name, "ImageID": int(id), "Groups": nGroups, "Masking": masking}
        nodeList.append(node)

        #if network in networkRegions.keys():
        #    if not region=="none":
        #        regionList = networkRegions[network]
        #        if not region in regionList:
        #            regionList.append(region)
        #            networkRegions[network] = regionList
        #else:
        #    regionList = []
        #    if not region=="none":
        #        regionList.append(region)
        #    networkRegions[network]=regionList


#networkList = []
#for abb,name in sorted(netAbb.items()):
#    netNode = {"Name": name, "Abbreviation": abb}
#    networkList.append(netNode)

#regionList = []
#for abb,name in sorted(regionAbb.items()):
#    regNode = {"Name": name, "Abbreviation": abb}
#    regionList.append(regNode)


#jOut = json.dumps({"nodes":nodeList})
hemiGroup = {"Name": "Hemisphere", "Values": []}
hemiGroup["Values"].append( { "Name": "left", "Abbreviation": "lr"})
hemiGroup["Values"].append( { "Name": "right", "Abbreviation": "rh"})
hemiGroup["Values"].append( { "Name": "none", "Abbreviation": "none"})

tissueGroup = {"Name": "Tissue", "Values": []}
tissueGroup["Values"].append( { "Name": "Other", "Abbreviation": "OTHER", "GroupID": 0})
tissueGroup["Values"].append( { "Name": "Cortical Spinal Fluid", "Abbreviation": "CSF", "GroupID": 1})
tissueGroup["Values"].append( { "Name": "Cortical Gray Matter", "Abbreviation": "CGM", "GroupID": 2})
tissueGroup["Values"].append( { "Name": "Whitematter", "Abbreviation": "WM", "GroupID": 3})
tissueGroup["Values"].append( { "Name": "Subcortical Gray Matter", "Abbreviation": "SCGM", "GroupID": 4})
tissueGroup["Values"].append( { "Name": "Brainstem", "Abbreviation": "GS", "GroupID": 5})
tissueGroup["Values"].append( { "Name": "Cerebellum", "Abbreviation": "CBM", "GroupID": 6})

regionList = []
for abb,name in sorted(regionAbb.items()):
    regNode = {"Name": name, "Abbreviation": abb}
    regionList.append(regNode)
regionGroup = {"Name": "Region", "Values": regionList}

#networkGroup = {"Name": "Network", "Values": networkList}




atlasDict["Groups"] = [ hemiGroup, tissueGroup ]

#atlasDict["Networks"]=networkList
atlasDict["Regions"]=regionList
atlasDict["ROI"]=nodeList
with open(atlasName+'.json', 'w') as outfile:
    json.dump(atlasDict, outfile, indent=2)