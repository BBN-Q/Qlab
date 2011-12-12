function [outx, outy] = dragSqPulse(params)
    self = PatternGen;
    yparams = params;
    yparams.amp = params.amp * params.delta;
    
    [outx, tmp] = gaussSquarePulse(params);
    [outy, tmp] = derivGaussSquarePulse(yparams);
end

function [outx, outy] = gaussSquarePulse(params)
    amp = params.amp;
    n = params.width;
    sigma = params.sigma;

    numSigmas = 6;
    % currently hard coded to 6 sigma gaussians
    self = PatternGen;
    passparams.amp = amp;

    passparams.width = numSigmas*sigma/2;
    passparams.sigma = sigma;

    turnon = self.gaussOnPulse(passparams);
    middle = amp*ones(n-numSigmas*sigma, 1);
    turnoff = self.gaussOffPulse(passparams);
    
    outx = [turnon; middle; turnoff];
    outy = zeros(n, 1);
end

function [outx, outy] = derivGaussSquarePulse(params)
    amp = params.amp;
    n = params.width;
    sigma = params.sigma;

    numSigmas = 6;
    % currently hard coded to 6 sigma gaussians
    self = PatternGen;
    passparams.amp = amp;
    passparams.width = numSigmas*sigma/2;
    passparams.sigma = sigma;

    turnon = derivGaussOnPulse(passparams);
    middle = amp*zeros(n-numSigmas*sigma, 1);
    turnoff = derivGaussOffPulse(passparams);
    outx = [turnon; middle; turnoff];
    outy = zeros(n, 1);
end

function [outx, outy] = derivGaussOnPulse(params)
   amp = params.amp;
   n = params.width;
   sigma = params.sigma;

   t = 1:n;
   outx = round(amp * (-(t-n)./sigma^2).*exp(-(t-n).^2./(2 * sigma^2))).';
   outy = zeros(n, 1);
end

function [outx, outy] = derivGaussOffPulse(params)
   amp = params.amp;
   n = params.width;
   sigma = params.sigma;

   t = 1:n;
   outx = round(amp * (-(t-1)./sigma^2).*exp(-(t-1).^2./(2 * sigma^2))).';
   outy = zeros(n, 1);
end