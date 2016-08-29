function ExpScripter2(expName, varargin)
%ExpScripter with optional inputs:
%expSettings: structure as loaded from DefaultExpSetting.json. Overwritten
%if passed as input
tic;
exp = ExpManager();

deviceName = 'IBMv11_2037W3';
exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, expName));
expSettings = json.read(getpref('qlab', 'CurScripterFile'));

singleShot = 0;
numShots = 1;
metaInfo = [];

%handle optional arguments
for n = 2:nargin
    if isstruct(varargin{n-1})
        expSettings = varargin{n-1};
    elseif ischar(varargin{n-1})
        if strcmp(varargin{n-1}, 'singleShot') %set round robins in all cards to 1
            singleShot=1;
        else
            metaFile = varargin{n-1};
            if ~exist(metaFile, 'file')
                metaFile = fullfile(getpref('qlab', 'awgDir'), [metaFile '-meta.json']);
            end
            if ~exist(metaFile, 'file')
                error('Could not find experiment meta file');
            end
            % load info from meta file
            metaInfo = json.read(metaFile);
        end
    elseif isnumeric(varargin{n-1})
        % numeric arguments are number of shots
        numShots = varargin{n-1};
    end
end

%Save all the settings in the hdf5 file
exp.dataFileHeader = expSettings;
exp.saveVariances = true;
exp.CWMode = expSettings.CWMode;
instrSettings = expSettings.instruments;
sweepSettings = expSettings.sweeps;
measSettings = expSettings.measurements;
if isfield(expSettings, 'saveAllSettings')
    exp.saveAllSettings = expSettings.saveAllSettings;
end
if isfield(expSettings, 'saveData')
    exp.saveData = expSettings.saveData;
end

for instrument = fieldnames(instrSettings)'
    fprintf('Connecting to %s\n', instrument{1});
    instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
    if ExpManager.is_AWG(instr) && ~isempty(metaInfo)
        if ~isfield(metaInfo.instruments, instrument{1})
            continue;
        end
        fprintf('Enabling %s\n', instrument{1});
        instrSettings.(instrument{1}).seqFile = metaInfo.instruments.(instrument{1});
    end

    if ExpManager.is_scope(instr)
        if singleShot==1
            instrSettings.(instrument{1}).averager.nbrRoundRobins = 1;
        end
        if ~isempty(metaInfo)
            instrSettings.(instrument{1}).averager.nbrSegments = numShots * metaInfo.num_measurements;
        end
    end
    add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
end

if ~isempty(metaInfo)
    if isfield(sweepSettings, 'SegmentNum')
        sweepSettings.SegmentNum.points = metaInfo.axis_descriptor(1).points;
        sweepSettings.SegmentNum.axisLabel = [metaInfo.axis_descriptor(1).name ' (' metaInfo.axis_descriptor(1).unit ')'];
    elseif isfield(sweepSettings, 'SegmentNumWithCals')
        points =  metaInfo.axis_descriptor(1).points;
        num_cals = length(metaInfo.axis_descriptor(2).points);
        % tack on calibration points assuming linear step
        step = (points(end) - points(1)) / max([1, (length(points) - 1)]);
        points = [points, points(end) + (1:num_cals)*step];
        sweepSettings.SegmentNumWithCals.points = points;
        sweepSettings.SegmentNumWithCals.axisLabel = [metaInfo.axis_descriptor(1).name ' (' metaInfo.axis_descriptor(1).unit ')'];
    end
end

for sweep = fieldnames(sweepSettings)'
    add_sweep(exp, sweepSettings.(sweep{1}).order, SweepFactory(sweepSettings.(sweep{1}), exp.instruments));
end

correlators = {};
measFilters = struct();
measNames = fieldnames(measSettings);
for meas = measNames'
    measName = meas{1};
    params = measSettings.(measName);
    if strcmp(params.filterType,'Correlator')
        %If it is a correlator than hold it back
        correlators{end+1} = measName;
    else
        %Otherwise load it and keep a reference to it
        measFilters.(measName) = MeasFilters.(params.filterType)(measName, params);
        add_measurement(exp, measName, measFilters.(measName));
    end
end

%Loop back and apply any correlators
for meas = correlators
    measName = meas{1};
    childFilters = cellfun(@(x) measFilters.(x), measSettings.(measName).filters, 'UniformOutput', false);
    add_measurement(exp, measName, MeasFilters.Correlator(measName, measSettings.(measName), childFilters{:}));
end

exp.init();
exp.run();

if exp.saveAllSettings && exp.saveData
    %saves a specific ExpSettings file, without overwriting the
    %DefaultExpSettings (already saved by ExpManager)
    fileName = exp.dataFileHandler.fileName;
    [pathname,basename,~] = fileparts(fileName);
    json.write(expSettings, fullfile(pathname,strcat(basename,'_cfg'),'ExpSettings.json'), 'indent', 2);
end

toc;
end
