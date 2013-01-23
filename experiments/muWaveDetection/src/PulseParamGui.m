function PulseParamGui()

%A simple launcher for the PulseParamGUI python program. 
progPath = fullfile(fileparts(mfilename('fullpath')), 'PulseParamGui.py');

%Check whether we are on windows to use pythonw instead of python
if ispc
    system(['pythonw "', progPath, '" -f "' getpref('qlab','pulseParamsBundleFile') '" &']);
%Otherwise just call regular python
else
    system(['python "', progPath, '" -f "' getpref('qlab','pulseParamsBundleFile') '" &']);
end

