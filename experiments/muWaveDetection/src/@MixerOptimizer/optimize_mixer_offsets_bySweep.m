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
% File: optimize_mixer_offsets.m
%
% Author: Blake Johnson and Colm Ryan BBN Technologies
%
% Description: Searches for optimal I/Q offset voltages to minimize carrier
% leakage by sweeping the offset voltages and looking for nulls
%

function [i_offset, q_offset] = optimize_mixer_offsets_bySweep(obj)

persistent figHandles
if isempty(figHandles)
                figHandles = struct();
end

% unpack constants from cfg file
ExpParams = obj.expParams;
awg_I_channel = str2double(obj.channelParams.physChan(end-1));
awg_Q_channel = str2double(obj.channelParams.physChan(end));

obj.awg.run();

offsetPts = linspace(ExpParams.Sweep.offset.start, ExpParams.Sweep.offset.stop, ExpParams.Sweep.offset.numPoints);
vertex = struct();
%Sweep the I with Q at 0
measPowers1 = nan(1, length(offsetPts));
if ~isfield(figHandles, 'mixOffset') || ~ishandle(figHandles.('mixOffset'))
    figHandles.('mixOffset') = figure('Name', 'I-Q offsets'); 
else
    figure(figHandles.('mixOffset')); clf;
end
axesH = axes();
tmpLine = plot(axesH,offsetPts, measPowers1, 'b*');
hold on
set(get(get(tmpLine,'Annotation'),'LegendInformation'),...
    'IconDisplayStyle','off'); % Exclude line from legend
xlabel(['Offset Voltage ' obj.chan ' (V)']);
ylabel('Peak Power (dBm)');
for ct = 1:length(offsetPts)
    vertex.a = offsetPts(ct); vertex.b = 0;
    setOffsets(vertex);
    measPowers1(ct) = readPower();
    set(tmpLine,'YData', measPowers1);
    drawnow()
end

[i_offset, fitData] = obj.find_null_offset(measPowers1, offsetPts);
fprintf('Found I offset of %f on first iteration\n',i_offset);

plot(axesH, offsetPts, fitData,'b--');
drawnow()

%Sweep the Q with I at the new best pt
measPowers2 = nan(1, length(offsetPts));
tmpLine = plot(axesH,offsetPts, measPowers2, 'r*');
set(get(get(tmpLine,'Annotation'),'LegendInformation'),...
    'IconDisplayStyle','off'); % Exclude line from legend

for ct = 1:length(offsetPts)
    vertex.a = i_offset; vertex.b = offsetPts(ct);
    setOffsets(vertex);
    measPowers2(ct) = readPower();
    set(tmpLine,'YData', measPowers2);
    drawnow()
end

[q_offset, fitData]  = obj.find_null_offset(measPowers2, offsetPts);
fprintf('Found Q offset of %f on first iteration\n',q_offset);

plot(axesH, offsetPts, fitData,'r--')
drawnow()

%Sweep the I again with Q at best pt
measPowers3 = nan(1, length(offsetPts));
tmpLine = plot(axesH,offsetPts, measPowers3, 'g*');
set(get(get(tmpLine,'Annotation'),'LegendInformation'),...
    'IconDisplayStyle','off'); % Exclude line from legend
for ct = 1:length(offsetPts)
    vertex.a = offsetPts(ct); vertex.b = q_offset;
    setOffsets(vertex);
    measPowers3(ct) = readPower();
    set(tmpLine,'YData', measPowers3);
    drawnow()
end

[i_offset, fitData] = obj.find_null_offset(measPowers3, offsetPts);
fprintf('Found I offset of %f on second iteration\n',i_offset);
plot(axesH, offsetPts, fitData,'g--')

legend({'First I Sweep','First Q Sweep', 'Second I Sweep'})
drawnow()

% nested functions


    function power = readPower()
        obj.sa.sweep()
        power = obj.sa.peakAmplitude();
%         [~, powerTrace] = obj.sa.downloadTrace();
%         power = log10(sum(10.^(powerTrace/10)));
        %We try twice to overcome the flakey network analsyer
%         obj.sa.sweep();
%         p1 = obj.sa.peakAmplitude();
%         obj.sa.sweep();
%         p2 = obj.sa.peakAmplitude();
%         power = max(p1, p2);
    end

    function setOffsets(vertex)
        
        switch class(obj.awg)
            case 'deviceDrivers.Tek5014'
                obj.awg.(['chan_' num2str(awg_I_channel)]).offset = vertex.a;
                obj.awg.(['chan_' num2str(awg_Q_channel)]).offset = vertex.b;
                obj.awg.operationComplete();
            case {'deviceDrivers.APS', 'APS'}
                obj.awg.setOffset(awg_I_channel, vertex.a);
                obj.awg.setOffset(awg_Q_channel, vertex.b);
            case 'APS2'
                obj.awg.stop();
                obj.awg.set_channel_offset(awg_I_channel, vertex.a);
                obj.awg.set_channel_offset(awg_Q_channel, vertex.b);
                obj.awg.run();
        end
        pause(0.1)
    end

end


