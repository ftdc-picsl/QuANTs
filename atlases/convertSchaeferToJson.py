import json
import os
import sys

#defFile = "/Users/jtduda/projects/Grossman/Parcellations/MNI/Schaefer2018_200Parcels_17Networks_order.txt"
defFile = sys.argv[1]

nameParts = os.path.split(defFile)[1].split("_")
nParcels = nameParts[1].replace("Parcels", "")
nNetworks = nameParts[2].replace("Networks", "")
atlasName = "Schaefer"+nParcels+"x"+nNetworks
print(atlasName)

hemiAbb = { 
    "LH" : "left",
    "RH" : "right"
}
net7Abb = {
    "Vis" : "visual",
    "SomMot" : "somatomotor",
    "DorsAttn" : "dorsal attention",
    "SalVentAttn" : "salience ventral attention",
    "Limbic" : "limbic",
    "Cont": "control",
    "Default": "default"
}
net17Abb = {
    "VisCent": "central visual",
    "VisPeri": "peripheral visual",
    "SomMotA": "somatomotor A",
    "SomMotB": "somatomotor B",
    "DorsAttnA" : "dorsal attention A",
    "DorsAttnB" : "dorsal attention B",
    "SalVentAttnA": "salience ventral attention A",
    "SalVentAttnB": "salience ventral attention B",
    "LimbicA" : "limbic A",
    "LimbicB" : "limbic B",
    "ContA" : "control A",
    "ContB" : "control B",
    "ContC" : "control C",
    "DefaultA" : "default A",
    "DefaultB" : "default B",
    "DefaultC" : "default C",   
    "TempPar": "temporal parietal"
}

region7Abb = {
    "Post" : "posterior",
    "FEF" : "frontal eye fields",
    "PrCv" : "percentral ventral",
    "ParOper": "parietal operculum",
    "FrOperIns" : "frontal operculum insula",
    "PFCl" : "lateral prefrontal cortex",
    "Med": "medial",
    "OFC" : "orbital frontal cortex",
    "TempPole": "temporal pole",
    "TempOCC": "temporal occipital",
    "Par": "parietal",
    "Temp": "temporal",
    "pCun": "precuneus",
    "Cing": "cingulate",
    "PFC": "prefrontal cortex",
    "PFCd": "dorsal prefrontal cortex",
    "pCunPCC": "precuneus posterior cingulate cortex",
    "PHC": "parahippocampal cortex",
    "TempOccPar": "temporal occipital parietal",
    "PrC": "precentral",
    "PFCv": "ventral prefrontal cortex",
    "PFCmp": "medial posterior prefrontal cortex",
    "PFCdPFCm": "dorsal prefrontal cortex medial prefrontal cortex",
    "pCunPCC": "precuneus posterior cingulate cortex",
    "TempOcc" : "temporal occipital"
}

reg17Abb = {
    "Striate": "striate cortex",
    "ExStr" : "extrastriate cortex",
    "StriCal" : "striate calcarine",
    "ExStrInf" : "extra-striate inferior",
    "ExStrSup" : "extra-striate superior",
    "Cent" : "central",
    "S2" : "S2",
    "Ins" : "insula",
    "Aud" : "auditory",
    "TempOcc" : "temporal occipital",
    "ParOcc" : "parietal occipital",
    "SPL" : "superior parietal lobule",
    "PostC" : "post central",
    "FEF" : "frontal eye fields",
    "PrCv" : "precentral ventral",
    "ParOper" : "parietal operculum",
    "FrOper" : "frontal operculum",
    "ParMed" : "parietal medial",
    "FrMed" : "frontal medial",
    "IPL" : "interior parietal lobule",
    "PFCd" : "dorsal prefrontal cortex",
    "PFCl" : "lateral prefrontal cortex",
    "PFCv" : "ventral prefrontal cortex",
    "PFCld" : "lateral dorsal prefrontal cortex",
    "OFC" : "orbital frontal cortex",
    "Temp" : "temporal",
    "TempPole": "temporal pole",
    "IPS" : "intraparietal sulcus",
    "PFClv" : "lateral ventral prefrontal cortex",
    "Cingm" : "mid-cingulate",
    "PFCmp" : "medial posterior prefrontal cortex",
    "pCun" : "precuneus",
    "Cingp" : "cingulate posterior",
    "pCunPCC" : "precuneus posterior cingulate cortex",
    "PFCm" : "medial prefrontal cortex",
    "Rsp" : "retrosplenial",
    "PHC" : "parahippocampal cortex",
    "TempPar" : "temporal parietal",
    "PrC" : "precentral",
    "AntTemp" : "anterior temporal",
    "Cinga" : "cingulate anterior"
}

