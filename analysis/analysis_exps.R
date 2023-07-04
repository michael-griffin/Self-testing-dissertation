#Blueprint for analysis code: Contains two main sets of analyses:
#1.   Repeated measures ANOVAs for each experiment individually

#2.   the 'practice choice' code, for estimating what the optimal practice choice is
#     as JOLs vary (results shown in practice_choice_graphs.xlsx)


library(xlsx)
library(dplyr)
library(tidyr)
library(ez) #for repeated measures ANOVA


exper = 5
runanov = 0
linear = 0 #Varies which model is used for the decision criteria analysis.
runreg = 0
runcombined = 0
writefile = 0

folder = paste0('data_exp', as.character(exper), '/csv/')

rawallstudy = read.csv(paste0(folder, 'allstudy.csv'))
rawallrestudy = read.csv(paste0(folder, 'allrestudy.csv'))
rawalltest = read.csv(paste0(folder, 'alltest.csv'))

subnums = unique(rawalltest$subn)


#Add jolquartile:
jolquartile = ceiling(rawallstudy$jolrankp*4)
allstudy = cbind(rawallstudy, jolquartile)

jolquartile = ceiling(rawallrestudy$jolrankp*4)
allrestudy = cbind(rawallrestudy, jolquartile)

jolquartile = ceiling(rawalltest$jolrankp*4)
alltest = cbind(rawalltest, jolquartile)


if (runanov == 1){
  ###############
  ####ANOVAS#####
  
  
  #Study analysis:
  #(For Exps 1 and 2): How do jols differ as lists go by during the study phase?
  summstudy = allstudy %>%
    group_by(subn, list, jolquartile) %>%
    summarize(jolmean = mean(jol), jolrt = mean(jolrt))
  
  #ezANOVA needs within-subject variables to be factors. Here's the conversion
  summstudy$list = as.factor(summstudy$list)
  summstudy$jolquartile = as.factor(summstudy$jolquartile)
  
  modelstudy = ezANOVA(data = summstudy, dv = jolmean, wid = subn, within = .(jolquartile, list), 
                       detailed = TRUE, type = 3)
  
  
  #Restudy Analysis:
  ###At the end of Day 1, how well are items of differing JOLs recalled?
  ###For experiments 3,4,5 there is an additional factor: practice list
  if (exper == 1 | exper == 2 | exper == 6){
    summrestudy = allrestudy %>%
      filter(practice == 1) %>%
      group_by(subn, jolquartile) %>%
      summarize(jolmean = mean(jol), restudyacc = mean(restudyacc), restudyrt = mean(restudyrt))
    #ezANOVA needs within subs factors as the actual factor data type.
    summrestudy$jolquartile = as.factor(summrestudy$jolquartile)
    
    modelrestudy = ezANOVA(data = summrestudy, dv = restudyacc, wid = subn, within = .(jolquartile), 
                           detailed = TRUE, type = 3) 
  }else if (exper == 3 | exper == 4 | exper == 5) {
    summrestudy = allrestudy %>%
      filter(practice == 1) %>%
      group_by(subn, jolquartile, list) %>%
      summarize(jolmean = mean(jol), restudyacc = mean(restudyacc), restudyrt = mean(restudyrt))
    
    summrestudy$subn = as.factor(summrestudy$subn)
    summrestudy$jolquartile = as.factor(summrestudy$jolquartile)
    summrestudy$list = as.factor(summrestudy$list)
    modelrestudy = ezANOVA(data = summrestudy, dv = restudyacc, wid = subn, within = .(jolquartile, list), 
                           detailed = TRUE, type = 3)
  }
  
  
  ####Basic ANOVA of JOL:
  results = aov(restudyacc ~ jolquartile , data= summrestudy)
}



