x = read.csv("mindboggle.csv")

names = sort(unique(x$name))
abb = rep("", length(names))

txt = "      \"Name\": \"Region\","
txt = c(txt, "      \"Values\": [")



for ( i in 1:length(names)) {
    abb[i] = x$abbreviation[ which(x$name==names[i])[1] ]
    txt = c(txt, "        {")
    txt = c(txt, paste0("          \"Name\": \"",names[i],"\","))
    txt = c(txt, paste0("          \"Abbreviation\": \"",abb[i],"\""))
    txt = c(txt, "        },")
}


fileConn=file("mindboggle.txt")
writeLines(txt, fileConn)
close(fileConn)

x$cortex[ is.na(x$cortex) ]=0
x$hemisphere[ is.na(x$hemisphere) ]="none"
x$lobe[ is.na(x$lobe) ] = "none"
name_us = gsub( " ", "_", x$name)

roi = c()
for ( i in 1:nrow(x) ) {
    roi = c(roi, "    {")
    hemi = ""
    if ( x$hemisphere[i]=="right" ){
        hemi = "_right"
    } else if ( x$hemisphere[i]=="left") {
        hemi="_left"
    }
    roi = c(roi, paste0("      \"Name\": \"", name_us[i],hemi,"\","))
    roi = c(roi, paste0("      \"ImageID\": ", x$number[i],","))
    roi = c(roi, "      \"Groups\": [")
    roi = c(roi, "        {")
    roi = c(roi, "          \"Name\": \"Hemisphere\"," )
    roi = c(roi, paste0("          \"Value\": \"", x$hemisphere[i], "\"" ))
    roi = c(roi, "        },")   
    roi = c(roi, "        {")
    roi = c(roi, "          \"Name\": \"Tissue\"," )

    hasTissue=FALSE
    if ( x$cortex[i] == 1 ) {   
       roi = c(roi, paste0("          \"Value\": \"", "CorticalGrayMatter", "\"" ))
       hasTissue=TRUE
    }
    if (x$lobe[i]=="subcortical") {
        roi = c(roi, paste0("          \"Value\": \"", "SubcorticalGrayMatter", "\"" ))
        hasTissue=TRUE
    }
    if (x$lobe[i]=="ventricle") {
        roi = c(roi, paste0("          \"Value\": \"", "CorticalSpinalFluid", "\"" ))
        hasTissue=TRUE
    }
    if (x$lobe[i]=="cerebellum") {
        roi = c(roi, paste0("          \"Value\": \"", "Cerebellum", "\"" ))
        hasTissue=TRUE
    }
    if (!hasTissue) {
        roi = c(roi, paste0("          \"Value\": \"", "Other", "\"" ))
        hasTissue=TRUE        
    }

    roi = c(roi, "        },")   
    roi = c(roi, "        {")
    roi = c(roi, "          \"Name\": \"Region\"," )
    roi = c(roi, paste0("          \"Value\": \"", x$name[i], "\"" ))
    roi = c(roi, "        },")   
    roi = c(roi, "        {")
    roi = c(roi, "          \"Name\": \"Group\"," )
    roi = c(roi, paste0("          \"Value\": \"", x$lobe[i], "\"" ))
    roi = c(roi, "        }")   
    roi = c(roi, "      ],")
    roi = c(roi, "      \"Masking\": {")
    roi = c(roi, "        \"Group\": \"Tissue\",")
    roi = c(roi, "        \"Include\": [")
    hasMask=FALSE
    if ( x$cortex[i]==1 ) {
        roi = c(roi, "          \"CorticalGrayMatter\"")
        hasMask=TRUE
    }
    if ( x$lobe[i]=="subcortical") {
        roi = c(roi, "          \"CorticalGrayMatter\",")
        roi = c(roi, "          \"SubcorticalGrayMatter\",")
        roi = c(roi, "          \"Brainstem\",")
        roi = c(roi, "          \"Cerebellum\"")
        hasMask=TRUE
    }
    if (!hasMask) {
        roi = c(roi, "          \"CorticalGrayMatter\",")
        roi = c(roi, "          \"SubcorticalGrayMatter\",")
        roi = c(roi, "          \"Brainstem\",")
        roi = c(roi, "          \"Cerebellum\",")
        roi = c(roi, "          \"Whitematter\",")
        roi = c(roi, "          \"CorticalSpinalFluid\"")
        hasMask=TRUE    
    }
    roi = c(roi, "        ]")
    roi = c(roi, "      }")
    if (i < nrow(x)) {
        roi = c(roi, "    },")
    } else {
        roi = c(roi, "    }")
    }





}

fileConn=file("mindboggle_roi.txt")
writeLines(roi, fileConn)
close(fileConn)