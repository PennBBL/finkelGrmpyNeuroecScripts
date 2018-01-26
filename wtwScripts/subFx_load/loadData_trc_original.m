function [grpData] = loadData_trc()
% load data for all subjects in the qtask_trc study

dataDir = '../qtask_trc/expt/data';

% identify the datafiles to be loaded
% subInfo is a cell array:
%   each row is 1 subject
%   3 columns: 
%       col1 = subject ID (string)
%       col2 = group (0=Control, 1=Patient)
%       col3 = datafile name (string)
subInfo = subjectInfo_trc;
n = size(subInfo,1);

% loop over subjects
for sIdx = 1:n
    
    % this subject's datafile
    dfile = subInfo{sIdx,3};
    switch subInfo{sIdx,2}
        case 0, grpID = 'Control';
        case 1, grpID = 'Patient';
        otherwise, error('Cannot identify group ID for subject %d',sIdx);
    end
    
    % load and format this subject's data (subfunction below)
    subID = subInfo{sIdx,1};
    subjData = loadData(fullfile(dataDir,dfile),grpID,subID);
    
    % append it to group
    grpData(sIdx) = subjData; %#ok<AGROW>
    
end

end % main function



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


