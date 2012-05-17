function data = loadData(makePlot, fullpath)
    if ~exist('makePlot', 'var')
        makePlot = true;
    end
    % loads data from file by using an expManager object to read in the data
    % base_path is up two levels from this file
    [base_path] = fileparts(mfilename('fullpath'));
    base_path = parent_dir(base_path, 3);

    % get path of file to load
    if ~exist('fullpath', 'var')
        [filename, pathname] = uigetfile('*.out');
        if isequal(filename,0) || isequal(pathname,0)
           data = [];
           return
        end
        fullpath = [pathname '/' filename];
    else
        [pathname, filename, ext] = fileparts(fullpath);
        filename = [filename ext];
    end

    % create the exp object (use the data file itself as the cfg file)
    Exp = expManager.homodyneDetection(base_path, fullpath, 'homodyneDetection', 1);
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