#library(data.table)
#library(ruimtehol)
#dir <- "/home/share/data/pubmed_doc"
#train <- "pubmed_train_v0.csv"
#train <- file.path(dir,train)
#train <- fread(train)
#train[,n:=.N,by=jt]
#train <- train[n>2000,]
#train[,jt:=gsub(" ","-",jt)]
#set.seed(100)
#model <- embed_tagspace(x=train[,ab],y=train[,jt],
#   early_stopping=0.9,validationPatience=10,dim=100,
#   lr=0.01,epoch=40,adagrad=TRUE,
#   similarity="dot",negSearchLimit=100,loss="hinge",
#   ngrams=2,minCount=100,bucket=100000,thread=18,margin=0.05)
#
#starspace_save_model(model, file = "jr_starspace_v0.ruimtehol") 



jpredict <- function(x,k=10,m)
{
   require(ruimtehol)
   .prepare_fun <- function(x)
   {
      require(stopwords)
      require(textstem)
      s <- stopwords(source="stopwords-iso")
      x <- tolower(x)
      x <- gsub('\\(.*?\\)', '',x)
      x <- strsplit(x,"\\W")
      x <- lapply(x,FUN=function(x) x[!x%in%s])
      x <- lapply(x,FUN=function(x) gsub("^[0-9].*","",x))
      x <- lapply(x,FUN=function(x) x[!x==""])
      x <- lapply(x,stem_words)
      x <- sapply(x,FUN=function(x) paste(x, collapse = " "))
      x
   }
   model <- starspace_load_model(m)
   x1 <- .prepare_fun(x)
   p <- predict(model,x1,k=k)
   p <- lapply(p,function(x) x$prediction$label)
   do.call("rbind",p)   
}

x1 <- c("apple","RNA-seq")
m <- "biomenderR.ruimtehol"
jpredict(x1,k=10,m=m)

ptm<-proc.time()
jpredict(x1,k=10,m=m)
proc.time()-ptm


