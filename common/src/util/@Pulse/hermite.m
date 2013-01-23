function [outx, outy] = hermite(params)

%Broadband excitation pulse based on Hermite polynomials.
numPoints = params.width;
timePts = linspace(-numPoints/2,numPoints/2,numPoints)';
switch params.rotAngle
    case pi/2
        A1 = -0.677;
    case pi
        A1 = -0.956;
    otherwise
        error('Unknown rotation angle for Hermite pulse.  Currently only handle pi/2 and pi.');
end
outx = params.amp*(1+A1*(timePts/params.sigma).^2).*exp(-((timePts/params.sigma).^2));
outy = zeros(numPoints,1);

end