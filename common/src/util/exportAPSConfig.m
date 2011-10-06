function exportAPSConfig(path, basename, ch1seq, ch2seq, ch3seq, ch4seq)
    Version = 1.0;
    useVarients = false;
    aps = deviceDrivers.APS();
    
    % construct filename
    disp('Writing APS file');
    fullpath = strcat(path, basename, '.mat');
    if ~exist(path, 'dir')
        mkdir(path);
    end
    
    miniLinkRepeat = 1;
    WaveformLibs = [];
    LinkLists = [];
    
    for i = 1:4
        % convert link lists to APS format
        varname = ['ch' num2str(i) 'seq'];
        if exist(varname, 'var')
            % set up struct
            LinkLists{i} = struct('bankA', [], 'repeatCount', 1);
            seq = eval(varname);
            [WaveformLibs{i}, banks] = aps.convertLinkListFormat(seq, useVarients);
            LinkLists{i}.bankA = banks{1};
            if length(banks) > 1
                LinkLists{i}.bankB = banks{2};
            end
        end
    end
    
    save(fullpath, 'Version', 'WaveformLibs', 'LinkLists', '-v7.3');
    
end