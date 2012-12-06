function [outx, outy] = derivGaussian(params)

n = params.width;
midpoint = (n+1)/2;
t = 1:n;
outx = round(params.params.amp .* (t - midpoint)./params.sigma^2 .* exp(-(t - midpoint).^2./(2 * params.sigma^2))).';
outy = zeros(n, 1);

end