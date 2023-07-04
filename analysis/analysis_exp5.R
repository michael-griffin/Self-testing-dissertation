#Analysis code for Experiment 6, supplemental to analysis_exps.R

#Experiment 5 and 6 have larger departures in design from Exps 1-4.
#This code runs updated inferentials for exp5 that include the new variable
#honor/dishonor

library(lme4)
library(xlsx)
library(dplyr)
library(tidyr)
library(ez) #for repeated measures ANOVA


exp = 5
folder = paste0('data_exp', as.character(exp), '/csv/')

rawallstudy = read.csv(paste0(folder, 'allstudy.csv'))
rawallrestudy = read.csv(paste0(folder, 'allrestudy.csv'))
rawalltest = read.csv(paste0(folder, 'alltest.csv'))

subns = unique(rawalltest$subn)

#Add jolquartile:
jolquartile = ceiling(rawallstudy$jolrankp*4)
allstudy = cbind(rawallstudy, jolquartile)

jolquartile = ceiling(rawallrestudy$jolrankp*4)
allrestudy = cbind(rawallrestudy, jolquartile)

jolquartile = ceiling(rawalltest$jolrankp*4)
alltest = cbind(rawalltest, jolquartile)

#Add whether or not subject had adaptive practice
adaptive = allstudy$subn %% 2
allstudy = cbind(allstudy, adaptive)

adaptive = allrestudy$subn %% 2
allrestudy = cbind(allrestudy, adaptive)

adaptive = alltest$subn %% 2
alltest = cbind(alltest, adaptive)

topbot = vector(length = dim(alltest)[1], mode = 'numeric')
for (n in 1:dim(alltest)[1]){
  if (alltest$choice[n] == 1){
    if (alltest$honor[n] & adaptive[n]){
      #If retrieval practice is honored and condition was adaptive, it was well learned
      topbot[n] = 1
    } else if (alltest$honor[n] == 0 & adaptive[n]){
      #if it was not honored, than it was not well learned
      topbot[n] = 0
    } else if (alltest$honor[n] & adaptive[n] == 0){
      #if retrieval practice is honored and condition was disruptive, it was not well learned
      topbot[n] = 0
    } else if (alltest$honor[n] == 0 & adaptive[n] == 0){
      #if retrieval practice is not honored, and disruptive, then it was well learned
      topbot[n] = 1
    }
  } else {
    #If chose restudy
    if (alltest$honor[n] & adaptive[n]){
      #If restudy is honored and condition was adaptive, it was not well learned
      topbot[n] = 0
    } else if (alltest$honor[n] == 0 & adaptive[n]){
      #if it was not honored, than it was well learned
      topbot[n] = 1
    } else if (alltest$honor[n] & adaptive[n] == 0){
      #if restudy choice is honored and condition was disruptive, it was well learned
      topbot[n] = 1
    } else if (alltest$honor[n] == 0 & adaptive[n] == 0){
      #if restudy is not honored, and disruptive, then it was not well learned
      topbot[n] = 0
    }
  }
}
alltest = cbind(alltest, topbot)

summtest = select(alltest, subn, jol, practice, honor, adaptive, testacc) %>%
  group_by(subn, practice, honor, adaptive) %>%
  summarize(accmean = mean(testacc, na.rm = TRUE))


#Using lme4 package, compare effects of each predictor.
modbase = lmer(accmean ~ 1 + (1|subn), data=summtest)
modprac = lmer(accmean ~ practice + (1|subn), data=summtest)
modhonor = lmer(accmean ~ practice + honor + (1|subn), data=summtest)
modadapt = lmer(accmean ~ practice + honor + adaptive + (1|subn), data=summtest)
modprachonor = lmer(accmean ~ practice + honor + adaptive + practice:honor + (1|subn), data=summtest)
modpracadapt = lmer(accmean ~ practice + honor + adaptive + practice:honor + practice:adaptive + (1|subn), data=summtest)
modhonoradapt = lmer(accmean ~ practice + honor + adaptive + practice:honor + practice:adaptive +
                       honor:adaptive + (1|subn), data=summtest)
modfull = lmer(accmean ~ practice*honor*adaptive + (1|subn), data=summtest)

anova(modbase, modprac, modhonor, modadapt, modprachonor, modpracadapt, modhonoradapt, modfull)




###Doing similar stuff for Day 1.
summrestudy = select(allrestudy, subn, list, jolquartile, practice, honor, adaptive, restudyacc) %>%
  filter(practice == 1) %>%
  group_by(subn, list, honor, adaptive, jolquartile) %>%
  summarize(accmean = mean(restudyacc, na.rm = TRUE))

modbase = lmer(accmean ~ 1 + (1|subn), data=summrestudy)
modjol = lmer(accmean ~ jolquartile + (1|subn), data=summrestudy)
modlist = lmer(accmean ~ jolquartile + list + (1|subn), data=summrestudy)
#modhonor = lmer(accmean ~ jolquartile + list + honor + (1|subn), data=summrestudy)
modint = lmer(accmean ~ jolquartile + list + jolquartile:list + (1|subn), data=summrestudy)
anova(modbase, modjol, modlist, modint)
