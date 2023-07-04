% PsychDebugWindowConfiguration([], .7);

%11.8 handled edge case for logistic regression. If someone chooses all
%restudy, logistic regression can't run, b coefficients are empty. If so,
%set cutoff for retrieval at 999 JOL (never retrieve), which leads to a
%cutoff index of 24, or the length of the list. Should work fine.

%10.24 stuff changed. New jol procedure (rather than 1 to 100, 1 to 9, and
%immediate move rather than wait for enter keypress. Box should enclose (or
%letter made green? To indicate which was chosen).

%New decision rule for adding in restudy and retrieval practice. Does a
%first pass with stuff just outside cutoff, then looks within cutoff and
%converts exceptions to the rule.

%Stuff to add:
%Do we give feedback in JOL? (argue not)
%Do we have rectangles around the cued words? (would rather not)


%NEED TO UPDATE MIN STATES WITH AN ISEMPTY CHECK. IF EITHER IS EMPTY, JUST
%USE NONEMPTY
%Looks pretty okay?
%Reduce cushion

%Aaron mentioned potential boxes around stuff. A possibility. Can have a
%version where it's tried. Also, get it up on the actual computers.


%clear Screen  %undoes above.

% %general goal:
% 1st experiment. general calibration --  JOLs at immediate vs. delayed, give retrieval practice to varying levels of JOL.
% 2nd experiment. Honor/dishonor and more vs. less retrieval practice.

% On method: Josh used word lists of 40. Had honor/dishonor decisions
% immediately follow study. Kornell had a more involved/unusual procedure
% in that people immediately made JOls, then were tested, then made restudy
% vs. done choices that were H/D.

%For H/D, Josh removed words from screen while they were making the
%decision.

%On list length -- Josh used 40 and got ~10% performance for items with
%restudy chosen. Short (1s presentation time though).

%For experiment, need: something to toggle for delayed vs immediate JOL.
%Something, either percentile or absolute number, to calibrate for JOLs.
%Something to construct the list. For now, crib from incidental learning.
rand('state', sum(100*clock))


joldelayed = 0; %or immed
studyoptions = 1; %1 for retrieval vs. restudy. Maybe have 2 if we have a follow up where items can be dropped.
joltype = 'cuetarget';
listlength = 40;



noinstructions = 0;
instructtime = 1;
prestime = 3; %presentation time of pair during study/restudy
jolslide = 1; %If 0, type in.
joltime = 20; %how many seconds participants have to make a JOL. right now not a factor, but could adjust.
jolend = .4; %time that the jol resp stays green.
waittime = .3; %blank screen duration for study phase
waittimetest = 1; %blank screen duration for test phase
cutofftime = 10; %UNUSED. do we need a max time people have to retrieve?




pilot = 0;
if pilot == 0
    subn = input('Please enter the subject number.\n'); %subNum;
    session  = input('Please enter the Session (1 or 2)\n'); %=part;
else
    subn = 980;
    session = 1;
    listlength = 4;
    prestime = 1.5;
end




%[num, txt, raw] = xlsread('Stimuli/wordpairs.xlsx'); %xlsread takes 20+ seconds to load on first use. save as .mat, use load.
load('Stimuli/wordpairs.mat'); %loads above.

wordpairs = txt(1:listlength,:);
wordpairs = wordpairs(randperm(length(wordpairs)),:);



%C1: studylist, C2 honor/addret/addrestudy, C3 %cutoffjol C4 %how many were
%actually changed. C5 how many were changed with the 'original' rule (just
%below cut off for retrieval, just above for restudy.


%Cols 1-2 is the word pair.
%Col 3 is JOLs
%Col 4 is jolRT
%Col 5 is restudy/retrieval practice decision
%Col 6 is what they'll actually do
%Col 7 is whether their decision was honored or not
%Col 8 is (for dishonored) whether it was 'outside' or 'inside' their
%decided cutoff (outside is original rule, inside is second pass
%%%%%%BELOW ONLY USED IN RESTUDYLIST, WHICH STARTS AS A COPY OF STUDYLIST
%Col 9 word recalled
%Col 10 whether it was correct or not.
%Col 11 startRT
%Col 12 endRT

%FOR TEST LIST:
%Col 13: word recalled
%Col 14: correct or not
%Col 15: startRT
%Col 16: endRT


studylist = cell(listlength, 12);
studylist(:,1:2) = wordpairs(:,:); %previous looped through several lists, used start:finish,:



%Screen('Preference', 'SkipSyncTests', 1);
[window, rect] = Screen(0, 'OpenWindow', [], []);
xPos = rect(3)/2;
yPos = rect(4)/2;
xSize = rect(3);
ySize = rect(4);

textSize = 34;
instructSize = 22;
textFont = 'Arial';
white=WhiteIndex(window);
black=BlackIndex(window);
wordcolor = black;
green = [0,255,0];

fkey = KbName('f');
jkey = KbName('j');
ndash = char(8211);
numcoords = linspace(100, xSize-100, 9); %used for JOLs, xcoords for where numbers 0-9 should appear.
%  The lists will be fairly long, but ' ...
%     'please do your best to remember as many word pairs as possible for the test.|' ...

%Screen('TextStyle', window, 0); makes text unbolded. Weird thing about default is that <b> itallicizes things.


Screen('TextFont', window, textFont);
Screen('TextSize', window, textSize);
msgbound = 'WWWWWWWWW';
[bounds, bounds2] = Screen('TextBounds', window, msgbound, 50, 50);
xbuffer = round(bounds(3)/2); %minimum space off center where the word should be presented.
xbound = bounds(3);
ybuffer = round(bounds(4)/4); %y adjust a little unusual WriteCentered. Should work.
ybound = bounds(4);
xcushion = 0;
yadjust = 100;

if session == 1
    Screen('TextSize', window, instructSize);
    instructions = ['In this experiment, you will study a series of word pairs that you need to learn '...
        'for an upcoming memory test.|' ...
        'You will take the test when you return tomorrow. On the test, I''ll give you the left ' ...
        'word and your job is to remember the right word.|'...
        'After studying the list, you''ll have an opportunity to get more practice on the words in those '...
        'lists.'];
    
    presstocontinue = ['Press any key to continue'];
    
    if ~noinstructions
        WriteLine(window, instructions, wordcolor, 100, 100, 100, 2);
        Screen('Flip', window, [], 1);
        WaitSecs(instructtime);
        WriteCentered(window, presstocontinue, xPos, ySize-100, wordcolor);
        Screen('Flip', window);
        wait = KbWait;
    end
    
    %next page
    instructions = ['For each word pair you will have several seconds to initially study it. ' ...
        'After studying each word pair, you''ll need to estimate how likely you are to remember ' ...
        'the right word when given the left word on tomorrow''s test.|'...
        'On this scale, you can choose 1 if you think there is absolutely no chance that you will successfully remember '...
        'this pair. You can choose 100 if you are certain you will be able to remember this pair. ' ...
        'And of course, you can choose anything in between.'];
    if ~noinstructions
        WriteLine(window, instructions, wordcolor, 100, 100, 100, 2);
        Screen('Flip', window, [], 1);
        WaitSecs(instructtime);
        WriteCentered(window, presstocontinue, xPos, ySize-100, wordcolor);
        Screen('Flip', window);
        wait = KbWait;
    end
    
    %3rd page
    instructions = ['Press any key when you''re ready to begin the experiment.'];
    if ~noinstructions
        WriteLine(window, instructions, wordcolor, 100, 100, 100, 2);
        Screen('Flip', window, [], 1);
        WaitSecs(instructtime);
        WriteCentered(window, presstocontinue, xPos, ySize-100, wordcolor);
        Screen('Flip', window);
        wait = KbWait;
    end
    
    
    %     instructions = ['After making this judgment you will be able to choose how you want to practice '...
    %         'this word pair later. For each word pair, you can choose to RESTUDY the pair, like this:'];
    %     instructions2 = ['Or you can choose TEST. Then you will see a screen like this||||' ...
    %         'and have to make your best guess. '];
    %     presstocontinue = ['Press any key to begin the experiment.'];
    %     if ~noinstructions
    %         WriteLine(window, instructions, wordcolor, 100, 100, 100, 2);
    %         WriteLine(window, instructions2, wordcolor, 100, 100, 450, 2);
    %
    %         sqrcoord = [xPos-xcushion-xbound, 0, xPos+xcushion+xbound, 2*ybound];
    %         Screen('TextSize', window, textSize);
    %         WriteCentered(window, 'word1', xPos-xcushion-xbuffer, 300, wordcolor);
    %         WriteCentered(window, ndash, xPos, 300, wordcolor); %using over a hyphen, '-'
    %         WriteCentered(window, 'word2', xPos+xcushion+xbuffer,300, wordcolor);
    %         WriteCentered(window, 'word1', xPos-xcushion-xbuffer, 630, wordcolor);
    %         WriteCentered(window, ndash, xPos, 630, wordcolor);
    %
    %         % windowPtr [,color], fromH, fromV, toH, toV [,penWidth])
    %         Screen('DrawLine', window, [0,0,0], xPos+xcushion+xbuffer*.5, 630+ybound, ...
    %             xPos+xcushion+1.75*xbuffer, 630+ybound, 2);
    %         %Screen('FrameRect', windowPtr [,color] [,rect] [,penWidth]);
    %         Screen('FrameRect', window, [0,0,0], [sqrcoord(1), sqrcoord(2)+240, sqrcoord(3), sqrcoord(4)+280], 2);
    %         Screen('FrameRect', window, [0,0,0], [sqrcoord(1), sqrcoord(2)+570, sqrcoord(3), sqrcoord(4)+610], 2);
    %         Screen('Flip', window, [], 1);
    %
    %         WaitSecs(instructtime);
    %         Screen('TextSize', window, instructSize);
    %         WriteCentered(window, presstocontinue, xPos, ySize-100, wordcolor);
    %         Screen('Flip', window);
    %         wait = KbWait;
    %     end
else %session = 2
    Screen('TextSize', window, instructSize);
    instructions = ['Welcome to Day 2 of the experiment. Today, you''ll be tested on the word pairs you learned ' ...
        'during the first session. For each pair, you''ll be given the left word, and need to type the right word.|' ...
        'If you''re unsure of what the word was, it''s okay to guess. If you''ve tried but still can''t '...
        'remember the right word, you can enter SKIP to move onto the next word pair.']; %incidental learning gave subjects a skip option, want to do that here?
    
    presstocontinue = ['Press any key to begin the test'];
    
    if ~noinstructions
        WriteLine(window, instructions, wordcolor, 100, 100, 100, 2);
        Screen('Flip', window, [], 1);
        WaitSecs(instructtime);
        WriteCentered(window, presstocontinue, xPos, ySize-100, wordcolor);
        Screen('Flip', window);
        wait = KbWait;
    end
    
end


% WriteLine(window, instructions, wordcolor, 50, 50, 100, 2); %used to be 1.3
% WriteCentered(window, trialtype, xPos, 100, wordcolor);
% Screen('Flip', window);



%[wordrecalled,startRT,endRT] = GetEchoStringCuedT4(window,'hohumasdfgfdsa', ...
%xPos+50,yPos,[0,0,0],[255,255,255],[0,0,0],'None',0,0,1);
%%%THIS IS THE ONLY THING CHANGED FROM THE ORIGINAL VERSION. originally just x.




%%%%%%%%%%%%
%Study phase
%%%%%%%%%%%%
%[normBoundsRect, offsetBoundsRect]= Screen('TextBounds', windowPtr, text [,x] [,y] [,yPositionIsBaseline] [,swapTextDirection]);

% Screen('FrameRect', window, [0,0,0], bounds2, 3);
%%%WriteCentered doesn't seem to quite center on Y. Closest seems to be start from top, go down by 1/4th textsize.
% WriteCentered(window, msgbound, (bounds2(1)+bounds2(3))/2, bounds2(2)+bounds1(4)/4, wordcolor);
if session == 1
    %jolmsg = ['Please choose a number between 1 and 100 to judge how well you ' ...
    %    'believe you''ve learned that pair.'];
    jolmsg = ['Please judge how well you believe you''ve learned that pair.'];
    for n = 1:size(studylist,1)
        Screen('TextSize', window, textSize);
        WriteCentered(window, studylist{n,1}, xPos-xcushion-xbuffer, yPos-yadjust-ybuffer, wordcolor);
        WriteCentered(window, ndash, xPos, yPos-yadjust-ybuffer, wordcolor);
        WriteCentered(window, studylist{n,2}, xPos+xcushion+xbuffer, yPos-yadjust-ybuffer, wordcolor);
        Screen('Flip', window);
        WaitSecs(prestime);
        
        if joldelayed == 0
            if jolslide == 1
                endPoints = {'1', '100'};
                wordpair = [studylist(n,1), studylist(n,2)];
                [position, RT, answered] = slideforJOL(window, rect, endPoints, jolmsg, wordpair, 'displayposition', false);
                studylist{n,3} = round(position);
                studylist{n,4} = RT;
            elseif jolslide == 0
                %%1 to 100 method
                Screen('TextSize', window, instructSize);
                WriteLine(window, jolmsg, wordcolor, 100, 100, ySize-150, 2);
                Screen('TextSize', window, textSize);
                WriteCentered(window, studylist{n,1}, xPos-xcushion-xbuffer, yPos-yadjust-ybuffer, wordcolor);
                WriteCentered(window, ndash, xPos, yPos-yadjust-ybuffer, wordcolor);
                WriteCentered(window, studylist{n,2}, xPos+xcushion+xbuffer, yPos-yadjust-ybuffer, wordcolor);
                
                Screen('DrawLine', window, [0,0,0], xPos-xbuffer*.5, yPos+200+ybound, ...
                    xPos+.5*xbuffer, yPos+200+ybound, 2);
                Screen('Flip', window, [], 1);
                [jolresp,startRT,endRT] = GetEcho_jol(window,'',xPos-xbuffer*.2,yPos+200, ... %originally StringCuedT4
                    [0,0,0],[255,255,255],[0,0,0],'None',0,0,1);
                studylist{n,3} = str2double(jolresp);
                studylist{n,4} = startRT;
            end

            Screen('Flip', window);
            WaitSecs(jolend);
        end
        
        Screen('Flip', window); %to the next trial
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%%Phase 2: delayed JOLs
    
    %Build in decision of honor/dishonor?
    %instructionsjol = [''];
    if joldelayed
        for n = 1:size(jollist,1)
            WriteLine(window, instructionsjol, wordcolor, 50, 50, 100, 2);
            WriteCentered(window, 'Confidence:', xPos - xbuffer, yPos+150, wordcolor);
            if strcmp(joltype, 'cueonly')
                WriteCentered(window, jollist{n,1}, xPos-xcushion-xbuffer, yPos-ybuffer, wordcolor);
                WriteCentered(window, '-', xPos, yPos-ybuffer, wordcolor);
                WriteCentered(window, '_______', xPos-xcushion-xbuffer, yPos-ybuffer, wordcolor);
            elseif strcmp(joltype, 'cuetarget')
                WriteCentered(window, jollist{n,1}, xPos-xcushion-xbuffer, yPos-ybuffer, wordcolor);
                WriteCentered(window, '-', xPos, yPos-ybuffer, wordcolor);
                WriteCentered(window, jollist{n,2}, xPos-xcushion-xbuffer, yPos-ybuffer, wordcolor);
            end
            Screen('Flip', window);
            [jol,startRT,endRT] = GetEcho_jol(window,'',xPos+xbuffer,yPos+150, ...
                [0,0,0],[255,255,255],[0,0,0],'None',0,0,1); %CONVERT JOL TO A DOUBLE
        end
    end
    
    %%%%%%%%%%%
    %%%Phase 3: Restudy/Test
    %%%%%%%%%%%
    
    
    %Update study choices with honored/dishonored decisions.
    jols = [cell2mat(studylist(:,3)) (1:listlength)'];
    jols = sortrows(jols,1);
    for n = 1:listlength
        
        if rem(subn,2)
            if rem(n,2)
                studylist{jols(n,2),6} = 'restudy';
            else
                studylist{jols(n,2),6} = 'retrieve';
            end
        else
            if rem(n,2)
                studylist{jols(n,2),6} = 'retrieve';
            else
                studylist{jols(n,2),6} = 'restudy';
            end
        end
        %Tell where the word's JOL falls, higher number = better learned.
        studylist{jols(n,2),7} = n;
        studylist{jols(n,2),8} = n/listlength;
    end
    
    %%%%BEGIN THE RESTUDY PHASE
    
    if ~noinstructions
        Screen('TextSize', window, instructSize);
        instructions = ['The practice phase is about to begin. ' ...
            'Some of the word pairs will be shown again for you to restudy ' ...
            'for tomorrow''s test. For others, only the left word will be shown, and you''ll need to retrieve '...
            'the other. If you''re unsure, it''s okay to guess. If you''ve tried but still can''t '...
            'remember the right word, you can enter ''skip'' to move onto the next word pair.'];
        WriteLine(window, instructions, wordcolor, 50, 50, 100, 2);
        Screen('Flip', window, [], 1);
        WaitSecs(1);
        WriteCentered(window, presstocontinue, xPos, ySize-100, wordcolor);
        Screen('Flip', window);
        wait = KbWait;
    end
    
    restudylist = studylist;
    neworder = randperm(size(restudylist,1))';
    restudylist = [restudylist(neworder,:), num2cell(neworder)];
    
    
    Screen('TextSize', window, textSize);
    for n = 1:size(restudylist,1)
        practicetype = restudylist{n,6};
        if strcmp(practicetype, 'retrieve')
            WriteCentered(window, restudylist{n,1}, xPos-xcushion-xbuffer, yPos-yadjust-ybuffer, wordcolor);
            WriteCentered(window, ndash, xPos, yPos-yadjust-ybuffer, wordcolor);
            Screen('DrawLine', window, [0,0,0], xPos+xcushion+xbuffer*.45, yPos-yadjust+ybound, ...
                xPos+xcushion+1.8*xbuffer, yPos-yadjust+ybound, 2);
            Screen('Flip', window, [], 1);
            [wordrecalled,startRT,endRT] = GetEchoStringCuedT4(window,'',xPos+xcushion+.7*xbuffer,yPos-yadjust, ...
                [0,0,0],[255,255,255],[0,0,0],'None',0,0,1);
            restudylist{n,9} = wordrecalled;
            restudylist{n,11} = startRT;
            restudylist{n,12} = endRT;
            if strcmp(wordrecalled, restudylist{n,2})
                restudylist{n,10} = 1;
            else
                restudylist{n,10} = 0;
            end
        elseif strcmp(practicetype, 'restudy')
            WriteCentered(window, restudylist{n,1}, xPos-xcushion-xbuffer, yPos-yadjust-ybuffer, wordcolor);
            WriteCentered(window, ndash, xPos, yPos-yadjust-ybuffer, wordcolor);
            WriteCentered(window, restudylist{n,2}, xPos+xcushion+xbuffer, yPos-yadjust-ybuffer, wordcolor);
            Screen('Flip', window);
            WaitSecs(prestime);
        end
        Screen('Flip', window);
        WaitSecs(waittime);
    end
end


if session == 2
    load(['SubjectData/sub' int2str(subn), '_study.mat']); %loads studylist, restudylist, listlength from first session
    cols = size(restudylist, 2);
    testlist = cell(listlength, cols+4);
    testlist(:,1:cols) = restudylist;
    testlist = testlist(randperm(size(testlist,1)),:);
    
    Screen('TextSize', window, textSize);
    %Phase 4 (Session 2): Final Test
    for n = 1:size(testlist)
        WriteCentered(window, testlist{n,1}, xPos-xcushion-xbuffer, yPos-yadjust-ybuffer, wordcolor);
        WriteCentered(window, ndash, xPos, yPos-yadjust-ybuffer, wordcolor);
        Screen('DrawLine', window, [0,0,0], xPos+xcushion+xbuffer*.45, yPos-yadjust+ybound, ...
            xPos+xcushion+1.8*xbuffer, yPos-yadjust+ybound, 2);
        Screen('Flip', window, [], 1);
        [wordrecalled,startRT,endRT] = GetEchoStringCuedT4(window,'',xPos+xcushion+.7*xbuffer,yPos-yadjust, ...
            [0,0,0],[255,255,255],[0,0,0],'None',0,0,1);
        Screen('Flip', window);
        WaitSecs(waittime);
        
        testlist{n,13} = wordrecalled;
        if strcmp(wordrecalled, testlist{n,2})
            testlist{n,14} = 1;
        else
            testlist{n,14} = 0;
        end
        
        testlist{n,15} = startRT;
        testlist{n,16} = endRT;
    end
end


Screen('Flip', window);
if session == 1 
    WriteCentered(window, 'The first day is complete', xPos, yPos, wordcolor)
    %     WriteCentered(window, 'Please go get the experimenter at this time', xPos, yPos+125, wordcolor)
    filename = ['SubjectData/sub', int2str(subn), '_study.mat'];
    save(filename, 'studylist', 'restudylist', 'listlength');
else
    WriteCentered(window, 'The experiment is complete!', xPos, yPos, wordcolor)
    WriteCentered(window, 'Thanks for Participating!', xPos, yPos+125, wordcolor)
    filename = ['SubjectData/sub', int2str(subn), '_test.mat'];
    save(filename, 'studylist', 'restudylist', 'listlength', 'testlist');
end

Screen('Flip', window); 
WaitSecs(2);
wait = KbWait;
sca;







%%%IF WE WANTED TO ADD A DEADLINE TO THE JOL TASK:
% jolstart = tic;
% hurrymsg = 0;
% while toc(jolstart) < joltime
%     if joltime - toc(start) < 4 && ~hurrymsg
%         hurrymsg = 1;
%         WriteCentered(window, 'Please Hurry.', xPos, ySize-150, wordcolor);
%         Screen('Flip', window);
%     end
% end