#!/bin/bash

Rscript extractdata.r
topojson --bbox --properties=NOM_SECTION,ARRONDISSEMENT,District,Bureau,Bergeron,Coderre,Joly,Côté --id-property=NOM_SECTION --external-properties=data.csv -o sections.topojson sectionelect.json