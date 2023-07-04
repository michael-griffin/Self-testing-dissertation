%Experiment 2 data was a bit messier to preprocess, since the data came in as .mat files
%reformat_cleanup prepares the raw matlab data for being combined.
%reformat_combine runs 2nd, and is closer to the typical preprocess code
%of the other experiments.

%Original .mat file column order:
%Study: 1-8:
%Word1, Word2, JOL, JOLRT, (BLANK), RESTUDY/RETRIEVE, JOLRANK, JOLPERCENTILE
%Restudy adds 9-12:
%Restudy response, Restudy Acc, StartRT, EndRT
%Test adds 13:16:
%Test response, Test Acc, StartRT, EndRT

%New Matlab order: 1-4 the same, Trial, List, then rest the same.


cutzero = 1;
online = 2; %1, 0, or 2. 0 is not online, 1 is online, 2 combines the two.
writefile = 1; %Writes combined data to excel file.

%Labels for the combined data at the end.
labelstudy = [{'subn'} {'word1'} {'word2'} {'jol'} {'jolrt'} {'trial'} {'list'} {'practice'} {'jolrank'} {'jolrankp'}];
labelrestudy = [labelstudy, {'restudyresp'} {'restudyacc'} {'restudyrtfirst'} {'restudyrt'}];
labeltest = [labelrestudy, {'response'} {'testacc'} {'rtfirst'} {'rt'}];


%Load in files
if online == 1
    allfiles = dir('online/');
    relevantnames = cell(size(allfiles,1),1);

    for n = 1:size(allfiles,1)
        if allfiles(n,1).isdir
            continue;
        end

        cname = allfiles(n,1).name;

        if strcmp('.txt', cname(end-3:end));
            relevantnames{n,1} = cname;
        end
    end
    relevantnames = relevantnames(~cellfun('isempty', relevantnames),1);

    subnums = [];
    for k = 1:length(relevantnames)
        cname = relevantnames{k};
        subn = find(double(cname) >= 48 & double(cname) <= 57);
        subn = str2double(cname(subn));
        subnums = [subnums; subn];
    end
    subnums = unique(subnums);



    allfiles = dir('converted');
    relevantnames = cell(size(allfiles,1),1);
    for n = 1:size(allfiles,1)
        if allfiles(n,1).isdir
            continue;
        end

        cname = allfiles(n,1).name;

        if strcmp('test.mat', cname(end-7:end));
            relevantnames{n,1} = cname;
        end
    end
    relevantnames = relevantnames(~cellfun('isempty', relevantnames),1);

    bigstudy = [];
    bigrestudy = [];
    bigtest = [];

    for k = 1:length(relevantnames)
        cname = relevantnames{k};
        subn = double(cname(1:7)) <= 57; %57 = double('9')
        subn = str2double(cname(subn));

        load(['converted/', cname]);

        bigstudy = [bigstudy; [num2cell(repmat(subn, length(studydata), 1)), studydata]];
        bigrestudy = [bigrestudy; [num2cell(repmat(subn, length(restudydata), 1)), restudydata]];
        bigtest = [bigtest; [num2cell(repmat(subn, length(testdata), 1)), testdata]];
    end



    bigstudy = [labelstudy; bigstudy];
    bigrestudy = [labelrestudy; bigrestudy];
    bigtest = [labeltest; bigtest];

    if writefile
        xlswrite('allstudy.xlsx', bigstudy, 4);
        xlswrite('allrestudy.xlsx', bigrestudy, 4);
        xlswrite('alltest.xlsx', bigtest, 4);
    end

