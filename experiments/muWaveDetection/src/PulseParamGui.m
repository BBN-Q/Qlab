function PulseParamGui()

%A simple launcher for the PulseParamGUI python program. 

%Check whether we are on windows to use pythonw instead of python
progPath = fileparts(mfilename('fullpath'));
if ispc
    system(['pythonw "' progPath filesep 'PulseParamGui.py" -f "' getpref('qlab','pulseParamsBundleFile') '" &']);
%Otherwise just call regular python
else
    system(['pythonw ' progPath filesep 'PulseParamGui.py -f "' getpref('qlab','pulseParamsBundleFile') '" &']);
end

