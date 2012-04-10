function singleShotFidelityDo(obj)

ExpParams = obj.inputStructure.ExpParams;

%% If there's anything thats particular to any device do it here

% stop the master and make sure it stopped
masterAWG = obj.awg{1};
masterAWG.stop();
masterAWG.operationComplete();
% start all the slave AWGs
for i = 2:length(obj.awg)
    awg = obj.awg{i};
    awg.run();
    [success_flag_AWG] = awg.waitForAWGtoStartRunning();
    if success_flag_AWG ~= 1, error('AWG %d timed out', i), end
end

%%

samplesPerAvg = obj.scope.averager.nbrSegments/2;
nbrSamples = ExpParams.softAvgs*samplesPerAvg;
groundData = zeros([nbrSamples, 1]);
excitedData = zeros([nbrSamples, 1]);
for avgct = 1:ExpParams.softAvgs
    fprintf('Soft average %d\n', avgct);
    
    % set the card to acquire
    obj.scope.acquire();
    
    % set the Tek to run
    masterAWG.run();
    pause(0.5);
    
    %Poll the digitizer until it has all the data
    success = obj.scope.wait_for_acquisition(60);
    if success ~= 0
        error('Failed to acquire waveform.')
    end
    
    % Then we retrive our data
    Amp_I = obj.scope.transfer_waveform(1);
%     Amp_Q = obj.scope.transfer_waveform(2);
%     assert(numel(Amp_I) == numel(Amp_Q), 'I and Q outputs have different lengths.')
    
    % signal processing and analysis
    [iavg qavg] = obj.digitalHomodyne(Amp_I, ...
                ExpParams.digitalHomodyne.IFfreq*1e6, ...
                obj.scope.horizontal.sampleInterval, ExpParams.filter.start, ExpParams.filter.length);
    
    % convert I/Q to Amp/Phase
    amp = sqrt(iavg.^2 + qavg.^2);
%     phase = (180.0/pi) * atan2(qavg, iavg);
    
    %Store the data
    groundData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = amp(1:2:end);
    excitedData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = amp(2:2:end);
    

    masterAWG.stop();
    % restart the slave AWGs so we can resync
    for i = 2:length(obj.awg)
        awg = obj.awg{i};
        awg.stop();
        awg.run();
    end
    pause(0.2);
end

%Analyse the data
%Setup bins from the minimum to maximum measured voltage
bins = linspace(min([groundData; excitedData]), max([groundData; excitedData]));

groundCounts = histc(groundData, bins);
excitedCounts = histc(excitedData, bins);

maxFidelity = (1/2/double(nbrSamples))*sum(abs(groundCounts-excitedCounts));

figure()
groundBars = bar(bins, groundCounts, 'histc');
set(groundBars, 'FaceColor','r','EdgeColor','w')
alpha(groundBars,0.5)
hold on
excitedBars = bar(bins, excitedCounts, 'histc');
set(excitedBars, 'FaceColor','b','EdgeColor','w')
alpha(excitedBars,0.5)

legend({'ground','excited'})
xlabel('Measurement Voltage');
ylabel('Counts');

fprintf('Best single shot fidelity of %f\n', maxFidelity);


end
