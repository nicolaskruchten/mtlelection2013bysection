library(reshape2)
election2013 <- read.csv("elections-2013-resultats-detailles.csv")
melted = melt(subset(election2013, Poste == "0"))
casted = dcast(subset(melted, variable=="Votes"), District+Bureau ~ Candidat)
casted$section = paste(sprintf("%03d", as.numeric(lapply(strsplit(as.character(casted$District), "-"), "[", 1))),
                       sprintf("%03d", as.numeric(as.character(casted$Bureau))),sep="-")
topThree = casted[c("section", "District", "Bureau", "CODERRE Denis", "BERGERON Richard", "JOLY Mélanie", "CΓTÉ Marcel")]
names(topThree) = c("NOM_SECTION", "District", "Bureau", "Coderre", "Bergeron", "Joly", "Côté")
write.csv(topThree, file="data.csv", row.names=FALSE)