function [outx, outy] = dragGaussOff(params)

derivParams = params;
derivParams.amp = params.amp*params.delta;
[outx, ~] = Pulse.gaussOff(params);
[outy, ~] = Pulse.derivGaussOff(derivParams);

end