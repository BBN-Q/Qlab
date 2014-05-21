function data = load_data(varargin)
% load_data(varargin)
% Usage:
%   load_data(path, plotMode)
%   load_data(path)
%   load_data(plotMode)
%   load_data()
%
%   path = path to filename to load; special argument 'latest' loads the
%   last data set taken
%   plotMode = 'real', 'imag', 'amp', 'phase', 'real/imag', 'amp/phase',
%        'quad', or '' (no plot)
if nargin == 2
    [fullpath, plotMode] = varargin{:};
    if strcmp(fullpath, 'latest')
        fullpath = get_latest_file();
    end
    [pathname, filename, ext] = fileparts(fullpath);

elseif nargin == 1
    %exist is too clever by half and searches the whole ruddy Matlab path
    %so it finds a quad.m somewhere on the path and returns 2
    %Hack around with some java
    %First check for "latest" flag
    if strcmp(varargin{1}, 'latest')
        fullpath = get_latest_file();
        [pathname, filename, ext] = fileparts(fullpath);
        plotMode = '';
    else
        javaFile = java.io.File(varargin{1});
        if javaFile.exists() && javaFile.isFile()
            fullpath = varargin{1};
            [pathname, filename, ext] = fileparts(fullpath);
            plotMode = '';
        else
            fullpath = '';
            plotMode = varargin{1};
        end
    end
else
    fullpath = '';
    plotMode = '';
end

%If we still don't have a file to load the use a ui to get one from the
%user
if isempty(fullpath)
    % get path of file to load
    [filename, pathname] = uigetfile(fullfile(getpref('qlab', 'dataDir'), '*.h5'));
    if isequal(filename,0) || isequal(pathname,0)
        data = [];
        return
    end
    fullpath = fullfile(pathname, filename);
    [pathname, filename, ext] = fileparts(fullpath);
end

% for backwards compatibility, we assume that files that do not have a
% 'nbrDataSets' attribute store data at the root level under the names
% 'idata' and 'qdata'. If it does have this attribute, then we look for
% data at '/DataSetN/real' and '/DataSetN/imag'.
info = h5info(fullpath, '/');
attributeNames = {info.Attributes.Name};
assert(any(strcmp(attributeNames, 'version')) && h5readatt(fullpath, '/', 'version') == 2, 'Please use an old file loader');
data.nbrDataSets = h5readatt(fullpath, '/', 'nbrDataSets');


headerStr = h5read(fullpath, '/header');
data.expSettings = json.load(headerStr{1});

for ii = 1:data.nbrDataSets
    rawData = h5read(fullpath, ['/DataSet' num2str(ii) '/real']) + 1i * h5read(fullpath, ['/DataSet' num2str(ii) '/imag']);
    data.data{ii} = rawData;
    data.dimension{ii} = h5readatt(fullpath, ['/DataSet' num2str(ii)], 'dimension');
    data.xpoints{ii} = h5read(fullpath, ['/DataSet' num2str(ii) '/xpoints']);
    data.xlabel{ii} = h5readatt(fullpath, ['/DataSet' num2str(ii) '/xpoints'], 'label');
    if data.dimension{ii} > 1
        data.ypoints{ii} = h5read(fullpath, ['/DataSet' num2str(ii) '/ypoints']);
        data.ylabel{ii} = h5readatt(fullpath, ['/DataSet' num2str(ii) '/ypoints'], 'label');
    end
    if data.dimension{ii} > 2
        data.zpoints{ii} = h5read(fullpath, ['/DataSet' num2str(ii) '/zpoints']);
        data.zlabel{ii} = h5readatt(fullpath, ['/DataSet' num2str(ii) '/zpoints'], 'label');
    end
    
    %Check for variance data
    groupInfo = info.Groups(ii);
    if any(strcmp('realvar', {groupInfo.Datasets.Name}))
        data.realvar{ii} = h5read(fullpath, ['/DataSet' num2str(ii) '/realvar']);
        data.imagvar{ii} = h5read(fullpath, ['/DataSet' num2str(ii) '/imagvar']);
        data.prodvar{ii} = h5read(fullpath, ['/DataSet' num2str(ii) '/prodvar']);
    end
    
end

data.filename = [filename, ext];
data.path = pathname;

% available plotting modes
plotMap = struct();
plotMap.abs = struct('label','Amplitude', 'func', @abs);
plotMap.phase = struct('label','Phase (degrees)', 'func', @(x) (180/pi)*angle(x));
plotMap.real = struct('label','Real Quad.', 'func', @real);
plotMap.imag = struct('label','Imag. Quad.', 'func', @imag);

switch plotMode
    case 'real'
        toPlot = {plotMap.real};
        numRows = 1; numCols = 1;
    case 'imag'
        toPlot = {plotMap.imag};
        numRows = 1; numCols = 1;
    case 'amp'
        toPlot = {plotMap.abs};
        numRows = 1; numCols = 1;
    case 'phase'
        toPlot = {plotMap.phase};
        numRows = 1; numCols = 1;
    case 'amp/phase'
        toPlot = {plotMap.abs, plotMap.phase};
        numRows = 2; numCols = 1;
    case 'real/imag'
        toPlot = {plotMap.real, plotMap.imag};
        numRows = 2; numCols = 1;
    case 'quad'
        toPlot = {plotMap.abs, plotMap.phase, plotMap.real, plotMap.imag};
        numRows = 2; numCols = 2;
    otherwise
        toPlot = {};
end


if ~isempty(plotMode)
    sanitizedFileName = strrep(filename, '_', '\_');
    for ii = 1:data.nbrDataSets
        figH = figure();
        for ct = 1:length(toPlot)
            axesH = subplot(numRows, numCols, ct, 'Parent', figH);
                switch data.dimension{ii}
                    case 1
                        plot(axesH, data.xpoints{ii}, toPlot{ct}.func(data.data{ii}));
                        xlabel(axesH, data.xlabel{ii});
                        ylabel(axesH, toPlot{ct}.label)
                        title(sanitizedFileName);
                    case 2
                        imagesc(data.xpoints{ii}(1:size(data.data{ii},2)), data.ypoints{ii}(1:size(data.data{ii},1)), toPlot{ct}.func(data.data{ii}), 'Parent', axesH)
                        xlabel(axesH, data.xlabel{ii});
                        ylabel(axesH, data.ylabel{ii});
                        title(sanitizedFileName);
                    otherwise
                        fprintf('Cannot plot for dimension = %d\n', data.dimension{ii});
                end
        end
    end
end

% if nbrDataSets = 1, then pull data out of cell arry
% wrappers
if data.nbrDataSets == 1
    data.dimension = data.dimension{1};
    data.data = data.data{1};
    data.xpoints = data.xpoints{1};
    if isfield(data, 'ypoints')
        data.ypoints = data.ypoints{1};
    end
    if isfield(data, 'zpoints')
        data.zpoints = data.zpoints{1};
    end
    if isfield(data, 'realvar')
        data.realvar = data.realvar{1};
        data.imagvar = data.imagvar{1};
        data.prodvar = data.prodvar{1};
    end
    
end

end

function fullpath = get_latest_file()

namer = DataNamer.get_instance();
fullpath = namer.lastFileName;

end
