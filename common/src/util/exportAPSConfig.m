function exportAPSConfig(path, basename, ch1seq, ch2seq, ch3seq, ch4seq)
    Version = 1.0;
    useVarients = 1;
    aps = deviceDrivers.APS();
    
    % construct filename
    disp('Writing APS file');
    fullpath = strcat(path, basename, '.mat');
    if ~exist(path, 'dir')
        mkdir(path);
    end
    
    miniLinkRepeat = 1000;
    WaveformLibs = [];
    LinkLists = [];
    
    for i = 1:4
        % convert link lists to APS format
        varname = ['ch' num2str(i) 'seq'];
        if exist(varname, 'var')
            % set up struct
            LinkLists{i} = struct('bankA', [], 'repeatCount', 1);
            seq = eval(varname);
            wfLib = aps.buildWaveformLibrary(seq.waveforms, useVarients);
            [WaveformLibs{i}, banks] = aps.convertLinkListFormat(seq, useVarients, wfLib, miniLinkRepeat);
            LinkLists{i}.bankA = banks{1};
            if length(banks) > 1
                LinkLists{i}.bankB = banks{2};
            else
                LinkLists{i}.bankB = banks{1}; % workaround for not handling empty bankB
           
            end
        else
            WaveformLibs{i} = [];
            LinkLists{i} = [];
        end
    end
    
    save(fullpath, 'Version', 'WaveformLibs', 'LinkLists', '-v7.3');
    
end