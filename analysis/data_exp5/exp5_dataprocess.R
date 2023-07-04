#Pre-processes data for Experiment 6, and saves to a summary file.

#Covers:
#Accuracy
#JOLs
#RTs

library(xlsx)
library(dplyr)
library(tidyr)

folder = 'online/'
fnames = list.files(folder)
cutzero = 1 #cut subjects with 0 accuracy on final memory test.
writefile = 0


subnums = vector()
for (n in 1:length(fnames)){
  cname = fnames[n]
  #Only use if they completed Day 1 + 2.
  if (substr(cname, 1, 4) == "test"){
    start = unlist(gregexpr(pattern = '_', cname))[1] + 1       #find underscore, subnum begins right after.
    finish = unlist(gregexpr(pattern = '.txt', cname))[1] - 1   #find file extension index, 1 before that is end of subnum.
    subnums = c(subnums, substr(cname, start, finish))
  }
}

if (cutzero == 1){
  indextocut = vector()
  for (i in 1:length(subnums)){
    subn = subnums[i]
    dattest = read.csv(paste0(folder, 'test_', subn, '.txt'))
    
    #Last columns are empty due to an artifact when converting from csv. Trim it.
    dattest = dattest[,1:dim(dattest)[2]-1]
    colinds = sapply(dattest, is.factor)
    dattest[colinds] = lapply(dattest[colinds], as.character)
    acc = vector(mode = 'double', length = dim(dattest)[1])
    for (n in 1:dim(dattest)[1]){
      if (is.na(dattest$response[n])){
        acc[n] = 0
      } else if (dattest$response[n] != dattest$word2[n]){
        acc[n] = 0
      } else {
        acc[n] = 1
      }
    }
    
    if (sum(acc) == 0) {
      indextocut = c(indextocut, i)
    }
  }
  
  if (length(indextocut) > 0){
    subnums_orig = subnums
    subnums = subnums[-indextocut]    
  }
}


#Size should match the reformatted stuff from Exp2 in the allstudy/restudy/test.xlsx files
allstudy = data.frame(matrix(data = NA, nrow = 0, ncol = 10))
allrestudy = data.frame(matrix(data = NA, nrow = 0, ncol=14))
alltest = data.frame(matrix(data = NA, nrow = 0, ncol = 18))

# From analysis, for reference
# #Subn, avg acc, avg jol, meta acc for restudy, meta acc for test, Jols for quartiles 1-4. Restudy Acc for quartiles, Test Acc for quartiles.
# datsummary = data.frame(matrix(data = NA, nrow = length(subnums), ncol = 19))
# colnames(datsummary) = c("subn", "accrestudyall", "acctestall", "jolmean", "jolrecalled","calstudy", "caltest", 
#                       "jol1", "jol2", "jol3", "jol4", "accrest1", "accrest2", "accrest3", "accrest4",
#                       "acctest1", "acctest2", "acctest3", "acctest4")

datreform = data.frame(matrix(data = NA, nrow = 0, ncol = 5))
colnames(datreform) = c("subn", "acc", "jolmean", "jolq", "prac")



