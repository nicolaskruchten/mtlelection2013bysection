#!/bin/bash

topojson --bbox --p id=NOM_SECTION --simplify-proportion=0.2 -o sections.topojson sectionelect.json
Rscript extractData.r
cat data.csv | sed 's/,0,/,,/g' | sed 's/,0,/,,/g' | sed 's/,*$//g' | \
sed 's/╘/È/g' | sed 's/Ω/Û/g' | sed 's/Γ/Ô/g' | sed 's/╖/À/g' | sed 's/╪/Ï/g'  > data2.csv
mv data2.csv data.csv
