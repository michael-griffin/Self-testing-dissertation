Repository for the data and analyses presented in:
Griffin, M. L. (2019). Optimizing practice through self-testing.


Summary

    Memory benefits from retrieval. This fact has motivated an entire literature on the testing effect, which demonstrates that retrieval practice benefits memory more than additional restudy opportunities. The overall robustness of this effect masks a surprising variability in just how advantageous (or not) retrieval practice actually is in practice, particularly for items that are difficult to retrieve or for learners who are highly unskilled or untrained. In a series of experiments, this dissertation examines effects of self-testing across a variety of levels of difficulty. The goal was to find techniques that allow precision in determining at what level of mastery the risks and benefits of self-testing outweigh the certain but modest benefits of restudy.

Organization - Folders

    analysis/ Analysis code and an overall summary file which includes data and figures
    analysis/data_exp1-6/ Data folders for each experiment. Each contains raw data, preprocessing code, (cleaned up) csv files, and summary files for that experiment.
    exp1-6/ Code to run each experiment. Each experiment can be run online, and Exps 1+2 also have a version in Matlab. Matlab requires CogToolbox Library to run. Online versions require the jspsych-6.0.2/ folder.
   
    
Organization - Analysis Code

    Data Files + Preprocessing
        Data split by experiment in data_exp#/ folders. Each contains raw data, summary files, and the preprocessing code to generate each summary file.
    Figures
        Figures were primarily generated within each summary file. The majority can be found in allexps_summary.xlsx
        practice_choice_graphs.xlsx also contains figures for the estimated 'optimal practice' one could achieve based on adjusting study choice by judgment of learning.
    Analysis
        analysis_exps.R	        runs repeated measures ANOVAS for each experiment, and the logistic regression model used in making practice_choice_graphs.xlsx
        analysis_exp5/6.R       A supplement to analysis_exps.R, runs inferential statistics for exps 5 and 6.

