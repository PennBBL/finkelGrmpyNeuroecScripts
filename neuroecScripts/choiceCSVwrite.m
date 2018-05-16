%write csv
function choiceCSVwrite(header, data, dir, filename)
cd(dir);
fid = fopen(filename, 'w');
if fid == -1
    filename
    return
end
fprintf(fid,'%s\n', header);
fclose(fid);
dlmwrite(filename, data, '-append','delimiter', ',');
end