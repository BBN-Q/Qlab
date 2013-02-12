function [outx, outy] = dragSquare(params)

yparams = params;
yparams.amp = params.amp * params.delta;

[outx, ~] = Pulse.gaussSquare(params);
[outy, ~] = Pulse.derivGaussSquare(yparams);

end