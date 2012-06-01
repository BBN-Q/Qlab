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

% unpack constants from cfg file
ExpParams = obj.inputStructure.ExpParams;
spec_analyzer_span = ExpParams.SpecAnalyzer.span;
spec_resolution_bw = ExpParams.SpecAnalyzer.resolution_bw;
spec_sweep_points = ExpParams.SpecAnalyzer.sweep_points;
awg_I_channel = ExpParams.Mixer.I_channel;
awg_Q_channel = ExpParams.Mixer.Q_channel;
max_offset = ExpParams.Search.max_offset; % max I/Q offset voltage

% grab instrument objects
sa = obj.sa;
awg = obj.awg;

% center on the current spec generator frequency
sa.center_frequency = obj.specgen.frequency * 1e9;
sa.span = spec_analyzer_span;
sa.sweep_mode = 'single';
sa.resolution_bw = spec_resolution_bw;
sa.sweep_points = spec_sweep_points;
sa.video_averaging = 0;

awg.run();
awg.waitForAWGtoStartRunning();

offsetPts = linspace(ExpParams.Sweep.offset.start, ExpParams.Sweep.offset.stop, ExpParams.Sweep.offset.numPoints);
vertex = struct();
%Sweep the I with Q at 0
measPowers1 = nan(1, length(offsetPts));
figure();
axesH = axes();
tmpLine = plot(axesH,offsetPts, measPowers1, 'b*');
hold on
set(get(get(tmpLine,'Annotation'),'LegendInformation'),...
    'IconDisplayStyle','off'); % Exclude line from legend
xlabel('Offset Voltage (V)');
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


% restore spectrum analyzer to a normal state
sa.sweep_mode = 'cont';
sa.resolution_bw = 'auto';
sa.sweep_points = 800;
sa.sweep();
sa.peakAmplitude();

% nested functions


    function power = readPower()
        sa.sweep()
        power = sa.peakAmplitude();
%         [~, powerTrace] = sa.downloadTrace();
%         power = log10(sum(10.^(powerTrace/10)));
        %We try twice to overcome the flakey network analsyer
%         sa.sweep();
%         p1 = sa.peakAmplitude();
%         sa.sweep();
%         p2 = sa.peakAmplitude();
%         power = max(p1, p2);
    end

    function setOffsets(vertex)
        
        switch class(awg)
            case 'deviceDrivers.Tek5014'
                awg.(['chan_' num2str(awg_I_channel)]).offset = vertex.a;
                awg.(['chan_' num2str(awg_Q_channel)]).offset = vertex.b;
                awg.operationComplete();
                pause(0.1);
            case 'deviceDrivers.APS'
                awg.stop();
                
                %We have to set the offset in the waveform
                % scale I waveform
                iwf = obj.awg.(['chan_' num2str(awg_I_channel)]).waveform;
                iwf.offset = vertex.a;
                obj.awg.loadWaveform(awg_I_channel-1, iwf.prep_vector());
   
                qwf = obj.awg.(['chan_' num2str(awg_Q_channel)]).waveform;
                qwf.offset = vertex.b;
                obj.awg.loadWaveform(awg_Q_channel-1, qwf.prep_vector());
                
                obj.awg.setOffset(awg_I_channel, vertex.a);
                obj.awg.setOffset(awg_Q_channel, vertex.b);
                
                obj.awg.run();
                pause(0.2);
        end
        
    end

end


