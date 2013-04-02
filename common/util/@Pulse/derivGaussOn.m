function [outx, outy] = derivGaussOn(params)

n = params.width;
t = 1:n;
outx = round(params.amp * (-(t-n)./params.sigma^2).*exp(-(t-n).^2./(2 * params.sigma^2))).';
outy = zeros(n, 1);

end