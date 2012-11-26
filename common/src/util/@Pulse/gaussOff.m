function [outx, outy] = gaussOff(params)

n = params.width;
t = 1:n;
baseLine = round(params.amp*exp(-n^2/(2*params.sigma^2)));
outx = round(params.amp * exp(-(t-1).^2./(2 * params.sigma^2))).'- baseLine;
outy = zeros(n, 1);

end