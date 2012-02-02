function exportAPSConfig(path, basename, ch12seq, ch34seq)
    Version = 1.0;
    useVarients = 1;
    
    % construct filename
    disp('Writing APS file');
    fullpath = strcat(path, basename, '.mat');
    if ~exist(path, 'dir')
        mkdir(path);
    end
    
    miniLinkRepeat = 0;
    WaveformLibs = {};
    LinkLists = {};
    
    for ii = [1,3]
        % convert link lists to APS format
        varname = ['ch' num2str(ii) num2str(ii+1) 'seq'];
        if exist(varname, 'var')
            % set up structs
            LinkLists{ii} = struct('bankA', [], 'repeatCount', 1);
            LinkLists{ii+1} = struct('bankA', [], 'repeatCount', 1);
            seq = eval(varname);
            [xWfLib, yWfLib] = APSPattern.buildWaveformLibrary(seq, useVarients);
            [WaveformLibs{ii}, xbanks] = APSPattern.convertLinkListFormat(seq, useVarients, xWfLib, miniLinkRepeat);
            [WaveformLibs{ii+1}, ybanks] = APSPattern.convertLinkListFormat(seq, useVarients, yWfLib, miniLinkRepeat);
            LinkLists{ii}.bankA = xbanks{1};
            LinkLists{ii+1}.bankA = ybanks{1};
            fprintf('Length of Bank A: %d\n',LinkLists{ii}.bankA.length)
            if length(xbanks) > 1
                LinkLists{ii}.bankB = xbanks{2}; 
                LinkLists{ii+1}.bankB = ybanks{2}; 
                fprintf('Length of Bank B: %d\n',LinkLists{ii}.bankB.length)
            end
        else
            WaveformLibs{ii} = [];
            LinkLists{ii} = [];
            WaveformLibs{ii+1} = [];
            LinkLists{ii+1} = [];
        end
    end
    
    save(fullpath, 'Version', 'WaveformLibs', 'LinkLists', '-v7.3');
    
end