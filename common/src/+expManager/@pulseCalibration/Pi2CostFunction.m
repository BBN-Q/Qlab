function [cost, J] = Pi2CostFunction(data)
    % finds sum of distance^2 from the first value, (assumed to be a good
    % approximation of the center)
    % 38 segments, two QId, 18 +X(Y), then 18 -X(Y)
    % every experiment is doubled
    
    % average together pairs of data points
    data = (data(1:2:end) + data(2:2:end))/2;
    
    % normalize data using first pulses as guess for middle
    norm = 0.5*(data(2)+data(11)) - data(1);
    data = (data(2:end)-data(1))/norm;
    
    cost = sum(data-1)/length(data);
    J = Pi2Jacobian(data);
end

function J = Pi2Jacobian(data)
    pdata = data(1:end/2) - 1;
    mdata = data(end/2+1:end) - 1;
    
    J = zeros(1,2);
    %npts = (-1).^(1:9).*(1+2*(0:8));
    %J(1) = sum(1 - npts.^2.*pdata.^2*pi/2)+sum(1 - npts.^2.*mdata.^2*pi/2);
    J(1) = (sum(1 - pdata.^2*pi/2) + sum(1 - mdata.^2*pi/2))/length(data);
    J(2) = 0.1*(pdata(end) - mdata(end)); % scales with the difference of end points
end