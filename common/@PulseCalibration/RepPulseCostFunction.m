function [cost, J, noiseVar] = RepPulseCostFunction(data, angle, numPulses)
    % finds sum of distance^2 from the first value, (assumed to be a good
    % approximation of the center)
    % 2 + 4*numPulses segments, two QId, 2*numPulses +X(Y), then 2*numPulses -X(Y)
    % every experiment is doubled
    % angle - repeated pulse rotation angle (usually pi/2 or pi)
    
    % average together pairs of data points
    rawData = data;
    avgdata = (data(1:2:end) + data(2:2:end))/2;
    
    % normalize data using first pulses as guess for middle
%     norm = 0.5*(data(2)+data(2+numPulses)) - data(1);
%     data = (data(2:end)-data(1))/norm;
    % use separate normalization for each half of the data
    data = [(avgdata(2:1+numPulses)-avgdata(1))/(avgdata(2)-avgdata(1)); (avgdata(2+numPulses:end)-avgdata(1))/(avgdata(2+numPulses)-avgdata(1))];
    % check for bad scaling
    if max(abs(data-1)) > 1.0
        data = data / max(abs(data-1));
    end
    
    %In this normalized scaling the ideal data is all ones
    cost = data-1;

    %Get the Jacobian
    J = PulseJacobian(data, angle, numPulses);
    
    %Estimate the noise from the distribution of difference of repeats
    %Seems like there should be a factor for that fact
    norm = 0.5*(avgdata(2)+avgdata(2+numPulses)) - avgdata(1);
    noiseVar = var((rawData(1:2:end) - rawData(2:2:end))/norm);
end

function J = PulseJacobian(data, angle, numPulses)

    %Vectors of number of pulses
    n = [1:numPulses, 1:numPulses];
    
    % make data and n column vectors
    data = data(:);
    n = n';
    
    switch angle
        case pi/2
            derivScale = 2*n-1;
        case pi
            derivScale = n-1; %(1-n) works in simulation
        otherwise
            error('Unrecognized rotation angle');
    end
    
    J = zeros(2*numPulses,2);
    J(:,1) = (-1).^(n+1).*sqrt(max(0, 1-(data-1).^2)).*derivScale*angle;
    J(1:numPulses,2) = J(1:numPulses,1);
    J(numPulses+1:end,2) = -J(numPulses+1:end,1);
end