function LinkListFormatUnitTest(sequence, useEndPadding)

% APS Enhanced Link List Unit Test
%
% Gets Pattern Generator and produces link lists from pattern generator
% And ELL link lists and plots for comparision
% May be Called Using Some Varient of deviceDrivers.APS.LinkListFormatUnitTest

% Test Status
% Last Tested: 4/19/2011
%
% Sequence 1: Echo: Passed 5/4/11
% Sequence 2: Rabi Amp: Passed 5/4/11
% Sequence 3: Ramsey: Passed 5/4/11
% Sequency 4: URamseySequence Failed: Passed 5/4/11

% Uses PatternGen Link List Generator to develop link lists

%addpath('../../common/src/','-END');
%addpath('../../common/src/util/','-END');

d = deviceDrivers.APS();
d.dbgForceELLMode();
d.verbose = 1;

if ~exist('sequence', 'var') || isempty(sequence)
    sequence = 1;
end


if ~exist('useEndPadding', 'var') || isempty(useEndPadding)
    useEndPadding = 1;
end

sequences = deviceDrivers.APS.LinkListSequences(sequence);


    function plotPatterns(patternGenX, patLinkListX, devLinkListX, ...
            patternGenY, patLinkListY, devLinkListY,...
            patternGenMarker, patLinkListMarker, devLinkListMarker)
        
        fh = figure(1);
        set(fh,'Name','Pattern Generation / Link List Comparision');
        
        for i = 1:sequence.numsteps
            
            clf
            
            %%%%%%%%%% X Channel %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,1)
            plot(patternGenX(i,:),'r'); title('PG X')
            ylim([0 2^14])
            
            subplot(5,3,4)
            plot(patLinkListX(i,:),'g'); title('PGLL X')
            ylim([0 2^14])
            
            subplot(5,3,7)
            error1 = patternGenX(i,:) - patLinkListX(i,:);
            error1 = error1 ./ patternGenX(i,:);
            plot(error1, 'g'); title('PGLL X Percent Error')
            ylim([-1 1])
            
            subplot(5,3,10)
            plot(devLinkListX(i,:),'b'); title('APSLL X')
            ylim([0 2^14])
            
            subplot(5,3,13)
            error2 = patternGenX(i,:) - devLinkListX(i,:);
            error2 = error2./ patternGenX(i,:);
            plot(error2 , 'b'); title('APSLL X Percent Error')
            ylim([-1 1])
            
            hold on
            error3 = patLinkListX(i,:) - devLinkListX(i,:);
            error3 = error3./ patternGenX(i,:);
            plot(error3 , 'r'); title('APSLL X Percent Error')
            ylim([-1 1])
            
            if (max(abs(error1)) > .1 || max(abs(error2)) > .1)
                %drawnow
                %keyboard
            end
            
            %%%%%%%%%% Y Channel %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,2)
            plot(patternGenY(i,:),'r'); title('PG Y')
            ylim([0 2^14])
            
            subplot(5,3,5)
            plot(patLinkListY(i,:),'g'); title('PGLL Y')
            ylim([0 2^14])
            
            subplot(5,3,8)
            error1 = patternGenY(i,:) - patLinkListY(i,:);
            plot(error1 ./ patternGenY(i,:), 'g'); title('PGLL Y Percent Error')
            ylim([-1 1])
            
            subplot(5,3,11)
            plot(devLinkListY(i,:),'b'); title('APSLL Y')
            ylim([0 2^14])
            
            subplot(5,3,14)
            error2 = patternGenY(i,:) - devLinkListY(i,:);
            plot(error2 ./ patternGenY(i,:), 'b'); title('APSLL Y Percent Error')
            ylim([-1 1])
            
            %%%%%%%%%% Marker %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,3)
            plot(patternGenMarker(i,:),'r'); title('PG M')
            
            subplot(5,3,6)
            plot(patLinkListMarker(i,:),'g'); title('PGLL M')
            
            subplot(5,3,9)
            error1 = patternGenMarker(i,:) - patLinkListMarker(i,:);
            plot(error1 ./ patternGenMarker(i,:), 'g'); title('PGLL M Percent Error')
            ylim([-1 1])
            
            subplot(5,3,12)
            plot(devLinkListMarker(i,:),'b'); title('APSLL M')
            
            subplot(5,3,15)
            error2 = patternGenMarker(i,:) - devLinkListMarker(i,:);
            plot(error2 ./ patternGenMarker(i,:), 'b'); title('APSLL M Percent Error')
            ylim([-1 1])
            drawnow()
            pause(.2);
            %keyboard
            %{
            figure(3);
            clf
            plot(patLinkListX(i,:),'g');
            hold on
            plot(devLinkListX(i,:),'b');
            
            keyboard
            %}
        end
    end

