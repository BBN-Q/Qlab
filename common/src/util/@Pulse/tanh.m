function [outx, outy] = tanh(params)

amp = params.amp;
n = params.width;
sigma = params.sigma;
if (n < 6*sigma)
    warning('tanhPulse:params', 'Tanh pulse length is shorter than rise+fall time');
end
t0 = 3*sigma + 1;
t1 = n - 3*sigma;
t = 1:n;
outx = round(0.5*params.amp * (tanh((t-t0)./sigma) + tanh(-(t-t1)./sigma))).';
outy = zeros(n, 1);

end