atlasDict = {
    "Name": atlasName,
    "Identifier": atlasName,
    "Description": "",
    "DevNotes": [""],
    "QuantsVersion" : "1.0",
    "BIDSVersion": "1.0",
    "TemplateSpace": "TustisonAging2019ANTs",
    "res" : "01",
    "Species": "Homo sapiens",
    "Authors": "",
    "Maintainers": "",
    "ReferenceAndLinks": ["https://doi.org/10.1093/cercor/bhx179"],
    "License": "",
    "Domains" : ["Volume", "Cortical", "Functional", "Connectivity"],
}

netAbb = net7Abb
regionAbb = region7Abb
print(nNetworks)
if int(nNetworks)==17:
    print("17")
    netAbb = net17Abb
    regionAbb = reg17Abb

nodeList = []
networkRegions = {}

with open(defFile, 'r') as file:
    lines = file.readlines();
    file.close()

    for line in lines:
        values = line.strip().split("\t")
        id = values[0]
        name = values[1]
        r = int(values[2])
        g = int(values[3])
        b = int(values[4])
        
        parts = name.split('_')
        atlas = parts[0]
        hemi = parts[1]
        network = parts[2]
        region = "none"
        localId = parts[3]
        if len(parts) > 4:
            region = parts[3]
            localId = parts[4]

        hemisphere=hemiAbb[hemi]
        regionName = region
        if not region=="none":
            regionName = regionAbb[region]
        networkName = netAbb[network]
        
        
        #print( atlas + " " + hemi + " " + network + " " + str(region) + " " + localId)
        nGroups = [ {"Name": "Hemisphere", "Value": hemisphere} ]
        nGroups.append( { "Name": "Tissue", "Value": "Cortical Gray Matter"} )
        nGroups.append( {"Name": "Region", "Value": regionName, "GroupID": int(localId)})
        nGroups.append( {"Name": "Network", "Value": networkName})

        node = { "Name": name, "ImageID": int(id), "RGB": [r,g,b], "Groups": nGroups}
        nodeList.append(node)

        if network in networkRegions.keys():
            if not region=="none":
                regionList = networkRegions[network]
                if not region in regionList:
                    regionList.append(region)
                    networkRegions[network] = regionList
        else:
            regionList = []
            if not region=="none":
                regionList.append(region)
            networkRegions[network]=regionList


networkList = []
for abb,name in sorted(netAbb.items()):
    netNode = {"Name": name, "Abbreviation": abb}
    networkList.append(netNode)

regionList = []
for abb,name in sorted(regionAbb.items()):
    regNode = {"Name": name, "Abbreviation": abb}
    regionList.append(regNode)


#jOut = json.dumps({"nodes":nodeList})
hemiGroup = {"Name": "Hemisphere", "Values": []}
hemiGroup["Values"].append( { "Name": "left", "Abbreviation": "LH"})
hemiGroup["Values"].append( { "Name": "right", "Abbreviation": "RH"})
hemiGroup["Values"].append( { "Name": "none", "Abbreviation": "none"})

tissueGroup = {"Name": "Tissue", "Values": []}
tissueGroup["Values"].append( { "Name": "Cortical Spinal Fluid", "Abbreviation": "CSF", "GroupID": 1})
tissueGroup["Values"].append( { "Name": "Cortical Gray Matter", "Abbreviation": "CGM", "GroupID": 2})
tissueGroup["Values"].append( { "Name": "Whitematter", "Abbreviation": "WM", "GroupID": 3})
tissueGroup["Values"].append( { "Name": "Subcortical Gray Matter", "Abbreviation": "SCGM", "GroupID": 4})
tissueGroup["Values"].append( { "Name": "Brainstem", "Abbreviation": "GS", "GroupID": 5})
tissueGroup["Values"].append( { "Name": "Cerebellum", "Abbreviation": "CBM", "GroupID": 6})

networkGroup = {"Name": "Network", "Values": networkList}
regionGroup = {"Name": "Region", "Values": regionList}

atlasDict["Groups"] = [ hemiGroup, tissueGroup, networkGroup, regionGroup ]
#atlasDict["Networks"]=networkList
#atlasDict["Regions"]=regionList
atlasDict["ROI"]=nodeList
with open(atlasName+'.json', 'w') as outfile:
    json.dump(atlasDict, outfile, indent=2)