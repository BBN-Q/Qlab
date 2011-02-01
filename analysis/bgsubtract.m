function out = bgsubtract(data)
    out = zeros(size(data));
    for i = 1:size(data,2)
        out(:,i) = data(:,i) - mean(data(:,i));
    end
end