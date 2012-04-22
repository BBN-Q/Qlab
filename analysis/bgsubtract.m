function outMat = bgsubtract(data)
% function outMat = bgsubtract(data)
% Subtracts the mean of every row from a 2D data set
% Returns the subtracted set.

outMat = data - repmat(mean(data,2),[1, size(data,2)]);

end