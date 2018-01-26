function [grpData] = loadData_nodra()
% load data for all subjects in the qtask_trc study

% !ls -d /import/monstrum/*/subjects/*_*/behavioral/neuroec/qtask* > wtwFilenames.txt
% 275 .mat files for subjects from fndm2, grmpy, nodra, 1 from "reward
% combined"

% dataDir = '../qtask_trc/expt/data';

%load test file with 2 subjects
FileNames = importdata('wtwFilenamesUse.txt');
%FileNames = importdata('wtwFilenamesTest.txt'); %for debug

% identify the datafiles to be loaded
% subInfo is a cell array:
%   each row is 1 subject
%   3 columns: 
%       col1 = subject ID (string)
%       col2 = group (0=Control, 1=Patient)
            %THIS IS NOT PRESENT, THOUGH THERE IS A "randSeed" variable
%       col3 = datafile name (string)

FileType = ~cellfun(@isempty,strfind(FileNames, 'nodra'));
FileType = FileType + 2*~cellfun(@isempty,strfind(FileNames, 'fndm2'));
FileType = FileType + 3*~cellfun(@isempty,strfind(FileNames, 'grmpy'));

%ask dan about "rewardCombined"
%/import/monstrum/rewardCombined/subjects/18213_9006/behavioral/neuroec/qtask_trc_18312_1.mat


% subInfo = subjectInfo_trc;
% TODO this is undefined?

%n = size(subInfo,1);
n = size(FileNames,1);

% loop over subjects
for sIdx = 1:n
    
    %load file
    subInfo = load(FileNames{sIdx});
    
    % this subject's datafile
    %dfile = subInfo.dataHeader.dfname;
    
    %MACK NOTE: NO GROUP IDS DETERMINABLE, REPLACED WITH RANDSEED
    %switch subInfo{sIdx,2}
    %    case 0, grpID = 'Control';
    %    case 1, grpID = 'Patient';
    %    otherwise, error('Cannot identify group ID for subject %d',sIdx);
    %end
    
    switch FileType(sIdx)
        case 1, subInfo.grpID = 'nodra';
        case 2, subInfo.grpID = 'fndm2';
        case 3, subInfo.grpID = 'grmpy';
        otherwise, error('Cannot identify group ID for subject %d',sIdx);
    end
    
    % load and format this subject's data (subfunction below)
    %subID = subInfo.dataHeader.id;
    
    %subjData = loadData(fullfile(dataDir,dfile),grpID,subID);
    % put together output struct
    
    %NOW get total earned
    %remove an empty row
    isComplete = ~cellfun(@isempty,{subInfo.trialData.outcomeTime});

    subInfo.nBks = max(cell2mat({subInfo.trialData.bkIdx}));
    subInfo.blockDuration = 420; % in s (assumed common across blocks and subjects)
    subInfo.earnings = sum(cell2mat({subInfo.trialData.totalEarned}));
    subInfo.earningsUnits = 'cents';
    
    trialData = table();
    trailTable = struct2table(subInfo.trialData);
    %for b = 1:subInfo.dataHeader.nBks
    %    % identify trials belonging to this block (complete trials only)
    %    idx = (b==cell2mat({subInfo.trialData.bkIdx}) & isComplete);
    %    subInfo.trialData(b) = table2struct(trailTable(idx,:));
    %end
    idx = (isComplete);
    subInfo.trialData = table2struct(trailTable(idx,:));
    
    subInfo.id = subInfo.dataHeader.id;
    subInfo.dfname = subInfo.dataHeader.dfname;
    subInfo.randSeed = subInfo.dataHeader.randSeed;
    subInfo.sessionTime = subInfo.dataHeader.sessionTime;
    subInfo.distribs = subInfo.dataHeader.distribs;
    
    % append it to group
    grpData(sIdx) = subInfo; %#ok<AGROW>
    
end

end % main function


%% MACK NOTE: I AM PRETTY SURE THIS WHOLE THING IS NOT NECESSARY

%%% subfunction to load and format one subject's data
function [subjData] = loadData(dfname,grpID,subID)

% load the datafile
d = load(dfname);

% assess the number of blocks
bkIdx = [d.trialData.bkIdx]';
nBks = max(bkIdx);

% assess which trials are complete
% (there may be a partial data record for the last trial in a block, if
% time ran after the trial began but before the outcome was delivered)
isComplete = ~cellfun(@isempty,{d.trialData.outcomeTime}');

% put together output struct
subjData.id = subID;
subjData.grpID = grpID;
subjData.nBks = nBks;
subjData.blockDuration = 420; % in s (assumed common across blocks and subjects)
subjData.distribs = d.dataHeader.distribs;
subjData.earnings = d.trialData(end).totalEarned;
subjData.earningsUnits = 'cents';

trialData = struct([]);
for b = 1:nBks
    
    % identify trials belonging to this block (complete trials only)
    idx = (bkIdx==b & isComplete);
    
    % add data fields for trial-level variables
    trialData(b).trialNums = (1:sum(idx))';
    trialData(b).designatedWait = [d.trialData(idx).designatedWait]';
    trialData(b).outcomeWin = [d.trialData(idx).payoff]'>5;
    trialData(b).outcomeQuit = [d.trialData(idx).payoff]'<5;
    trialData(b).payoff = [d.trialData(idx).payoff]';
    trialData(b).startTime = [d.trialData(idx).initialTime]';
    trialData(b).latency = [d.trialData(idx).latency]';
    trialData(b).outcomeTime = [d.trialData(idx).outcomeTime]';
    trialData(b).totalEarned = [d.trialData(idx).totalEarned]';
    
end

% add trialData to output
subjData.trialData = trialData;

end % subfunction loadData

