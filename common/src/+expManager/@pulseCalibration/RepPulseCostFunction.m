function [cost, J] = RepPulseCostFunction(data, angle)
    % finds sum of distance^2 from the first value, (assumed to be a good
    % approximation of the center)
    % 38 segments, two QId, 18 +X(Y), then 18 -X(Y)
    % every experiment is doubled
    % angle - repeated pulse rotation angle (usually pi/2 or pi)
    
    % average together pairs of data points
    data = (data(1:2:end) + data(2:2:end))/2;
    
    % normalize data using first pulses as guess for middle
    norm = 0.5*(data(2)+data(11)) - data(1);
    data = (data(2:end)-data(1))/norm;
    
    cost = data-1;
    J = PulseJacobian(data, angle);
end

function J = PulseJacobian(data, angle)
    J = zeros(18,2);
    n = 1:9;
    n = [n n];
    
    % make data and n column vectors
    data = data(:);
    n = n';
    
    switch angle
        case pi/2
            derivScale = 2*n-1;
        case pi
            derivScale = 1-n;
        otherwise
            error('Unrecognized rotation angle');
    end
    
    J(:,1) = (-1).^(n+1).*sqrt(1-(data-1).^2).*derivScale*angle;
    J(1:9,2) = J(1:9,1);
    J(10:18,2) = -J(10:18,1);
end