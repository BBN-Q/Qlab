function [data, h1, h2] = parseDataFile(obj,makePlot)

filename = [obj.DataPath '/' obj.DataFileName];
% process header
obj.inputStructure = parseParamFile(filename,1);

% read data
fid = fopen(filename);

startData = 0;
index1 = 1;
index2 = 1;
index3 = 1;
while 1
    line = fgetl(fid);
    if ~isempty(strfind(line,'$$$ Beginning of Data')) || ~isempty(strfind(line,'$$$ Beginning of data'))
        startData = 1;
        continue;
    end
    if startData
        if ~isempty(strfind(line,'$$$ End of Data')) || ~isempty(strfind(line,'$$$ End of data'))
            if startData == 0
                Data = [];
            end
            break;
        else
            if strfind(line,'### iterating loop2_index')
                index2 = index2+1;
                index1 = 1;
            elseif strfind(line,'### iterating loop3_index')
                index3 = index3+1;
                index2 = 1;
                index1 = 1;
            else
                if isempty(line)
                    continue
                elseif line == -1
                    break
                else
                    temp = str2num(line); %#ok<ST2NM>
                    Data(1:length(temp),index1,index2,index3) = temp; %#ok<AGROW>
                    index1 = index1+1;
                end
            end
        end
    end
end

fclose(fid);

data.params = obj.inputStructure;
data.Data   = Data;
data.mean_Data = squeeze(abs(mean(data.Data)));
data.abs_Data = squeeze(abs(data.Data));
data.phase_Data = squeeze(180.0/pi * atan2(imag(data.Data), real(data.Data)));

if ~exist('makePlot','var')
    makePlot = 1; % the default setting is to produce plots
end

if makePlot
	% construct x and y range from Loop objects
	Loop = obj.populateLoopStructure(true); % true = just construct lists of points
    x_range = Loop.one.sweep.points;
    
	if ~isempty(Loop.two) && ~strcmp(Loop.two.sweep.name, 'Nothing')
        y_range = Loop.two.sweep.points;
	end
    if size(data.mean_Data(:,:,index3),1) > 1
        for index3 = 1:size(data.mean_Data,3)
            h1 = figure;
			imagesc(x_range,y_range,data.abs_Data(:,:,index3).')
            xlabel(['\fontname{Times}\fontsize{16}' Loop.one.sweep.name]);
            ylabel(['\fontname{Times}\fontsize{16}' Loop.two.sweep.name]);
            set(gca,'FontSize',12)
			
			h2 = figure;
			imagesc(x_range,y_range,data.phase_Data(:,:,index3).')
            xlabel(['\fontname{Times}\fontsize{16}' Loop.one.sweep.name]);
            ylabel(['\fontname{Times}\fontsize{16}' Loop.two.sweep.name]);
            set(gca,'FontSize',12)
        end
    else
        h1 = figure;
        h2 = 0;
		subplot(2,1,1);
		plot(x_range,data.abs_Data,'linewidth',1.5);
		xlabel(['\fontname{Times}\fontsize{16}' Loop.one.sweep.name]);
		ylabel(['\fontname{Times}\fontsize{16}Amplitude']);
		set(gca,'FontSize',12);
		subplot(2,1,2);
		plot(x_range,data.phase_Data,'linewidth',1.5);
        xlabel(['\fontname{Times}\fontsize{16}' Loop.one.sweep.name]);
		ylabel(['\fontname{Times}\fontsize{16}Phase']);
        set(gca,'FontSize',12);
        subplot(2,1,1);
    end
else
    h1 = 0;
    h2 = 0;
end

obj.DataStruct = data;

end