for (i in 1:length(subnums)){
#for (i in 23){
  subn = subnums[i]

  rawstudy = read.csv(paste0(folder, 'study_', subn, '.txt'))
  rawrestudy = read.csv(paste0(folder, 'restudy_', subn, '.txt'))
  rawtest = read.csv(paste0(folder, 'test_', subn, '.txt'))
  
  rawstudy[] = lapply(rawstudy, function(x) if (is.factor(x)) as.character(x) else {x})
  rawrestudy[] = lapply(rawrestudy, function(x) if (is.factor(x)) as.character(x) else {x})
  rawtest[] = lapply(rawtest, function(x) if (is.factor(x)) as.character(x) else {x})
  
  #Last columns are empty due to an artifact when converting from csv. Trim it.
  rawstudy = rawstudy[,1:dim(rawstudy)[2]-1]
  rawrestudy = rawrestudy[,1:dim(rawrestudy)[2]-1]
  rawtest = rawtest[,1:dim(rawtest)[2]-1]
  
  datstudy = data.frame(matrix(data = NA, nrow = dim(rawstudy)[1], ncol = 13))
  datrestudy = data.frame(matrix(data = NA, nrow = dim(rawrestudy)[1], ncol=17))
  dattest = data.frame(matrix(data = NA, nrow = dim(rawtest)[1], ncol = 21))
  
  #Exp5: now have choice + honor/dishonor introduced.
  #Now also reorders and uses jol rank from rawrestudy
  cnames = c("subn", "word1", "word2", "trial", "list", "jol", "jolrt", "jolrank", "jolrankp",
             "practice", "honor", "choice", "choicert", 
             "restudyresp", "restudyacc", "restudyrtfirst", "restudyrt",
             "response", "testacc", "rtfirst", "rt")
  
  colnames(datstudy) = cnames[1:dim(datstudy)[2]]
  colnames(datrestudy) = cnames[1:dim(datrestudy)[2]]
  colnames(dattest) = cnames[1:dim(dattest)[2]]

  if (i == 1){
    allstudy = datstudy[0,]
    allrestudy = datrestudy[0,]
    alltest = dattest[0,]
  }
  
  trial = 1:40
  jolrank = 1:40 #used to use   #datstudy = datstudy[order(datstudy$jol),]
  jolrankp = jolrank/40
  #restudyrank = 1:20
  
  #### Update Study
  datstudy[,1] = subn
  datstudy[,2:7] = rawstudy[,1:6]
  datstudy$choice = rawstudy$choice
  datstudy$choicert = rawstudy$choicert
  
  
  start = dim(datstudy)[1]-length(trial)+1
  finish = dim(datstudy)[1]
  datstudy = datstudy[order(datstudy$jol),]
  datstudy$jolrank[start:finish] = jolrank
  datstudy$jolrankp[start:finish] = jolrankp
  datstudy = datstudy[order(datstudy$list, datstudy$trial),]
  
  
  practice = vector(mode = 'double', length = dim(datstudy)[1])
  honor = practice
  
  for (n in 1:dim(rawstudy)[1]){
    index = which(rawstudy[n,1] == rawrestudy[,1])
    practice[n] = rawrestudy$praccond[index[1]] #warnings pop up otherwise, if one has multiple restudy
    honor[n] = rawrestudy$hondis[index[1]]
  }
  
  datstudy$practice = practice
  datstudy$honor = honor

  
  #### Update Restudy
  datrestudy[,1] = subn
  datrestudy[,2:3] = rawrestudy[,1:2]
  datrestudy$jol =rawrestudy$jol
  datrestudy$jolrt = rawrestudy$jolrt
  datrestudy$practice = rawrestudy$praccond
  datrestudy$restudyresp = rawrestudy$response

  for (n in 1:3){
    start = (n-1)*length(trial)+1
    finish = n*length(trial)
    datrestudy$list[start:finish] = n
    datrestudy$trial[start:finish] = trial
  }

  datrestudy$restudyrtfirst = rawrestudy$rtfirst
  datrestudy$restudyrt = rawrestudy$rt
  
  
  restudyacc = vector(mode = 'double', length = dim(dattest)[1])

  for (n in 1:dim(rawrestudy)[1]){
    index = which(rawrestudy[n,1] == rawstudy[,1]) 
    index = index[length(index)] #grab last index, which is where JOLs were entered since they're delayed.
    
    datrestudy$jolrank[n] = datstudy$jolrank[index]
    datrestudy$jolrankp[n] = datstudy$jolrankp[index]
    datrestudy$honor[n] = datstudy$honor[index]
    datrestudy$choice[n] = datstudy$choice[index]
    datrestudy$choicert[n] = datstudy$choicert[index]

    if (rawrestudy$praccond[n] == 0){
      restudyacc[n] = NA
      datrestudy$restudyrt[n] = NA
      datrestudy$restudyrtfirst = NA
      datrestudy$restudyresp[n] = ''
    } else if (is.na(rawrestudy$response[n])) {
      restudyacc[n] = 0
    } else if (rawrestudy$response[n] != rawrestudy$word2[n]){
      restudyacc[n] = 0
    } else {
      restudyacc[n] = 1
    }
  }
  
  datrestudy$restudyacc = restudyacc
  
  
  ####Update Test
  dattest$response = rawtest$response
  dattest$rtfirst = rawtest$rtfirst
  dattest$rt = rawtest$rt
  
  testacc = vector(mode = 'double', length = dim(dattest)[1])
  #Grab relevant parts from restudy
  for (n in 1:dim(dattest)[1]){
    
    index = which(rawtest[n,1] == rawrestudy[,1])[1] #match word1
    dattest[n,1:dim(datstudy)[2]] = datrestudy[index,1:dim(datstudy)[2]]
    

    if (is.na(rawtest$response[n])) {
      testacc[n] = 0
    } else if (rawtest$response[n] != rawtest$word2[n]){
      testacc[n] = 0
    } else {
      testacc[n] = 1
    }
  }
  dattest$testacc = testacc
  
  
  #Combine individual subjects' data into omnibus variables
  allstudy = rbind(allstudy, datstudy)
  allrestudy = rbind(allrestudy, datrestudy)
  alltest = rbind(alltest, dattest)
}



##WRITE THE FILE
if (writefile == 1){
  write.xlsx(allstudy, paste0('allstudy.xlsx'), sheetName = "Sheet1", row.names=FALSE)
  write.xlsx(allrestudy, paste0('allrestudy.xlsx'), sheetName="Sheet1", row.names=FALSE)
  write.xlsx(alltest, paste0('alltest.xlsx'), sheetName = "Sheet1", row.names=FALSE)
  
  write.csv(allstudy, paste0('csv/', 'allstudy.csv'), row.names=FALSE)
  write.csv(allrestudy, paste0('csv/', 'allrestudy.csv'), row.names=FALSE)
  write.csv(alltest, paste0('csv/', 'alltest.csv'), row.names=FALSE)
}
