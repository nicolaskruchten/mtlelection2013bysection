library(reshape2)
library(gtools)
library(stringr)

election2013 <- read.csv("elections-2013-resultats-detailles.csv")
election2013$early = ifelse(str_detect(election2013$Bureau, "[096]...?"), "early", "electionday")

election2013$Bureau = factor(election2013$Bureau,mixedsort(levels(election2013$Bureau)))
compacted = dcast(subset(election2013, early=="electionday"), 
                  District+Poste+Candidat~Bureau, value.var="Votes", fun.aggregate=sum)
compacted$District = as.numeric(lapply(strsplit(as.character(compacted$District), "-"), "[", 1))
write.csv(compacted, file="data.csv", row.names=FALSE)