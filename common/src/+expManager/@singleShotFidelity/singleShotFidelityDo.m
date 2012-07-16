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
            masterAWG.operationComplete();
            
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
            groundData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = iavg(1:2:end) + 1i*qavg(1:2:end);
            excitedData(1+(avgct-1)*samplesPerAvg:avgct*samplesPerAvg) = iavg(2:2:end) + 1i*qavg(2:2:end);
            
            
            masterAWG.stop();
            masterAWG.operationComplete();

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
        meanGround = mean(groundData);
        meanExcited = mean(excitedData);
        %Assume they are symmetric and calculate the variance
        varGround = mean(diag(cov([real(groundData), imag(groundData)])));
        varExcited = mean(diag(cov([real(excitedData), imag(excitedData)])));
        %Calculate the unormalized probabilities of prep|meas assuming
        %Gaussian distributions
        ggProb = (1/varGround)*exp(-(1/2/varGround)*(abs(groundData-meanGround).^2));
        geProb = (1/varExcited)*exp(-(1/2/varExcited)*(abs(groundData-meanExcited).^2));
        egProb = (1/varGround)*exp(-(1/2/varGround)*(abs(excitedData-meanGround).^2));
        eeProb = (1/varExcited)*exp(-(1/2/varExcited)*(abs(excitedData-meanExcited).^2));
        %Average probability of getting it right
        %Normalize and average probabilities 
        P00 = length(find(ggProb>geProb))/length(groundData);
        P01 = 1- P00;
        P11 = length(find(eeProb>egProb))/length(groundData);
        P10 = 1-P11;
        fprintf('Confusion matrix: gg = %.3f; ge = %.3f; eg = %.3f; ee = %.3f\n',P00, P01, P10, P11);
        meanProb = 0.5*(length(find(ggProb>geProb))/length(groundData) + length(find(eeProb>egProb))/length(groundData));
        %Fidelity 
        RBFidelity = 2*meanProb-1;
        fprintf('Max fidelity with radial basis functions: %.1f\n',100*RBFidelity)

        
        %Phase to rotate by to get two blobs on either side of I axis
        phaseRot = 0.5*( angle(mean(groundData)) +  angle(mean(excitedData)));
        
        groundAmpData = real(exp(-1i*phaseRot)*groundData);
        excitedAmpData = real(exp(-1i*phaseRot)*excitedData);
        
        groundPhaseData = imag(exp(-1i*phaseRot)*groundData);
        excitedPhaseData = imag(exp(-1i*phaseRot)*excitedData);
        
        %Setup bins from the minimum to maximum measured voltage
        bins = linspace(min([groundAmpData; excitedAmpData]), max([groundAmpData; excitedAmpData]));
        
        groundCounts = histc(groundAmpData, bins);
        excitedCounts = histc(excitedAmpData, bins);
        
        maxAmpFidelity = (1/2/double(nbrSamples))*sum(abs(groundCounts-excitedCounts));
        
        figure(figH)
        subplot(2,1,1)
        cla()
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
        text(0.1, 0.75, sprintf('Fidelity: %.1f%%',100*maxAmpFidelity), 'Units', 'normalized', 'FontSize', 14)
        
        bins = linspace(min([groundPhaseData; excitedPhaseData]), max([groundPhaseData; excitedPhaseData]));
        
        groundCounts = histc(groundPhaseData, bins);
        excitedCounts = histc(excitedPhaseData, bins);
        
        maxPhaseFidelity = (1/2/double(nbrSamples))*sum(abs(groundCounts-excitedCounts));
        
        subplot(2,1,2)
        cla()
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
        text(0.1, 0.75, sprintf('Fidelity: %.1f%%',100*maxPhaseFidelity), 'Units', 'normalized', 'FontSize', 14)
        
        ampFidelity(loopct1, loopct2) = maxAmpFidelity;
        phaseFidelity(loopct1, loopct2) = maxPhaseFidelity;
        
        figure(figH2D)
        subplot(2,1,1)
        cla()
        if obj.Loop.two.steps == 1
            plot(obj.Loop.one.plotRange, ampFidelity);
            xlabel(obj.Loop.one.sweep.name);
        else
            imagesc(obj.Loop.two.plotRange, obj.Loop.one.plotRange, ampFidelity);
            xlabel(obj.Loop.two.sweep.name);
            ylabel(obj.Loop.one.sweep.name);
            colorbar()
        end
        title('Amplitude Measurement Fidelity');
        subplot(2,1,2)
        cla()
        if obj.Loop.two.steps == 1
            plot(obj.Loop.one.plotRange, phaseFidelity);
            xlabel(obj.Loop.one.sweep.name);
        else
            imagesc(obj.Loop.two.plotRange, obj.Loop.one.plotRange, phaseFidelity);
            xlabel(obj.Loop.two.sweep.name);
            ylabel(obj.Loop.one.sweep.name);
            colorbar()
        end
        title('Phase Measurement Fidelity');
        
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
