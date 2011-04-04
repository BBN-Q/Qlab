function LinkListFormatUnitTest(sequence)

%% APS Enhanced Link List Unit Test
%%
%% Gets Pattern Generator and produces link lists from pattern generator
%% And ELL link lists and plots for comparision
%% May be Called Using Some Varient of deviceDrivers.APS.LinkListFormatUnitTest

%% Test Status
%% Last Tested: 2/2/2011
%% $Rev$
%%
%% Sequence 1: Echo: Passed
%% Sequence 2: Rabi Amp: Passed
%% Sequence 3: Ramsey: Passed
%% Sequency 4: URamseySequence Failed:Both PatternGen LL and DacLL show errors

% Uses PatternGen Link List Generator to develop link lists

addpath('../../common/src/','-END');
addpath('../../common/src/util/','-END');

d = deviceDrivers.APS();
d.dbgForceELLMode();
d.verbose = 0;

if ~exist('sequence', 'var') || isempty(sequence)
 sequence = 1;
end

sequence = deviceDrivers.APS.LinkListSequences(sequence);

%% Allocate memory
patternGenX = zeros(sequence.numsteps, sequence.cycleLength);
patLinkListX = patternGenX;
devLinkListX = patternGenX;

patternGenY = patternGenX;
patLinkListY = patternGenX;
devLinkListY = patternGenX;

patternGenMarker = patternGenX;
patLinkListMarker = patternGenX;
devLinkListMarker = patternGenX;

useVarients = 1;


[wf, banks] = d.convertLinkListFormat(sequence.llpatx,useVarients);
patternX = d.linkListToPattern(wf, banks);

[wf, banks] = d.convertLinkListFormat(sequence.llpaty,useVarients);
patternY = d.linkListToPattern(wf, banks);

for n = 1:sequence.numsteps;
    [patx paty] = sequence.pg.getPatternSeq(sequence.patseq, n, sequence.delay, sequence.fixedPt);
    patternGenX(n, :) = patx + sequence.offset;
    patternGenY(n, :) = paty + sequence.offset;
    
    patLinkListX(n, :) = sequence.pg.linkListToPattern(sequence.llpatx,n)+sequence.offset;
    patLinkListY(n, :) = sequence.pg.linkListToPattern(sequence.llpaty,n)+sequence.offset;
    
    
    st = fix((n-1)*sequence.cycleLength+1);
    en = fix(n*sequence.cycleLength);
    devLinkListX(n, :) = patternX(st:en) + sequence.offset;
    devLinkListY(n, :) = patternY(st:en) + sequence.offset;
    
    pattenGenMarker(n, :) = sequence.pg.bufferPulse(patx, 0, sequence.bufferPadding, sequence.bufferReset, sequence.bufferDelay);
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
            
            subplot(5,3,4)
            plot(patLinkListX(i,:),'g'); title('PGLL X')
            
            subplot(5,3,7)
            plot(patternGenX(i,:) - patLinkListX(i,:), 'g'); title('PGLL X Error')
            
            subplot(5,3,10)
            plot(devLinkListX(i,:),'b'); title('APSLL X')
            
            subplot(5,3,13)
            plot(patternGenX(i,:) - devLinkListX(i,:), 'b'); title('APSLL X Error')
            
            %%%%%%%%%% Y Channel %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,2)
            plot(patternGenY(i,:),'r'); title('PG Y')
            
            subplot(5,3,5)
            plot(patLinkListY(i,:),'g'); title('PGLL Y')
            
            subplot(5,3,8)
            plot(patternGenY(i,:) - patLinkListY(i,:), 'g'); title('PGLL Y Error')
            
            subplot(5,3,11)
            plot(devLinkListY(i,:),'b'); title('APSLL Y')
            
            subplot(5,3,14)
            plot(patternGenY(i,:) - devLinkListY(i,:), 'b'); title('APSLL Y Error')
            
            %%%%%%%%%% Marker %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,3)
            plot(patternGenMarker(i,:),'r'); title('PG M')
            
            subplot(5,3,6)
            plot(patLinkListMarker(i,:),'g'); title('PGLL M')
            
            subplot(5,3,9)
            plot(patternGenMarker(i,:) - patLinkListMarker(i,:), 'g'); title('PGLL M Error')
            
            subplot(5,3,12)
            plot(devLinkListMarker(i,:),'b'); title('APSLL M')
            
            subplot(5,3,15)
            plot(patternGenMarker(i,:) - devLinkListMarker(i,:), 'b'); title('APSLL M Error')
            drawnow()
            pause(.1);
        end
    end

plotPatterns(patternGenX, patLinkListX, devLinkListX, ...
    patternGenY, patLinkListY, devLinkListY,...
    patternGenMarker, patLinkListMarker, devLinkListMarker)
end

