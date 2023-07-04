%Experiment 2 data was a bit messier to preprocess, since the data came in as .mat files
%reformat_cleanup prepares the raw matlab data for being combined.
%reformat_combine is closer to the typical preprocess code of the other experiments.

%Goal of this is to get all this matlab data into 1-2 excel files. Can keep
%it raw, or add a little bit of extra info if it would help. Would want
%study trial for each of the 3 practice, as well as JOL. RT can maybe skip.

%One minor difference. Jol Slider for Matlab went from 0 to 100. For Online
%1 to 100. Kludge, but added 1 when JOL = 0 in the makebig section.

%Original .mat file column order:
%Study: 1-8:
%Word1, Word2, JOL, JOLRT, (BLANK), RESTUDY/RETRIEVE, JOLRANK, JOLPERCENTILE
%Restudy adds 9-12:
%Restudy response, Restudy Acc, StartRT, EndRT
%Test adds 13:16:
%Test response, Test Acc, StartRT, EndRT

%New Matlab order: 1-4 the same, Trial, List, then rest the same.

%Matlab saves to matlab/, online saves to converted/
cleanup = 0; %Takes raw files, converts them to standardized .mat format before reformat_combine
online = 1;
savefile = 0; %save results of cleanup.


if online
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

    %%%%Clean up online files
    %This involves cutting column 5 (jolrtfirst) from study and restudy, adding
    %cols 7 to 9 from Restudylist back.
    for k = 1:length(subnums)
        subn = subnums(k);
        for m = 1:3
            switch m
                case 1
                    filename = ['restudy_', int2str(subn), '.txt'];
                case 2
                    filename = ['study_', int2str(subn), '.txt'];
                case 3
                    filename = ['test_', int2str(subn), '.txt'];
            end

            cdata = fopen(['Online/', filename]);
            countlines = 0;
            rawrows = cell(300,1);
            while feof(cdata) == 0
                current = fgetl(cdata);
                countlines = countlines + 1;
                rawrows{countlines,1} = current;
            end
            fclose('all');

            index = find(cellfun('isempty', rawrows), 1); %return index of first empty cell
            rawrows = rawrows(1:index-1);
            coln = length(regexp(rawrows{1,1}, ',', 'split'));
            rawdata = cell(length(rawrows), coln);

            for o = 1:length(rawrows)
                rawdata(o,:) = regexp(rawrows{o,1}, ',', 'split');
            end
            rawdata = rawdata(2:end,1:end-1); %First row is labels. Last col is empty (artifact of csv formatting).

            switch m
                case 1
                    newcols = num2cell([1:length(rawdata); repmat(4,1,length(rawdata))]');
                    restudydata = [rawdata(:,1:4), newcols, rawdata(:,6:8), cell(length(rawdata),1), rawdata(:,[10,9])];
                    %Convert numbers to actual numbers.
                    restudydata(:,[3:4,7:8,11:12]) = num2cell(cellfun(@str2double,restudydata(:,[3:4,7:8,11:12])));


                    %Clear out restudy junk, add in restudy accuracy.
                    for n = 1:length(restudydata)
                        if restudydata{n,7} == 0 %If in the restudy condition.
                            restudydata(n,9:12) = {[]};
                        elseif restudydata{n,7} == 1
                            if strcmpi(restudydata{n,2}, restudydata{n,9}) %If they got it right when retrieving. strcmpi ignores case.
                                restudydata{n,10} = 1;
                            else
                                restudydata{n,10} = 0;
                            end
                        end
                    end

                    %Add in JOL info.
                    restudydata = sortrows(restudydata,3);
                    newrcols = num2cell([1:40; (1:40)/40]');
                    restudydata = [restudydata(:,1:7), newrcols, restudydata(:,9:12)];
                    restudydata = sortrows(restudydata,5);
                case 2
                    studydata = [rawdata(:,[1:4,6:end]), cell(length(rawdata), 3)]; %cuts jolrtfirst column, which Matlab subs didn't have.
                    studydata(:,3:6) = num2cell(cellfun(@str2double, studydata(:,3:6)));
                    %Must add in info from restudy. So this must be run AFTER
                    %restudy.

                    for n = 1:length(studydata)
                        index = find(ismember(restudydata(:,1), studydata{n,1}));
                        studydata(n,7:9) = restudydata(index,7:9);
                    end
                case 3
                    testdata = [rawdata(:,[1:2, 7,9,8])]; %going to paste everything in from restudy. 7,9,8 ensures that RTfirst comes a column BEFORE RT.
                    testdata(:,4:5) = num2cell(cellfun(@str2double, testdata(:,4:5)));
                    newtcols = cell(length(testdata), size(restudydata,2)-2);
                    acc = cell(length(testdata),1);
                    for n = 1:length(testdata)
                        index = find(ismember(restudydata(:,1), testdata{n,1}));
                        newtcols(n,:) = restudydata(index,3:end);

                        if strcmpi(testdata{n,2}, testdata{n,3})
                            acc{n} = 1;
                        else
                            acc{n} = 0;
                        end
                    end
                    newtcols(:,4) = {5}; %List 5, doesn't really matter.
                    testdata = [testdata(:,1:2), newtcols, testdata(:,3), acc, testdata(:,4:5)];
            end
        end

        listlength = length(restudydata);
        nlists = 3;
        if savefile
            save(['converted/sub', int2str(subn), '_test.mat'], 'studydata', 'restudydata', 'testdata', 'listlength', 'nlists');
        end
    end
else
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

    %%%Clean up test.mat files found in raw folder.
    for k = 1:length(relevantnames)
        cname = relevantnames{k};
        load(['matlab/raw/', cname]);


        newcols = num2cell([1:length(restudylist); repmat(4,1,length(restudylist))]');
        restudylist = [restudylist(:,1:4), newcols, restudylist(:,6:end)];
        newcols = num2cell([1:length(testlist); repmat(5,1,length(restudylist))]');
        testlist = [testlist(:,1:4), newcols, testlist(:,6:end)];

        for n = 1:listlength
            if strcmp(restudylist{n,7}, 'retrieve')
                restudylist{n,7} = 1;
            elseif strcmp(restudylist{n,7}, 'restudy')
                restudylist{n,7} = 0;
            end

            if strcmp(testlist{n,7}, 'retrieve')
                testlist{n,7} = 1;
            elseif strcmp(testlist{n,7}, 'restudy')
                testlist{n,7} = 0;
            end
        end

        studylistsall = [];
        for m = 1:3
            clist = studylists{m};
            newcols = cell(length(clist), 2);
            for n = 1:length(clist)
                newcols{n,1} = n;
                newcols{n,2} = m;

                index = find(ismember(restudylist(:,1), clist{n,1}));
                clist(n,6:8) = restudylist(index,7:9);
            end
            studylists{m} = [clist(:,1:4), newcols, clist(:,6:8)];
            studylistsall = [studylistsall; studylists{m}];
            if m == 3
                studylist = [clist(:,1:4), newcols, clist(:,6:8)];
            end
        end

        if savefile
            save(['matlab/', cname], 'restudylist', 'testlist', 'studylist', 'studylists', 'studylistsall', 'listlength', 'nlists');
        end
    end
end




