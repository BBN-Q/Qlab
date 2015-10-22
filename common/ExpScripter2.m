function ExpScripter2(expName, varargin)
%ExpScripter with optional inputs:
%expSettings: structure as loaded from DefaultExpSetting.json. Overwritten
%if passed as input
%lockSegments: string to set the number of segments on all cards equal to
%the number of steps in the sequence
tic;
exp = ExpManager();

deviceName = 'IBMv11_2037W3';
exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, expName));
expSettings = json.read(getpref('qlab', 'CurScripterFile'));

lockSegments=0; 
singleShot=0;

%handle optional arguments
for n = 2:nargin
    if isstruct(varargin{n-1})
        expSettings = varargin{n-1};
    elseif ischar(varargin{n-1})
        if strcmp(varargin{n-1}, 'lockSegments')
            lockSegments=1;
        elseif strcmp(varargin{n-1}, 'singleShot')
            singleShot=1;
        end
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
else
    exp.saveAllSettings = true;
end
if isfield(expSettings, 'saveData')
    exp.saveData = expSettings.saveData;
else
    exp.saveData = true;
end
sweep = fieldnames(sweepSettings)';

for instrument = fieldnames(instrSettings)'
        fprintf('Connecting to %s\n', instrument{1});
        instr = InstrumentFactory(instrument{1}, instrSettings.(instrument{1}));
        if ExpManager.is_AWG(instr)
            if isfield(expSettings, 'AWGs') && sum(strcmp(instrument{1}, expSettings.AWGs))==0
                %if a list of AWGs is specified, disregard the remaining ones 
                expSettings.instruments = rmfield(expSettings.instruments, instrument{1});
                continue
            end
            fprintf('Enabling %s\n', instrument{1});
            if isa(instr, 'deviceDrivers.APS') || isa(instr, 'APS2') || isa(instr, 'APS')
                ext = 'h5';
            else
                ext = 'awg';
            end
            if isfield(expSettings, 'AWGfilename')
                %if a sequence name is specified, load this sequence in all
                %AWGs
                instrSettings.(instrument{1}).seqFile = fullfile(getpref('qlab', 'awgDir'), expSettings.AWGfilename, [expSettings.AWGfilename '-' instrument{1} '.' ext]);
            end
        end
        add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
        
        if ExpManager.is_scope(instr) && nargin>1 
            if lockSegments==1
                if isfield(sweepSettings, 'SegmentNum')
                    exp.instrSettings.(instrument{1}).averager.nbrSegments =  sweepSettings.SegmentNum.numPoints;
                elseif isfield(sweepSettings, 'SegmentNumWithCals')
                    exp.instrSettings.(instrument{1}).averager.nbrSegments =  sweepSettings.SegmentNumWithCals.numPoints;
                else
                    warning('Sweeps do not include segments')
                end
            end
            if singleShot==1
                exp.instrSettings.(instrument{1}).averager.nbrRoundRobins = 1;
            end
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

if exp.saveAllSettings
    %saves a specific ExpSettings file, without overwriting the
    %DefaultExpSettings (already saved by ExpManager)
    fileName = exp.dataFileHandler.fileName;
    [pathname,basename,~] = fileparts(fileName);
    json.write(expSettings, fullfile(pathname,strcat(basename,'_cfg'),'ExpSettings.json'), 'indent', 2);  
end

toc;
end