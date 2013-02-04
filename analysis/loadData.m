function data = loadData(makePlot, fullpath)
    if ~exist('makePlot', 'var')
        makePlot = true;
    end

    % base_path is up two levels from this file
    [base_path] = fileparts(mfilename('fullpath'));
    base_path = parent_dir(base_path, 3);

    % get path of file to load
    if ~exist('fullpath', 'var')
        [filename, pathname] = uigetfile('*.h5');
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
        data.abs_Data{ii} = abs(rawData);
        data.phase_Data{ii} = 180.0/pi * angle(rawData);
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
                    amplitude = data.abs_Data{ii}(:);
                    phase = data.phase_Data{ii}(:);
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
                    imagesc(data.xpoints{ii}(1:size(data.abs_Data{ii},2)),data.ypoints{ii}(1:size(data.abs_Data{ii},1)),data.abs_Data{ii})
                    xlabel(['\fontname{Times}\fontsize{14}' data.xlabel{ii}]);
                    ylabel(['\fontname{Times}\fontsize{14}' data.ylabel{ii}]);
                    set(gca,'FontSize',12)
                    title(sanitized_filedname);

                    h2 = figure();
                    imagesc(data.xpoints{ii}(1:size(data.phase_Data{ii},2)),data.ypoints{ii}(1:size(data.phase_Data{ii},1)),data.phase_Data{ii})
                    xlabel(['\fontname{Times}\fontsize{14}' data.xlabel{ii}]);
                    ylabel(['\fontname{Times}\fontsize{14}' data.ylabel{ii}]);
                    set(gca,'FontSize',12)
                    title(sanitized_filedname);
                otherwise
                    error('Cannot plot for dimension = %d', dimension);
            end
        end
    end
    
    % if nbrDataSets = 1, then pull abs_Data and phase_Data out of the cell
    % wrappers
    if data.nbrDataSets == 1
        data.abs_Data = data.abs_Data{1};
        data.phase_Data = data.phase_Data{1};
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