elseif online == 0
    allfiles = dir('matlab/raw');
    relevantnames = cell(size(allfiles,1),1);

    for n = 1:size(allfiles,1)
        if allfiles(n,1).isdir
            continue;
        end

        cname = allfiles(n,1).name;

        %Only need the test lists, as it has everything saved there
        %already (it loads in study.mat at start of Day2).
        if strcmp('test.mat', cname(end-7:end));
            relevantnames{n,1} = cname;
        end
    end
    relevantnames = relevantnames(~cellfun('isempty', relevantnames),1);




    bigstudy = [];
    bigrestudy = [];
    bigtest = [];

    for k = 1:length(relevantnames)
        cname = relevantnames{k};
        subn = double(cname(1:7)) <= 57;
        subn = str2double(cname(subn));

        load(['matlab/', cname]);

        bigstudy = [bigstudy; [num2cell(repmat(subn, length(studylistsall), 1)), studylistsall]];
        bigrestudy = [bigrestudy; [num2cell(repmat(subn, length(restudylist), 1)), restudylist]];
        bigtest = [bigtest; [num2cell(repmat(subn, length(testlist), 1)), testlist]];
    end

    %Kludge: adjusts for 0s in the JOL slider.
    holding = cell2mat(bigstudy(:,4));
    holding(holding == 0) = 1;
    bigstudy(:,4) = num2cell(holding);
    holding = cell2mat(bigrestudy(:,4));
    holding(holding == 0) = 1;
    bigrestudy(:,4) = num2cell(holding);
    holding = cell2mat(bigtest(:,4));
    holding(holding == 0) = 1;
    bigtest(:,4) = num2cell(holding);

    bigstudy = [labelstudy; bigstudy];
    bigrestudy = [labelrestudy; bigrestudy];
    bigtest = [labeltest; bigtest];

    if writefile
        xlswrite('allstudy.xlsx', bigstudy, 3);
        xlswrite('allrestudy.xlsx', bigrestudy, 3);
        xlswrite('alltest.xlsx', bigtest, 3);
    end
elseif online == 2

    %%%%%%%COMBINE BOTH INTO A BIG FILE
    [~, ~, allstudymat] = xlsread('allstudy.xlsx', 3);
    [~, ~, allstudyonline] = xlsread('allstudy.xlsx', 4);
    [~, ~, allrestudymat] = xlsread('allrestudy.xlsx', 3);
    [~, ~, allrestudyonline] = xlsread('allrestudy.xlsx', 4);
    [~, ~, alltestmat] = xlsread('alltest.xlsx', 3);
    [~, ~, alltestonline] = xlsread('alltest.xlsx', 4);


   labels = alltestmat(1,:);
   allstudy = [allstudymat(2:end,:); allstudyonline(2:end,:)];
   allrestudy = [allrestudymat(2:end,:); allrestudyonline(2:end,:)];
   alltest = [alltestmat(2:end,:); alltestonline(2:end,:)];


   if cutzero
       subnums = unique(cell2mat(alltest(:,1)));
       tocut = [];

       for n = 1:length(subnums)
           index = find(cell2mat(alltest(:,1)) == subnums(n));
           acc = sum(cell2mat(alltest(index,16)));
           if acc == 0
              tocut = [tocut, subnums(n)];
           end
       end

       indexes = find(ismember(cell2mat(allstudy(:,1)), tocut));
       allstudy(indexes,:) = [];
       indexes = find(ismember(cell2mat(allrestudy(:,1)), tocut));
       allrestudy(indexes,:) = [];
       indexes = find(ismember(cell2mat(alltest(:,1)), tocut));
       alltest(indexes,:) = [];
   end

   allstudy = [labels(1:size(allstudy,2)); allstudy];
   allrestudy = [labels(1:size(allrestudy,2)); allrestudy];
   alltest = [labels; alltest];

   if writefile
      if cutzero
        xlswrite('allstudy.xlsx', allstudy, 1);
        xlswrite('allrestudy.xlsx', allrestudy, 1);
        xlswrite('alltest.xlsx', alltest, 1);
      else
        xlswrite('allstudy.xlsx', allstudy, 2);
        xlswrite('allrestudy.xlsx', allrestudy, 2);
        xlswrite('alltest.xlsx', alltest, 2);
      end
   end
end


