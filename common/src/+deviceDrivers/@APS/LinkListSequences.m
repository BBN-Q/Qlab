function output = LinkListSequences(sequence)

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
        
        %numsteps = 50;
        numsteps = 1;
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

% build as patern generator link list
[llpatx llpaty] = pg.build(patSeqLL,numsteps,delay, fixedPt);

flds = {'llpatx','llpaty','numsteps','cycleLength','patseq','delay','fixedPt', ...
        'pg','bufferPadding','bufferReset','bufferDelay','offset'};
output = [];

for i = 1:length(flds)
   output.(flds{i}) = eval(flds{i}); 
end


end
