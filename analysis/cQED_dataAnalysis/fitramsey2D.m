function [T2s, freqs] = fitramsey2D(xdata, ydata)
% Fits 2D Ramsey scan
%
% [times, freqs] = fitramsey2D(xdata, ydata)
% xdata : vector of time samples
% ydata : matrix of data (each Ramsey experiment along a row)

numScans = size(ydata,1);
T2s = zeros(numScans, 1);
freqs = zeros(numScans, 1);

beta = zeros(1,4);

for cnt=1:numScans
    y = ydata(cnt,:);

    %Use KT estimation to get initial guesses
    [freqs, Ts, amps] = KT_estimation(y, xdata(2)-xdata(1),2);
    [~, biggestC] = max(abs(amps));

    % model A + B Exp(-t/tau) * cos(w t + phi)
    rabif = inline('p(1) + p(2)*exp(-tdata/p(3)).*cos(p(4)*tdata + p(5))','p','tdata');
    p = [mean(y) abs(amps(biggestC)) Ts(biggestC) 2*pi*freqs(biggestC) 0];
    [beta,r,j] = nlinfit(xdata, y, rabif, p);

    figure(100)
    subplot(3,1,2:3)
    plot(xdata,y,'o')
    hold on
    % construct finer step tdata for plotting fit
    xdata_finer = linspace(0, max(xdata), 4*length(xdata))';
    plot(xdata_finer,rabif(beta,xdata_finer),'-r')
    xlabel('Time [ns]')
    ylabel('<\sigma_z>')
    hold off
    subplot(3,1,1)
    bar(xdata,r)
    axis tight
    xlabel('Time [ns]')
    ylabel('Residuals [V]')
    
    subplot(3,1,2:3)
    %ylim([-1.05 1.05])
    
    pause(.2)

    t2 = beta(3);
    ci = nlparci(beta,r,j);
    t2error = (ci(3,2)-ci(3,1))/2;
    detuning = abs(beta(4))/2/pi; % in GHz, assuming time is in ns
    T2s(cnt) = t2;
    freqs(cnt) = detuning;
end