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

ampFidelity = zeros(obj.Loop.one.steps,obj.Loop.two.steps);
phaseFidelity = zeros(obj.Loop.one.steps,obj.Loop.two.steps);

persistent figH;
persistent figH2D;
if isempty(figH) || ~ishandle(figH)
    figH = figure();
end
if isempty(figH2D) || ~ishandle(figH2D)
    figH2D = figure();
end




for loopct1 = 1:obj.Loop.one.steps
    
    obj.Loop.one.sweep.step(loopct1);
    fprintf('Loop 1: Step %d of %d\n', [loopct1, obj.Loop.one.steps]);
    
    for loopct2 = 1:obj.Loop.two.steps
        
        obj.Loop.two.sweep.step(loopct2);
        fprintf('Loop 2: Step %d of %d\n', [loopct2, obj.Loop.two.steps]);
        
        samplesPerAvg = obj.scope.averager.nbrSegments/4;
        nbrSamples = ExpParams.softAvgs*samplesPerAvg;
        ggData = zeros([nbrSamples, 1]);
        geData = zeros([nbrSamples, 1]);
        egData = zeros([nbrSamples, 1]);
        eeData = zeros([nbrSamples, 1]);
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
            
            %Store the data
            ggData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = iavg(1:4:end) + 1i*qavg(1:4:end);
            geData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = iavg(2:4:end) + 1i*qavg(2:4:end);
            egData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = iavg(3:4:end) + 1i*qavg(3:4:end);
            eeData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = iavg(4:4:end) + 1i*qavg(4:4:end);
            
            
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
        %Calculate the centres of the distributions
%         meanGround = mean(ggData);
%         meanExcited = mean(eeData);
%         %Assume they are symmetric and calculate the variance
%         varGround = mean(diag(cov([real(ggData), imag(ggData)])));
%         varExcited = mean(diag(cov([real(eeData), imag(eeData)])));
%         %Calculate the unormalized probabilities of prep|meas assuming
%         %Gaussian distributions
%         ggProb = (1/varGround)*exp(-(1/2/varGround)*(abs(ggData-meanGround).^2));
%         geProb = (1/varExcited)*exp(-(1/2/varExcited)*(abs(ggData-meanExcited).^2));
%         egProb = (1/varGround)*exp(-(1/2/varGround)*(abs(eeData-meanGround).^2));
%         eeProb = (1/varExcited)*exp(-(1/2/varExcited)*(abs(eeData-meanExcited).^2));
%         %Average probability of getting it right
%         meanProb = 0.5*(length(find(ggProb>geProb))/length(ggData) + length(find(eeProb>egProb))/length(ggData));
%         %Fidelity 
%         RBFidelity = 2*meanProb-1;
%         fprintf('Max fidelity with radial basis functions: %.1f\n',100*RBFidelity)

        
        
        
        %Phase to rotate by to get two blobs on either side of I axis
        phaseRot = 0.5*( angle(mean(ggData)) +  angle(mean(eeData)));
        
        ggAmpData = real(exp(-1i*phaseRot)*ggData);
        geAmpData = real(exp(-1i*phaseRot)*geData);
        egAmpData = real(exp(-1i*phaseRot)*egData);
        eeAmpData = real(exp(-1i*phaseRot)*eeData);
        
        ggPhaseData = imag(exp(-1i*phaseRot)*ggData);
        gePhaseData = imag(exp(-1i*phaseRot)*geData);
        egPhaseData = imag(exp(-1i*phaseRot)*egData);
        eePhaseData = imag(exp(-1i*phaseRot)*eeData);
        
        %Setup bins from the minimum to maximum measured voltage
        bins = linspace(min([ggAmpData; geAmpData; egAmpData; eeAmpData]), max([ggAmpData; geAmpData; egAmpData; eeAmpData]));
        
        ggCounts = histc(ggAmpData, bins);
        geCounts = histc(geAmpData, bins);
        egCounts = histc(egAmpData, bins);
        eeCounts = histc(eeAmpData, bins);
        
        countData = {ggCounts, geCounts, egCounts, eeCounts};
        
        colours = {'r','b','g','m'};
        figure(figH)
        subplot(2,1,1)
        cla()
        hold on
        for ct = 1:4
            tmpBars = bar(bins, countData{ct}, 'histc');
            set(tmpBars, 'FaceColor',colours{ct},'EdgeColor','w')
            alpha(tmpBars,0.5)
        end
        legend({'gg','ge','eg','ee'})
        xlabel('Measurement Voltage');
        ylabel('Counts');
        title('I Quad. Histogram');
        
        bins = linspace(min([ggPhaseData; gePhaseData; egPhaseData;  eePhaseData]), max([ggPhaseData; gePhaseData; egPhaseData; eePhaseData]));
        
        ggCounts = histc(ggPhaseData, bins);
        geCounts = histc(gePhaseData, bins);
        egCounts = histc(egPhaseData, bins);
        eeCounts = histc(eePhaseData, bins);

        countData = {ggCounts, geCounts, egCounts, eeCounts};
        
        subplot(2,1,2)
        cla()
        hold on
        for ct = 1:4
            tmpBars = bar(bins, countData{ct}, 'histc');
            set(tmpBars, 'FaceColor',colours{ct},'EdgeColor','w')
            alpha(tmpBars,0.5)
        end
        legend({'gg','ge','eg','ee'})
        xlabel('Measurement Voltage');
        ylabel('Counts');
        title('Q Quad. Histogram');
        
        
%         figure(figH2D)
%         subplot(2,1,1)
%         cla()
%         if obj.Loop.two.steps == 1
%             plot(obj.Loop.one.plotRange, ampFidelity);
%             xlabel(obj.Loop.one.sweep.name);
%         else
%             imagesc(obj.Loop.two.plotRange, obj.Loop.one.plotRange, ampFidelity);
%             xlabel(obj.Loop.two.sweep.name);
%             ylabel(obj.Loop.one.sweep.name);
%             colorbar()
%         end
%         title('Amplitude Measurement Fidelity');
%         subplot(2,1,2)
%         cla()
%         if obj.Loop.two.steps == 1
%             plot(obj.Loop.one.plotRange, phaseFidelity);
%             xlabel(obj.Loop.one.sweep.name);
%         else
%             imagesc(obj.Loop.two.plotRange, obj.Loop.one.plotRange, phaseFidelity);
%             xlabel(obj.Loop.two.sweep.name);
%             ylabel(obj.Loop.one.sweep.name);
%             colorbar()
%         end
%         title('Phase Measurement Fidelity');
        
%         subplot(3,1,3)
%         cla()
%         if obj.Loop.two.steps == 1
%             plot(obj.Loop.one.plotRange, RBFidelity);
%             xlabel(obj.Loop.one.sweep.name);
%         else
%             imagesc(obj.Loop.two.plotRange, obj.Loop.one.plotRange, RBFidelity);
%             xlabel(obj.Loop.two.sweep.name);
%             ylabel(obj.Loop.one.sweep.name);
%             colorbar()
%         end
%         title('RB Measurement Fidelity');
        
    end
end

end
