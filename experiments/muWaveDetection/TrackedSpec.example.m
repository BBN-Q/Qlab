 % timeDomain
function TrackedSpec(expName)

import MeasFilters.*

exp = ExpManager();

deviceName = 'Syracuse_Sideband_b';
exp.dataFileHandler = HDF5DataHandler(DataNamer.get_data_filename(deviceName, expName));

expSettings = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'tracked_spec.json'));
exp.dataFileHeader = expSettings;

exp.CWMode = true;
instrSettings = expSettings.instruments;
sweepSettings = expSettings.sweeps;
measSettings = expSettings.measurements;

for instrument = fieldnames(instrSettings)'
    instr = InstrumentFactory(instrument{1});
    add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
end

cavitySweepSettings = struct(...
    'genID', 'Source5',...
    'start', 8.048,...
    'stop', 8.055,...
    'step', 0.0001,...
    'offset', -0.0008);

add_sweep(exp, 1, SweepFactory(sweepSettings.DC, exp.instruments), rebias_cavity_callback(cavitySweepSettings));
add_sweep(exp, 2, SweepFactory(sweepSettings.Frequency, exp.instruments));

%Loop over the measurments: insert the single channel measurements, keep
%back the correlators and then apply them
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
        measFilters.(measName) = MeasFilters.(params.filterType)(params);
        add_measurement(exp, measName, measFilters.(measName));
    end
end

%Loop back and apply any correlators
for meas = correlators
    measName = meas{1};
    childFilters = cellfun(@(x) measFilters.(x), measSettings.(measName).filters, 'UniformOutput', false);
    add_measurement(exp, measName, MeasFilters.Correlator(childFilters{:}));
end

exp.init();
exp.run();

end

function fcn = rebias_cavity_callback(settings)
    freqPts = settings.start:settings.step:settings.stop;
    genID = settings.genID;
    offset = settings.offset;
    
    persistent ampHandle phaseHandle
    
    if isempty(ampHandle) || isempty(phaseHandle)
        fh = figure('WindowStyle', 'docked', 'HandleVisibility', 'callback', 'NumberTitle', 'off', 'Name', 'Cavity');
        ampHandle = subplot(2,1,1, 'Parent', fh);
        phaseHandle = subplot(2,1,2,'Parent', fh);
    end
    
    function rebias_cavity(exp)
        data = nan(1, length(freqPts));
        for ct = 1:length(freqPts)
            exp.instruments.(genID).frequency = freqPts(ct);
            exp.take_data();
            data(ct) = exp.measurements.M1.get_data();
            plot(ampHandle, freqPts(1:ct), abs(data(1:ct)));
            ylabel('Amp');
            plot(phaseHandle, freqPts(1:ct), (180/pi)*angle(data(1:ct)));
            ylabel('Phase');
        end
        % find cavity peak
        peak_freq = freqPts( find(abs(data) == max(abs(data)), 1) );
        fprintf('Found cavity frequency: %f GHz\n', peak_freq);
        exp.instruments.(genID).frequency = peak_freq + offset;
    end

    fcn = @rebias_cavity;
end
