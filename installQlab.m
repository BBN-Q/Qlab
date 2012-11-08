function installQlab()
    answer = inputdlg({'Path to configuration files', 'Path to AWG files'},'Qlab preference folders');
    setpref('qlab', 'cfgDir', answer{1});
    setpref('qlab', 'awgDir', answer{2});
    setpref('qlab', 'pulseParamsBundleFile', fullfile(answer{1}, 'pulseParams.json'));
    setpref('qlab', 'Qubit2ChannelMap', fullfile(answer{1}, 'Qubit2ChannelMap.json'));
    setpref('qlab', 'ExpQuickPickFile', fullfile(answer{1}, 'ExpQuickPick.json'));
    
    % copy example files if param file and channel map don't exist
    srcCfgPath = fullfile(fileparts(mfilename('fullpath')), 'experiments/muWaveDetection/cfg/');
    if ~exist(getpref('qlab', 'pulseParamsBundleFile'), 'file')
        copyfile(fullfile(srcCfgPath, 'pulseParams.example.json'), getpref('qlab', 'pulseParamsBundleFile'));
    end
    
    if ~exist(getpref('qlab', 'Qubit2ChannelMap'), 'file')
        copyfile(fullfile(srcCfgPath, 'Qubit2ChannelMap.example.json'), getpref('qlab', 'Qubit2ChannelMap'));
    end
    
    if ~exist(getpref('qlab', 'ExpQuickPickFile'), 'file')
        copyfile(fullfile(srcCfgPath, 'ExpQuickPick.example.json'), getpref('qlab', 'ExpQuickPickFile'));
    end
    
    parentPath = fileparts(mfilename('fullpath'));
    fprintf('Add these paths to the path:\n');
    fprintf('%s\\common\\src\n', parentPath);
    fprintf('%s\\common\\src\\util\n', parentPath);
    fprintf('%s\\experiments\\muWaveDetection\n', parentPath);
    fprintf('%s\\experiments\\muWaveDetection\\src\n', parentPath);
    fprintf('%s\\experiments\\muWaveDetection\\sequences\n', parentPath);
    fprintf('%s\\analysis\n', parentPath);
    fprintf('%s\\analysis\\cQED_dataAnalysis\n', parentPath);
end