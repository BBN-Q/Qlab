function [outx, outy] = derivGaussOff(params)

t = 1:params.width;
outx = round(params.amp * (-(t-1)./params.sigma^2).*exp(-(t-1).^2./(2 * params.sigma^2))).';
outy = zeros(params.width, 1);

end