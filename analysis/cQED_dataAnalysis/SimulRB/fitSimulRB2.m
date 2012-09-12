function alphas = fitSimulRB2(seqlengths, meanPopulations, stdErrors)
%this function fits the zeroth order benchmarking formula

% construct simulated tracing over the two subsystems
simulatedZI = meanPopulations(1,:) + meanPopulations(3,:);
simulatedIZ = meanPopulations(1,:) + meanPopulations(2,:);
simulatedZZ = meanPopulations(1,:) + meanPopulations(4,:);

stdErrorsZI = sqrt(stdErrors(1,:).^2 + stdErrors(3,:).^2);
stdErrorsIZ = sqrt(stdErrors(1,:).^2 + stdErrors(2,:).^2);
stdErrorsZZ = sqrt(stdErrors(1,:).^2 + stdErrors(4,:).^2);


[alpha1, ci1] = dofit(seqlengths, simulatedZI, stdErrorsZI);
[alpha2, ci2] = dofit(seqlengths, simulatedIZ, stdErrorsIZ);
[alpha12, ci12] = dofit(seqlengths, simulatedZZ, stdErrorsZZ);
alphas = [alpha1, alpha2, alpha12];

fprintf('alpha1 = %.04f +/- %.04f, alpha2 = %.04f +/- %.04f, alpha12 = %.04f +/- %.04f\n', [alpha1, ci1, alpha2, ci2, alpha12, ci12]);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function yfit = model(n,vec)

    alpha = vec(1);
    a = vec(2);
    b = vec(3);

    yfit = a*alpha.^n + b;

end

function [alpha, ci] = dofit(seqlengths, data, errors)
    initialGuess=[0.99 0.5 0.5];
    [beta, r, j] = nlinfit(seqlengths, data, @(p, seqlengths) model(seqlengths,p), initialGuess);
    yfit = model(1:max(seqlengths), beta);
    figure();
    plot(seqlengths, data, '.');
    hold on;
    plot(1:max(seqlengths), yfit, 'r');
    xlim([0 max(seqlengths)])
    ylim([-0.05 1.05])

    % get confidence intervals (1 sigma = 68%)
    cis = nlparci(beta,r,'jacobian', j, 'alpha', 0.32);
    cis = (cis(:,2)-cis(:,1))./2;
    
    alpha = beta(1);
    ci = cis(1);
    
    chisquared = sum(r.^2./errors.^2);
    dof = length(seqlengths)-3;
    fprintf('chi^2 = %f (%.03f)\n', chisquared, chisquared/dof);
    if (chisquared/dof > 1)
        fprintf('chi^2 extremal probability: %.02f\n', 1-chi2cdf(chisquared, dof));
    end
end
