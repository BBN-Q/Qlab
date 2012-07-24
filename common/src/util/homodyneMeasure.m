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
% File: homodyneMeasure.m
%
% Description: Downloads I/Q data from scope (Acqiris card) and processes the
% result to find an average I and Q value from the data.

function [iavg, qavg] = homodyneMeasure(scope, DHsettings, displayScope)
    persistent scopeHandle;

    if isempty(scopeHandle) && displayScope
        scopeHandle = figure;
    end
    
    % set the card to acquire
    success = scope.acquire();
    if success ~= 0
        error('failed to start acquisition');
    end

    success = scope.wait_for_acquisition();
    if success ~= 0
        error('failed to acquire waveform')
    end

    % Download data from card
    [Amp_I timesI] = scope.transfer_waveform(1);
    [Amp_Q timesQ] = scope.transfer_waveform(2);
    if numel(Amp_I) ~= numel(Amp_Q)
        error('I and Q outputs have different lengths')
    end

    % scope display
    if displayScope
        figure(scopeHandle);
        plot(timesI,Amp_I,'b');
        hold on
        plot(timesQ,Amp_Q,'r');
        grid on
        legend('Ch1', 'Ch2', 'Location', 'SouthEast');
        xlabel('Time')
        hold off
    end

    % extract amplitude and phase
    switch (DHsettings.DHmode)
        case 'OFF'
            % calcuate average amplitude and phase
            iavg = mean(Amp_I);
            qavg = mean(Amp_Q);
        case 'DH1'
            switch DHsettings.channel
                case {1, '1'}
                    [iavg qavg] = digitalHomodyne(Amp_I, DHsettings.IFfreq*1e6, scope.horizontal.sampleInterval);
                case {2, '2'} 
                    [iavg qavg] = digitalHomodyne(Amp_Q, DHsettings.IFfreq*1e6, scope.horizontal.sampleInterval);
                otherwise
                    error('Unhandled digital homodyne channel parameter')
            end
        case 'DIQ'
            [iavg qavg] = digitalHomodyneIQ(Amp_I, Amp_Q, ...
                DHsettings.IFfreq*1e6, scope.horizontal.sampleInterval);
    end
    % convert I/Q to Amp/Phase
%     amp = sqrt(iavg.^2 + qavg.^2);
%     phase = (180.0/pi) * atan2(qavg, iavg);

end