function [t3, t3error,amp] = fitramsey(xdata, ydata)
% Fits rabi data in time range (x-axis) from start to end using a decaying
% sine.

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
    % save figure title
    plotTitle = get(get(gca, 'Title'), 'String');
else
    h = figure;
end
%y = ydata .* 1000;
y = ydata(:);

% if xdata is a single value, assume that it is the time step
if length(xdata) == 1
    xdata = 0:xdata:xdata*(length(y)-1);
end
% construct finer step tdata
xdata_finer = linspace(0, max(xdata), 4*length(xdata));

xdata = xdata(:);
xdata_finer = xdata_finer(:);

% model A + B Exp(-t/tau) * cos(w t + phi)
rabif = inline('p(1) + p(2)*exp(-tdata/p(3)).*cos(p(4)*tdata + p(5))','p','tdata');

% initial guess for amplitude is max - mean
amp = max(y) - mean(y);

% initial guess for Rabi time is length/3
trabi = max(xdata)/3.;

% use largest FFT frequency component to seed Rabi frequency
yfft = fft(ydata);
[freqamp freqpos] = max(abs( yfft(2:floor(end/2)) ));
frabi = 2*pi*(freqpos-1)/xdata(end);

p = [mean(y) amp trabi frabi 0];

tic
[beta,r,j] = nlinfit(xdata, y, rabif, p);
toc

figure(h)
subplot(3,1,2:3)
plot(xdata/1e3,y,'o')
hold on
plot(xdata_finer/1e3,rabif(beta,xdata_finer),'-r')
xlabel('Time [\mus]')
ylabel('<\sigma_z>')
hold off
subplot(3,1,1)
bar(xdata/1e3,r)
axis tight
xlabel('Time [\mus]')
ylabel('Residuals [V]')
title(plotTitle)

subplot(3,1,2:3)
ylim([-1.05 1.05])

t2 = beta(3);
ci = nlparci(beta,r,j);
t2error = (ci(3,2)-ci(3,1))/2;
detuning = abs(beta(4))/2/pi; % in GHz, assuming time is in ns
detuningError = (ci(4,2)-ci(4,1))/2;

% annotate the graph with T_Rabi result
text(xdata(end-1)/1e3, max(y), ...
    sprintf(['T_{2}^{*} = %.1f +/- %.1f us \n' ...
        '\\delta/2\\pi = %.3f +/- %.3f MHz'], t2/1e3, t2error/1e3, detuning*1e3, detuningError*1e3), ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
axis tight
% if you want confidence bands, use something like:
% ci = nlparci(beta,r,j);
% [ypred,delta] = nlpredci(rabif,x,beta,r,j);