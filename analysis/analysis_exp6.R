#Analysis code for Experiment 6, supplemental to analysis_exps.R

#Experiment 5 and 6 have larger departures in design from Exps 1-4.
#This code runs updated inferentials for exp6 that include the new variables
#honor/dishonor and point value.

library(xlsx)
library(lme4)
library(dplyr)
library(tidyr)
library(ez) #for repeated measures ANOVA


exp = 6
folder = paste0('data_exp', as.character(exp), '/csv/')

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



#Test analysis:
summtest = alltest %>%
  group_by(subn, value, practice, honor) %>%
  summarize(accmean = mean(testacc, na.rm = TRUE))

summtest$subn = as.factor(summtest$subn)
summtest$value = as.factor(summtest$value) 
summtest$practice = as.factor(summtest$practice)
summtest$honor = as.factor(summtest$honor)



#Using lme4 package, compare effects of each predictor.
modbase = lmer(accmean ~ 1 + (1|subn), data=summtest)
modprac = lmer(accmean ~ practice + (1|subn), data=summtest)
modvalue = lmer(accmean ~ practice + value + (1|subn), data=summtest)
modhonor = lmer(accmean ~ practice + value + honor + (1|subn), data=summtest)
modpracvalue = lmer(accmean ~ practice + value + honor + practice:value + (1|subn), data=summtest)
modprachonor = lmer(accmean ~ practice + value + honor + practice:value + practice:honor + (1|subn), data=summtest)
modvaluehonor = lmer(accmean ~ practice + value + honor + practice:value + practice:honor +
                     value:honor + (1|subn), data=summtest)
modfull = lmer(accmean ~ practice*value*honor + (1|subn), data=summtest)

anova(modbase, modprac, modvalue, modhonor, modpracvalue, modprachonor, modvaluehonor, modfull)



####Test JOLs
summjoltest = alltest %>%
  group_by(subn, practice, jolquartile, value) %>%
  summarize(accmean = mean(testacc, na.rm = TRUE))

linquart = lm(accmean ~ jolquartile * practice * value, data = summjoltest)


####Restudy analysis 
summrestudy = allrestudy %>%
  filter(practice == 1) %>%
  group_by(subn, value, honor, jolquartile) %>%
  summarize(accmean = mean(restudyacc, na.rm = TRUE))

modbase = lmer(accmean ~ 1 + (1|subn), data=summrestudy)
modjol = lmer(accmean ~ jolquartile + (1|subn), data=summrestudy)
modvalue = lmer(accmean ~ jolquartile + value + (1|subn), data=summrestudy)
modhonor = lmer(accmean ~ jolquartile + value + honor + (1|subn), data=summrestudy)
modjolvalue = lmer(accmean ~ jolquartile + value + honor + jolquartile:value + (1|subn), data=summrestudy)
modvaluehonor = lmer(accmean ~ jolquartile + value + honor + jolquartile:value + 
                     value:honor + (1|subn), data=summrestudy)
modjolhonor = lmer(accmean ~ jolquartile + value + honor + jolquartile:value + 
                       value:honor + jolquartile:honor + (1|subn), data=summrestudy)
modfull = lmer(accmean ~ jolquartile*value*honor + (1|subn), data=summrestudy)

anova(modbase, modjol, modvalue, modhonor, modjolvalue, modvaluehonor, modjolhonor, modfull)



####Analysis of study choice
summchoice = allrestudy %>%
  group_by(subn, value, jolquartile) %>%
  summarize(choicemean = mean(choice, na.rm = TRUE))

summchoice$value = as.factor(summchoice$value)
summchoice$jolquartile = as.factor(summchoice$jolquartile)

choiceanov = ezANOVA(data= summchoice, dv = choicemean, wid = subn, within = .(jolquartile, value), 
                     detailed = TRUE, type = 3)


jolnorm = vector(mode = 'double', length = dim(alltest)[1])
crow = 1
for (k in 1:length(subnums)){
  subn = subnums[k]
  index = allrestudy$subn == subn
  cdata = allrestudy[index,]
  
  #Norm JOL scores, to be used in a logistic regression across subjects.
  jolmean = mean(cdata$jol)
  jolsd = sd(cdata$jol)
  for (n in 1:dim(cdata)[1]){
    jolnorm[crow] = (cdata$jol[n] - jolmean)/jolsd
    crow = crow + 1
  }
}
allrestudy = cbind(allrestudy, jolnorm)

#See what's going on:
logfitchoice = glm(choice ~ jolquartile * value, data = allrestudy, family = binomial())
logfit2choice = glm(choice ~ jol * value, data = allrestudy, family = binomial())
