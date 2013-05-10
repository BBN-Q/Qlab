function data = loadData(makePlot, fullpath)
    if ~exist('makePlot', 'var')
        makePlot = true;
    end

    % get path of file to load
    if ~exist('fullpath', 'var')
        [filename, pathname] = uigetfile(fullfile(getpref('qlab', 'dataDir'), '*.h5'));
        if isequal(filename,0) || isequal(pathname,0)
           data = [];
           return
        end
        fullpath = [pathname '/' filename];
    else
        [pathname, filename, ext] = fileparts(fullpath);
        filename = [filename ext];
    end
    
    % for backwards compatibility, we assume that files that do not have a
    % 'nbrDataSets' attribute store data at the root level under the names
    % 'idata' and 'qdata'. If it does have this attribute, then we look for
    % data at '/DataSetN/real' and '/DataSetN/imag'.
    info = h5info(fullpath, '/');
    attributeNames = {info.Attributes.Name};
    assert(any(strcmp(attributeNames, 'version')) && h5readatt(fullpath, '/', 'version') == 2, 'Please use an old file loader');
    data.nbrDataSets = h5readatt(fullpath, '/', 'nbrDataSets');
    for ii = 1:data.nbrDataSets
        rawData = h5read(fullpath, ['/DataSet' num2str(ii) '/real']) + 1i * h5read(fullpath, ['/DataSet' num2str(ii) '/imag']);
        data.absData{ii} = abs(rawData);
        data.phaseData{ii} = 180.0/pi * angle(rawData);
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
    
    
    data.filename = filename;
    data.path = pathname;

    if (makePlot)
        sanitized_filedname = strrep(filename, '_', '\_');
        for ii = 1:data.nbrDataSets
            switch data.dimension{ii}
                case 1
                    h1 = figure();
                    subplot(2,1,1);
                    amplitude = data.absData{ii}(:);
                    phase = data.phaseData{ii}(:);
                    plot(data.xpoints{ii}(1:length(amplitude)),amplitude,'linewidth',1.5);
                    xlabel(['\fontname{Times}\fontsize{14}' data.xlabel{ii}]);
                    ylabel('\fontname{Times}\fontsize{14}Amplitude');
                    set(gca,'FontSize',12);
                    subplot(2,1,2);
                    plot(data.xpoints{ii}(1:length(phase)),phase,'linewidth',1.5);
                    xlabel(['\fontname{Times}\fontsize{14}' data.xlabel{ii}]);
                    ylabel('\fontname{Times}\fontsize{14}Phase');
                    set(gca,'FontSize',12);
                    subplot(2,1,1);
                    title(sanitized_filedname);
                case 2
                    h1 = figure();
                    imagesc(data.xpoints{ii}(1:size(data.absData{ii},2)),data.ypoints{ii}(1:size(data.absData{ii},1)),data.absData{ii})
                    xlabel(['\fontname{Times}\fontsize{14}' data.xlabel{ii}]);
                    ylabel(['\fontname{Times}\fontsize{14}' data.ylabel{ii}]);
                    set(gca,'FontSize',12)
                    title(sanitized_filedname);

                    h2 = figure();
                    imagesc(data.xpoints{ii}(1:size(data.phaseData{ii},2)),data.ypoints{ii}(1:size(data.phaseData{ii},1)),data.phaseData{ii})
                    xlabel(['\fontname{Times}\fontsize{14}' data.xlabel{ii}]);
                    ylabel(['\fontname{Times}\fontsize{14}' data.ylabel{ii}]);
                    set(gca,'FontSize',12)
                    title(sanitized_filedname);
                otherwise
                    fprintf('Cannot plot for dimension = %d\n', data.dimension{ii});
            end
        end
    end
    
    % if nbrDataSets = 1, then pull absData and phaseData out of the cell
    % wrappers
    if data.nbrDataSets == 1
        data.dimension = data.dimension{1};
        data.data = data.data{1};
        data.absData = data.absData{1};
        data.phaseData = data.phaseData{1};
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