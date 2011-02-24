function out = bgsubtract(data)
    % FUNCTION bgsubtract(data)
    % subtracts the mean of every row from a 2D data set
    % Returns the subtracted set.
    out = zeros(size(data));
    for i = 1:size(data,2)
        out(:,i) = data(:,i) - mean(data(:,i));
    end
end