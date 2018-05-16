% recursively get field names and values for struct
% return cells of var names, corresponding values
% example use: structData = getStructVars(struct, {}, {})
function [structData, counter] = getStructVars(struct, structData, fieldvar, counter)
if ~isstruct(struct)
    %???
end
if isempty(structData)
    structData = cell(0);
end
if isempty(fieldvar)
    varName = '';
end
fields = fieldnames(struct);

counter = counter + 1;

for i = 1:length(fields)
    % get all data in substructs
    val = struct.(fields{i});
    if isstruct(val)
        parentfield = '';
        if ~isempty(fieldvar)
            parentfield = fieldvar;
            fieldvar = strcat(fields(i),'.',fieldvar);
        else
            fieldvar = fields(i);
        end
        structData = getStructVars(val,structData,fieldvar,counter-1);
        if ~isempty(parentfield)
            fieldvar = parentfield;
            clear parentfield;
        else
            fieldvar = '';
        end
        varName = '';
        continue
    % skip multiple variables
    elseif length(val) > 1
        continue
    end
    if ~isempty(fieldvar)
        varName = strcat('.',fieldvar);
    end
    varName = strcat(fields(i), varName);
    if isempty(structData)
        structData(1) = varName;
    end
    varNameidx = strcmp(structData(1,:),varName);
    if all(~varNameidx)
        varNameidx(length(varNameidx)+1) = 1;
        structData(1,varNameidx) = varName;
    end
    structData{counter,varNameidx} = val;
    varName = '';
end
end