function LinkListFormatUnitTest(sequence)

%% DacII Enhanced Link List Unit Test
%%
%% Gets Pattern Generator and produces link lists from pattern generator
%% And ELL link lists and plots for comparision
%% May be Called Using Some Varient of deviceDrivers.DacII.LinkListFormatUnitTest

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

d = deviceDrivers.DacII();
d.dbgForceELLMode();
d.verbose = 0;

if ~exist('sequence', 'var') || isempty(sequence)
 sequence = 1;
end

% common sequency parameteres
delay = -10;
measDelay = -53;
bufferDelay = 58;
bufferReset = 100;
bufferPadding = 20;
cycleLength = 10000;
fixedPt = 6000;
offset = 8192;

switch sequence
    case 1
        % Echo Sequence

        piAmp = 8000;
        piWidth = 40;
        pi2Width = 20;
        
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dPulseLength', piWidth, 'cycleLength', cycleLength);
        
        numsteps = 50;
        stepsize = 15;
        delaypts = 0:stepsize:(numsteps-1)*stepsize;
        
        patSeqLL = {
            {'X90p', 'pType', 'square'}, ...
            {'QId', 'width', delaypts}, ...
            {'Xp', 'pType', 'square'}, ...
            {'QId', 'width', delaypts}, ...
            {'X90p', 'pType', 'square'},...
            };
    case 2
        % Rabi Amp Sequence

        piAmp = 8000; % not in orginal script
        
        numsteps = 41;
        stepsize = 200;
        sigma = 10;
        pulseLength = 4*sigma;
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma, 'dPulseLength', pulseLength, 'cycleLength', cycleLength);
        
        amps = 0:stepsize:(numsteps-1)*stepsize;
        patSeqLL = {
            {'Xtheta', 'amp', amps}};
    case 3
        % Ramsey

        numsteps = 100;
        piWidth = 27;
        piAmp = 8000;
        pi2Width = 14;
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dPulseLength', piWidth, 'cycleLength', cycleLength);
        
        stepsize = 5;
        delaypts = 0:stepsize:(numsteps-1)*stepsize;
        patSeqLL = {...
            {'X90p', 'pType', 'square'}, ...
            {'QId', 'width', delaypts}, ...
            {'X90p', 'pType', 'square'} ...
            };
    case 4
        % URamseySequence
 
        numsteps = 50;
        piAmp = 8000;
        sigma = 6;
        pg = PatternGen('dPiAmp', piAmp, 'dPiOn2Amp', piAmp/2, 'dSigma', sigma, 'dPulseLength', 6*sigma, 'cycleLength', cycleLength);
        
        stepsize = 10;
        delaypts = 0:stepsize:(numsteps-1)*stepsize;
        anglepts = 0:pi/8:(numsteps-1)*pi/8;
        patSeqLL = {...
            {'X90p'}, ...
            {'QId', 'width', delaypts}, ...
            {'U90p', 'angle', anglepts} ...
            };
end

for i = 1:length(patSeqLL)
    name = patSeqLL{i}{1};
    if length(patSeqLL{i}) > 1
        patseq{i} = pg.pulse(name, patSeqLL{i}{2:end});
    else
        patseq{i} = pg.pulse(name);
    end
end

%% Allocate memory
patternGenX = zeros(numsteps, cycleLength);
patLinkListX = patternGenX;
devLinkListX = patternGenX;

patternGenY = patternGenX;
patLinkListY = patternGenX;
devLinkListY = patternGenX;

patternGenMarker = patternGenX;
patLinkListMarker = patternGenX;
devLinkListMarker = patternGenX;


% build as patern generator link list
[llpatx llpaty] = pg.build(patSeqLL,numsteps,delay, fixedPt);


useVarients = 1;


[wf, banks] = d.convertLinkListFormat(llpatx,useVarients);
patternX = d.linkListToPattern(wf, banks);

[wf, banks] = d.convertLinkListFormat(llpaty,useVarients);
patternY = d.linkListToPattern(wf, banks);



for n = 1:numsteps;
    [patx paty] = pg.getPatternSeq(patseq, n, delay, fixedPt);
    patternGenX(n, :) = patx + offset;
    patternGenY(n, :) = paty + offset;
    
    patLinkListX(n, :) = pg.linkListToPattern(llpatx,n)+offset;
    patLinkListY(n, :) = pg.linkListToPattern(llpaty,n)+offset;
    
    
    st = fix((n-1)*cycleLength+1);
    en = fix(n*cycleLength);
    devLinkListX(n, :) = patternX(st:en) + offset;
    devLinkListY(n, :) = patternY(st:en) + offset;
    
    pattenGenMarker(n, :) = pg.bufferPulse(patx, paty, 0, bufferPadding, bufferReset, bufferDelay);
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
        
        for i = 1:numsteps
            
            clf
            
            %%%%%%%%%% X Channel %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,1)
            plot(patternGenX(i,:),'r'); title('PG X')
            
            subplot(5,3,4)
            plot(patLinkListX(i,:),'g'); title('PGLL X')
            
            subplot(5,3,7)
            plot(patternGenX(i,:) - patLinkListX(i,:), 'g'); title('PGLL X Error')
            
            subplot(5,3,10)
            plot(devLinkListX(i,:),'b'); title('DacIILL X')
            
            subplot(5,3,13)
            plot(patternGenX(i,:) - devLinkListX(i,:), 'b'); title('DacIILL X Error')
            
            %%%%%%%%%% Y Channel %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,2)
            plot(patternGenY(i,:),'r'); title('PG Y')
            
            subplot(5,3,5)
            plot(patLinkListY(i,:),'g'); title('PGLL Y')
            
            subplot(5,3,8)
            plot(patternGenY(i,:) - patLinkListY(i,:), 'g'); title('PGLL Y Error')
            
            subplot(5,3,11)
            plot(devLinkListY(i,:),'b'); title('DacIILL Y')
            
            subplot(5,3,14)
            plot(patternGenY(i,:) - devLinkListY(i,:), 'b'); title('DacIILL Y Error')
            
            %%%%%%%%%% Marker %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            subplot(5,3,3)
            plot(patternGenMarker(i,:),'r'); title('PG M')
            
            subplot(5,3,6)
            plot(patLinkListMarker(i,:),'g'); title('PGLL M')
            
            subplot(5,3,9)
            plot(patternGenMarker(i,:) - patLinkListMarker(i,:), 'g'); title('PGLL M Error')
            
            subplot(5,3,12)
            plot(devLinkListMarker(i,:),'b'); title('DacIILL M')
            
            subplot(5,3,15)
            plot(patternGenMarker(i,:) - devLinkListMarker(i,:), 'b'); title('DacIILL M Error')
            drawnow()
            pause(.1);
        end
    end

plotPatterns(patternGenX, patLinkListX, devLinkListX, ...
    patternGenY, patLinkListY, devLinkListY,...
    patternGenMarker, patLinkListMarker, devLinkListMarker)
end

