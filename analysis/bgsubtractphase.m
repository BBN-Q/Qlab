function out = bgsubtractphase(data)
    % FUNCTION bgsubtractphase(data)
    % subtracts the mean of every row from a 2D data set after correcting
    % for 2pi phase wraps
    % Returns the subtracted set.
    out = zeros(size(data));
    data = 180/pi * unwrap(pi/180 * data, 2);
    for i = 1:size(data,2)
        slice = data(:,i);
        out(:,i) = data(:,i) - mean(data(:,i));
    end
end