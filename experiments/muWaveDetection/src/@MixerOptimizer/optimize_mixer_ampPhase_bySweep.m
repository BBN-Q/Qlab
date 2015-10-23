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

function [ampFactor, phaseSkew] = optimize_mixer_ampPhase_bySweep(obj)

persistent figHandles
if isempty(figHandles)
                figHandles = struct();
end

% unpack constants from cfg file
ExpParams = obj.expParams;
awgAmp = obj.awgAmp;
fssb = ExpParams.SSBFreq; % SSB modulation frequency (usually 10 MHz)

% initialize instruments

obj.awg.run();

obj.sa.centerFreq = obj.uwsource.frequency - fssb/1e9;

fprintf('\nStarting sweep search for optimal amp/phase\n');

%First we scan the amplitude with the phase at zero
ampPts = linspace(ExpParams.Sweep.ampFactor.start*awgAmp, ExpParams.Sweep.ampFactor.stop*awgAmp, ExpParams.Sweep.ampFactor.numPoints);

if ~isfield(figHandles, 'mixAmpPhase') || ~ishandle(figHandles.('mixAmpPhase'))
figHandles.('mixAmpPhase') = figure('Name', 'I-Q Amp/Skew'); 
else
    figure(figHandles.('mixAmpPhase')); clf;
end
axesHAmp = subplot(2,1,1);
measPowers1 = nan(1, length(ampPts));
tmpLine = plot(axesHAmp, ampPts/awgAmp, measPowers1, 'b*');
hold on
xlabel('Amplitude Factor');
ylabel('Peak Power (dBm)');
title(obj.chan);

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
[bestAmp, fitData] = obj.find_null_offset(measPowers1,ampPts);
fprintf('Found best amplitude factor of %f on first iteration.\n',bestAmp/awgAmp);
plot(axesHAmp, ampPts/awgAmp, fitData,'r--')
drawnow()

%Now we scan the channel skew withe amp factor set appropriately
skewPts = linspace((pi/180)*ExpParams.Sweep.phaseSkew.start,(pi/180)*ExpParams.Sweep.phaseSkew.stop, ExpParams.Sweep.phaseSkew.numPoints);
measPowers2 = nan(1, length(skewPts));
tmpLine = plot(axesHPhase, skewPts*180/pi, measPowers2, 'b*');
for ct = 1:length(skewPts);
    obj.setInstrument(bestAmp, skewPts(ct));
    measPowers2(ct) = readPower();
    set(tmpLine,'YData', measPowers2);
    drawnow()
end

[bestSkew, fitData] = obj.find_null_offset(measPowers2, skewPts);
fprintf('Found best skew angle of %f on first iteration.\n',bestSkew*180/pi);
plot(axesHPhase, skewPts*180/pi, fitData,'r--')
drawnow()

%Finally we rescan the amp factor
measPowers3 = nan(1, length(ampPts));
tmpLine = plot(axesHAmp, ampPts/awgAmp, measPowers3, 'g*');

for ct = 1:length(ampPts);
    obj.setInstrument(ampPts(ct), bestSkew);
    measPowers3(ct) = readPower();
    set(tmpLine,'YData', measPowers3);
    drawnow()
end
[bestAmp, fitData] = obj.find_null_offset(measPowers3,ampPts);
fprintf('Found best amplitude factor of %f on second iteration.\n',bestAmp/awgAmp);
plot(axesHAmp, ampPts/awgAmp, fitData,'r--')
drawnow

ampFactor = bestAmp/awgAmp;

fprintf('Optimal amp/phase parameters:\n');
fprintf('a: %.3g, skew: %.3f (%.3f degrees)\n', [ampFactor, bestSkew, bestSkew*180/pi]);
fprintf('SSB power: %.2f\n', min(measPowers3));

phaseSkew = bestSkew*180/pi;

obj.setInstrument(bestAmp, bestSkew);

    function power = readPower()
        obj.sa.sweep();
        power = obj.sa.peakAmplitude();
%         %We try twice to overcome the flakey network analsyer
%         sa.sweep();
%         p1 = sa.peakAmplitude();
%         sa.sweep();
%         p2 = sa.peakAmplitude();
%         power = max(p1, p2);
    end
end

