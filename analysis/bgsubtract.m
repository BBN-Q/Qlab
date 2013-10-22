function outMat = bgsubtract(data)
% function outMat = bgsubtract(data)
% Subtracts the mean of every row from a 2D data set
% Returns the subtracted set.

outMat = bsxfun(@minus, data, mean(data,2));

end