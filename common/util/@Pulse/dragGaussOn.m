function [outx, outy] = dragGaussOn(params)

derivParams = params;
derivParams.amp = params.amp*params.delta;
[outx, ~] = Pulse.gaussOn(params);
[outy, ~] = Pulse.derivGaussOn(derivParams);

end