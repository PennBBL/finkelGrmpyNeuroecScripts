%get bblid and scanid from filename
function [bblid, scanid] = getIDs(FileName)
info = strsplit(FileName,'/');
j = 1;
idx = find(~cellfun(@isempty,strfind(info,'_'))>0);
idx = idx(j);
subjIDs = strsplit(info{idx},'_');
while isnan(str2double(subjIDs{1}))
    j = j + 1;
    idx = find(~cellfun(@isempty,strfind(info,'_'))>0);
    idx = idx(j);
    subjIDs = strsplit(info{idx},'_');
end
scanid = str2double(subjIDs{2});
bblid = str2double(subjIDs{1});
end