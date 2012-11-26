function [outx, outy, frameChange] = arbAxisDRAG(params)

    rotAngle = params.rotAngle;
    polarAngle = params.polarAngle;
    aziAngle = params.aziAngle;
    nutFreq = params.nutFreq; %nutation frequency for 1 unit of pulse amplitude
    sampRate = params.samplingRate;

    n = params.width;
    sigma = params.sigma;

    if n > 0
        timePts = linspace(-0.5, 0.5, n)*(n/sigma); 
        gaussPulse = exp(-0.5*(timePts.^2)) - exp(-2);

        calScale = (rotAngle/2/pi)*sampRate/sum(gaussPulse);
        % calculate phase steps given the polar angle
        phaseSteps = -2*pi*cos(polarAngle)*calScale*gaussPulse/sampRate;
        % calculate DRAG correction to phase steps
        % need to convert XY DRAG parameter to Z DRAG parameter
        beta = params.delta/sampRate;
        instantaneousDetuning = beta*(2*pi*calScale*sin(polarAngle)*gaussPulse).^2;
        phaseSteps = phaseSteps + instantaneousDetuning*(1/sampRate);
        % center phase ramp around the middle of the pulse
        phaseRamp = cumsum(phaseSteps) - phaseSteps/2;

        frameChange = sum(phaseSteps);

        complexPulse = (1/nutFreq)*sin(polarAngle)*calScale*exp(1i*aziAngle)*gaussPulse.*exp(1i*phaseRamp);

        outx = real(complexPulse)';
        outy = imag(complexPulse)';

    elseif abs(polarAngle) < 10*eps
        frameChange = -rotAngle;
        outx = []; outy = [];
    else
        error('Non-zero transverse rotation with zero-length pulse.');
    end

end