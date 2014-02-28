function SSBCalSequence
    [ipattern, qpattern] = ssbWaveform(1.0, 0);
    saveAWGFile(ipattern, qpattern, 'MixerCal2', 3, 4);
end

function [ipat, qpat] = ssbWaveform(amp, phase)
    % generate SSB modulation signals
    waveform_length = 10000;
    fssb = 100e6; % SSB modulation frequency
    assb = 8000;
    t = 0:(waveform_length-1);
    t = t*1e-9;
    ipat = assb * amp * cos(2*pi*fssb.*t);
    qpat = -assb * amp * sin(2*pi*fssb.*t + pi/180.0*phase);
end

function fname = saveAWGFile(ipattern, qpattern, name, awg_I_channel, awg_Q_channel)
    script = java.io.File(mfilename('fullpath'));
    path = char(script.getParentFile().getParentFile().getParentFile().getParent());
    addpath([path '/common/src'],'-END');
    addpath([path '/common/src/util/'],'-END');

    temppath = [char(script.getParent()) '\'];
    path = 'U:\AWG\MixerCal\';
    if ~exist('name', 'var')
        basename = 'MixerCal';
    else
        basename = name;
    end
    fname = [path basename '.awg'];
    len = length(ipattern);
    % initialize everything to zeroes
    offset = 8192;
    ch1 = zeros(1, len) + offset;
    ch1m1 = zeros(1, len);
    ch1m2 = zeros(1, len);
    ch2 = zeros(1, len) + offset;
    ch2m1 = zeros(1, len);
    ch2m2 = zeros(1, len);
    ch3 = zeros(1, len) + offset;
    ch3m1 = zeros(1, len);
    ch3m2 = zeros(1, len);
    ch4 = zeros(1, len) + offset;
    ch4m1 = zeros(1, len);
    ch4m2 = [ones(1, 10) zeros(1, len-10)]; % provide a trigger here

    % put the pattern on the appropriate channels
    ipattern = ipattern + offset;
    qpattern = qpattern + offset;
    eval(sprintf('ch%d = ipattern;', awg_I_channel));
    eval(sprintf('ch%d = qpattern;', awg_Q_channel));

    TekPattern.exportTekSequence(temppath, basename, ch1, ch1m1, ch1m2, ch2, ch2m1, ch2m2, ch3, ch3m1, ch3m2, ch4, ch4m1, ch4m2);
    disp('Moving AWG file to destination');
    movefile([temppath basename '.awg'], [path basename '.awg']);
end