function [date1,date2] = getEprimeDate(filename)

%read file
fileID = fopen(filename);
file=fread(fileID, 'uint16=>char')';
fclose(fileID);

%get session date in header
varname = 'SessionDate: ';
headerend = '*** Header End ***';

starts = strfind(file, varname);
ends = strfind(file, headerend);
header = file(starts(1):ends(1));
ends = strfind(header, sprintf('\n'));

%get variable line
dateline = header(1:ends(1));
%date as string
date = dateline(length(varname):end);

%date as excel serial
date1 = m2xdate(datenum(date));
split = strsplit(date,'-');
date2 = str2double(strcat(split(3), split(1), split(2)));

end