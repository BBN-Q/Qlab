%%
fprintf('Initializing APS\n');
settings = struct();
settings.chan_1.enabled = false;
settings.chan_1.amplitude = 1.0;
settings.chan_1.offset = 0;
settings.chan_2.enabled = false;
settings.chan_2.amplitude = 1.0;
settings.chan_2.offset = 0;
settings.chan_3.enabled = false;
settings.chan_3.amplitude = 1.0;
settings.chan_3.offset = 0;
settings.chan_4.enabled = false;
settings.chan_4.amplitude = 1.0;
settings.chan_4.offset = 0;
settings.samplingRate = 1200;
settings.triggerSource = 'internal';
settings.seqfile = 'U:\APS\Echo\EchoBBNAPS12.mat';
settings.seqforce = true;

awg = deviceDrivers.APS();
awg.open(0,1);
if ~awg.is_open
    error('Fail')
end
awg.stop();
forceLoadBitFile = 0;
awg.init(forceLoadBitFile);
awg.setAll(settings);
%awg.setLinkListMode(2, awg.LL_ENABLE, awg.LL_ONESHOT);
%awg.chan_3.enabled = true;
awg.run();

keyboard
awg.stop();
awg.close();
delete(awg); clear awg