x = read.csv("dkt31.csv")

x$name = trimws(as.character(x$name))
x$hemisphere = trimws(as.character(x$hemisphere))
names = sort(unique(x$name))
abb = rep("", length(names))

txt = "      \"Name\": \"Region\","
txt = c(txt, "      \"Values\": [")



for ( i in 1:length(names)) {
    #abb[i] = x$abbreviation[ which(x$name==names[i])[1] ]
    txt = c(txt, "        {")
    txt = c(txt, paste0("          \"Name\": \"",names[i],"\","))
    txt = c(txt, paste0("          \"Abbreviation\": \"",names[i],"\""))
    txt = c(txt, "        },")
}


fileConn=file("dkt31_names.txt")
writeLines(txt, fileConn)
close(fileConn)

x$hemisphere[ is.na(x$hemisphere) ]="none"
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
    roi = c(roi, paste0("          \"Value\": \"", "CorticalGrayMatter", "\"" ))
    roi = c(roi, "        },")   
    roi = c(roi, "        {")
    roi = c(roi, "          \"Name\": \"Region\"," )
    roi = c(roi, paste0("          \"Value\": \"", x$name[i], "\"" ))
    roi = c(roi, "        }")   
    roi = c(roi, "      ],")
    roi = c(roi, "      \"Masking\": {")
    roi = c(roi, "        \"Group\": \"Tissue\",")
    roi = c(roi, "        \"Include\": [")
    roi = c(roi, "          \"CorticalGrayMatter\"")
    roi = c(roi, "        ]")
    roi = c(roi, "      }")
    if (i < nrow(x)) {
        roi = c(roi, "    },")
    } else {
        roi = c(roi, "    }")
    }
}

fileConn=file("dkt31_roi.txt")
writeLines(roi, fileConn)
close(fileConn)