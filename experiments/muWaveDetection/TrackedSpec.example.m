 % timeDomain
function TrackedSpec(expName)

import MeasFilters.*

exp = ExpManager();

global dataNamer
deviceName = 'SUCR';
if ~isa(dataNamer, 'DataNamer')
    dataNamer = DataNamer(getpref('qlab', 'dataDir'), deviceName);
end
if ~strcmp(dataNamer.deviceName, deviceName)
    dataNamer.deviceName = deviceName;
    reset(dataNamer);
end
exp.dataFileHandler = HDF5DataHandler(dataNamer.get_name(expName));

expSettings = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'tracked_spec.json'));
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

dh1 = DigitalHomodyne(measSettings.M1);
add_measurement(exp, 'M1', dh1);

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