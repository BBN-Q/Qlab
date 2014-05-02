function switch_marker_state(awgName, ch)
%Little helper function to put out a single marker blip to switch the state
%of the flip-flops

if ischar(awgName)                                               
  awg = InstrumentFactory(awgName);
else
  awg = awgName;
end

switch class(awg)

	case 'deviceDrivers.Tek5014'
        
        fakeSeq.ch1 = zeros(1, 1000);
        fakeSeq.ch2 = zeros(1, 1000);
        fakeSeq.ch3 = zeros(1, 1000);
        fakeSeq.ch4 = zeros(1, 1000);
        fakeSeq.ch1m1 = zeros(1, 1000);
        fakeSeq.ch1m2 = zeros(1, 1000);
        fakeSeq.ch2m1 = zeros(1, 1000);
        fakeSeq.ch2m2 = zeros(1, 1000);
        fakeSeq.ch3m1 = zeros(1, 1000);
        fakeSeq.ch3m2 = zeros(1, 1000);
        fakeSeq.ch4m1 = zeros(1, 1000);
        fakeSeq.ch4m2 = zeros(1, 1000);
        
        fakeSeq.(ch) = [zeros(1,100), ones(1,100), zeros(1,800)];
        
        TekPattern.exportTekSequence(tempdir, 'SwitchMarkerSeq', fakeSeq);
        networkDriveName =  fullfile(getpref('qlab', 'awgDir'), 'SwitchMarkerSeq.awg');
        movefile(fullfile(tempdir, 'SwitchMarkerSeq.awg'), networkDriveName);
        awg.openConfig(networkDriveName);
        awg.operationComplete();
        awg.runMode = 'triggered';
        awg.triggerSource = 'internal';
        
        %Figure out the channel
        chNum = sscanf(ch, 'ch%dm');
        awg.write(sprintf('OUTP%d ON', chNum));
        
        %Get things going
        awg.run();
        awg.operationComplete();
       
        %Send a single force trigger
        awg.write('*TRG');
        
        
        awg.stop();
	case 'deviceDrivers.APS'                    
   
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


		awg.init();
		for ct = 1:4, awg.setEnabled(ct,1); end
		awg.setRunMode(1, awg.RUN_SEQUENCE); awg.setRunMode(3, awg.RUN_SEQUENCE);
		awg.triggerSource = 'int';
		awg.triggerInterval = 0.1;
		awg.loadConfig(fullfile(tempdir, 'SwitchMarker.h5'));
		awg.run();
        pause(0.09);
		awg.stop();

end

end

