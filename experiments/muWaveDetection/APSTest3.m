% get scope ready to measure
clear settings
script = java.io.File(mfilename('fullpath'));
cfg_name = [char(script.getParent()) '\unit_test.cfg'];
settings = parseParamFile(cfg_name);

fprintf('Initializing Acqiris card\n');
scope = deviceDrivers.AgilentAP120();
scope.setAll(settings.scope);

fprintf('Initializing TekAWG\n');
TekAWG = deviceDrivers.Tek5014();
TekAWG.connect(settings.TekAWG.Address);
TekAWG.setAll(settings.TekAWG);
TekAWG.stop();

clear settings;

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
settings.seqfile = 'C:\Qlab software\experiments\muWaveDetection\sequences\RabiWidthSquare56.mat';
%settings.seqfile = 'C:\Qlab software\experiments\muWaveDetection\sequences\EchoTest.mat';
settings.seqforce = true;

awg = deviceDrivers.APS();
awg.open(0,1);
if ~awg.is_open
    error('Fail')
end

awg.init();
awg.setAll(settings);
awg.run();

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

awg.stop();
awg.close();
scope.disconnect();
TekAWG.disconnect();
delete(awg); clear awg; delete(scope); clear scope; delete(TekAWG); clear TekAWG