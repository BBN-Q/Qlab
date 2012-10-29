function errorMsg = startCounting(Instr)

errorMsg = '';

if ~isfield(Instr,'counter')
    errorMsg = 'Error: counter not found';
    return
end
%fprintf(Instr.counter,'CONF:TOT:CONT');pause(0.5)
fprintf(Instr.counter,'INIT');