% Copyright 2010 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% File: optimize_mixer_ampPhase.m
%
% Description: Searches for optimal amplitude and phase correction on an
% I/Q mixer.

function T = optimize_mixer_ampPhase_bySweep(obj, i_offset, q_offset)

% unpack constants from cfg file
ExpParams = obj.inputStructure.ExpParams;
InstrParams = obj.inputStructure.InstrParams;
spec_analyzer_span = ExpParams.SpecAnalyzer.span;
spec_resolution_bw = ExpParams.SpecAnalyzer.resolution_bw;
spec_sweep_points = ExpParams.SpecAnalyzer.sweep_points;
fssb = ExpParams.SSBFreq; % SSB modulation frequency (usually 10 MHz)
awg_amp = InstrParams.AWG.(['chan_' num2str(ExpParams.Mixer.I_channel)]).Amplitude;

% initialize instruments
% grab instrument objects
sa = obj.sa;
awg = obj.awg;

awg.(['chan_' num2str(ExpParams.Mixer.I_channel)]).offset = i_offset;
awg.(['chan_' num2str(ExpParams.Mixer.Q_channel)]).offset = q_offset;

sa.center_frequency = obj.specgen.frequency * 1e9 - fssb;
sa.span = spec_analyzer_span;
sa.sweep_mode = 'single';
sa.resolution_bw = spec_resolution_bw;
sa.sweep_points = spec_sweep_points;
sa.video_averaging = 0;
sa.sweep();
sa.peakAmplitude();

awg.run();
awg.waitForAWGtoStartRunning();

fprintf('\nStarting sweep search for optimal amp/phase\n');

%First we scan the amplitude with the phase at zero
ampPts = linspace(0.75*awg_amp, 1.25*awg_amp, 100);

figure();
axesHAmp = subplot(2,1,1);
measPowers1 = nan(1, length(ampPts));
tmpLine = plot(axesHAmp, ampPts/awg_amp, measPowers1, 'b*');
hold on
xlabel('Amplitude Factor');
ylabel('Peak Power (dBm)');

axesHPhase = subplot(2,1,2);
hold on
xlabel('Channel Skew (degrees)');
ylabel('Peak Power (dBm)');

for ct = 1:length(ampPts);
    obj.setInstrument(ampPts(ct), 0);
    measPowers1(ct) = readPower();
    set(tmpLine,'YData', measPowers1);
    drawnow()
end
[bestAmp, goodXPts, goodPowers] = find_null_offset(measPowers1,ampPts);
fprintf('Found best amplitude factor of %f on first iteration.\n',bestAmp/awg_amp);
plot(axesHAmp, goodXPts/awg_amp, goodPowers,'r--')
drawnow()

%Now we scan the channel skew withe amp factor set appropriately
skewPts = linspace(-pi/10,pi/10,100);
measPowers2 = nan(1, length(skewPts));
tmpLine = plot(axesHPhase, skewPts*180/pi, measPowers2, 'b*');
for ct = 1:length(skewPts);
    obj.setInstrument(bestAmp, skewPts(ct));
    measPowers2(ct) = readPower();
    set(tmpLine,'YData', measPowers2);
    drawnow()
end

[bestSkew, goodXPts, goodPowers] = find_null_offset(measPowers2,skewPts);
fprintf('Found best skew angle of %f on first iteration.\n',bestSkew*180/pi);
plot(axesHPhase, goodXPts*180/pi, goodPowers,'r--')
drawnow()

%Finally we rescan the amp factor
measPowers3 = nan(1, length(ampPts));
tmpLine = plot(axesHAmp, ampPts/awg_amp, measPowers3, 'g*');
xlabel('Amplitude Factor')
ylabel('Peak Power (dBm)');

for ct = 1:length(ampPts);
    obj.setInstrument(ampPts(ct), bestSkew);
    measPowers3(ct) = readPower();
    set(tmpLine,'YData', measPowers3);
    drawnow()
end
[bestAmp, goodXPts, goodPowers] = find_null_offset(measPowers3,ampPts);
fprintf('Found best amplitude factor of %f on second iteration.\n',bestAmp/awg_amp);
plot(axesHAmp, goodXPts/awg_amp, goodPowers,'r--')
drawnow

ampFactor = bestAmp/awg_amp;

fprintf('Optimal amp/phase parameters:\n');
fprintf('a: %.3g, skew: %.3f (%.3f degrees)\n', [ampFactor, bestSkew, bestSkew*180/pi]);
fprintf('SSB power: %.2f\n', min(goodPowers));

% correction transformation
T = [ampFactor ampFactor*tan(bestSkew); 0 sec(bestSkew)];

% restore instruments to a normal state
sa.center_frequency = obj.specgen.frequency * 1e9;
sa.span = 25e6;
sa.sweep_mode = 'cont';
sa.resolution_bw = 'auto';
sa.sweep_points = 800;
sa.video_averaging = 1;
sa.sweep();
sa.peakAmplitude();

obj.setInstrument(bestAmp, bestSkew);

    function power = readPower()
        %We try twice to overcome the flakey network analsyer
        sa.sweep();
        p1 = sa.peakAmplitude();
        sa.sweep();
        p2 = sa.peakAmplitude();
        power = max(p1, p2);
    end
end

function [bestOffset, goodOffsetPts, measPowers] = find_null_offset(measPowers, xPts)
%Find the offset corresponding to the minimum power with some crude
%spike detection and removal

%First apply an n-pt median filter
n = 5;
%Extrapolate the first and last points
extendedPowers = [measPowers(1)*ones(1,floor(n/2)), measPowers, measPowers(end)*ones(1,floor(n/2))];
filteredPowers = zeros(1,length(measPowers));
shift = floor(n/2);
for ct = 1:length(measPowers)
    filteredPowers(ct) = median(extendedPowers(ct:ct+2*shift));
end

%We arbitrarily choose a cutoff of 6dB spikes
goodPts = find(abs(measPowers - filteredPowers) < 6);

goodOffsetPts = xPts(goodPts);
measPowers = measPowers(goodPts);

[~, goodIdx] = min(measPowers);
bestOffset = goodOffsetPts(goodIdx);
end
