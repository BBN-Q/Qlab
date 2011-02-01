function [pulseData] = generatePulseData(time,amp,samplingRate,plot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USAGE: [pulseData] = generatePulseData(time,amp,device,samplingRate)
%
% Description: the purpose of this function is to format time 
% amplitude pairs given by the user in units of volts and seconds
% into data that can be used to program an AWG, either the Tektronix
% 5000 series or the DACII boxes.  Since this routine will be instrument
% specific device parameters for error checking can be hard coded in.
% Whenever this routine is called it is assumed that the DACII and 
% tektronix code has already been included in the path.
%
% Inputs:
%
% Outputs:
%
% v1.1 25 JUNE 2009 William Kelly <wkelly@bbn.com>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isvector(time)) || (~isvector(amp))
    error('time and amp must be vectors')
end

if length(time) ~= length(amp)
    error('time and amp must have the same length');
else
    numPairs = length(time);
end

if ~exist('plot','var')
    plot = false;
end

if plot ~= true
    
    % For the tektronix we must convert the TA pairs
    % into a vector of values where the time scale is
    % given by the sampling rate, and the amplitude scale
    % is in volts.

    max_tek_amp = 4.5; %volts
    
    if max(abs(amp)) > max_tek_amp
        error('amplitude exeeds maximum for device ''tek''')
    end
    
    pulseData = [];
    for TA_index = 1:(numPairs-1)
        numPoints = time(TA_index)*samplingRate;
        if (numPoints < 1) && (amp(TA_index)==amp(TA_index+1)) && (TA_index ~= 1)
            newData = [];
        else
            newData = linspace(amp(TA_index),amp(TA_index+1),numPoints);
        end
        pulseData = [pulseData newData];
    end
    numPoints = time(numPairs)*samplingRate;
    newData = linspace(amp(numPairs),amp(numPairs),numPoints);
    pulseData = [pulseData newData];
    
else
    pulseData = [];
    for TA_index = 1:(numPairs-1)
        numPoints = time(TA_index)*samplingRate;
        newData = linspace(amp(TA_index),amp(TA_index+1),numPoints);
        pulseData = [pulseData newData];
    end
    numPoints = time(numPairs)*samplingRate;
    newData = linspace(amp(numPairs),amp(numPairs),numPoints);
    pulseData = [pulseData newData];
    plot(1/samplingRate*(1:length(pulseData)),pulseData);
    hold on

end;
end