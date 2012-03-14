function [commonSettings, prevSettings] = get_previous_settings(caller, cfg_path, instrumentNames)
    % FUNCTION get_previous_settings
    % inputs:
    % caller - name of the calling program
    % cfg_path - path to find cfg files
    % instrumentNames - a cell array of instrument names that are expected
    % to be in the settings structures
    
    % get common setings
    cfg_name = fullfile(cfg_path, 'common.cfg');
    if exist(cfg_name, 'file')
        commonSettings = parseParamFile(cfg_name);
    else
        commonSettings = struct();
    end

    % get previous settings
    cfg_name = fullfile(cfg_path, [caller '.cfg']);
    if exist(cfg_name, 'file')
        prevSettings = parseParamFile(cfg_name);
    else
        prevSettings = struct();
        prevSettings.InstrParams = struct();
    end
    % make sure prevSettings has fields for all instruments in
    % instrumentNames
    for f = instrumentNames
        name = cell2mat(f);
        if ~isfield(prevSettings.InstrParams, name)
            prevSettings.InstrParams.(name) = struct();
        end
    end
end