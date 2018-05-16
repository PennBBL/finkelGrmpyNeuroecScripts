function [data] = eprimetxttomatlab(filename)

%read file
fileID = fopen(filename);
file=fread(fileID, 'uint16=>char')';
fclose(fileID);
logframestart = '*** LogFrame Start ***';
logframeend = '*** LogFrame End ***';

%find lines of starts and ends of log frames
starts = strfind(file, logframestart);
ends = strfind(file, logframeend);
header = {};
data = {};
rownum = 2;
if length(starts) ~= length(ends)
    disp(strcat('file seems to be broken...terminating file import for ', filename))
else
    for f = 1:length(starts)-1
        %get log for 1 trial
        log = file(starts(f):ends(f)+length(logframeend));
        
        %index of end of line
        endLine=strfind(log,  sprintf('\n'));
        
        %index of colon
        colons = strfind(log, ':');
        
        %?
        thisorthat = 0;
        
        indice = [];
        for sorter = 1:length(colons)+length(endLine)
            if ~isempty(colons) && ~isempty(endLine)
                if min(endLine) < min(colons)
                    if thisorthat == 2
                        endLine(1) = [];
                    else
                        thisorthat = 2;
                        indice(end+1) = min(endLine);
                        endLine(1) = [];
                    end
                elseif min(endLine) > min(colons)
                    if thisorthat == 1
                        colons(1) = [];
                    else
                        thisorthat = 1;
                        indice(end+1) = min(colons);
                        colons(1) = [];
                    end
                end
            else
                if thisorthat == 2 && ~isempty(colons)
                    indice(end+1) = colons(1);
                elseif thisorthat == 1 && ~isempty(endLine)
                    indice(end+1) = endLine(1);
                end
            end
        end
        
        q = 2;
        %this loop freezes at last variable
        while q <= length(indice)
            snip = log(indice(q-1):indice(q));
            %prevent loop frong getting stuck at end of trial
            if snip == sprintf('\n')
                break
            elseif length(snip) == strfind(snip,':') %colon is at the end. This is variable name
                snip2 = log(indice(q):indice(q+1)); % this should be the corresponding value
                if strfind(snip2,':') ~= 1
                    disp('unhandled exception: varname not followed by value');
                    keyboard
                else
                    varname = strtrim(snip(1:end-1));
                    value = strtrim(snip2(2:end));
                    if isstrprop(value, 'digit')
                        value = str2double(value);
                    end
                    
                    %find if header exists
                    where = find(strcmp(varname, header));
                    if rownum == 2 || isempty(where)
                        data{1,end+1} = varname;
                        data{rownum,end} = value;
                        header = data(1,1:end);
                    else
                        data{rownum,where} = value;
                    end
                end
                q = q+2;
            elseif strfind(snip,':') == 1 %colon is at the beginning. This is a variable
                disp('unhandled exception: value detected before varname')
                keyboard
            else %unnecessary case
                %data
            end
        end
        rownum = rownum+1;
    end
end