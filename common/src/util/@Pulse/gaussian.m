function [outx, outy] = gaussian(params)

midpoint = (params.width+1)/2;
t = 1:params.width;
baseLine = round(params.amp*exp(-midpoint^2/(2*params.sigma^2)));
outx = round(params.amp * exp(-(t - midpoint).^2./(2 * params.sigma^2))).'- baseLine;
outy = zeros(params.width, 1);

end