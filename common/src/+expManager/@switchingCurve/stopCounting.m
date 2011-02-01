function errorMsg = stopCounting(Instr)

errorMsg = '';
if ~isfield(Instr,'counter')
    errorMsg = 'Error: counter not found';
    return
end
fprintf(Instr.counter,'ABORT');
