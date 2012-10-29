function [Data errorMsg] = acquireCounts(Instr)

errorMsg = '';
if ~isfield(Instr,'counter')
    errorMsg = 'Error: counter not found';
    return
end
fprintf(Instr.counter,'FETCH?');
DataStr = fscanf(Instr.counter);
Data = str2double(DataStr);
end