useVarients = 1;

numSequences = length(sequences);

% unify sequce waveform libraries
%[unifiedX unifiedY] = APSPattern.unifySequenceLibraryWaveforms(sequences);

%unifiedX = APSPattern.buildWaveformLibrary(unifiedX, useVarients);
%unifiedY = APSPattern.buildWaveformLibrary(unifiedY, useVarients);

%{
figure(2);
plot(unifiedX.waveforms)
%}


for seq = 1:numSequences
    sequence = sequences{seq};
    patternGenX = zeros(sequence.numsteps, sequence.cycleLength);
    patLinkListX = patternGenX;
    devLinkListX = patternGenX;
    
    patternGenY = patternGenX;
    patLinkListY = patternGenX;
    devLinkListY = patternGenX;
    
    patternGenMarker = patternGenX;
    patLinkListMarker = patternGenX;
    devLinkListMarker = patternGenX;
    
    
    d.verbose = 0;
    miniLinkRepeat = 0;
    [xWfLib, yWfLib] = APSPattern.buildWaveformLibrary(sequence.llpatxy, useVarients);
    [wf, xbanks] = APSPattern.convertLinkListFormat(sequence.llpatxy, useVarients, xWfLib, miniLinkRepeat);
    patternX = APSPattern.linkListToPattern(wf, xbanks);
    
    [wf, ybanks] = APSPattern.convertLinkListFormat(sequence.llpatxy, useVarients, yWfLib, miniLinkRepeat);
    patternY = APSPattern.linkListToPattern(wf, ybanks);
    
    for n = 1:sequence.numsteps;
        
        [patx paty] = sequence.pg.getPatternSeq(sequence.patseq, n, sequence.delay, sequence.fixedPt);
        patternGenX(n, :) = patx + sequence.offset;
        patternGenY(n, :) = paty + sequence.offset;
        
        [patx paty] = sequence.pg.linkListToPattern(sequence.llpatxy,n);
        patLinkListX(n, :) = patx + sequence.offset;
        patLinkListY(n, :) = paty + sequence.offset;
        
        st = fix((n-1)*sequence.cycleLength+1);
        en = fix(n*sequence.cycleLength);
        devLinkListX(n, :) = patternX(st:en) + sequence.offset;
        devLinkListY(n, :) = patternY(st:en) + sequence.offset;
        
        % force paty to 0
        pattenGenMarker(n, :) = sequence.pg.bufferPulse(patx, 0, sequence.offset,sequence.bufferPadding, sequence.bufferReset, sequence.bufferDelay);
    end
    
    %{

Not currently working on triggers

% trigger at beginning of measurement pulse
% measure from (6000:8000)
measLength = 2000;
measSeq = {pg.pulse('M', 'width', measLength)};
ch1m1 = zeros(numsteps, cycleLength);
ch1m2 = zeros(numsteps, cycleLength);
for n = 1:numsteps;
	ch1m1(n,:) = pg.makePattern([], fixedPt-500, ones(100,1), cycleLength);
	ch1m2(n,:) = pg.getPatternSeq(measSeq, n, measDelay, fixedPt+measLength);
end
    %}
    
    figure(1);
    plotPatterns(patternGenX, patLinkListX, devLinkListX, ...
        patternGenY, patLinkListY, devLinkListY,...
        patternGenMarker, patLinkListMarker, devLinkListMarker)
end
end

