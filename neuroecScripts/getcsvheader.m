function output = getcsvheader(filename)
%% Import data from text file.
% Script for importing data from the following text file:
%
%    /import/monstrum2/Users/finkelm/ITC/mack/n453_ITC_unique_bblids.csv
%
% To extend the code to different selected data or a different text file, generate a function instead of a script.

%% Initialize variables.
endRow = 1;

%% Format string for each line of text:
%   column1: text (%s)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow, 'Delimiter', '', 'WhiteSpace', '', 'ReturnOnError', false);


%% Close the text file.
fclose(fileID);
%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post processing code is included. To generate code which works for unimportable data, select unimportable cells in a file and regenerate the script.

%% Create output variable
header = lower(strrep(dataArray{1}{1},'"',''));
commas = strfind(header,',');
commas(end+1) = length(header)+1;
varnum = length(commas);
cellheader = cell(1,varnum);
cellheader{1} = header(1:commas(1)-1);
for i = 2:varnum
    cellheader{i} = header(commas(i-1)+1:commas(i)-1);
end
output = cellheader;