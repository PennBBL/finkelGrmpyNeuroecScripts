   function NeuroEcPipeline(today)

% TODO link to wiki

%example usage: NeuroEcPipeline(pwd)
%function takes data from DAY2, FNDM2, GRMPY, NEFF, PNC

%version key:
    %1	DAY2
    %2	FNDM2
    %3	GRMPY
    %4	NEFF
    %5	PNC
    
%output is ITCData.csv and importedNeuroecData.mat containing structdata
%with each subj.
%loads NeuroEcfilenames.txt, containing a list of files with subject data in
%EPRIME or CSV format. can generate NeuroEcfilenames.txt from ls -d commands
%below if desired.
%saves choice data from individual subjects as csv in subject folders
%optimal set of predictors in the calling of logisticGLMFitAug16 is under debate

% get raw grmpy subject data

!ls -d /data/jux/BBL/studies/grmpy/rawNeuroec/*/*/*ITC*.txt > NeuroEcfilenames.txt
!ls -d /data/jux/BBL/studies/grmpy/rawNeuroec/*/*/*Loss*.txt >> NeuroEcfilenames.txt
!ls -d /data/jux/BBL/studies/grmpy/rawNeuroec/*/*/*Risk*.txt >> NeuroEcfilenames.txt

%outputdir
outputdir = '/data/jux/BBL/projects/finkelGrmpyWtw/processedData';

%add directory with called functions to path
funcdir = '/data/jux/BBL/projects/finkelGrmpyWtw/finkelGrmpyWtwScripts/neuroecScripts';
addpath(funcdir);

%import list of filenames, get types
FileNames = importdata('NeuroEcfilenames.txt');
FileType = ~cellfun(@isempty,strfind(FileNames, 'day2')) + ~cellfun(@isempty,strfind(FileNames, '/fndm/'));
FileType = FileType + 2*~cellfun(@isempty,strfind(FileNames, 'fndm2')) + 2*~cellfun(@isempty,strfind(FileNames, 'nodra'));
FileType = FileType + 3*~cellfun(@isempty,strfind(FileNames, 'grmpy'));
FileType = FileType + 4*~cellfun(@isempty,strfind(FileNames, '.csv'));

TaskType = ~cellfun(@isempty,strfind(FileNames,'ITC'));
TaskType = TaskType + 2*~cellfun(@isempty,strfind(FileNames,'Risk'));
TaskType = TaskType + 3*~cellfun(@isempty,strfind(FileNames,'Loss'));

%create empty cell array, to be filled with cells containing structs for
%each subj
ITCdata = cell(0);
RISKdata = cell(0);
LOSSdata = cell(0);

%set header for individual csvs containing choice data
ITCheader = 'ChoseDelayed, Amt1, Delay1, Amt2, Delay2, RT';
RISKheader = 'ChoseRisky, certainAmt1, riskyAmt2, Risk, RT';
LOSSheader = 'ChoseLossRisk, gainAmt1, lossAmt2, RT';

