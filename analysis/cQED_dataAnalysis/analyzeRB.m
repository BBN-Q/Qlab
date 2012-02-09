function analyzeRB(ypts)
    %[xpts ypts] = calScale;
    % if no input arguments, try to get the data from the current figure
    if nargin < 2
        h = gcf;
        line = findall(h, 'Type', 'Line');
        ypts = get(line(1), 'ydata');
        % save figure title
        plotTitle = get(get(gca, 'Title'), 'String');
    else
        h = figure;
    end

    %seqlengths = [2, 4, 8, 12, 16, 24, 32, 48, 64, 80, 96];
    seqlengths = [2, 4, 8, 16, 32, 64, 96, 128, 192, 256, 320];
    xpts2 = seqlengths(1 + floor((0:length(ypts)-1)./32));
    
    % force long times to <sigma_z> = 0 by rescaling
    %midvalue = mean(ypts(end-32+1:end));
    %scale = midvalue + 1;
    %ypts2 = (ypts+1)./scale - 1;
    ypts2 = ypts(:);
    
    avgpts = mean(reshape(ypts, 32, 11));
    errors = std(reshape(ypts, 32, 11));
    
    fidelity = .5 * (1 - ypts2);
    avgFidelity = .5 * (1 - avgpts);
    
    figure(h)
    plot(xpts2, fidelity, '.', 'Color', [.5 .5 .5])
    hold on
    errorbar(seqlengths, avgFidelity, errors/sqrt(32), '.')
    xlabel('Number of Clifford gates')
    ylabel('Fidelity')
    title(plotTitle)
    
    % fit to exponential
    fitf = inline('p(1) * exp(-p(2)*n) + p(3)','p','n');
    [beta, r, j] = nlinfit(seqlengths, avgFidelity, fitf, [1.0 .05 0.5]);

    yfit = beta(1)*exp(-beta(2) * (1:seqlengths(end))) + beta(3);
    
    % get confidence intervals
    ci = nlparci(beta,r,j);
    cis = (ci(:,2)-ci(:,1))./2;

    plot(yfit, 'r')
    fprintf('Fit function: a*exp(-b*n)+c\n');
    fprintf(' a = %.03f +/- %.03f\n b = %.03f +/- %.03f\n c = %.03f +/- %.03f\n', [beta(1) cis(1) beta(2) cis(2) beta(3) cis(3)])
end