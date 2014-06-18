function installQlab()
    answer = inputdlg({'Path to configuration files', 'Path to AWG files', 'Path to PyQLab', 'Data directory', 'Experiment settings file'},'Qlab preference folders');
    setpref('qlab', 'cfgDir', answer{1});
    setpref('qlab', 'awgDir', answer{2});
    setpref('qlab', 'PyQLabDir', answer{3});
    setpref('qlab', 'InstrumentLibraryFile', fullfile(answer{3}, 'Instruments.json'));
    setpref('qlab', 'dataDir', answer{4});
    setpref('qlab', 'CurScripterFile', answer{5})
    
    parentPath = fileparts(mfilename('fullpath'));
    fprintf('Add these paths to the path:\n');
    fprintf('%s\\common\n', parentPath);
    fprintf('%s\\common\\util\n', parentPath);
    fprintf('%s\\experiments\\muWaveDetection\n', parentPath);
    fprintf('%s\\experiments\\muWaveDetection\\src\n', parentPath);
    fprintf('%s\\analysis\n', parentPath);
    fprintf('%s\\analysis\\cQED_dataAnalysis\n', parentPath);
end