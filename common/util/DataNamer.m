classdef DataNamer < handle
    properties
        fileCount
        deviceName
        dataDir
    end
    methods
        function obj = DataNamer(dataDir, deviceName)
            obj.dataDir = dataDir;
            obj.deviceName = deviceName;
            reset(obj);
        end
        
        function reset(obj)
            % if the current data path is not empty, reset the counter to
            % one more than the highest value file name in the path
            newval = 0;
            
            % check for existence of dataDir/deviceName
            folderList = dir(fullfile(obj.dataDir, obj.deviceName));
            if isempty(folderList)
                % make device folder
                mkdir(fullfile(obj.dataDir, obj.deviceName));
            else
                % there are existing folders, descend into them to look for
                % largest file number
                folderList = folderList(arrayfun(@(x) x.isdir, folderList));
                folderNames = sort(arrayfun(@(x) x.name, folderList, 'UniformOutput', false));
                ct = length(folderNames);
                while (ct > 0)
                    fileList = dir(fullfile(obj.dataDir, obj.deviceName, folderNames{ct}, '*.h5'));
                    % pull out the number from ###_device_experiment.out
                    tokens = regexp({fileList.name}, '(\d+)_.*\.h5', 'tokens', 'once');
                    if ~isempty(tokens)
                        expNums = cellfun(@str2double, tokens);
                        newval = max(expNums);
                        break;
                    end
                    ct = ct - 1;
                end
            end

            obj.fileCount = newval+1;
        end
        
        function increment(obj)
            obj.fileCount = obj.fileCount + 1;
        end
        
        function out = get_name(obj, expName)
            %Check if we have a folder for today
            todaysFolder = fullfile(obj.dataDir, obj.deviceName, datestr(now(), 'yymmdd'));
            if ~exist(todaysFolder, 'dir')
                % make a folder for today
                mkdir(todaysFolder);
            end
            out = fullfile(todaysFolder, [num2str(obj.fileCount) '_' obj.deviceName '_' expName '.h5']);
            increment(obj);
        end
            
        end
    end