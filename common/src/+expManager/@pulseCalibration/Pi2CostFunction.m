function cost = Pi2CostFunction(data)
    % finds sum of distance^2 from the first value, (assumed to be a good
    % approximation of the center)
    % 38 segments, two QId, 18 +X(Y), then 18 -X(Y)
    % every experiment is doubled
    
    % average together pairs of data points
    data = (data(1:2:end) + data(2:2:end))/2;
    
    offset = data(1);
    
    % use average of first pulses in each direction as offset
    mid = 0.5*(data(2)+data(11));
    
    norm = mid - offset;
    
    cost = sum((data(2:end)-mid).^2/norm^2)/length(data);
end