%loop through FileNames based on type, process each
reverseStr = '';
for i = 1:length(FileNames)
    percentDone = 100 * i / length(FileNames);
    msg = sprintf('\n Percent done: %3.1f', percentDone);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
    cd(funcdir)
    progress = [num2str(i/length(FileNames)*100),'%'];
    switch FileType(i)
        case 1 %OUT OF SCANNER VERSION DAY2 FNDM
            
            eprimefile = eprimetxttomatlab(FileNames{i});%all variables
            
            %get sessiondata
            sessiondata = struct;
            [sessiondata.bblid, sessiondata.subjnum] = getIDs(FileNames{i});
            sessiondata.version = 1;
            [sessiondata.xldate, sessiondata.date] = getEprimeDate(FileNames{i});
            
            %process by task type
            switch TaskType(i)
                case 1 % ITC
                    %    'AmtL'    'DelL'    'AmtR'    'DelR'    'LeftRight'    'Amount6.RT'    'Amount6.RESP'    'Amount14.RT'    'Amount14.RESP'
                    % leftright (out of scan) or LeftRight variable (inscan) says whether the now/easy choice was presented on the left or the right; for in-scanner a 1 means it was on the RIGHT, for out-of-scanner a 1 means it was on the left.  Depending on this variable, you look at either the first or 2nd column of the logfile output, for both versions, column2 (in-scanner called Choice1.RESP) contains the response when now option is on the left, and column1 (in-scanner called Choice.RESP) contains it when the now option is on the right.
                    % IN ALL CASES, a 1 in column 1 or 2 (when relevant based on the LeftRight variable) means subject chose LEFT, and a 0 means they chose RIGHT (original logfile codes these as “y” for yes/left and “r” for right.
                    % The RT columns go along with the RESP columns.
                    
                    % Entries in non-relevant columns are confusing, as they carry forward the entry from the prior trial (and for the first trial, a 3 is listed as missing for that column if it was irrelevant).

                    % convert empty cells to nan values, 'now' to 0
                    eprimefile(cellfun(@isempty,eprimefile)) = {nan};
                    eprimefile(strcmp(eprimefile,'now')) = {0};

                    % convert string 'x days' to double x, convert 'ListX' to double X
                    strless = eprimefile(2:end,2:end);
                    stridx = arrayfun(@iscellstr, strless);
                    strs = strrep(strless(stridx),'days','');
                    strs = strrep(strs,'List','');
                    strless(stridx) = num2cell(str2double(strs));
                    eprimefile(2:end,2:end) = strless;

                    % get index of column
                    AmtLidx = strcmp(eprimefile(1,:),'AmtL');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isnan,eprimefile(2:end,AmtLidx))==1);
                    trials = trials(1)+2:trials(2);

                    % get indices of columns
                    AmtRidx = strcmp(eprimefile(1,:),'AmtR');
                    DelRidx = strcmp(eprimefile(1,:),'DelR');
                    LeftRightidx = strcmp(eprimefile(1,:), 'LeftRight');
                    Amt6RTidx = strcmp(eprimefile(1,:),'Amount6.RT');
                    Amt6RESPidx = strcmp(eprimefile(1,:),'Amount6.RESP');
                    Amt14RTidx = strcmp(eprimefile(1,:),'Amount14.RT');
                    Amt14RESPidx = strcmp(eprimefile(1,:),'Amount14.RESP');

                    % convert desired columns to mat
                    LeftRightcol = cell2mat(eprimefile(trials,LeftRightidx));
                    AmtRcol = cell2mat(eprimefile(trials,AmtRidx));
                    DelRcol = cell2mat(eprimefile(trials,DelRidx));
                    AmtLcol = cell2mat(eprimefile(trials,AmtLidx));
                    Amt6RESPcol = cell2mat(eprimefile(trials,Amt6RESPidx));
                    Amt14RESPcol = cell2mat(eprimefile(trials,Amt14RESPidx));
                    Amt6RTcol = cell2mat(eprimefile(trials,Amt6RTidx));
                    Amt14RTcol = cell2mat(eprimefile(trials,Amt14RTidx));

                    % chosedelayed indicates whether delay was chosen
                    chosedelayed = nansum([LeftRightcol.*(1-Amt6RESPcol),(1-LeftRightcol).*Amt14RESPcol],2);

                    % RT indicates reaction time in each trial
                    RT = nansum([LeftRightcol.*Amt6RTcol,(1-LeftRightcol).*Amt14RTcol],2);

                    chosedelayed(RT == 0) = [];
                    AmtRcol(RT == 0) = [];
                    DelRcol(RT == 0) = [];
                    AmtLcol(RT == 0) = [];
                    RT(RT == 0) = [];
                    
                    sessiondata.processed = ITCanalysis(chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,RT);
                    predictors = [AmtLcol, AmtRcol, DelRcol, AmtLcol.^2, AmtRcol.^2, DelRcol.^2, AmtLcol.*AmtRcol,AmtLcol.*DelRcol,AmtRcol.*DelRcol];
                    predictornames = [{'immediateAmt'},{'delayedAmt'},{'delay'},{'immediateAmt2'},{'delayedAmt2'},{'delay2'},{'IAxDA'},{'IAxD'},{'DAxD'}]; %testing linear & quadratic (square)
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    ITCdata{end+1} = sessiondata;
                    
                    %change directory to write choice csv
                    %TODO SPECIFY DIRECTORY directory = '/data/jux/BBL/studies/grmpy/processedNeuroec/itc';
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(ITCheader, [chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,RT], directory, strcat('ITC_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
                case 2 % RISK
                    % get index of column
                    Attribute1idx = strcmp(eprimefile(1,:),'Attribute1');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isempty,eprimefile(2:end,Attribute1idx))==1);
                    trials = trials(1)+2:trials(2);
                    
                    % get indices of columns
                    AmtRidx = strcmp(eprimefile(1,:),'AmtR');
                    LeftRightidx = strcmp(eprimefile(1,:), 'LeftRight');
                    Amt6RTidx = strcmp(eprimefile(1,:),'Amount6.RT');
                    Amt6RESPidx = strcmp(eprimefile(1,:),'Amount6.RESP');
                    Amt14RTidx = strcmp(eprimefile(1,:),'Amount14.RT');
                    Amt14RESPidx = strcmp(eprimefile(1,:),'Amount14.RESP');

                    % convert desired columns to mat
                    raweprime = eprimefile;
                    eprimefile(cellfun(@ischar,eprimefile(:,:))) = {0};
                    
                    LeftRightcol = cell2mat(eprimefile(trials,LeftRightidx));
                    AmtRcol = cell2mat(eprimefile(trials,AmtRidx));
                    Attribute1col = (cell2mat(eprimefile(trials,Attribute1idx)));
                    Amt6RESPcol = cell2mat(eprimefile(trials,Amt6RESPidx));
                    Amt14RESPcol = cell2mat(eprimefile(trials,Amt14RESPidx));
                    Amt6RTcol = cell2mat(eprimefile(trials,Amt6RTidx));
                    Amt14RTcol = cell2mat(eprimefile(trials,Amt14RTidx));
                    
                    %risk is 0.5 in all cases
                    Riskcol = 0.5*ones(size(AmtRcol));

                    % chosedelayed indicates whether delay was chosen
                    choseRisky = nansum([LeftRightcol.*(Amt6RESPcol),(1-LeftRightcol).*(1-Amt14RESPcol)],2);
                    chosedelayed = choseRisky;

                    % RT indicates reaction time in each trial
                    RT = nansum([LeftRightcol.*Amt6RTcol,(1-LeftRightcol).*Amt14RTcol],2);

                    choseRisky(RT == 0) = [];
                    AmtRcol(RT == 0) = [];
                    Attribute1col(RT == 0) = [];
                    Riskcol(RT == 0) = [];
                    RT(RT == 0) = [];
                    
                    sessiondata.processed = KableLab_RISK_EU(choseRisky,AmtRcol,Attribute1col,Riskcol,RT);
                    predictors = [AmtRcol, Attribute1col, AmtRcol.^2, Attribute1col.^2, AmtRcol.*Attribute1col];
                    predictornames = [{'certainAmt'},{'riskAmt'},{'CA2'},{'RA2'},{'CAxRA'}];
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    RISKdata{end+1} = sessiondata;
                    
                    %change directory to write choice csv
                    %TODO SPECIFY DIRECTORY directory = '/data/jux/BBL/studies/grmpy/processedNeuroec/risk';
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(RISKheader, [chosedelayed,AmtRcol,Attribute1col, Riskcol, RT], directory, strcat('RISK_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
		    	
                case 3 % LOSS
                    
                    % convert empty cells to nan values,
                    eprimefile(cellfun(@isempty,eprimefile)) = {nan};
                    
                    %get index of trials
                    choice1RESPidx = strcmp(eprimefile(1,:),'choice1.RESP');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isnan,eprimefile(2:end,choice1RESPidx))==1);
                    trials = (trials(end-1)+2:trials(end))';
                    
                    % remove '+' and '-' off gain and loss values
                    strless = eprimefile(2:end,2:end);
                    stridx = arrayfun(@iscellstr, strless);
                    strs = strrep(strless(stridx),'+','');
                    strs = strrep(strs,'-','');
                    strless(stridx) = num2cell(str2double(strs));
                    eprimefile(2:end,2:end) = strless;
                    
                    %get gain, loss, resp, RT
                    Attribute1idx = strcmp(eprimefile(1,:),'Attribute1');
                    Attribute3idx = strcmp(eprimefile(1,:),'Attribute3');
                    choice1RTidx = strcmp(eprimefile(1,:),'choice1.RT');

                    % convert desired columns to mat
                    Attribute1col = cell2mat(eprimefile(trials,Attribute1idx));
                    Attribute3col = cell2mat(eprimefile(trials,Attribute3idx));
                    choice1RTcol = cell2mat(eprimefile(trials,choice1RTidx));
                    choice1RESPcol = cell2mat(eprimefile(trials,choice1RESPidx));
                    chosedelayed = choice1RESPcol;

                    sessiondata.processed = LossAnalysis(Attribute1col,Attribute3col,choice1RESPcol,choice1RTcol);
                    predictors = [Attribute1col, Attribute3col, Attribute1col.^2, Attribute3col.^2, Attribute1col.*Attribute3col];
                    predictornames = [{'gain'},{'loss'},{'gain2'},{'loss2'},{'gainxloss'}]; %testing linear & quadratic (square)
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    LOSSdata{end+1} = sessiondata;
                    
                    %change directory to write choice csv
                    %TODO SPECIFY DIRECTORY directory = '/data/jux/BBL/studies/grmpy/processedNeuroec/loss';
                    slash = strfind(directory,'/');
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    directory = directory(1:slash(end));
                    choiceCSVwrite(LOSSheader, [chosedelayed,Attribute1col,Attribute3col,choice1RTcol], directory, strcat('LOSS_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
            end

 	case 2 % IN SCANNER VERSION FNDM2 (NODRA)   
            % get variables
            eprimefile = eprimetxttomatlab(FileNames{i});
            
            % get sessiondata
            sessiondata = struct;
            sessiondata.version = 2;
            [sessiondata.bblid, sessiondata.subjnum] = getIDs(FileNames{i});
            [sessiondata.xldate, sessiondata.date] = getEprimeDate(FileNames{i});
            
            switch TaskType(i)
                case 1 %ITC
                    % Choice.RESP	Choice1.RESP	Offer	delay	LeftRight	Choice.RT	Choice1.RT
                    % leftright (out of scan) or LeftRight variable (inscan) says whether the now/easy choice was presented on the left or the right; for in-scanner a 1 means it was on the RIGHT, for out-of-scanner a 1 means it was on the left.  Depending on this variable, you look at either the first or 2nd column of the logfile output, for both versions, column2 (in-scanner called Choice1.RESP) contains the response when now option is on the left, and column1 (in-scanner called Choice.RESP) contains it when the now option is on the right. SO FOR INSCANNER, if LeftRight=1, then now option was on the left, so look at Choice1.RESP for their response, if LeftRight=0, then now option was on the right, so look in Choice.RESP. 
                    % IN ALL CASES, a 1 in column 1 or 2 (when relevant based on the LeftRight variable) means subject chose LEFT, and a 0 means they chose RIGHT (original logfile codes these as “y” for yes/left and “r” for right.
                    % The RT columns go along with the RESP columns, ie, use col6 for RT when col1 active, and col7 for RT when col2 active.

                    % get index of columns
                    ChoiceRESPidx = strcmp(eprimefile(1,:),'Choice.RESP');	
                    Choice1RESPidx = strcmp(eprimefile(1,:),'Choice1.RESP');
                    Offeridx = strcmp(eprimefile(1,:),'Offer');	
                    Delidx = strcmp(eprimefile(1,:),'delay');
                    LeftRightidx = strcmp(eprimefile(1,:),'LeftRight');	
                    ChoiceRTidx = strcmp(eprimefile(1,:),'Choice.RT');
                    Choice1RTidx = strcmp(eprimefile(1,:),'Choice1.RT');

                    eprimefile(cellfun(@isempty,eprimefile(:,Offeridx)),:) = [];

                    % cycle through each trial, eliminate redundancies
                    % count missed trials
                    missed = 0;
                    for j = 2:length(eprimefile(:,1))
                        curRow = eprimefile(j,:);
                        if isequal(curRow(:,LeftRightidx),num2cell(0))
                            curRow(:,ChoiceRESPidx) = {[]};
                            curRow(:,ChoiceRTidx)={[]};
                        end
                        if isequal(curRow(:,LeftRightidx),num2cell(1))
                            curRow(:,Choice1RESPidx) = {[]};
                            curRow(:,Choice1RTidx) = {[]};
                        end
                        if isequal(curRow(:,Choice1RESPidx),{[]}) && isequal(curRow(:,ChoiceRESPidx),{[]})
                            missed = missed + 1;
                        end
                        eprimefile(j,:) = curRow;
                    end

                    eprimefile(cellfun(@isempty,eprimefile(:,Offeridx)),:) = [];

                    % convert empty cells to 0s, 'y's to 1s, 'r's to 0s
                    eprimefile(cellfun(@isempty,eprimefile)) = {nan};
                    eprimefile(strcmp(eprimefile,'y')) = {1};
                    eprimefile(strcmp(eprimefile,'r')) = {0};

                    trials = 2:length(eprimefile(:,1));

                    % convert string strings with numerical values to numbers
                    strless = eprimefile(trials,Offeridx);
                    stridx = arrayfun(@iscellstr, strless);
                    strless(stridx) = num2cell(str2double(strless(stridx)));
                    eprimefile(trials,Offeridx) = strless;

                    % get RT
                    RT = nansum([cell2mat(eprimefile(trials,Choice1RTidx)), cell2mat(eprimefile(trials,ChoiceRTidx))],2);

                    % get choice
                    Choice1RESPcol = cell2mat(eprimefile(trials,Choice1RESPidx));
                    ChoiceRESPcol = cell2mat(eprimefile(trials,ChoiceRESPidx));
                    chosedelayed = nansum([abs(Choice1RESPcol-1),ChoiceRESPcol],2); 

                    % get AmtR
                    AmtRcol = cell2mat(eprimefile(trials, Offeridx));
                    DelRcol = cell2mat(eprimefile(trials, Delidx));

                    % The immediate amount is always 20
                    AmtLcol = 20*ones(size(AmtRcol));
                    chosedelayed(RT == 0) = [];
                    AmtRcol(RT == 0) = [];
                    DelRcol(RT == 0) = [];
                    AmtLcol(RT == 0) = [];
                    RT(RT == 0) = [];
                    
                    sessiondata.missed = missed;
                    sessiondata.missedpct = missed/length(trials);
                    sessiondata.processed = ITCanalysis(chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,RT);
                    
                    predictors = [AmtRcol, DelRcol, AmtRcol.^2, DelRcol.^2, AmtRcol.*DelRcol];
                    predictornames = [{'delayedAmt'},{'delay'},{'delayedAmt2'},{'delay2'},{'DAxD'}]; %testing linear & quadratic (square)
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    ITCdata{end+1} = sessiondata;
                    
                    %change directory to write choice csv
                    %TODO SPECIFY DIRECTORY directory = FileNames{i};
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(ITCheader, [chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,RT], directory, strcat('ITC_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
                case 2 %RISK
                    % get index of column
                    Attribute1idx = strcmp(eprimefile(1,:),'Attribute1');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isempty,eprimefile(2:end,Attribute1idx))==1);
                    trials = trials(1)+2:trials(2);
                    
                    % get indices of columns
                    AmtRidx = strcmp(eprimefile(1,:),'AmtR');
                    LeftRightidx = strcmp(eprimefile(1,:), 'LeftRight');
                    Amt6RTidx = strcmp(eprimefile(1,:),'Amount6.RT');
                    Amt6RESPidx = strcmp(eprimefile(1,:),'Amount6.RESP');
                    Amt14RTidx = strcmp(eprimefile(1,:),'Amount14.RT');
                    Amt14RESPidx = strcmp(eprimefile(1,:),'Amount14.RESP');

                    % convert desired columns to mat
                    eprimefile(cellfun(@ischar,eprimefile(:,:))) = {0};
                    
                    LeftRightcol = cell2mat(eprimefile(trials,LeftRightidx));
                    AmtRcol = cell2mat(eprimefile(trials,AmtRidx));
                    Attribute1col = cell2mat(eprimefile(trials,Attribute1idx));
                    Amt6RESPcol = cell2mat(eprimefile(trials,Amt6RESPidx));
                    Amt14RESPcol = cell2mat(eprimefile(trials,Amt14RESPidx));
                    Amt6RTcol = cell2mat(eprimefile(trials,Amt6RTidx));
                    Amt14RTcol = cell2mat(eprimefile(trials,Amt14RTidx));
                    
                    %risk is 0.5 in all cases
                    Riskcol = 0.5*ones(size(AmtRcol));

                    % chosedelayed indicates whether delay was chosen
                    % if leftright = 1 look at Amt6RESP, 1 is risky, 0 is
                    % not
                    
                    % if leftright = 0 look at Amt14RESP, 0 is risky, 1 is
                    % not
                    
                    choseRisky = nansum([LeftRightcol.*(Amt6RESPcol),(1-LeftRightcol).*(1-Amt14RESPcol)],2);

                    % RT indicates reaction time in each trial
                    RT = nansum([LeftRightcol.*Amt6RTcol,(1-LeftRightcol).*(1-Amt14RTcol)],2);

                    choseRisky(RT == 0) = [];
                    AmtRcol(RT == 0) = [];
                    Attribute1col(RT == 0) = [];
                    Riskcol(RT == 0) = [];
                    RT(RT == 0) = [];
                    
                    chosedelayed = choseRisky;
                    sessiondata.processed = KableLab_RISK_EU(choseRisky,AmtRcol,Attribute1col,Riskcol,RT);
                    %disp(num2str([choseRisky,AmtRcol,Attribute1col,Riskcol,RT]))
		    

                    predictors = [AmtRcol, Attribute1col, AmtRcol.^2, Attribute1col.^2, AmtRcol.*Attribute1col];
                    predictornames = [{'certainAmt'},{'riskAmt'},{'CA2'},{'RA2'},{'CAxRA'}];
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    RISKdata{end+1} = sessiondata;
                    
                    %change directory to write choice csv
                    %TODO SPECIFY DIRECTORY directory = FileNames{i};
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(RISKheader, [chosedelayed,AmtRcol,Attribute1col, Riskcol, RT], directory, strcat('RISK_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
                case 3 %LOSS
                    
                    % convert empty cells to nan values,
                    eprimefile(cellfun(@isempty,eprimefile)) = {nan};
                    
                    %get index of trials
                    choice1RESPidx = strcmp(eprimefile(1,:),'choice1.RESP');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isnan,eprimefile(2:end,choice1RESPidx))==1);
                    trials = (trials(end-1)+2:trials(end))';
                    
                    % remove '+' and '-' off gain and loss values
                    strless = eprimefile(2:end,2:end);
                    stridx = arrayfun(@iscellstr, strless);
                    strs = strrep(strless(stridx),'+','');
                    strs = strrep(strs,'-','');
                    strless(stridx) = num2cell(str2double(strs));
                    eprimefile(2:end,2:end) = strless;
                    
                    %get gain, loss, resp, RT
                    Attribute1idx = strcmp(eprimefile(1,:),'Attribute1');
                    Attribute3idx = strcmp(eprimefile(1,:),'Attribute3');
                    choice1RTidx = strcmp(eprimefile(1,:),'choice1.RT');

                    % convert desired columns to mat
                    Attribute1col = cell2mat(eprimefile(trials,Attribute1idx));
                    Attribute3col = cell2mat(eprimefile(trials,Attribute3idx));
                    choice1RTcol = cell2mat(eprimefile(trials,choice1RTidx));
                    choice1RESPcol = cell2mat(eprimefile(trials,choice1RESPidx));
                    
                    chosedelayed = choice1RESPcol;
                    sessiondata.processed = LossAnalysis(Attribute1col,Attribute3col,choice1RESPcol,choice1RTcol);
                    predictors = [Attribute1col, Attribute3col, Attribute1col.^2, Attribute3col.^2, Attribute1col.*Attribute3col];
                    predictornames = [{'gain'},{'loss'},{'gain2'},{'loss2'},{'gainxloss'}]; %testing linear & quadratic (square)
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    LOSSdata{end+1} = sessiondata;
                    
                    % change directory and save choice csv
                    %TODO SPECIFY DIRECTORY directory = FileNames{i};
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(LOSSheader, [chosedelayed,Attribute1col,Attribute3col,choice1RTcol], directory, strcat('LOSS_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
            end
      
        case 3 %grmpy
            % get variables
            eprimefile = eprimetxttomatlab(FileNames{i});
            
            % get sessiondata
            sessiondata = struct;
            sessiondata.version = 3;
            [sessiondata.bblid, sessiondata.subjnum] = getIDs(FileNames{i});
            [sessiondata.xldate, sessiondata.date] = getEprimeDate(FileNames{i});
            
            switch TaskType(i)
                case 1 %ITC
                    %    'AmtL'    'DelL'    'AmtR'    'DelR'    'LeftRight'    'Amount6.RT'    'Amount6.RESP'    'Amount14.RT'    'Amount14.RESP'
                    % leftright (out of scan) or LeftRight variable (inscan) says whether the now/easy choice was presented on the left or the right; for in-scanner a 1 means it was on the RIGHT, for out-of-scanner a 1 means it was on the left.  Depending on this variable, you look at either the first or 2nd column of the logfile output, for both versions, column2 (in-scanner called Choice1.RESP) contains the response when now option is on the left, and column1 (in-scanner called Choice.RESP) contains it when the now option is on the right.
                    % IN ALL CASES, a 1 in column 1 or 2 (when relevant based on the LeftRight variable) means subject chose LEFT, and a 0 means they chose RIGHT (original logfile codes these as “y” for yes/left and “r” for right.
                    % The RT columns go along with the RESP columns.
                    
                    % Entries in non-relevant columns are confusing, as they carry forward the entry from the prior trial (and for the first trial, a 3 is listed as missing for that column if it was irrelevant).

                    % convert empty cells to nan values, 'now' to 0
                    eprimefile(cellfun(@isempty,eprimefile)) = {nan};
                    eprimefile(strcmp(eprimefile,'now')) = {0};

                    % convert string 'x days' to double x, convert 'ListX' to double X
                    strless = eprimefile(2:end,2:end);
                    stridx = arrayfun(@iscellstr, strless);
                    strs = strrep(strless(stridx),'days','');
                    strs = strrep(strs,'List','');
                    strless(stridx) = num2cell(str2double(strs));
                    eprimefile(2:end,2:end) = strless;

                    % get index of column
                    AmtLidx = strcmp(eprimefile(1,:),'AmtL');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isnan,eprimefile(2:end,AmtLidx))==1);
                    trials = trials(1)+2:trials(2);

                    % get indices of columns
                    AmtRidx = strcmp(eprimefile(1,:),'AmtR');
                    DelRidx = strcmp(eprimefile(1,:),'DelR');
                    LeftRightidx = strcmp(eprimefile(1,:), 'LeftRight');
                    Amt6RTidx = strcmp(eprimefile(1,:),'Amount6.RT');
                    Amt6RESPidx = strcmp(eprimefile(1,:),'Amount6.RESP');
                    Amt14RTidx = strcmp(eprimefile(1,:),'Amount14.RT');
                    Amt14RESPidx = strcmp(eprimefile(1,:),'Amount14.RESP');

                    % convert desired columns to mat
                    LeftRightcol = cell2mat(eprimefile(trials,LeftRightidx));
                    AmtRcol = cell2mat(eprimefile(trials,AmtRidx));
                    DelRcol = cell2mat(eprimefile(trials,DelRidx));
                    AmtLcol = cell2mat(eprimefile(trials,AmtLidx));
                    Amt6RESPcol = cell2mat(eprimefile(trials,Amt6RESPidx));
                    Amt14RESPcol = cell2mat(eprimefile(trials,Amt14RESPidx));
                    Amt6RTcol = cell2mat(eprimefile(trials,Amt6RTidx));
                    Amt14RTcol = cell2mat(eprimefile(trials,Amt14RTidx));

                    % chosedelayed indicates whether delay was chosen
                    chosedelayed = nansum([LeftRightcol.*(1-Amt6RESPcol),(1-LeftRightcol).*Amt14RESPcol],2);

                    % RT indicates reaction time in each trial
                    RT = nansum([LeftRightcol.*Amt6RTcol,(1-LeftRightcol).*Amt14RTcol],2);

                    chosedelayed(RT == 0) = [];
                    AmtRcol(RT == 0) = [];
                    DelRcol(RT == 0) = [];
                    AmtLcol(RT == 0) = [];
                    RT(RT == 0) = [];
                    
                    sessiondata.processed = ITCanalysis(chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,RT);
                    predictors = [AmtLcol, AmtRcol, DelRcol, AmtLcol.^2, AmtRcol.^2, DelRcol.^2, AmtLcol.*AmtRcol,AmtLcol.*DelRcol,AmtRcol.*DelRcol];
                    predictornames = [{'immediateAmt'},{'delayedAmt'},{'delay'},{'immediateAmt2'},{'delayedAmt2'},{'delay2'},{'IAxDA'},{'IAxD'},{'DAxD'}]; %testing linear & quadratic (square)
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    ITCdata{end+1} = sessiondata;
                    
                    %change directory to write choice csv
                    directory = '/data/jux/BBL/projects/finkelGrmpyWtw/processedData/itc/';
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(ITCheader, [chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,RT], directory, strcat('ITC_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));

                case 2 %RISK
                    % get index of column
                    Attribute1idx = strcmp(eprimefile(1,:),'Attribute1');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isempty,eprimefile(2:end,Attribute1idx))==1);
                    trials = trials(1)+2:trials(2);
                    
                    % get indices of columns
                    AmtRidx = strcmp(eprimefile(1,:),'AmtR');
                    LeftRightidx = strcmp(eprimefile(1,:), 'LeftRight');
                    Amt6RTidx = strcmp(eprimefile(1,:),'Amount6.RT');
                    Amt6RESPidx = strcmp(eprimefile(1,:),'Amount6.RESP');
                    Amt14RTidx = strcmp(eprimefile(1,:),'Amount14.RT');
                    Amt14RESPidx = strcmp(eprimefile(1,:),'Amount14.RESP');

                    % convert desired columns to mat
                    eprimefile(cellfun(@ischar,eprimefile(:,:))) = {0};
                    
                    LeftRightcol = cell2mat(eprimefile(trials,LeftRightidx));
                    AmtRcol = cell2mat(eprimefile(trials,AmtRidx));
                    Attribute1col = cell2mat(eprimefile(trials,Attribute1idx));
                    Amt6RESPcol = cell2mat(eprimefile(trials,Amt6RESPidx));
                    Amt14RESPcol = cell2mat(eprimefile(trials,Amt14RESPidx));
                    Amt6RTcol = cell2mat(eprimefile(trials,Amt6RTidx));
                    Amt14RTcol = cell2mat(eprimefile(trials,Amt14RTidx));
                    
                    %risk is 0.5 in all cases
                    Riskcol = 0.5*ones(size(AmtRcol));

                    % chosedelayed indicates whether delay was chosen
                    choseRisky = nansum([LeftRightcol.*(Amt6RESPcol),(1-LeftRightcol).*(1-Amt14RESPcol)],2);

                    % RT indicates reaction time in each trial
                    RT = nansum([LeftRightcol.*Amt6RTcol,(1-LeftRightcol).*Amt14RTcol],2);

                    choseRisky(RT == 0) = [];
                    AmtRcol(RT == 0) = [];
                    Attribute1col(RT == 0) = [];
                    Riskcol(RT == 0) = [];
                    RT(RT == 0) = [];
                    
                    chosedelayed = choseRisky;
                    sessiondata.processed = KableLab_RISK_EU(choseRisky,AmtRcol,Attribute1col,Riskcol,RT);
                    predictors = [AmtRcol, Attribute1col, AmtRcol.^2, Attribute1col.^2, AmtRcol.*Attribute1col];
                    predictornames = [{'certainAmt'},{'riskAmt'},{'CA2'},{'RA2'},{'CAxRA'}];
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    RISKdata{end+1} = sessiondata;
                    
                    %change directory to write choice csv
                    directory = '/data/jux/BBL/projects/finkelGrmpyWtw/processedData/risk/';
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(RISKheader, [chosedelayed,AmtRcol,Attribute1col, Riskcol, RT], directory, strcat('RISK_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
                    
                    
                case 3 %LOSS
                    % convert empty cells to nan values,
                    eprimefile(cellfun(@isempty,eprimefile)) = {nan};
                    
                    %get index of trials
                    choice1RESPidx = strcmp(eprimefile(1,:),'choice1.RESP');
                    % get indexes of trials by finding nan amount values
                    trials = find(cellfun(@isnan,eprimefile(2:end,choice1RESPidx))==1);
                    trials = (trials(end-1)+2:trials(end))';
                    
                    % remove '+' and '-' off gain and loss values
                    strless = eprimefile(2:end,2:end);
                    stridx = arrayfun(@iscellstr, strless);
                    strs = strrep(strless(stridx),'+','');
                    strs = strrep(strs,'-','');
                    strless(stridx) = num2cell(str2double(strs));
                    eprimefile(2:end,2:end) = strless;
                    
                    %get gain, loss, resp, RT
                    Attribute1idx = strcmp(eprimefile(1,:),'Attribute1');
                    Attribute3idx = strcmp(eprimefile(1,:),'Attribute3');
                    choice1RTidx = strcmp(eprimefile(1,:),'choice1.RT');

                    % convert desired columns to mat
                    Attribute1col = cell2mat(eprimefile(trials,Attribute1idx));
                    Attribute3col = cell2mat(eprimefile(trials,Attribute3idx));
                    choice1RTcol = cell2mat(eprimefile(trials,choice1RTidx));
                    choice1RESPcol = cell2mat(eprimefile(trials,choice1RESPidx));
                    
                    chosedelayed = choice1RESPcol;
                    sessiondata.processed = LossAnalysis(Attribute1col,Attribute3col,choice1RESPcol,choice1RTcol);
                    predictors = [Attribute1col, Attribute3col, Attribute1col.^2, Attribute3col.^2, Attribute1col.*Attribute3col];
                    predictornames = [{'gain'},{'loss'},{'gain2'},{'loss2'},{'gainxloss'}]; %testing linear & quadratic (square)
                    sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    LOSSdata{end+1} = sessiondata;
                    
                    % change directory and save choice csv
                    directory = '/data/jux/BBL/projects/finkelGrmpyWtw/processedData/loss/';
                    slash = strfind(directory,'/');
                    directory = directory(1:slash(end));
                    %TODO put in different directory other than current
                    %directory "directory" in function below
                    choiceCSVwrite(LOSSheader, [chosedelayed,Attribute1col,Attribute3col,choice1RTcol], directory, strcat('LOSS_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
            end
        case 4
            % get version number
            if ~isempty(strfind(FileNames{i},'NEFF'))
                version = 4;
            else
                version = 5;
            end
            
            % get csv info
            csvheader = getcsvheader(FileNames{i});
            csvdata = getcsvdata(FileNames{i});
            
            % get date names, either 'dotest_scales' or 'date_of_cnb'
            dateidx = strcmp(csvheader,'dotest_scales');
            if sum(dateidx) == 0
                dateidx = strcmp(csvheader,'date_of_cnb');
            end
            
            % get ids
            bblididx = strcmp(csvheader,'bblid');
            scanididx = strcmp(csvheader,'scanid');
            if sum(scanididx) == 0
                scanididx(end+1) = 1;
                csvdata(:,length(scanididx)) = {'nan'};
            end
            
            % change '.' to NaN
            csvdata(strcmp(csvdata,'.'))={'nan'};
            
            % get decision data
            choicedata = cellfun(@str2num,csvdata(:,~cellfun(@isempty,regexp(csvheader,'disc[._]+q_*'))));
            
            csvdata = csvdata(logical(sum(~isnan(choicedata)')'),:);
            
            choicesITC = cellfun(@str2num,csvdata(:,~cellfun(@isempty,regexp(csvheader,'ddisc[._]+q_*')))') - 1;
            rtsITC      =  cellfun(@str2num,csvdata(:,~cellfun(@isempty,regexp(csvheader,'ddisc[._]+tr_*')))');
            
            choicesRISK = cellfun(@str2num,csvdata(:,~cellfun(@isempty,regexp(csvheader,'rdisc[._]+q_*')))') - 1;
            rtsRISK     = cellfun(@str2num,csvdata(:,~cellfun(@isempty,regexp(csvheader,'rdisc[._]+tr_*')))');
            
            %get questiondata
            load('/data/jux/BBL/projects/finkelGrmpyWtw/finkelGrmpyWtwScripts/neuroecScripts/itemOrderITC.mat')
            load('/data/jux/BBL/projects/finkelGrmpyWtw/finkelGrmpyWtwScripts/neuroecScripts/itemOrderRisk.mat')
            
            %deal with individual subjects
            for j=1:size(choicesITC,2)
                if ~isnan(choicesITC(1,j))
                    sessiondata = struct;
                    date = csvdata(j,dateidx);
                    
                    %if date exists, get info
                    if ~isequal(date,{''})
                        sessiondata.xldate = m2xdate(datenum(date));
                        split = strsplit(date{1,1},'/');
                        for k = 1:2
                            if length(split{k}) == 1
                                split(k) = strcat('0',split(k));
                            end
                        end
                        if length(split{3}) == 2
                            split(3) = strcat('20',split(3));
                        end
                        sessiondata.date = str2double(strcat(split(3), split(1), split(2)));
                    else sessiondata.date = NaN;
                    end
                    
                    %get IDs
                    sessiondata.subjnum = str2double(csvdata{j,scanididx});
                    sessiondata.bblid = str2double(csvdata{j,bblididx});
                    
                    %get choicedata
                    chosedelayed = choicesITC(:,j);
                    choseRisky = abs(1-choicesRISK(:,j));
                    
                    %skip subject if values are NaN
                    if isnan(sum(chosedelayed))
                        continue
                    end
                    
                    %get question data columns
                    AmtLcol = itemOrderITC(:,2);
                    AmtRcol = itemOrderITC(:,4);
                    DelRcol = itemOrderITC(:,5);
                    AmtRisky = itemOrderRisk(:,2);
                    AmtCertain = itemOrderRisk(:,3);
                    
                    %fetch ITCsessiondata
                    %sessiondata.processed = ITCanalysis(chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,rtsITC(:,j));
                    %predictors = [AmtLcol, AmtRcol, DelRcol, AmtLcol.^2, AmtRcol.^2, DelRcol.^2, AmtLcol.*AmtRcol,AmtLcol.*DelRcol,AmtRcol.*DelRcol];
                    %predictornames = [{'immediateAmt'},{'delayedAmt'},{'delay'},{'immediateAmt2'},{'delayedAmt2'},{'delay2'},{'IAxDA'},{'IAxD'},{'DAxD'}]; %testing linear & quadratic (square)
                    %sessiondata.agnostic = logisticGLMFitAug16(chosedelayed,predictors,predictornames);
                    sessiondata.version = version;
                    
                    %add data to cell array
                    ITCdata{end+1} = sessiondata;
                    
                    %fetch RISKressiondata
                    if version == 4
                        Riskcol = 0.5*ones(size(AmtRisky));
                        sessiondata.processed = KableLab_RISK_EU(choseRisky,AmtCertain,AmtRisky,Riskcol,rtsRISK(:,j));
                        predictors = [AmtCertain, AmtRisky, AmtCertain.^2, AmtRisky.^2, AmtCertain.*AmtRisky];
                        predictornames = [{'certainAmt'},{'riskAmt'},{'CA2'},{'RA2'},{'CAxRA'}];
                        sessiondata.agnostic = logisticGLMFitAug16(choseRisky,predictors,predictornames);
                        RISKdata{end+1} = sessiondata;
                    end
                    
                    %save NEFF data as csv in subject folder, create folder
                    %if it doesn't exist
                    if version == 4
                        %directory = '/import/monstrum/neff/subjects/';
                    elseif version == 5
                        directory = strcat(outputdir, 'subjects/');
                    end
                    cd(directory);
                    bblsubj = strcat(num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'/');
                    directory = strcat(directory, bblsubj);
                    if ~isequal(exist(directory, 'dir'), 7)
                        mkdir(bblsubj)
                        cd(bblsubj)
                        mkdir behavioral
                        cd behavioral
                        mkdir itc
                        mkdir risk
                        cd ../..
                    elseif ~isequal(exist(strcat(directory,'behavioral/'),'dir'),7)
                        cd(directory)
                        mkdir behavioral
                        cd behavioral
                        mkdir itc
                        mkdir risk
                        cd ../..
                    elseif ~isequal(exist(strcat(directory,'behavioral/itc/'),'dir'),7) || ~isequal(exist(strcat(directory,'behavioral/risk/'),'dir'),7)
                        cd(directory)
                        cd behavioral
                        mkdir itc
                        mkdir risk
                        cd ../..
                    end
                    choiceCSVwrite(ITCheader, [chosedelayed,AmtLcol,zeros(size(AmtLcol)),AmtRcol,DelRcol,rtsITC(:,j)],strcat(directory, '/behavioral/itc/'), strcat('ITC_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
                    if version == 4
                        choiceCSVwrite(RISKheader, [choseRisky,AmtCertain,AmtRisky,Riskcol,rtsRISK(:,j)],strcat(directory, 'behavioral/risk/'), strcat('RISK_processed_', num2str(sessiondata.bblid), '_', num2str(sessiondata.subjnum),'_', num2str(sessiondata.date), '.csv'));
                    end
                end
            end
        otherwise
            disp('unexpected task type')
            %keyboard
    end
end
cd (outputdir)

formatOut = 'yyyymmdd';
today = datestr(today, formatOut);
neuroeccsvwrite(ITCdata', strcat('ITC', 'Finkel', today, '.csv'), outputdir);
neuroeccsvwrite(LOSSdata', strcat('LOSS', 'Finkel', today, '.csv'), outputdir);
neuroeccsvwrite(RISKdata', strcat('RISK', 'Finkel', today, '.csv'), outputdir);

save importedNeuroecData.mat

end

function neuroeccsvwrite(data, name, outputdir)
structData = {};
counter = 1;
for i = 1:length(data)
    [structData, counter] = getStructVars(data{i}, structData, {}, counter);
end

%format structData
structData(cellfun(@isempty,structData)) = {nan};
structData((cellfun(@islogical,structData))) = num2cell(double(cell2mat(structData(cellfun(@islogical,structData)))));

%export csv
variables = structData(1,:);
header = variables(1);
for i = 2:length(variables);
    header = strcat(header,',',variables(i));
end
header = char(header);

structData = cell2mat(structData(2:end,:));

cd(outputdir);
fid = fopen(name, 'w');
fprintf(fid,'%s\n', header);
fclose(fid);
dlmwrite(name, structData, '-append', 'precision', '%.6f','delimiter', ',');

end
