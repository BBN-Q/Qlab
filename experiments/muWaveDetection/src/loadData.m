function data = loadData(makePlot)
    if ~exist('makePlot', 'var')
        makePlot = true;
    end
    % loads data from file by using an expManager object to read in the data
    % base_path is up two levels from this file
    [base_path] = fileparts(mfilename('fullpath'));
    base_path = parent_dir(base_path, 3);
    % need a dummy (but valid!) cfg file
    cfg_file_name = [base_path '/experiments/muWaveDetection/cfg/lastRun.cfg'];

    addpath([ base_path '/experiments/muWaveDetection/'],'-END');
    addpath([ base_path '/common/src'],'-END');
    addpath([ base_path '/experiments/muWaveDetection/src'],'-END');
    addpath([ base_path '/common/src/util/'],'-END');    

    % get path of file to load
    [filename, pathname] = uigetfile('*.out');

    % create the exp object
    Exp = expManager.homodyneDetection(base_path,cfg_file_name);
    % overwrite the filename to the file specified from uigetfile()
    Exp.DataPath = pathname;
    Exp.DataFileName = filename;

    % parse
    Exp.parseExpcfgFile;
    [data, h1, h2] = Exp.parseDataFile(makePlot);
    data.loops = Exp.populateLoopStructure(true);
    data.filename = filename;
    data.path = pathname;
    
    sanitized_filedname = strrep(filename, '_', '\_');
    if h1 ~= 0, figure(h1); title(sanitized_filedname); end
    if h2 ~= 0, figure(h2); title(sanitized_filedname); end

    % helper function to find the nth parent of directory given in 'path'
    function str = parent_dir(path, n)
        str = path;
        if nargin < 2
            n = 1;
        end
        for j = 1:n
            pos = find(str == filesep, 1, 'last');
            str = str(1:pos-1);
        end
    end
end