function gerror = analyzeRB(ypts)
%analyzeRB Analyzes a randomized benchmarking experiment
% gerror = analyzeRB(ypts)
%   ypts - (optional) <sigma_z> for each experiment, if no arguments provided
%          will grab this data from the current figure

if nargin < 1
    h = gcf;
    line = findall(h, 'Type', 'Line');
    ypts = get(line(1), 'ydata');
    % save figure title
    plotTitle = get(get(gca, 'Title'), 'String');
else
    h = figure;
    plotTitle = '';
end

% seqlengths = [2, 4, 8, 12, 16, 24, 32, 48, 64, 80, 96];
% seqlengths = [2, 4, 8, 16, 32, 64, 96, 128, 192, 256, 320];
%seqlengths = [4,8,16, 32, 64, 128, 192, 256, 320];
%seqlengths = [4,8,16,32, 64, 128, 192, 256];
seqlengths = [16,32, 64, 128, 192,256];
%seqlengths = [4, 8, 16, 32, 64, 128, 256,384];
% seqlengths = [1 2 4 8 16 32 64 126 252];
numRepeats = length(ypts)/length(seqlengths);

xpts2 = seqlengths(1 + floor((0:length(ypts)-1)./numRepeats));

% force long times to <sigma_z> = 0 by rescaling
%midvalue = mean(ypts(end-32+1:end));
%scale = midvalue + 1;
%ypts2 = (ypts+1)./scale - 1;
ypts2 = ypts(:);

avgpts = mean(reshape(ypts, numRepeats, length(seqlengths)));
errors = std(reshape(ypts, numRepeats, length(seqlengths)));

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
fitf = inline('p(1) * (1-p(2)).^n + p(3)','p','n');
[beta, r, j] = nlinfit(seqlengths, avgFidelity, fitf, [0.5 .01 0.5]);

yfit = fitf(beta, 1:seqlengths(end));

% get confidence intervals
ci = nlparci(beta,r,j);
cis = (ci(:,2)-ci(:,1))./2;

plot(yfit, 'r')

labelStr = sprintf('Fit function: a*(1-b)^n+c\n');
labelStr = [labelStr sprintf(' a = %.03f +/- %.03f\n b = %.03f +/- %.03f\n c = %.03f +/- %.03f\n', [beta(1) cis(1) beta(2) cis(2) beta(3) cis(3)])];

text(.7, .85, labelStr, 'FontSize', 12, 'Units', 'normalized');

ylim([min(fidelity) 1.05])

gerror = beta(2)/2;
end