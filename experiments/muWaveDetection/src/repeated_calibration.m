%% Run repeated calibrations 

pi2Amps = [];
piAmps = [];
dragScalings = [];
ampFactors = [];
phaseSkews = [];
timeStamps = [];
offsets_I = [];
offsets_Q = [];  

qubit = 'q2';
channelMap = jsonlab.loadjson(getpref('qlab', 'Qubit2ChannelMap'));
IQKey = channelMap.(qubit).IQkey;
%C = strsplit(IQKey, '_'); %only 2013
AWGName = IQKey(1:strfind(IQKey, '_')-1);
IChan = IQKey(strfind(IQKey, '_')+1);
QChan = IQKey(strfind(IQKey, '_')+2);

while true
    %Run the calibration on q2
    calibratePulses(qubit);

    timeStamps(end+1) = now;

    %Load the params from the files
    params = json.read(getpref('qlab', 'pulseParamsBundleFile'));

    pi2Amps(end+1) = params.(qubit).pi2Amp;
    piAmps(end+1) = params.(qubit).piAmp;
    dragScalings(end+1) = params.(qubit).delta;
    ampFactors(end+1) = params.(IQKey).T(1,1);
    phaseSkews(end+1) = asecd(params.(IQKey).T(2,2));

    params = json.read(getpref('qlab', 'CurScripterFile'));
    offsets_I(end+1) = params.instruments.(AWGName).(['chan_' IChan]).offset;
    offsets_Q(end+1) = params.instruments.(AWGName).(['chan_' QChan]).offset;
    
    save('CalibrationRecords.mat', 'pi2Amps', 'piAmps', 'dragScalings', 'ampFactors', 'phaseSkews', 'timeStamps', 'offsets_I', 'offsets_Q');

    close all;

end

%% Plotting
dateStrs = arrayfun(@(x) datestr(x), timeStamps, 'UniformOutput', false);

%Plot the calibration amps together
figure()
subplot(2,1,1);
tseries = timeseries(pi2Amps, dateStrs);
tseries.TimeInfo.Format = 'HH:MM';
tseries.Name = 'Pi2Amp';
plot(tseries);
curXTicks = get(gca(), 'XTick');
curXTickLabels = get(gca(), 'XTickLabel');
set(gca(), 'XTick', curXTicks(2:2:end));
set(gca(), 'XTickLabel', curXTickLabels(2:2:end,:));

subplot(2,1,2);
tseries = timeseries(piAmps, dateStrs);
tseries.TimeInfo.Format = 'HH:MM';
tseries.Name = 'PiAmp';
plot(tseries);
set(gca(), 'XTick', curXTicks(2:2:end));
set(gca(), 'XTickLabel', curXTickLabels(2:2:end,:));

%Plot drag scalings; ampFactor and phase skew together
figure()
subplot(3,1,1);
tseries = timeseries(dragScalings, dateStrs);
tseries.TimeInfo.Format = 'HH:MM';
tseries.Name = 'Drag Scaling';
plot(tseries);
set(gca(), 'XTick', curXTicks(2:2:end));
set(gca(), 'XTickLabel', curXTickLabels(2:2:end,:));

subplot(3,1,2);
tseries = timeseries(ampFactors, dateStrs);
tseries.TimeInfo.Format = 'HH:MM';
tseries.Name = 'Amp. Factor';
plot(tseries);
set(gca(), 'XTick', curXTicks(2:2:end));
set(gca(), 'XTickLabel', curXTickLabels(2:2:end,:));

subplot(3,1,3);
tseries = timeseries(phaseSkews, dateStrs);
tseries.TimeInfo.Format = 'HH:MM';
tseries.Name = 'Phase Skew';
plot(tseries);
set(gca(), 'XTick', curXTicks(2:2:end));
set(gca(), 'XTickLabel', curXTickLabels(2:2:end,:));

%Plot the two offsets together
figure()
subplot(2,1,1);
tseries = timeseries(offsets_I, dateStrs);
tseries.TimeInfo.Format = 'HH:MM';
tseries.Name = 'I Offset';
plot(tseries);
set(gca(), 'XTick', curXTicks(2:2:end));
set(gca(), 'XTickLabel', curXTickLabels(2:2:end,:));

subplot(2,1,2);
tseries = timeseries(offsets_Q, dateStrs);
tseries.TimeInfo.Format = 'HH:MM';
tseries.Name = 'Q Offset';
plot(tseries);
set(gca(), 'XTick', curXTicks(2:2:end));
set(gca(), 'XTickLabel', curXTickLabels(2:2:end,:));
