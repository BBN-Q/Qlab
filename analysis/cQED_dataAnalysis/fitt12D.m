function [T1s, T1errors] = fitt12D(xdata, ydata)
% Fits 2D Ramsey scan
%
% [T1s, T1errors] = fitt12D(xdata, ydata)
% xdata : vector of time samples
% ydata : matrix of data (each T1 experiment along a row)

numScans = size(ydata,1);
T1s = zeros(numScans, 1);
T1errors = zeros(numScans, 1);

beta = zeros(1,4);

for cnt=1:numScans
    y = ydata(cnt,:);

    % Model: A Exp(-t/tau) + offset
    t1f = @(p,t) p(1)*exp(-t/p(2)) + p(3);
    
    p = [max(y)-min(y), max(xdata)/3., y(end)];
    [beta,r,j] = nlinfit(xdata(:), y(:), t1f, p);

    figure(100)
    subplot(3,1,2:3)
    plot(xdata/1e3,y,'.')
    hold on
    % construct finer step tdata for plotting fit
    xdata_finer = linspace(0, max(xdata), 10*length(xdata))';
    plot(xdata_finer/1e3,t1f(beta,xdata_finer),'-r')
    xlabel('Time [\mus]')
    ylabel('<\sigma_z>')
    hold off
    subplot(3,1,1)
    bar(xdata/1e3,r)
    axis tight
    xlabel('Time [\mus]')
    ylabel('Residuals [V]')
    
    subplot(3,1,2:3)
    ylim([-1.05 1.05])
    
    pause(.2)

    t1 = beta(2);
    ci = nlparci(beta,r,j);
    t1error = (ci(2,2)-ci(2,1))/2;
    T1s(cnt) = t1;
    T1errors(cnt) = t1error;
end