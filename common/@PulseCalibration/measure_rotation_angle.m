function [phase, sigma] = measure_rotation_angle(obj, amp, direction, target)
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
        [filenames, ~] = obj.PulsePhaseEstimate(obj.settings.Qubit, direction, numPulses, amp);
        obj.loadSequence(filenames, 1);
        data = obj.take_data(segmentPoints);
    else
        data = simulateMeasurement(amp, target);
        plot(data);
        ylim([-1.1 1.1])
        drawnow()
        pause(.1);
    end
    
    [phase, sigma] = obj.PhaseEstimation(data);
    % correct for some errors related to 2pi uncertainties
    if sign(phase) ~= sign(amp)
        phase = phase + sign(amp)*2*pi;
    end
    angleError = phase - target;
    fprintf('Angle error: %.4f\n', angleError);
end

function data = simulateMeasurement(amp, target)
    idealAmp = 0.34;
    noiseScale = 0.1;

    % data representing over/under rotation of pi/2 pulse
    % theta = pi/2 * (amp/idealAmp);
    theta = target * (amp/idealAmp);
    ks = arrayfun(@(k) 2^k, 0:8);
    xdata = arrayfun(@(x) sin(x*theta), ks);
    zdata = arrayfun(@(x) cos(x*theta), ks);
    data = [1  zdata;
            -1 xdata];
    data = data(:);
    % repeat each experiment
    data = repmat(data', 2, 1);
    data = data(:);
    % add noise
    data = data + noiseScale * randn(size(data));
end