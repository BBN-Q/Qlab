function [outx, outy] = drag(params)

yparams = params;
yparams.params.amp = params.amp * params.delta;

[outx, ~] = Pulse.gaussian(params);
[outy, ~] = Pulse.derivGaussian(yparams);

end