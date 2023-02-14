

biomenderR_project
==========
BiomenderR projct is a lightweight, user-friendly recommendation framework for biomedical journals. It can recommend suitable journals for user as long as the user enters the abstract of the paper.
## Authors



[周晓北] (Zhou Xiaobei)  
[周淼]  (Zhou Miao)                             
[刘文粟]（Liu Wensu）

## R package installation
```r
install.packages("devtools")
devtools::install_github("xizhou/biomenderR")
```

## Web application programming interface
a web application programming interface (API) is available on
```
https://beilab.goho.co/biomenderR_app
```

##  How to use biomenderR locally

###  Download the file "biomenderR.ruimtehol", this is the trained model. 
We also provide codes that can load biomenderR and use biomenderR in R for the convenience of users. The code is in file "jpredict.R".
```
cd biomenderR 
```
BiomenderR needs to be loaded in the R software.
### R  
```
source("jpredict.R") 
```
###  A example of use biomenderR
```r
x1 <- c("We proposed a xxx model for yyy analysis that can provide statistical inferences about zzz. The conceptual model framework and simulations are illustrated in the manuscript.")
m <- "biomenderR.ruimtehol"
jpredict(x1,k=10,m=m)
```
Here, x1 is the text of your abstract, we just use a word instead of abstract. Then,we want to get top-10 journals, so we set k=10. If you want to get different numbers of results, you can set k=n (n is an integer).  The process of predicting results only take 3.036 seconds, results are showed as follow.

```text
     [,1]                                      
[1,] "Statistical-methods-in-medical-research"
     [,2]
     "Entropy-(Basel,-Switzerland)"
     [,3]
[1,] "Statistics-in-medicine"
     [,4]
[1,] "Computer-methods-in-biomechanics-and-biomedical-engineering"
     [,5]
[1,] "IEEE/ACM-transactions-on-computational-biology-and-bioinformatics"
     [,6]
[1,] "Journal-of-biomedical-informatics"
     [,7]
[1,] "Computer-methods-and-programs-in-biomedicine"
     [,8]                                                                       
[1,] "Philosophical-transactions.-Series-A,-Mathematical,-physical,-and-engineering-sciences"
     [,9]                                                                       
[1,] "Applied-radiation-and-isotopes-:-including-data,-instrumentation-and-methods-for-use-in-agriculture,-industry-and-medicine"
     [,10]
[1,] "Journal-of-computational-chemistry"

```
From the predicting results, what we see is match with the x1.
###  Predicting similar abstracts
BiomenderR can not only recommend journals, but also find the most similar abstracts.
**Prepare the data set of abstract**
We take the journal "Statistical methods in medical research" as the example, we download the abstract and PMID of publications of Statistical methods in medical research from PubMed. The search strategy is as follows.
```
'("2010/01/01"[PDAT]:"2021/10/01"[PDAT]) AND "Statistical methods in medical research"[Journal]'
```
**Predicting the closest abstracts**
Then, we can use biomenderR to predict the closest abstracts in R software. The code of R is as follows.
```r
model <- starspace_load_model("biomenderR.ruimtehol", method = "ruimtehol")
predict(model, newdata = "We proposed a xxx model for yyy analysis that can provide statistical inferences about zzz. The conceptual model framework and simulations are illustrated in the manuscript.", basedoc=ab)
```
Here ab is the processed abstracts of the journals. In order to see this example intuitively, we visualized the prediction results. As shown below.

"![Image text](https://raw.githubusercontent.com/Miao-zhou/biomenderR/main/Fig.jpg)"

##  Model training
We also provide the process of model training. If you want to train a new model, you only change your training set and you can get your own model.

 ### Processing training set and test set
 
 We provide data processing code for training set and test set. The code is in file "train_test_data.R". The users can use this code to process their data before training the model.   In this place, we use the articles published in the journals retrieved in PubMed database for 10 years as the training set. The code for mining and downloading data from PubMed is in the file "pubmed_export_data.txt"
 
**Import the downloaded data**
```r
library(dplyr)
library(pubMR)
library(data.table)
library(textstem)
dir <- "/home/share/data/pubmed_doc/pubmed_"
year <-2011:2020
file <- paste0(dir,year,".csv")
```
**Data processing**
```r
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
```
**Save as training set or test set**
```r
train <- data.table(ab_raw=df$ab,ab=x,label=y,jt=df$jt,pmid=df$pmid)
fwrite(train,file= paste0(dir,"train_v0.csv"))
```

 ### Training model 
 The code of training model is in file "benchmark_starspace.R"
 
**Import the training set and test set** 
```r
library(data.table)
library(ruimtehol)
dir <- "/home/share/data/pubmed_doc"
train <- "pubmed_train_v0.csv"
train <- file.path(dir,train)
test <- "pubmed_test_v0.csv"
test <- file.path(dir,test)
train <- fread(train)
train[,n:=.N,by=jt]
train <- train[n>2000,]
train[,jt:=gsub(" ","-",jt)]
train <- train[!train[,ab]=="",]
```
**Training the model** 
```r
set.seed(100)
model <- embed_tagspace(x=train[,ab],y=train[,jt],
   early_stopping=0.9,validationPatience=10,dim=100,
   lr=0.01,epoch=40,adagrad=TRUE,
   similarity="dot",negSearchLimit=100,loss="hinge",
   ngrams=2,minCount=100,bucket=100000,thread=18,margin=0.05)
```
**Saving the trained model**
```r
starspace_save_model(model, file = "biomenderR.ruimtehol") 
```
##  Testing the model 
We use the articles published in 2021 medical journals in PubMed as the test set to test the model.
**Import the test set**
```r
test <- fread(test)
test[,jt:=gsub(" ","-",jt)]
idx <- test[,jt] %in% train[,unique(jt)]
test <-test[idx,]
```
**Predicting the test set**
```r
p <- predict(model,test[,ab],k=10)
```
**Get the the probability value and accuracy**
```r
p <- lapply(p,function(x) x$prediction$label)
p <- do.call("rbind",p)
s <- apply(p==test[,jt],10,any)
mean(s)
```
The accuracy of the prediction. The acc@N means  the accuracy of top-N
```text
acc@1: 26.4%
acc@3: 47.2%
acc@5: 57.5%
acc@10: 70.6%
```

