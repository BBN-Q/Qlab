function [phase, sigma] = PhaseEstimation(data, vardata, varscale, verbose)
    % Estimates pulse rotation angle from a sequence of P^k experiments, where k is 
    % of the form 2^n. Uses the modified phase estimation algorithm from 
    % Kimmel et al, quant-ph/1502.02677 (2015).
    % Every experiment is doubled.
    if nargin < 4
        verbose = false;
    end
    
    % average together pairs of data points
    avgdata = (data(1:2:end) + data(2:2:end))/2;
    
    % normalize data using the first two pulses to calibrate the "meter"
    data = 1 + 2*(avgdata(3:end) - avgdata(1)) / (avgdata(1) - avgdata(2));
    zdata = data(1:2:end);
    xdata = data(2:2:end);

    % similar scaling with variances
    vardata = (vardata(1:2:end) + vardata(2:2:end))/2;
    vardata = vardata(3:end) * 2/abs(avgdata(1) - avgdata(2))^2;
    %the X6 card returns the variance of single shots, not of the mean
    if varscale>0
        vardata = vardata/varscale;
    end
    zvar = vardata(1:2:end);
    xvar = vardata(2:2:end);
    
    phases = atan2(xdata, zdata);
    distances = sqrt(xdata.^2 + zdata.^2);

    curGuess = phases(1);
    phase = curGuess;
    sigma = pi;
    if verbose
        curGuess
    end
    for k = 2:length(phases)
        if verbose
            k
        end
        % Each step of phase estimation needs to assign the measured phase to
        % the correct half circle. We will conservatively require that the
        % (x,z) tuple is long enough that we can assign it to the correct
        % quadrant of the circle with 2σ confidence
        if distances(k) < 2*sqrt(xvar(k) + zvar(k))
            fprintf(2, 'Phase estimation terminated at %dth pulse because the (x,z) vector is too short\n', k);
            break
        end
        lowerBound = restrict(curGuess - pi/2^(k-1));
        upperBound = restrict(curGuess + pi/2^(k-1));
        possibles = arrayfun(@(n) restrict((phases(k) + 2*n*pi)/2^(k-1)), 0:2^(k-1));
        if verbose
            lowerBound
            upperBound
        end
        if lowerBound > upperBound
            satisfiesLB = (possibles > lowerBound) | (possibles < 0);
            satisfiesUP = (possibles < upperBound) | (possibles > 0);
        else
            satisfiesLB = possibles > lowerBound;
            satisfiesUP = possibles < upperBound;
        end
        possibles = possibles(satisfiesLB & satisfiesUP);
        curGuess = possibles(1);
        if verbose
            curGuess
        end
    end
    phase = curGuess;
    sigma = max(abs(curGuess - lowerBound), abs(curGuess - upperBound));
end

function out = restrict(phase)
    out = mod(phase + pi, 2*pi) - pi;
end
