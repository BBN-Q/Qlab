function APSTest3

% get scope ready to measure
instrSettings = jsonlab.loadjson(fullfile(getpref('qlab', 'cfgDir'), 'scripter.json'));

fprintf('Initializing Acqiris card\n');
scope = InstrumentFactory('scope');
scope.setAll(instrSettings.scope);

fprintf('Initializing TekAWG\n');
TekAWG = InstrumentFactory('TekAWG')
TekAWG.setAll(instrSettings.TekAWG);
TekAWG.stop();

% initialize APS
fprintf('Initializing APS\n');
settings = struct();
settings.chan_1.enabled = true;
settings.chan_1.amplitude = 1.0;
settings.chan_1.offset = 0;
settings.chan_2.enabled = true;
settings.chan_2.amplitude = 1.0;
settings.chan_2.offset = 0;
settings.chan_3.enabled = false;
settings.chan_3.amplitude = 1.0;
settings.chan_3.offset = 0;
settings.chan_4.enabled = false;
settings.chan_4.amplitude = 1.0;
settings.chan_4.offset = 0;
settings.samplingRate = 1200;
settings.triggerSource = 'external';
settings.seqfile = fullfile(getpref('qlab', 'awgDir'), 'RabiWidth', 'RabiWidth-BBNAPS.h5');
%settings.seqfile = 'C:\Qlab software\experiments\muWaveDetection\sequences\EchoTest.mat';
settings.seqforce = true;

aps = deviceDrivers.APS();
aps.connect(0);
aps.init();
aps.setAll(settings);
aps.run();

% acquire data
scope.acquire();
fprintf('Acquiring\n');
TekAWG.run();
pause(0.5);
success = scope.wait_for_acquisition(10);
if success ~= 0
    error('failed to acquire waveform')
end

% download data and display it
[Amp_I timesI] = scope.transfer_waveform(1);
[Amp_Q timesQ] = scope.transfer_waveform(2);
figure(1);
%foo = subplot(2,1,1);
imagesc(Amp_I');
xlabel('Time');
ylabel('Segment');
set(gca, 'YDir', 'normal');
title('Ch 1 (I)');

figure(2);
imagesc(Amp_Q');
xlabel('Time');
ylabel('Segment');
set(gca, 'YDir', 'normal');
title('Ch 2 (Q)');

aps.stop();
aps.disconnect();
scope.disconnect();
TekAWG.stop();
TekAWG.disconnect();