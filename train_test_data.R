## train data ##

library(dplyr)
library(pubMR)
library(data.table)
library(textstem)
dir <- "/home/share/data/pubmed_doc/pubmed_"
year <-2011:2020
file <- paste0(dir,year,".csv")

df <- list()
for(i in seq(file))
{
   tmp <- fread(file[i],header=F,sep="\t",fill=T,quote="",
      col.names=c("pmid","ti","jt","ab"))
   df[[i]] <- tmp
   cat("file = ",file[i],"\n")
}
df <- rbindlist(df)
df <- df[!ab=="",]
df[,n:=.N,by=jt]
#df <- df[n>2000,]
#idx <- c("PloS one","Scientific reports","Journal of clinical medicine","International journal of environmental research and public health")
#idx <- c("PloS one","Scientific reports") 
#df <- df[!jt%in%idx,]
df[,label:=.GRP,by=jt]
ID <- df[,list(label=unique(label)),by=jt]

library(stopwords)
s <- stopwords(source="stopwords-iso")
x <- df$ab
x <- tolower(x)
x <- gsub('\\(.*?\\)', '',x)
x <- strsplit(x, "\\W")
x <- lapply(x, FUN = function(x) x[!x%in%s])
x <- lapply(x,FUN=function(x) gsub("^[0-9].*","",x))
x <- lapply(x, FUN = function(x) x[!x==""])
x <- lapply(x,stem_words)
x <- sapply(x, FUN = function(x) paste(x, collapse = " "))
y <- df$label

train <- data.table(ab_raw=df$ab,ab=x,label=y,jt=df$jt,pmid=df$pmid)
fwrite(train,file= paste0(dir,"train_v0.csv"))

## test data ##
df1 <- fread("/home/share/data/pubmed_doc/pubmed_2021_10_01.csv",
   header=F,sep="\t",fill=T,quote="",
   col.names=c("pmid","ti","jt","ab"))
df1 <- df1[!ab=="",]
df1 <- merge(df1,ID,all.x=TRUE,by="jt")
df1 <- df1[!is.na(label),]


x1 <- df1$ab
x1 <- tolower(x1)
x1 <- gsub('\\(.*?\\)', '',x1)
x1 <- strsplit(x1, "\\W")
x1 <- lapply(x1, FUN = function(x) x[!x%in%s])
x1 <- lapply(x1,FUN=function(x) gsub("^[0-9].*","",x))
x1 <- lapply(x1, FUN = function(x) x[!x==""])
x1 <- lapply(x1,stem_words)
x1 <- sapply(x1, FUN = function(x) paste(x, collapse = " "))

y1 <- df1$label
id <- !x1==""
x1 <- x1[id]
y1 <- y1[id]
jt <- df1[,jt][id]
ab_raw <- df1[,ab][id]
pmid <- df1[,pmid][id]
test <- data.table(ab_raw=ab_raw,ab=x1,label=y1,jt=jt,pmid=pmid)
fwrite(test,file= paste0(dir,"test_v0.csv"))

fwrite(ID,file= paste0(dir,"ID_v0.csv"))

