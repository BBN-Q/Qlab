function [phase, sigma] = measure_rotation_angle(obj, amp, direction, target, varargin)
    % inputs:
    %   amp - pulse amplitude
    %   direction - 'X' or 'Y'
    %   target - target angle (e.g. pi/2 or pi)
    % outputs:
    %   phase - rotation angle of the pulse
    %   sigma - uncertainty in the estimate of 'phase'
    if abs(target) == pi/2
        numPulses = obj.settings.NumPi2s;
        targetStr = '90';
    elseif abs(target) == pi
        numPulses = obj.settings.NumPis;
        targetStr = '';
    else
        error('Unrecognized target rotation angle');
    end
    if target > 0
        signStr = '+';
    else
        signStr = '-';
    end

    fprintf('%s%s%s pulse amplitude: %.4f\n', signStr, direction, targetStr, amp);
    
    % create sequence and measure
    if ~obj.testMode
        if isfield(obj.settings, 'CRpulses')
            [filenames, segmentPoints] = obj.PhaseEstimationSequence2q(obj.settings.Qubit, varargin{1}, numPulses, amp); %target
        else
            [filenames, segmentPoints] = obj.PhaseEstimationSequence(obj.settings.Qubit, direction, numPulses, amp);
        end
        obj.loadSequence(filenames, 1);
        [data, vardata] = obj.take_data(segmentPoints);
    else
        [data, vardata] = simulateMeasurement(amp, target, numPulses);
        plot(-1:0.25:numPulses+0.75, data);
        ylim([-1.1 1.1])
        drawnow()
        pause(.1);
    end
    % scale vardata by numShots to get variance of the mean
    [phase, sigma] = obj.PhaseEstimation(data, vardata/obj.numShots);
    % correct for some errors related to 2pi uncertainties
    if sign(phase) ~= sign(amp)
        phase = phase + sign(amp)*2*pi;
    end
    angleError = phase - target;
    fprintf('Angle error: %.4f\n', angleError);
end

function [data, vardata] = simulateMeasurement(amp, target, numPulses)
    idealAmp = 0.34;
    noiseScale = 0.05;
    polarization = 0.99; % residual polarization after each pulse

    % data representing over/under rotation of pi/2 pulse
    % theta = pi/2 * (amp/idealAmp);
    theta = target * (amp/idealAmp);
    ks = arrayfun(@(k) 2^k, 0:numPulses);
    xdata = arrayfun(@(x) polarization^x * sin(x*theta), ks);
    zdata = arrayfun(@(x) polarization^x * cos(x*theta), ks);
    data = [1  zdata;
            -1 xdata];
    data = data(:);
    % repeat each experiment
    data = repmat(data', 2, 1);
    data = data(:);
    % add noise
    data = data + noiseScale * randn(size(data));
    vardata = noiseScale^2 * ones(size(data));
end