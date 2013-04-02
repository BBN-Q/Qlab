%%
fprintf('Initializing APS\n');
settings = struct();
settings.chan_1.enabled = true;
settings.chan_1.amplitude = 1.0;
settings.chan_1.offset = 0;
settings.chan_2.enabled = true;
settings.chan_2.amplitude = 1.0;
settings.chan_2.offset = 0;
settings.chan_3.enabled = true;
settings.chan_3.amplitude = 1.0;
settings.chan_3.offset = 0;
settings.chan_4.enabled = true;
settings.chan_4.amplitude = 1.0;
settings.chan_4.offset = 0;
settings.samplingRate = 1200;
settings.triggerSource = 'external';
%settings.triggerSource = 'internal';
settings.seqfile = 'U:\AWG\Ramsey\Ramsey-BBNAPS.h5';
% settings.seqfile = 'U:\APS\Ramsey\RamseyBBNAPS34.h5';
settings.seqforce = true;

awg = deviceDrivers.APS();
awg.connect(0);

awg.stop();
forceLoadBitFile = 0;
awg.init(forceLoadBitFile);
awg.setAll(settings);
awg.run();

keyboard
awg.stop();
awg.disconnect();
delete(awg); clear awg