if (runreg == 1){
  ###########################################
  ####REGRESSIONS + PRACTICE CHOICE GRAPH####
  
  ##Logistic model is on non-summarized data after norming subjects' JOL scores.
  jolnorm = vector(mode = 'double', length = dim(alltest)[1])
  crow = 1
  for (k in 1:length(subnums)){
    subn = subnums[k]
    index = alltest$subn == subn
    cdata = alltest[index,]
    
    #Norm JOL scores
    jolmean = mean(cdata$jol)
    jolsd = sd(cdata$jol)
    for (n in 1:dim(cdata)[1]){
      jolnorm[crow] = (cdata$jol[n] - jolmean)/jolsd
      crow = crow + 1
    }
  }
  alltest = cbind(alltest, jolnorm)
  
  
  #Fitting regular regression to the normed, raw, and quartile data
  linraw = lm(testacc ~ jol * practice, data = alltest)
  linnormed = lm(testacc ~ jolnorm * practice, data = alltest)
  linquart = lm(testacc ~ jolquartile * practice, data = alltest)
  
  
  #Fitting logistic regression to the normed scores
  lograw = glm(testacc ~ jol * practice, data = alltest, family = binomial())
  lognormed = glm(testacc ~ jolnorm * practice, data = alltest, family = binomial())
  
  
  
  #Create hypothetical performance scores by varying decision rule
  #Decision rule is study at JOL _____ or below
  xjol = c(1,10,20,30,40,50,60,70,80,90,100)
  
  
  if (linear){
    cmodel = linraw
  } else{
    cmodel = lograw
  }
  
  logit2prob <- function(logit){
    odds <- exp(logit)
    prob <- odds / (1 + odds)
    return(prob)
  }
  
  #What are the predicted values for all study vs. all test at each level of JOL
  #contained within xJOL?
  yvalues = data.frame(matrix(data = NA, nrow = length(xjol), ncol = 7))
  colnames(yvalues) = c('jol', 'studypredict', 'testpredict', 'studyemp', 'testemp',
                        'predicttestabove', 'emptestabove')
  yvalues$jol = xjol
  
  xdata = data.frame(cbind(xjol, rep(0,length(xjol))))
  colnames(xdata) = c('jol', 'practice')
  #type="resp" means you don't need to use logit2prob for nonlinear.
  yvalues[,'studypredict'] = predict(cmodel, xdata, type="resp")
  
  xdata$practice = rep(1,length(xjol))
  yvalues[,'testpredict'] = predict(cmodel, xdata, type="resp")
  
  
  
  #get empirical values by finding indexes with jols around each xjol val.
  halfdist = (xjol[2]-xjol[1])/2
  for (o in 1:length(xjol)){
    
    index = alltest$jol >= (xjol[o]-halfdist) & 
      alltest$jol < (xjol[o] + halfdist) & alltest$practice == 0
    index = which(index == 1)
    yvalues[o,'studyemp'] = mean(alltest$testacc[index])
    
    index = alltest$jol >= (xjol[o]-halfdist) & 
      alltest$jol < (xjol[o] + halfdist) & alltest$practice == 1
    index = which(index == 1)
    yvalues[o,'testemp'] = mean(alltest$testacc[index])
  }
  
  
  #Decision rule: retrieval practice if >= cut off JOL. Restudy if below.
  #As jol cut off decreases more and more testing is done, and performance should (mostly) increase.
  for (o in 1:length(xjol)){
    
    practice = sapply(alltest$jol >= xjol[o], as.numeric)
    xdata = data.frame(cbind(alltest$jol, practice))
    colnames(xdata) = c("jol", "practice")
    yvalues[o,'predicttestabove'] = mean(predict(cmodel, xdata, type="resp"))
    
    index = alltest$jol >= xjol[o] & alltest$practice == 1 #include all test trials above cutoff
    index = index + (alltest$jol < xjol[o] & alltest$practice == 0) #and all restudy trials below cutoff
    index = which(index == 1)
    yvalues[o,'emptestabove'] = mean(alltest$testacc[index])
  }
  
  #individual excel files below have been combined into practice_choice_graphs. 
  #For simplicity, only logistic is plotted
  if (writefile){ 
    fname = paste0('exp', exper, 'decision.xlsx') 
    if (linear){
      write.xlsx(yvalues, fname, sheetName = "sheet1", row.names=FALSE, append=TRUE)
    } else {
      write.xlsx(yvalues, fname, sheetName = "sheet2", row.names=FALSE, append=TRUE)
    }
  }
}