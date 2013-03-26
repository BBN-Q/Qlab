function RamseySequence()

%The right-alignment point
fixedPt = 40000;

% setup PatternGen object with defaults
pg = PatternGen(...
    'piAmp', 6000, ... % amplitude for a pi pulse (8191 = full scale)
    'pi2Amp', 3000, ... % amplitude for a pi/2 pulse
    'sigma', 12, ... % width of gaussian pulse in samples (12 samples = 10 ns at 1.2 GS/s)
    'pulseType', 'drag', ... % pulse shape: square, gauss, tanh, drag, etc
    'delta', -0.5, ... % DRAG pulse scale factor
    'T', eye(2),... % mixer imperfection correction: 2x2 matrix applied to all I/Q pairs
    'bufferDelay', -24,... % relative delay of gating pulse in samples
    'bufferReset', 120,... % minimum spacing between gate pulses
    'bufferPadding', 24, ... % additional width of gate pulses
    'buffer', 4, ... % space between pulses
    'pulseLength', 4*12, ... % pulse length, 4*12 gives a +/- 2sigma cutoff for Gaussian pulses
    'cycleLength', fixedPt+1000, ... % total length of each pulse sequence
    'linkListMode', true, ... % enabled for use with APS
    'SSBFreq', 0e6); % SSB modulation frequency in Hz

numsteps = 300;
stepsize = 120; % 100ns steps
delaypts = 0:stepsize:(numsteps-1)*stepsize;
patseq = {...
    pg.pulse('X90p'), ...
    pg.pulse('QId', 'width', delaypts), ...
    pg.pulse('X90p')
   };

% build the link lists
delay = -12; % relative analog I/Q channel delay (for aligning channels on various hardware platforms)
addGatePulses = true; %whether we're going to add blanking pulses: by default comes out on the ch1m1 for 1&2 and ch3m1 for 3&4
IQ12 = pg.build(patseq, numsteps, delay, fixedPt, addGatePulses);

%Add a digitizer trigger to ch2m1
% addTrigger(seqs, delay, width, ch)
IQ12 = PatternGen.addTrigger(IQ12, fixedPt-500, 0, 2);

%put empty output on channels 3/4
pg2 = PatternGen('linkListMode', 1, 'cycleLength', fixedPt+1000);
IQ34 = struct();
IQ34.linkLists = pg2.build({pg.pulse('QId')}, 1, 0, fixedPt, false);
IQ34.waveforms = pg2.pulseCollection;

% plot sequence
figure
[ch1, ch2] = pg.linkListToPattern(IQ12{20}); % look at the 20th sequence
plot(ch1)
hold on
plot(ch2, 'r')

% export file Ramsey.h5
relpath = './';
basename = 'Ramsey';
nbrRepeats = 1;
APSPattern.exportAPSConfig(relpath, basename, nbrRepeats, struct('waveforms', pg.pulseCollection, 'linkLists', {IQ12}), IQ34);

end