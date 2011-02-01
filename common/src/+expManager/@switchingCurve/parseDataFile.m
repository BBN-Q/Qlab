function data = parseDataFile(obj,makePlot)

filename = obj.DataFileName;
CFG = parseParamFile(filename,1);
fid = fopen(filename);

startData = 0;
% index1 = 1;
index2 = 1;
index3 = 1;
while 1
    line = fgetl(fid);
    if strfind(line,'$$$ Beginning of Data')
        startData = 1;
        continue;
    end
    if startData
        if strfind(line,'$$$ End of Data')
            if startData == 0
                Data = [];
            end
            break;
        else
            if strfind(line,'### iterating loop3_index')
                index3 = index3+1;
                index2 = 1;
            else
                if isempty(line)
                    continue
                elseif line == -1
                    break
                else
                    temp = str2num(line);
                    Data(1:length(temp),index2,index3) = temp;
                    index2 = index2+1;
                end
            end
        end
    end
end

data.params  = CFG;
data.Data = Data;

LoopNames = fieldnames(data.params.LoopParams);
numLoops  = numel(LoopNames);

plot_MinMax     = cell(numel(LoopNames),1);
numSteps        = cell(numel(LoopNames),1);
plot_range      = cell(numel(LoopNames),1);
plot_range_name = cell(numel(LoopNames),1);
parameter_name  = cell(numel(LoopNames),1);


for Loop_index = 1:numLoops
    
    loopNumber                  = data.params.LoopParams.(LoopNames{Loop_index}).number;

    plot_MinMax{loopNumber}     = data.params.LoopParams.(LoopNames{Loop_index}).plotRange;
    numSteps{loopNumber}        = data.params.LoopParams.(LoopNames{Loop_index}).steps;
    plot_range{loopNumber}      = linspace(plot_MinMax{loopNumber}.start,plot_MinMax{loopNumber}.end,numSteps{loopNumber});
    plot_range_name{loopNumber} = LoopNames{Loop_index};
    % by default we use the first parameter for labeling
    parameter_name{loopNumber}  = data.params.LoopParams.(LoopNames{Loop_index}).parameter{1};
    
    data.PlotRanges.([plot_range_name{loopNumber} '_range']) = plot_range{loopNumber};

end
% matlab is funny about imagesc, the .' is necessary to recover the correct
% plot

if ~exist('makePlot','var')
    makePlot = 1; % the default setting is to produce plots
end

if makePlot
    if numLoops > 1
        for index3 = 1:size(data.Data,3)

            figure;
            imagesc(plot_range{2}(1:size(data.Data(:,:,index3),2)),plot_range{1}(1:size(data.Data(:,:,index3),1)),data.Data(:,:,index3))
            xlabel(['\fontname{Times}\fontsize{30}' regexprep(sprintf('%s %s',plot_range_name{2},parameter_name{2}),'_',' ')]);
            ylabel(['\fontname{Times}\fontsize{30}' regexprep(sprintf('%s %s',plot_range_name{1},parameter_name{1}),'_',' ')]);
            set(gca,'FontSize',20)
        end
    else
        figure
        plot(plot_range{1},data.Data)
        xlabel(['\fontname{Times}\fontsize{30}' regexprep(sprintf('%s %s',plot_range_name{1},parameter_name{1}),'_',' ')]);
        set(gca,'FontSize',20)
    end
end

obj.DataStruct = data;

end
