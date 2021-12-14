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
set.seed(100)
model <- embed_tagspace(x=train[,ab],y=train[,jt],
   early_stopping=0.9,validationPatience=10,dim=100,
   lr=0.01,epoch=40,adagrad=TRUE,
   similarity="dot",negSearchLimit=100,loss="hinge",
   ngrams=2,minCount=100,bucket=100000,thread=18,margin=0.05)

starspace_save_model(model, file = "biomenderR.ruimtehol") 


#model <- starspace_load_model("jr_starspace_v0.ruimtehol")




test <- fread(test)
test[,jt:=gsub(" ","-",jt)]
idx <- test[,jt] %in% train[,unique(jt)]
test <-test[idx,]


p <- predict(model,test[,ab],k=10)
p <- lapply(p,function(x) x$prediction$label)
p <- do.call("rbind",p)
s <- apply(p==test[,jt],1,any)
mean(s)


res <- data.table(score=s,label=test[,jt])
res[,N:=.N,by=label]
res <- res[,list(s=mean(score)),by=c("label","N")]
res <- res[order(s),]





df <- split(train,by="jt")
n <- 1000
for(i in seq(df))
{
   id <- sample(nrow(df[[i]]),n)
   df[[i]] <- df[[i]][id,]
}
df <- rbindlist(df)
p <- predict(model,df[,ab],k=10)
p <- lapply(p,function(x) x$prediction$label)
p <- do.call("rbind",p)
counts <- table(p)
counts <- sort(counts,decreasing=TRUE)
f <- data.table(jt=names(counts),counts=as.numeric(counts))
fwrite(f,"counts.csv")



