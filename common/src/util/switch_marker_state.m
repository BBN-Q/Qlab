function switch_marker_state(apsStr, ch)
%Little helper function to put out a single marker blip to switch the state
%of the flip-flops

pg = PatternGen('linkListMode', true);
patSeq = {pg.pulse('QId')};

IQ_seqs12 = pg.build(patSeq, 1, 0, 1000, false);
IQ_seqs34 = pg.build(patSeq, 1, 0, 1000, false);

switch ch
    case {1,2}
        IQ_seqs12 = pg.addTrigger(IQ_seqs12, 4, 0, 2-mod(ch,2));
    case {3,4}
        IQ_seqs34 = pg.addTrigger(IQ_seqs34, 4, 0, 2-mod(ch,2));
end
        
APSPattern.exportAPSConfig(tempdir, 'SwitchMarker', 1,...
                            struct('waveforms', pg.pulseCollection, 'linkLists', {IQ_seqs12}),...
                            struct('waveforms', pg.pulseCollection, 'linkLists', {IQ_seqs34}));
                        
aps = deviceDrivers.APS();
aps.connect(apsStr);
aps.init();
for ct = 1:4, aps.setEnabled(ct,1); end
aps.setRunMode(1, aps.RUN_SEQUENCE); aps.setRunMode(3, aps.RUN_SEQUENCE);
aps.triggerSource = 'int';
aps.triggerInterval = 0.1;
aps.loadConfig(fullfile(tempdir, 'SwitchMarker.h5'));
aps.run();
pause(0.15);
aps.stop();


